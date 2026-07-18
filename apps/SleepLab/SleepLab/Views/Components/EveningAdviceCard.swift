import SwiftUI

struct EveningAdviceCard: View {
    let advice: EveningAdviceEngine.EveningAdvice

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: advice.icon)
                .font(.title2)
                .foregroundStyle(SleepTheme.accent)
            VStack(alignment: .leading, spacing: 6) {
                Text(advice.title)
                    .font(.headline)
                Text(advice.body)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
