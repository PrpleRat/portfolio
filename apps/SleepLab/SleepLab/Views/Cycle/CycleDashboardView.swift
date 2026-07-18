import Charts
import SwiftData
import SwiftUI

struct CycleDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @Query(sort: \DreamEntry.dreamDate, order: .reverse) private var dreams: [DreamEntry]
    @Query private var profiles: [UserProfile]

    @State private var snapshot: CycleSnapshot?
    @State private var insight: CyclePeriodEngine.CycleInsight?
    @State private var phaseStats: [PhaseSleepStats] = []
    @State private var sparkline: [CycleDayScorePoint] = []
    @State private var todaySymptom: DailySymptom?
    @State private var isLoading = true
    private let cycleService = MenstrualCycleService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView("Lecture du cycle…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let snapshot {
                    periodQuickActions
                    if let insight {
                        comfortCard(insight)
                        predictionRow(insight)
                    }
                    cycleHeader(snapshot)
                    NavigationLink {
                        CyclePeriodCalendarView()
                    } label: {
                        Label("Modifier le calendrier des règles", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(SleepTheme.accent)
                    PhaseTimelineCard(
                        snapshot: snapshot,
                        sparkline: sparkline,
                        currentPhase: snapshot.phase
                    )
                    phaseStatsGrid
                    if let todaySymptom {
                        SymptomQuickLogRow(symptom: todaySymptom)
                        linkedNightsSection
                    }
                } else {
                    emptyCycleState
                }

                Text("À titre indicatif, non médical.")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                MedicalDisclaimer()
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Cycle & sommeil")
        .navigationBarTitleDisplayMode(.large)
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var emptyCycleState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commence ton suivi")
                .font(.headline)
            Text("Marque tes jours de règles dans le calendrier — c’est le plus simple et le plus fiable pour calculer ta phase et t’accompagner sur le sommeil.")
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)
            NavigationLink {
                CyclePeriodCalendarView()
            } label: {
                Label("Ouvrir le calendrier des règles", systemImage: "calendar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SleepTheme.accent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var periodQuickActions: some View {
        HStack(spacing: 12) {
            Button {
                CyclePeriodEngine.setPeriodDay(Date(), flow: .medium, in: modelContext)
                Task { await reload() }
            } label: {
                Label("Règles aujourd’hui", systemImage: "drop.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.85, green: 0.35, blue: 0.45))

            NavigationLink {
                CyclePeriodCalendarView()
            } label: {
                Label("Calendrier", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func comfortCard(_ insight: CyclePeriodEngine.CycleInsight) -> some View {
        let card = CycleComfortContent.card(
            phase: insight.phase,
            isOnPeriod: insight.isOnPeriodToday,
            daysUntilNextPeriod: insight.daysUntilNextPeriod
        )
        return VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.headline)
            Text(card.message)
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)
            Divider().opacity(0.3)
            Label(card.sleepTip, systemImage: "moon.zzz.fill")
                .font(.caption)
            Label(card.selfCare, systemImage: "heart.fill")
                .font(.caption)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func predictionRow(_ insight: CyclePeriodEngine.CycleInsight) -> some View {
        HStack {
            if let d = insight.daysUntilNextPeriod, let next = insight.predictedNextPeriodStart {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prochaines règles estimées")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                    Text("Dans \(d) j · \(next.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline.weight(.medium))
                }
            }
            Spacer()
            if insight.isOnPeriodToday {
                Text("En cours")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.85, green: 0.35, blue: 0.45).opacity(0.3))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 4)
    }

    private func cycleHeader(_ snap: CycleSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Jour \(snap.cycleDay) / \(snap.cycleLength)")
                    .font(.title2.bold())
                Spacer()
                Text(snap.phase.displayName)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(phaseColor(snap.phase).opacity(0.25))
                    .foregroundStyle(phaseColor(snap.phase))
                    .clipShape(Capsule())
            }
            Text("Début de cycle : \(snap.periodStart.formatted(date: .abbreviated, time: .omitted)) · Source : \(snap.source)")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
        }
    }

    private var phaseStatsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Par phase")
                .font(.headline)
            ForEach(phaseStats) { stat in
                HStack(spacing: 12) {
                    Circle()
                        .fill(phaseColor(stat.phase))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.phase.displayName)
                            .font(.subheadline.weight(.medium))
                        Text("\(stat.sessionCount) nuit\(stat.sessionCount > 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(stat.averageScore.map { "Score \(Int($0))" } ?? "Score —")
                            .font(.subheadline.bold())
                        Label(stat.dominantEmotionLabel, systemImage: stat.dominantDreamEmotion?.sfSymbol ?? "moon.zzz")
                            .font(.caption2)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }
                .padding(12)
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var linkedNightsSection: some View {
        Group {
            if let todaySymptom {
                let linked = CycleAnalytics.sessions(on: todaySymptom.dayStart, from: sessions)
                if !linked.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nuits liées (aujourd’hui)")
                            .font(.headline)
                        ForEach(Array(linked.prefix(3))) { session in
                            HStack {
                                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text("Score \(session.overallScore)")
                                    .foregroundStyle(SleepTheme.accent)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private func reload() async {
        isLoading = true
        defer { isLoading = false }
        let profile = profiles.first
        snapshot = await cycleService.currentSnapshot(profile: profile, modelContext: modelContext)
        let logged = CyclePeriodEngine.loggedDaySet(in: modelContext)
        let healthStart = await cycleService.latestPeriodStartFromHealthKit()
        insight = CyclePeriodEngine.buildInsight(
            profile: profile,
            loggedDays: logged,
            healthPeriodStart: healthStart
        )
        if let profile, let insight {
            CyclePeriodEngine.syncProfile(profile, insight: insight, loggedDays: logged)
        }

        guard let snapshot else {
            phaseStats = []
            sparkline = []
            insight = nil
            todaySymptom = CycleAnalytics.symptom(in: modelContext)
            try? modelContext.save()
            return
        }
        phaseStats = CycleAnalytics.phaseStats(
            sessions: sessions,
            dreams: dreams,
            snapshot: snapshot
        )
        sparkline = CycleAnalytics.sparklinePoints(sessions: sessions, snapshot: snapshot)
        todaySymptom = CycleAnalytics.symptom(in: modelContext)
        try? modelContext.save()
    }

    private func phaseColor(_ phase: CyclePhase) -> Color {
        let c = phase.timelineColor
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}

// MARK: - Timeline + sparkline

private struct PhaseTimelineCard: View {
    let snapshot: CycleSnapshot
    let sparkline: [CycleDayScorePoint]
    let currentPhase: CyclePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline du cycle")
                .font(.headline)

            GeometryReader { geo in
                let total = CGFloat(snapshot.cycleLength)
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(CyclePhase.allCases) { phase in
                            let width = geo.size.width * CGFloat(phaseDayCount(phase, length: snapshot.cycleLength)) / total
                            Rectangle()
                                .fill(phaseSwiftColor(phase).opacity(phase == currentPhase ? 1 : 0.45))
                                .frame(width: max(1, width))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if !sparkline.isEmpty {
                        Chart(sparkline) { point in
                            LineMark(
                                x: .value("Jour", point.cycleDay),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Jour", point.cycleDay),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(Color.white)
                            .symbolSize(18)
                        }
                        .chartXScale(domain: 1...snapshot.cycleLength)
                        .chartYScale(domain: 0...100)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartLegend(.hidden)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(
                            width: max(2, geo.size.width * CGFloat(snapshot.cycleDay) / total),
                            height: geo.size.height
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 88)

            HStack {
                ForEach(CyclePhase.allCases) { phase in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(phaseSwiftColor(phase))
                            .frame(width: 6, height: 6)
                        Text(phase.displayName)
                            .font(.caption2)
                    }
                    if phase != CyclePhase.allCases.last { Spacer(minLength: 0) }
                }
            }
            .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func phaseDayCount(_ phase: CyclePhase, length: Int) -> Int {
        (1...length).filter { CyclePhase.from(cycleDay: $0, cycleLength: length) == phase }.count
    }

    private func phaseSwiftColor(_ phase: CyclePhase) -> Color {
        let c = phase.timelineColor
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}

// MARK: - Symptômes rapides

private struct SymptomQuickLogRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var symptom: DailySymptom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptômes du jour")
                .font(.headline)

            HStack(spacing: 10) {
                SymptomToggleChip(
                    title: "Bouffée de chaleur",
                    icon: "flame.fill",
                    isOn: $symptom.hotFlash
                )
                .onChange(of: symptom.hotFlash) { _, _ in persist() }
                SymptomToggleChip(
                    title: "Crampes",
                    icon: "bolt.heart",
                    isOn: $symptom.cramps
                )
                .onChange(of: symptom.cramps) { _, _ in persist() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Humeur")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(DailyMood.allCases) { mood in
                        Button {
                            symptom.mood = mood
                            symptom.touch()
                            try? modelContext.save()
                        } label: {
                            Label(mood.displayName, systemImage: mood.sfSymbol)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    symptom.mood == mood
                                        ? SleepTheme.accent.opacity(0.35)
                                        : SleepTheme.card.opacity(0.8)
                                )
                                .foregroundStyle(
                                    symptom.mood == mood ? SleepTheme.textPrimary : SleepTheme.textSecondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func persist() {
        symptom.touch()
        try? modelContext.save()
    }
}

private struct SymptomToggleChip: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isOn ? SleepTheme.accent.opacity(0.3) : SleepTheme.card.opacity(0.7))
            .foregroundStyle(isOn ? SleepTheme.textPrimary : SleepTheme.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CycleDashboardView()
    }
}
