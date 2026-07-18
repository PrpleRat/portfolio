import SwiftUI

struct BedtimeRecommendationCard: View {
    let recommendation: BedtimeAdvisor.BedtimeRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Fenêtre de coucher", systemImage: "bed.double.fill")
                .font(.headline)
            Text(recommendation.message)
                .font(.subheadline)
            Text(recommendation.factorsSummary)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            HStack {
                Text("Fenêtre")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
                Text("\(recommendation.windowStart.formatted(date: .omitted, time: .shortened)) – \(recommendation.windowEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
