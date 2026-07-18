import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var tracker: SleepTracker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [AlarmConfig]
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var allFactors: [SleepFactor]
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var completedSessions: [SleepSession]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: MainTab = .home
    @State private var showTrackingFromURL = false
    @State private var recoveryAlertMessage: String?

    private var tracksMenstrualCycle: Bool {
        profiles.first?.tracksMenstrualCycle ?? false
    }

    var body: some View {
        ThemeReader {
            Group {
                if hasCompletedOnboarding {
                    mainTabs
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .onOpenURL(perform: handleDeepLink)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background || phase == .inactive {
                    tracker.persistBeforeBackgroundIfTracking()
                }
            }
            .onChange(of: tracksMenstrualCycle) { _, enabled in
                if !enabled, selectedTab == .cycle {
                    selectedTab = .settings
                }
            }
            .task(id: hasCompletedOnboarding) {
                guard hasCompletedOnboarding else { return }
                await runInterruptedSessionRecovery()
            }
            .alert("Nuit récupérée", isPresented: recoveryAlertBinding) {
                Button("OK", role: .cancel) {}
                Button("Voir l’historique") {
                    selectedTab = .history
                }
            } message: {
                if let recoveryAlertMessage {
                    Text(recoveryAlertMessage)
                }
            }
            .fullScreenCover(isPresented: $showTrackingFromURL) {
                TrackingActiveView {
                    showTrackingFromURL = false
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sleeplab" else { return }
        switch url.host {
        case "home": selectedTab = .home
        case "history": selectedTab = .history
        case "dreams": selectedTab = .dreams
        case "insights": selectedTab = .insights
        case "cycle":
            if tracksMenstrualCycle { selectedTab = .cycle }
        case "profile", "settings": selectedTab = .settings
        case "tracking":
            selectedTab = .home
            if tracker.isTracking { showTrackingFromURL = true }
        case "wake":
            selectedTab = .home
            Task { await handleWakeRequest() }
        default: selectedTab = .home
        }
    }

    private func handleWakeRequest() async {
        guard tracker.isTracking else { return }
        await tracker.requestWakeFromLiveActivity()
        if tracker.lastCompletedSession != nil {
            showTrackingFromURL = true
        }
    }

    private var recoveryAlertBinding: Binding<Bool> {
        Binding(
            get: { recoveryAlertMessage != nil },
            set: { if !$0 { recoveryAlertMessage = nil } }
        )
    }

    @MainActor
    private func runInterruptedSessionRecovery() async {
        guard !tracker.isTracking else { return }
        tracker.configure(
            context: modelContext,
            profile: profiles.first,
            alarm: alarms.first
        )
        do {
            _ = try SleepNightGrouper.mergeFragmentedWakeDaySessions(in: modelContext)
            let recovered = try InterruptedSleepRecovery.recoverSessions(
                in: modelContext,
                profile: profiles.first,
                skipIfTracking: tracker.isTracking
            )
            _ = try SleepNightGrouper.mergeFragmentedWakeDaySessions(in: modelContext)
            guard let first = recovered.first else {
                SleepFactorAttribution.relinkAll(
                    sessions: completedSessions,
                    allFactors: allFactors,
                    in: modelContext
                )
                SleepPhaseBackfill.repairStoredSessions(
                    sessions: completedSessions,
                    profile: profiles.first,
                    in: modelContext
                )
                return
            }
            SleepFactorAttribution.relinkAll(
                sessions: completedSessions,
                allFactors: allFactors,
                in: modelContext
            )
            SleepPhaseBackfill.repairStoredSessions(
                sessions: completedSessions,
                profile: profiles.first,
                in: modelContext
            )
            let healthKit = HealthKitService()
            for item in recovered {
                await healthKit.exportSessionToHealth(item.session)
            }
            let dateText = first.session.startTime.formatted(date: .abbreviated, time: .omitted)
            let count = recovered.count
            if count == 1 {
                recoveryAlertMessage =
                    "Ta nuit du \(dateText) avait été interrompue quand l’iPhone a arrêté l’app. Elle est de nouveau dans l’historique (fin estimée vers \(first.estimatedEnd.formatted(date: .omitted, time: .shortened)))."
            } else {
                recoveryAlertMessage =
                    "\(count) nuits interrompues ont été récupérées, dont celle du \(dateText)."
            }
        } catch {
            // Pas de blocage utilisateur si la récupération échoue.
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "moon.stars.fill") }
                .tag(MainTab.home)

            HistoryView()
                .tabItem { Label("Historique", systemImage: "calendar") }
                .tag(MainTab.history)

            DreamJournalView()
                .tabItem { Label("Rêves", systemImage: "book.closed.fill") }
                .tag(MainTab.dreams)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(MainTab.insights)

            if tracksMenstrualCycle {
                CycleTabRootView()
                    .tabItem { Label("Cycle", systemImage: "heart.circle.fill") }
                    .tag(MainTab.cycle)
            }

            ProfileView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
                .tag(MainTab.settings)
        }
    }
}
