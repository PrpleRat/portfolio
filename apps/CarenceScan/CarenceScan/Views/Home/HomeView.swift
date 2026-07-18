import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var showProfil = false
    @State private var showQuestionnaire = false
    @State private var showMedicaments = false
    @State private var showContextes = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                BrandHeader()

                VStack(spacing: 12) {
                    Text("Identifiez vos carences en 2 minutes")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(CarenceColors.textPrimary)

                    Text("Basé sur vos symptômes. Gratuit. Confidentiel.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(CarenceColors.textSecondary)
                }

                ResumeBannerView { etape in
                    resumeVers(etape)
                }

                Button {
                    vm.restoreDraftIfNeeded()
                    showProfil = true
                } label: {
                    Text(ResultsStorage.hasSavedResults ? "Refaire le questionnaire" : "Commencer le questionnaire")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(CarenceColors.primary)
                .accessibilityLabel("Commencer le questionnaire")

                if ResultsStorage.hasSavedResults {
                    accesRapidesSection
                }

                NavigationLink {
                    SymptomesEncyclopedieView()
                } label: {
                    Label("Encyclopédie des symptômes", systemImage: "book.pages")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                NavigationLink {
                    GlossaireView()
                } label: {
                    Label("Glossaire médical", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationDestination(isPresented: $showProfil) {
            ProfilView()
        }
        .navigationDestination(isPresented: $showQuestionnaire) {
            QuestionnaireView()
        }
        .navigationDestination(isPresented: $showMedicaments) {
            MedicamentsView()
        }
        .navigationDestination(isPresented: $showContextes) {
            ContextesMedicauxView()
        }
    }

    private func resumeVers(_ etape: QuestionnaireStep) {
        switch etape {
        case .profil:
            showProfil = true
        case .symptomes:
            showQuestionnaire = true
        case .medicaments:
            showMedicaments = true
        case .contextes:
            showContextes = true
        case .resultats:
            tabRouter.openBilanSummary()
        }
    }

    private var accesRapidesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accès rapide")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            Button {
                tabRouter.openBilanSummary()
            } label: {
                Label("Mon résumé de bilan", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)

            Button {
                tabRouter.openRecettes()
            } label: {
                Label("Mes recettes personnalisées", systemImage: "fork.knife")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)

            Button {
                tabRouter.openCourses(section: .liste)
            } label: {
                Label("Ma liste de courses", systemImage: "cart.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)

            Button {
                tabRouter.openSuivi()
            } label: {
                Label("Tableau de suivi", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }
}

struct BrandHeader: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: compact ? 28 : 56))
                .foregroundStyle(CarenceColors.primary)
                .accessibilityHidden(true)

            Text(AppConstants.appName)
                .font(compact ? .headline.bold() : .largeTitle.bold())
                .foregroundStyle(CarenceColors.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AppConstants.appName), application de bilan carences")
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(QuestionnaireViewModel())
            .environmentObject(SymptomTrackerViewModel.shared)
            .environmentObject(AppTabRouter())
    }
}
