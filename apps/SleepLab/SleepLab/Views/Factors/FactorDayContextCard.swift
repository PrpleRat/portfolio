import SwiftUI

/// Montre comment le jour sélectionné se relie à la nuit suivante / précédente.
struct FactorDayContextCard: View {
    let selectedDay: Date
    let allFactors: [SleepFactor]
    let completedSessions: [SleepSession]

    private var nightEndingOnDay: SleepSession? {
        completedSessions.first { session in
            guard session.kind == .night, let end = session.endTime else { return false }
            return Calendar.current.isDate(end, inSameDayAs: selectedDay)
        }
    }

    private var nightStartingAfterDay: SleepSession? {
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: FactorJournalHelpers.startOfDay(selectedDay)) ?? selectedDay
        return completedSessions
            .filter { $0.kind == .night }
            .sorted { $0.startTime < $1.startTime }
            .first { $0.startTime >= FactorJournalHelpers.startOfDay(selectedDay) && $0.startTime < dayEnd.addingTimeInterval(18 * 3600) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lien avec le sommeil")
                .font(.subheadline.bold())

            if let night = nightEndingOnDay {
                let attributed = SleepFactorAttribution.factors(for: night, allFactors: allFactors)
                Text("Réveil ce jour · score \(night.overallScore) · \(attributed.count) facteur(s) comptés pour cette nuit.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            } else if let upcoming = nightStartingAfterDay {
                Text("Ces entrées seront reliées à la nuit commencée \(upcoming.startTime.formatted(date: .omitted, time: .shortened)).")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            } else {
                Text("Saisis caféine, repas, etc. dans la journée : au lancement de la prochaine nuit, tout est relié automatiquement (fenêtre ~18 h avant le coucher).")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SleepTheme.card.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
