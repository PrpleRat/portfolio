import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var completedSessions: [SleepSession]
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [AlarmConfig]
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var recentFactors: [SleepFactor]
    @Query(filter: #Predicate<DailySubstanceRoutine> { $0.isActive }) private var activeRoutines: [DailySubstanceRoutine]

    @EnvironmentObject private var tracker: SleepTracker
    @AppStorage("showAdvancedHomeInsights") private var showAdvancedHomeInsights = false
    @State private var showPreSleep = false
    @State private var showNapStart = false
    @State private var showTracking = false

    private var lastSession: SleepSession? { sessions.first { $0.endTime != nil } }

    private var sleepDebtReport: SleepDebtEngine.SleepDebtReport {
        SleepDebtEngine.report(sessions: completedSessions, profile: profiles.first)
    }

    private var contextualFactors: [SleepFactor] {
        SleepFactorAttribution.factorsForCurrentContext(
            sessions: completedSessions,
            allFactors: recentFactors
        )
    }

    private var energyForecast: CircadianEnergyEngine.Forecast? {
        CircadianEnergyEngine.forecast(
            sessions: completedSessions,
            profile: profiles.first,
            factors: contextualFactors
        )
    }

    private var morningRecovery: MorningRecoveryEngine.MorningRecoveryScore? {
        MorningRecoveryEngine.score(
            sessions: completedSessions,
            profile: profiles.first,
            factors: contextualFactors
        )
    }

    private var bedtimeRecommendation: BedtimeAdvisor.BedtimeRecommendation? {
        BedtimeAdvisor.recommend(
            profile: profiles.first,
            sessions: completedSessions,
            factors: contextualFactors
        )
    }

    private var medWarnings: [MedicationInteractionEngine.InteractionWarning] {
        MedicationInteractionEngine.warnings(
            factors: contextualFactors,
            routines: activeRoutines
        )
    }

    private var caffeineInsight: CaffeinePersonalizationEngine.CaffeineInsight? {
        CaffeinePersonalizationEngine.insight(
            factors: recentFactors,
            sessions: completedSessions
        )
    }

    private var cycleSleepComparison: CycleSleepAnalytics.PhaseComparison? {
        CycleSleepAnalytics.compare(sessions: completedSessions, profile: profiles.first)
    }

    private var eveningAdvice: EveningAdviceEngine.EveningAdvice? {
        EveningAdviceEngine.advice(profile: profiles.first)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if tracker.isTracking {
                        NavigationLink { TrackingActiveView() } label: {
                            trackingBanner
                        }
                    } else {
                        startNightCard
                    }

                    if !tracker.isTracking {
                        HomeQuickGuideCard()
                        if !contextualFactors.isEmpty {
                            FactorInfluenceCard(
                                factors: contextualFactors,
                                allFactors: recentFactors,
                                sessions: completedSessions
                            )
                        }
                        coreInsightsSection
                        advancedInsightsToggle
                        if showAdvancedHomeInsights {
                            advancedInsightsSection
                        }
                    }

                    if let session = lastSession {
                        lastNightCard(session)
                    } else if !tracker.isTracking {
                        emptyState
                    }

                    phaseBars
                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle(AppBrand.displayName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FactorJournalView()
                    } label: {
                        Label("Journal", systemImage: "list.bullet.clipboard")
                    }
                }
            }
            .sheet(isPresented: $showPreSleep) {
                PreSleepView(onStart: {
                    showPreSleep = false
                    showTracking = true
                })
            }
            .sheet(isPresented: $showNapStart) {
                NapStartView(onStart: {
                    showNapStart = false
                    showTracking = true
                })
            }
            .fullScreenCover(isPresented: $showTracking) {
                TrackingActiveView {
                    showTracking = false
                }
            }
            .onAppear {
                tracker.configure(
                    context: modelContext,
                    profile: profiles.first,
                    alarm: alarms.first
                )
                if let rec = bedtimeRecommendation {
                    DailyRoutineNotificationScheduler.scheduleBedtimeReminder(recommendation: rec)
                }
            }
            .onChange(of: tracker.isTracking) { _, isTracking in
                if !isTracking {
                    showTracking = false
                }
            }
        }
    }

    @ViewBuilder
    private var coreInsightsSection: some View {
        if completedSessions.contains(where: { $0.kind == .night }) {
            SleepDebtCard(report: sleepDebtReport)
        }
        if let energyForecast {
            CircadianEnergyCard(forecast: energyForecast)
        }
        if let bedtimeRecommendation {
            BedtimeRecommendationCard(recommendation: bedtimeRecommendation)
        }
    }

    private var advancedInsightsToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAdvancedHomeInsights.toggle()
            }
        } label: {
            HStack {
                Label(
                    showAdvancedHomeInsights ? "Masquer les détails" : "Voir analyses détaillées",
                    systemImage: showAdvancedHomeInsights ? "chevron.up" : "chevron.down"
                )
                .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(SleepTheme.accent)
    }

    @ViewBuilder
    private var advancedInsightsSection: some View {
        if let morningRecovery {
            MorningRecoveryCard(score: morningRecovery)
        }
        if !medWarnings.isEmpty {
            MedicationWarningsBanner(warnings: medWarnings)
        }
        if let caffeineInsight {
            CaffeineInsightCard(insight: caffeineInsight)
        }
        if let eveningAdvice {
            EveningAdviceCard(advice: eveningAdvice)
        }
        if let cycleSleepComparison {
            CyclePhaseSleepCard(comparison: cycleSleepComparison)
        }
    }

    private var startNightCard: some View {
        VStack(spacing: 12) {
            Button {
                showPreSleep = true
            } label: {
                startCardRow(
                    icon: SleepSessionKind.night.systemImage,
                    title: SleepSessionKind.night.startActionTitle,
                    subtitle: "Une nuit → score, dette, coucher conseillé"
                )
            }
            .buttonStyle(.fullAreaTap)

            Button {
                showNapStart = true
            } label: {
                startCardRow(
                    icon: SleepSessionKind.nap.systemImage,
                    title: SleepSessionKind.nap.startActionTitle,
                    subtitle: "Éclair 20 min · récup 26 min · cycle 90 min"
                )
            }
            .buttonStyle(.fullAreaTap)
        }
    }

    private func startCardRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(SleepTheme.textPrimary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var trackingBanner: some View {
        HStack {
            Image(systemName: "waveform")
                .symbolEffect(.pulse)
            Text(tracker.currentSession?.kind.trackingTitle ?? "Tracking en cours…")
            Spacer()
            Text(formatDuration(tracker.elapsed))
                .monospacedDigit()
        }
        .padding()
        .background(SleepTheme.accent.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func lastNightCard(_ session: SleepSession) -> some View {
        VStack(spacing: 16) {
            HStack {
                Label(session.kind.displayName, systemImage: session.kind.systemImage)
                    .font(.headline)
                Spacer()
            }

            SleepScoreView(
                score: session.overallScore,
                label: SleepScoreCalculator.labelForScore(session.overallScore, kind: session.kind)
            )

            HStack(spacing: 16) {
                statItem("Durée", formatDuration(session.totalDuration))
                if let est = SleepPhaseTheoreticalEstimate.estimate(for: session) {
                    statItem("Profond", "~\(est.deepMinutes)m")
                    statItem("REM", "~\(est.remMinutes)m")
                } else {
                    statItem("Profond", "\(session.deepSleepMinutes)m")
                    statItem("REM", "\(session.remSleepMinutes)m")
                }
            }

            if let est = SleepPhaseTheoreticalEstimate.estimate(for: session) {
                TheoreticalPhaseEstimateCard(architecture: est, compact: true)
            }

            NavigationLink("Voir le détail") {
                NightDetailView(session: session)
            }
            .buttonStyle(.borderedProminent)
            .tint(SleepTheme.accent)

            Button {
                showPreSleep = true
            } label: {
                Label("Recommencer une nuit", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(SleepTheme.accent)
            .disabled(tracker.isTracking)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundStyle(SleepTheme.accent)
            Text("Aucune nuit enregistrée")
                .font(.headline)
            Text("Pose ton iPhone sur le matelas, écran vers le bas, et lance une nuit.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var phaseBars: some View {
        Group {
            if let s = lastSession, s.totalDuration > 0 {
                HStack(spacing: 4) {
                    phaseBar(minutes: s.deepSleepMinutes, color: SleepTheme.phaseDeep)
                    phaseBar(minutes: s.lightSleepMinutes, color: SleepTheme.phaseLight)
                    phaseBar(minutes: s.remSleepMinutes, color: SleepTheme.phaseREM)
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
        }
    }

    private func phaseBar(minutes: Int, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(maxWidth: .infinity)
            .layoutPriority(Double(max(1, minutes)))
    }

    private func statItem(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundStyle(SleepTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return "\(h)h\(String(format: "%02d", m))"
    }
}
