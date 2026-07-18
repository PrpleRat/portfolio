import SwiftUI

/// Résumé des facteurs du jour reliés au sommeil (cohérent avec énergie / coucher).
struct FactorInfluenceCard: View {
    let factors: [SleepFactor]
    let allFactors: [SleepFactor]
    let sessions: [SleepSession]

    private var lastNight: SleepSession? {
        sessions.first { $0.kind == .night && $0.endTime != nil }
    }

    private var topToday: [(FactorType, Double)] {
        Dictionary(grouping: factors, by: \.type)
            .map { ($0.key, $0.value.map(\.value).reduce(0, +)) }
            .sorted { $0.1 > $1.1 }
            .prefix(4)
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Facteurs du jour", systemImage: "list.bullet.clipboard")
                .font(.headline)

            if topToday.isEmpty {
                Text("Rien noté depuis ton réveil. Le journal substances alimente l’énergie et le coucher conseillé.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            } else {
                Text("Pris depuis ton réveil — utilisés pour énergie, coucher et corrélations.")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
                ForEach(topToday, id: \.0.rawValue) { type, value in
                    HStack {
                        Image(systemName: type.sfSymbol)
                            .foregroundStyle(SleepTheme.accent)
                            .frame(width: 20)
                        Text(type.displayName)
                            .font(.caption)
                        Spacer()
                        if value > 0, !type.defaultUnit.isEmpty {
                            Text("\(formatted(value)) \(type.defaultUnit)")
                                .font(.caption2)
                                .foregroundStyle(SleepTheme.textSecondary)
                        }
                    }
                }
            }

            if let night = lastNight {
                let linked = SleepFactorAttribution.factors(for: night, allFactors: allFactors)
                if !linked.isEmpty {
                    Divider()
                    Text("Dernière nuit : \(linked.count) facteur(s) relié(s) · score \(night.overallScore)")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }

            NavigationLink {
                FactorJournalView()
            } label: {
                Text("Ouvrir le journal")
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
