import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house.fill")
            }
            .tag(AppTab.accueil)

            NavigationStack {
                BilanTabRootView()
            }
            .tabItem {
                Label("Bilan", systemImage: "doc.text.fill")
            }
            .tag(AppTab.bilan)

            NavigationStack {
                SuiviDashboardView()
            }
            .tabItem {
                Label("Suivi", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.suivi)

            NavigationStack {
                JournalView()
            }
            .tabItem {
                Label("Journal", systemImage: "fork.knife")
            }
            .tag(AppTab.journal)

            NavigationStack {
                CoursesTabRootView()
            }
            .tabItem {
                Label("Courses", systemImage: "cart.fill")
            }
            .tag(AppTab.courses)
        }
        .tint(CarenceColors.primary)
        .preferredColorScheme(.light)
        .sheet(isPresented: $tabRouter.showCheckInSheet) {
            NavigationStack {
                DailyCheckInView()
                    .environmentObject(tracker)
                    .environmentObject(tabRouter)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                tabRouter.consumePendingCheckInIfNeeded()
            }
        }
        .task {
            await SmartNotificationService.evaluateAndSchedule(tracker: tracker)
        }
    }
}

struct BilanTabRootView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var showFullResults = false
    @State private var showProfil = false

    var body: some View {
        Group {
            if ResultsStorage.hasSavedResults {
                BilanSummaryView(onVoirDetail: { showFullResults = true })
                    .onAppear {
                        vm.loadSavedResults()
                        if tabRouter.highlightSummaryOnBilan {
                            tabRouter.highlightSummaryOnBilan = false
                        }
                    }
            } else {
                bilanVide
            }
        }
        .navigationDestination(isPresented: $showFullResults) {
            ResultsView(onRestart: {
                vm.resetQuestionnaire()
                showFullResults = false
                showProfil = true
            })
        }
        .navigationDestination(isPresented: $showProfil) {
            ProfilView()
        }
    }

    private var bilanVide: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Pas encore de bilan")
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
            Text("Répondez au questionnaire pour obtenir votre résumé personnalisé et le parcours « Et maintenant ? ».")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(.horizontal, 32)
            Button {
                vm.restoreDraftIfNeeded()
                showProfil = true
            } label: {
                Text("Commencer le questionnaire")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CarenceColors.primary)
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoursesTabRootView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var section: CoursesHubSection = .liste

    private var scores: [ScoreResult] {
        vm.scores.isEmpty ? (ResultsStorage.load()?.scores ?? []) : vm.scores
    }

    private var symptomes: [String] {
        vm.symptomesSelectionnes.isEmpty
            ? (ResultsStorage.load()?.symptomeSelections.map(\.symptomeId) ?? [])
            : Array(vm.symptomesSelectionnes)
    }

    private var recettesCount: Int {
        RecettesEngine.nombreRecettesDansBase
    }

    var body: some View {
        Group {
            if ResultsStorage.hasSavedResults, !scores.isEmpty {
                VStack(spacing: 0) {
                    Picker("Section", selection: $section) {
                        Text("🛒 Liste").tag(CoursesHubSection.liste)
                        Text("🍳 Recettes (\(recettesCount))").tag(CoursesHubSection.recettes)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(CarenceColors.surface)

                    switch section {
                    case .liste:
                        ListeCoursesView(
                            scores: scores,
                            symptomesDetectes: symptomes,
                            showHomeButton: false,
                            embedded: true
                        )
                    case .recettes:
                        RecettesView(scores: scores, showHomeButton: false, embedded: true)
                    }
                }
                .navigationTitle(section == .liste ? "Liste de courses" : "Recettes pour vous")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                coursesVide
            }
        }
        .onAppear {
            vm.loadSavedResults()
            section = tabRouter.coursesSection
        }
        .onChange(of: tabRouter.coursesSection) { _, newSection in
            section = newSection
        }
    }

    private var coursesVide: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Courses & recettes")
                .font(.title2.bold())
            Text("Complétez d'abord votre bilan pour générer une liste et des recettes adaptées à vos carences.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Courses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
