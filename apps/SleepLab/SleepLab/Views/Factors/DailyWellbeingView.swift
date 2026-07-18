import SwiftData
import SwiftUI

/// Règles + humeur + sommeil de la veille sur un seul écran.
struct DailyWellbeingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @Query(sort: \DailySymptom.dayStart, order: .reverse) private var symptoms: [DailySymptom]
    @Query(sort: \PeriodDayLog.dayStart, order: .reverse) private var periodLogs: [PeriodDayLog]

    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var mood: DailyMood = .neutral
    @State private var cramps = false
    @State private var hotFlash = false
    @State private var bleeding = false

    private var nightForSelectedDay: SleepNightGrouper.LogicalNight? {
        let nights = SleepNightGrouper.logicalNights(
            from: sessions.filter { $0.kind == .night },
            days: 60
        )
        return nights.first {
            Calendar.current.isDate($0.wakeDay, inSameDayAs: selectedDay)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DatePicker("Jour", selection: $selectedDay, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .onChange(of: selectedDay) { _, _ in loadSymptom() }

                if let night = nightForSelectedDay {
                    nightSection(night)
                } else {
                    Text("Pas de nuit enregistrée pour ce jour de réveil.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }

                periodSection
                moodSection
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Bien-être du jour")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSymptom() }
    }

    private func nightSection(_ night: SleepNightGrouper.LogicalNight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sommeil de la veille")
                .font(.headline)
            HStack {
                SleepScoreView(
                    score: night.primarySession.overallScore,
                    label: SleepScoreCalculator.labelForScore(
                        night.primarySession.overallScore,
                        kind: night.primarySession.kind
                    )
                )
                Spacer()
                VStack(alignment: .trailing) {
                    Text(formatDuration(night.primarySession.totalDuration))
                        .font(.subheadline.bold())
                    if night.fragmentCount > 1 {
                        Text("\(night.fragmentCount) fragments")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .background(SleepTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Règles & symptômes")
                .font(.headline)
            Toggle("Saignements aujourd’hui", isOn: $bleeding)
                .onChange(of: bleeding) { _, on in
                    if on {
                        CyclePeriodEngine.setPeriodDay(selectedDay, flow: .medium, in: modelContext)
                    }
                    saveSymptom()
                }
            Toggle("Crampes", isOn: $cramps).onChange(of: cramps) { _, _ in saveSymptom() }
            Toggle("Bouffées de chaleur", isOn: $hotFlash).onChange(of: hotFlash) { _, _ in saveSymptom() }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Humeur")
                .font(.headline)
            Picker("Humeur", selection: $mood) {
                ForEach(DailyMood.allCases) { m in
                    Label(m.displayName, systemImage: m.sfSymbol).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mood) { _, _ in saveSymptom() }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadSymptom() {
        let start = Calendar.current.startOfDay(for: selectedDay)
        bleeding = periodLogs.contains { Calendar.current.isDate($0.dayStart, inSameDayAs: start) }
        if let s = symptoms.first(where: { Calendar.current.isDate($0.dayStart, inSameDayAs: start) }) {
            mood = s.mood
            cramps = s.cramps
            hotFlash = s.hotFlash
        } else {
            mood = .neutral
            cramps = false
            hotFlash = false
        }
    }

    private func saveSymptom() {
        let start = Calendar.current.startOfDay(for: selectedDay)
        let existing = symptoms.first { Calendar.current.isDate($0.dayStart, inSameDayAs: start) }
        let s = existing ?? DailySymptom(dayStart: start)
        s.mood = mood
        s.cramps = cramps
        s.hotFlash = hotFlash
        s.touch()
        if existing == nil { modelContext.insert(s) }
        try? modelContext.save()
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return "\(h)h\(String(format: "%02d", m))"
    }
}
