import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var sessions: [SleepSession]
    @Query(sort: \DreamEntry.dreamDate, order: .reverse) private var dreams: [DreamEntry]
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var allFactors: [SleepFactor]

    @State private var dashboard: SleepInsightsDashboard = InsightsAnalytics.emptyDashboard()
    @State private var isRefreshingInsights = false

    private var dashboardTaskKey: String {
        let nightCount = sessions.filter { $0.kind == .night && $0.endTime != nil }.count
        let latest = sessions.first?.overallScore ?? 0
        return "\(nightCount)-\(sessions.count)-\(allFactors.count)-\(latest)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        tipsSection
                        overviewSection
                        scoreTrendSection
                        if dashboard.durationTrend.count >= 2 {
                            durationSection
                        }
                        if !dashboard.weekdayScores.isEmpty {
                            weekdaySection
                        }
                        if let phases = dashboard.phaseAverages {
                            phasesSection(phases)
                        }
                        if !dashboard.phaseBars.isEmpty {
                            phaseChartSection
                        }
                        if let health = dashboard.health {
                            healthSection(health)
                        }
                        if let sound = dashboard.sound {
                            soundSection(sound)
                        }
                        if !dashboard.topFactors.isEmpty {
                            factorsUsageSection
                        }
                        if !dashboard.factorComparisons.isEmpty {
                            comparisonsSection
                        }
                        if !dashboard.cyclePhases.isEmpty {
                            cycleSection
                        }
                        if let records = dashboard.records {
                            recordsSection(records)
                        }
                        correlationsSection
                        extendedCorrelationsSection
                        InsightEngineSection(sessions: sessions, dreams: dreams)
                    }
                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Insights")
            .overlay {
                if isRefreshingInsights {
                    ProgressView()
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .task(id: dashboardTaskKey) {
                await refreshDashboard()
            }
        }
    }

    @MainActor
    private func refreshDashboard() async {
        let snapshotSessions = sessions
        let snapshotFactors = allFactors
        isRefreshingInsights = true
        let built = await Task.detached(priority: .userInitiated) {
            InsightsAnalytics.build(from: snapshotSessions, allFactors: snapshotFactors)
        }.value
        dashboard = built
        isRefreshingInsights = false
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(SleepTheme.accent)
            Text("Pas encore de données")
                .font(.headline)
            Text("Enregistre ta première nuit ou importe depuis Santé (Profil) pour voir tes stats.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var tipsSection: some View {
        Group {
            if !dashboard.tips.isEmpty {
                InsightsCard {
                    InsightsSectionHeader(title: "Pour toi", icon: "sparkles", subtitle: "Basé sur tes dernières nuits")
                    TipsList(tips: dashboard.tips)
                }
            }
        }
    }

    private var overviewSection: some View {
        InsightsCard {
            InsightsSectionHeader(title: "Vue d’ensemble", icon: "gauge.with.dots.needle.67percent")
            OverviewStatsGrid(overview: dashboard.overview)
        }
    }

    private var scoreTrendSection: some View {
        InsightsCard {
            InsightsSectionHeader(
                title: "Évolution du score",
                icon: "chart.line.uptrend.xyaxis",
                subtitle: "14 dernières nuits"
            )
            if dashboard.scoreTrend.count < 2 {
                Text("Encore \(2 - dashboard.scoreTrend.count) nuit(s) pour la courbe.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            } else {
                ScoreTrendChart(
                    points: dashboard.scoreTrend,
                    average: dashboard.overview.avgScoreAll
                )
            }
        }
    }

    private var durationSection: some View {
        InsightsCard {
            InsightsSectionHeader(title: "Durée de sommeil", icon: "bed.double.fill")
            DurationTrendChart(points: dashboard.durationTrend)
        }
    }

    private var weekdaySection: some View {
        InsightsCard {
            InsightsSectionHeader(
                title: "Score par jour",
                icon: "calendar",
                subtitle: "Quel jour tu récupères le mieux ?"
            )
            WeekdayScoreChart(data: dashboard.weekdayScores)
        }
    }

    private func phasesSection(_ phases: PhaseAverages) -> some View {
        InsightsCard {
            InsightsSectionHeader(title: "Architecture du sommeil", icon: "waveform.path.ecg")
            PhaseDonutRow(averages: phases)
            Divider().opacity(0.3)
            HStack {
                miniStat("Profond", "\(phases.avgDeepMinutes) min")
                miniStat("REM", "\(phases.avgRemMinutes) min")
                miniStat("Réveils", String(format: "%.1f", phases.avgAwakenings))
            }
        }
    }

    private var phaseChartSection: some View {
        InsightsCard {
            InsightsSectionHeader(title: "Répartition par nuit", icon: "chart.bar.fill", subtitle: "100 % = phases")
            PhaseStackedChart(bars: dashboard.phaseBars)
        }
    }

    private func healthSection(_ health: HealthAverages) -> some View {
        InsightsCard {
            InsightsSectionHeader(title: "Santé (Apple Health)", icon: "heart.fill", subtitle: "\(health.nightsWithData) nuits avec données")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let hr = health.avgHeartRate {
                    StatTile(title: "FC moyenne", value: String(format: "%.0f bpm", hr), footnote: nil)
                }
                if let hrv = health.avgHRV {
                    StatTile(title: "VFC moyenne", value: String(format: "%.0f ms", hrv), footnote: "Variabilité cardiaque")
                }
                if let spo2 = health.avgSpO2 {
                    let pct = spo2 <= 1.5 ? spo2 * 100 : spo2
                    StatTile(title: "SpO₂ moyen", value: String(format: "%.0f %%", pct), footnote: nil)
                }
            }
        }
    }

    private func soundSection(_ sound: SoundInsights) -> some View {
        InsightsCard {
            InsightsSectionHeader(title: "Audio nocturne", icon: "waveform")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatTile(
                    title: "Ronflement moy.",
                    value: String(format: "%.0f min", sound.avgSnoringMinutes),
                    footnote: "\(sound.nightsWithSnoring) nuits détectées"
                )
                StatTile(
                    title: "Événements sonores",
                    value: "\(sound.totalSoundEvents)",
                    footnote: sound.topSoundType.map { "Souvent : \($0.displayName)" }
                )
            }
        }
    }

    private var factorsUsageSection: some View {
        InsightsCard {
            InsightsSectionHeader(title: "Facteurs les plus notés", icon: "list.bullet.clipboard")
            FactorUsageChart(usage: dashboard.topFactors)
        }
    }

    private var comparisonsSection: some View {
        InsightsCard {
            InsightsSectionHeader(
                title: "Avec vs sans",
                icon: "arrow.left.arrow.right",
                subtitle: "Impact moyen sur ton score"
            )
            VStack(spacing: 12) {
                ForEach(dashboard.factorComparisons) { c in
                    FactorComparisonRow(comparison: c)
                }
            }
        }
    }

    private var cycleSection: some View {
        InsightsCard {
            InsightsSectionHeader(title: "Cycle & score", icon: "circle.dotted")
            Chart(dashboard.cyclePhases) { item in
                BarMark(
                    x: .value("Phase", item.phaseName),
                    y: .value("Score", item.averageScore)
                )
                .foregroundStyle(SleepTheme.accent.gradient)
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 160)
        }
    }

    private func recordsSection(_ records: PersonalRecords) -> some View {
        InsightsCard {
            InsightsSectionHeader(title: "Records perso", icon: "trophy.fill")
            RecordsRow(records: records)
        }
    }

    private var correlationsSection: some View {
        InsightsCard {
            InsightsSectionHeader(
                title: "Corrélations",
                icon: "point.topleft.down.curvedto.point.bottomright.up",
                subtitle: dashboard.correlationReport.minimumNightsMet
                    ? "Liens statistiques facteur ↔ score"
                    : "Disponible après \(InsightsAnalytics.correlationMinimum) nuits"
            )
            if dashboard.correlationReport.minimumNightsMet {
                impactList(title: "Ce qui t’aide", impacts: dashboard.correlationReport.topPositive, positive: true)
                impactList(title: "Ce qui te pénalise", impacts: dashboard.correlationReport.topNegative, positive: false)
            } else {
                Text("Encore \(max(0, InsightsAnalytics.correlationMinimum - sessions.count)) nuit(s) pour des corrélations fiables.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }

    // MARK: - Helpers UI

    private func miniStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold())
            Text(title).font(.caption2).foregroundStyle(SleepTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var extendedCorrelationsSection: some View {
        InsightsCard {
            InsightsSectionHeader(
                title: "Corrélations détaillées",
                icon: "arrow.triangle.branch",
                subtitle: dashboard.extendedCorrelations.minimumNightsMet
                    ? "Facteur ↔ métrique de sommeil"
                    : "Après \(InsightsAnalytics.correlationMinimum) nuits"
            )
            if dashboard.extendedCorrelations.minimumNightsMet {
                if !dashboard.extendedCorrelations.metricCorrelations.isEmpty {
                    metricCorrelationList(
                        title: "Substances & habitudes",
                        items: dashboard.extendedCorrelations.metricCorrelations
                    )
                }
                if !dashboard.extendedCorrelations.stressDurationLinks.isEmpty {
                    metricCorrelationList(
                        title: "Bien-être & architecture",
                        items: dashboard.extendedCorrelations.stressDurationLinks
                    )
                }
            } else {
                Text("Encore \(max(0, InsightsAnalytics.correlationMinimum - sessions.count)) nuit(s) pour croiser facteurs, durée, phases et ronflement.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }

    private func metricCorrelationList(title: String, items: [MetricFactorCorrelation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.bold())
            ForEach(items) { link in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: link.factor.sfSymbol)
                        .foregroundStyle(SleepTheme.accent)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(link.factor.displayName) → \(link.metric.displayName)")
                            .font(.caption.bold())
                        Text(link.insight)
                            .font(.caption2)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    Spacer()
                    Text(String(format: "%+.0f%%", link.correlation * 100))
                        .font(.caption.bold())
                        .foregroundStyle(link.correlation >= 0 ? .green : .orange)
                }
            }
        }
        .padding(.top, 4)
    }

    private func impactList(title: String, impacts: [FactorImpact], positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.bold())
            if impacts.isEmpty {
                Text("Pas assez de signal.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            ForEach(impacts) { impact in
                NavigationLink {
                    FactorImpactView(impact: impact)
                } label: {
                    HStack {
                        Image(systemName: impact.factor.sfSymbol)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(impact.factor.displayName).font(.caption.bold())
                            Text(impact.insight)
                                .font(.caption2)
                                .foregroundStyle(SleepTheme.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", abs(impact.correlation) * 100))
                            .font(.caption.bold())
                            .foregroundStyle(positive ? .green : .orange)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}
