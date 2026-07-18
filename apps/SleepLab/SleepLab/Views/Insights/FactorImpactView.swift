import SwiftUI

struct FactorImpactView: View {
    let impact: FactorImpact

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: impact.factor.sfSymbol)
                    .font(.largeTitle)
                    .foregroundStyle(SleepTheme.accent)
                VStack(alignment: .leading) {
                    Text(impact.factor.displayName)
                        .font(.title2.bold())
                    Text(impact.factor.category.displayName)
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }

            Text(impact.insight)
                .font(.body)

            LabeledContent("Corrélation") {
                Text(String(format: "%.2f", impact.correlation))
            }
            LabeledContent("Impact moyen sur le score") {
                Text(String(format: "%+.0f pts", impact.avgImpact))
            }

            Text("Analyse calculée localement sur ton appareil — aucune donnée n'est envoyée en ligne.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)

            Spacer()
            MedicalDisclaimer()
        }
        .padding()
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Impact")
    }
}
