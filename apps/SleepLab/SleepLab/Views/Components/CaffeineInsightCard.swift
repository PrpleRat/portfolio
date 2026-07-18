import SwiftUI

struct CaffeineInsightCard: View {
    let insight: CaffeinePersonalizationEngine.CaffeineInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(SleepTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Seuil caféine personnel")
                    .font(.subheadline.bold())
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
