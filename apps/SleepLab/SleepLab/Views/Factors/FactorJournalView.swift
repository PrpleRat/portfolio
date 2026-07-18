import SwiftData
import SwiftUI

/// Journal substances — calendrier : tap sur un jour → liste ; ajout via popup (3 dernières en tête).
struct FactorJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var allFactors: [SleepFactor]
    @Query(sort: \DailySubstanceRoutine.typeRaw, order: .forward) private var dailyRoutines: [DailySubstanceRoutine]
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var completedSessions: [SleepSession]

    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var showAddSheet = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth),
              let range = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: interval.start) {
                days.append(cal.startOfDay(for: date))
            }
        }
        return days
    }

    private var markedDays: Set<Date> {
        FactorJournalHelpers.daysWithEntries(in: displayedMonth, factors: allFactors)
    }

    private var dayFactors: [SleepFactor] {
        FactorJournalHelpers.factors(on: selectedDay, from: allFactors)
    }

    private var recentPicks: [RecentSubstancePick] {
        FactorJournalHelpers.recentSubstancePicks(from: allFactors)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                introCard
                FactorDayContextCard(
                    selectedDay: selectedDay,
                    allFactors: allFactors,
                    completedSessions: completedSessions
                )
                DailyRoutineSectionView(
                    selectedDay: selectedDay,
                    allFactors: allFactors,
                    routines: dailyRoutines
                )
                monthHeader
                weekdayHeader
                dayGrid
                selectedDaySection
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    DailyWellbeingView()
                } label: {
                    Label("Bien-être", systemImage: "heart.text.square")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Ajouter une substance")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFactorSheet(day: selectedDay, recentPicks: recentPicks) {
                showAddSheet = false
            }
            .id(selectedDay)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal substances & habitudes")
                .font(.headline)
            Text("1. Choisis un jour sur le calendrier · 2. Ajoute ce que tu as pris · 3. C’est relié à ta prochaine nuit automatiquement.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: {
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
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
        let hasEntries = markedDays.contains(day)
        let isToday = Calendar.current.isDateInToday(day)

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.subheadline.bold())
                Circle()
                    .fill(hasEntries ? SleepTheme.accent : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? SleepTheme.accent.opacity(0.25) : SleepTheme.card.opacity(isToday ? 0.9 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday ? SleepTheme.accent : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.fullAreaTap(cornerRadius: 10))
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDay.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
            }

            if dayFactors.isEmpty {
                Text("Rien enregistré ce jour-là.")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(dayFactors) { factor in
                    FactorJournalRow(factor: factor) {
                        deleteFactor(factor)
                    }
                }
            }
        }
    }

    private func shiftMonth(by delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = Calendar.current.startOfDay(for: next)
        }
    }

    private func deleteFactor(_ factor: SleepFactor) {
        modelContext.delete(factor)
        try? modelContext.save()
    }
}

private struct FactorJournalRow: View {
    let factor: SleepFactor
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: factor.type.sfSymbol)
                .foregroundStyle(SleepTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(factor.type.displayName)
                    .font(.subheadline.bold())
                Text(factor.consumedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                if factor.hoursBeforeSleep > 0 {
                    Text("\(String(format: "%.1f", factor.hoursBeforeSleep)) h avant le coucher")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
                if let session = factor.session {
                    Text("Lié à \(session.kind.displayName.lowercased()) du \(session.startTime.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.accent)
                }
                if factor.isDailyRoutineEntry {
                    Text("Prise quotidienne")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.accent)
                } else if let notes = DailyRoutineMarkers.userFacingNotes(factor.notes) {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
            Spacer()
            if !factor.isDailyRoutineEntry, !factor.unit.isEmpty, factor.value > 0 {
                Text("\(formattedValue)\(factor.unit)")
                    .font(.caption.monospacedDigit())
            }
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var formattedValue: String {
        if factor.value.rounded() == factor.value {
            return "\(Int(factor.value))"
        }
        return String(format: "%.1f", factor.value)
    }
}
