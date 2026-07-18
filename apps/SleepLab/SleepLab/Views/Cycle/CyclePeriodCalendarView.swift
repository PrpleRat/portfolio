import SwiftData
import SwiftUI

/// Calendrier pour marquer les jours de règles (tap = ajouter / retirer).
struct CyclePeriodCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var loggedDays: Set<Date> = []
    @State private var selectedFlow: MenstrualFlowIntensity = .medium
    @State private var insight: CyclePeriodEngine.CycleInsight?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                introCard
                flowPicker
                monthHeader
                weekdayHeader
                dayGrid
                legendCard
                if let insight {
                    predictionCard(insight)
                }
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Calendrier des règles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Marque chaque jour où tu as tes règles")
                .font(.headline)
            Text("Tape un jour pour l’ajouter ou le retirer. Plus tu renseignes, plus le calcul de phase et les prévisions sont fiables.")
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)
            HStack(spacing: 12) {
                Button {
                    markToday()
                } label: {
                    Label("Règles aujourd’hui", systemImage: "drop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)

                Button {
                    markLastSevenDays()
                } label: {
                    Label("7 derniers jours", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var flowPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensité pour les prochains jours ajoutés")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            Picker("Flux", selection: $selectedFlow) {
                ForEach(MenstrualFlowIntensity.allCases, id: \.self) { flow in
                    Text(flow.displayName).tag(flow)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.bold())
                    .foregroundStyle(SleepTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(monthDays, id: \.self) { day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func dayCell(_ day: Date) -> some View {
        let start = Calendar.current.startOfDay(for: day)
        let isPeriod = loggedDays.contains(start)
        let isToday = Calendar.current.isDateInToday(day)
        let inFuture = day > Date()

        return Button {
            guard !inFuture else { return }
            toggle(day: start)
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                if isPeriod, let log = CyclePeriodEngine.log(for: start, in: modelContext) {
                    Text(log.flowIntensity.shortLabel)
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPeriod ? Color(red: 0.85, green: 0.35, blue: 0.45).opacity(0.55) : SleepTheme.card.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? SleepTheme.accent : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(inFuture ? SleepTheme.textSecondary.opacity(0.35) : SleepTheme.textPrimary)
        }
        .buttonStyle(.plain)
        .disabled(inFuture)
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Jour marqué = règles", systemImage: "drop.fill")
            Text("Les jours futurs ne peuvent pas être renseignés à l’avance.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .font(.caption)
    }

    private func predictionCard(_ insight: CyclePeriodEngine.CycleInsight) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Calcul actuel")
                .font(.headline)
            Text("Jour \(insight.cycleDay) · \(insight.phase.displayName)")
            if let next = insight.predictedNextPeriodStart, let d = insight.daysUntilNextPeriod {
                Text("Prochaines règles estimées : \(next.formatted(date: .abbreviated, time: .omitted)) (dans \(d) j)")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            Text("\(insight.loggedPeriodDays) jour(s) enregistré(s) · Source : \(insight.source)")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var monthDays: [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(date)
            }
        }
        return cells
    }

    private func shiftMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private func toggle(day: Date) {
        if CyclePeriodEngine.log(for: day, in: modelContext) != nil {
            _ = CyclePeriodEngine.togglePeriodDay(day, in: modelContext)
        } else {
            CyclePeriodEngine.setPeriodDay(day, flow: selectedFlow, in: modelContext)
        }
        reload()
    }

    private func markToday() {
        CyclePeriodEngine.setPeriodDay(Date(), flow: selectedFlow, in: modelContext)
        reload()
    }

    private func markLastSevenDays() {
        let cal = Calendar.current
        for offset in 0..<7 {
            if let day = cal.date(byAdding: .day, value: -offset, to: Date()) {
                CyclePeriodEngine.setPeriodDay(day, flow: selectedFlow, in: modelContext)
            }
        }
        reload()
    }

    private func reload() {
        loggedDays = CyclePeriodEngine.loggedDaySet(in: modelContext)
        let profile = profiles.first
        Task {
            let health = await MenstrualCycleService().latestPeriodStartFromHealthKit()
            insight = CyclePeriodEngine.buildInsight(
                profile: profile,
                loggedDays: loggedDays,
                healthPeriodStart: health
            )
            if let profile, let insight {
                CyclePeriodEngine.syncProfile(profile, insight: insight, loggedDays: loggedDays)
                try? modelContext.save()
            }
        }
    }
}
