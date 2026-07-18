import SwiftUI

struct MorningRecoveryCard: View {
    let score: MorningRecoveryEngine.MorningRecoveryScore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Récupération du matin", systemImage: "sunrise.fill")
                    .font(.headline)
                Spacer()
                Text("\(score.score)")
                    .font(.title.bold())
                    .foregroundStyle(colorForScore(score.score))
            }
            Text(score.label)
                .font(.subheadline.bold())
            Text(score.detail)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            HStack(spacing: 8) {
                miniTag("Dette", score.debtPenalty)
                miniTag("Inertie", score.inertiaPenalty)
                miniTag("Caféine", score.caffeinePenalty)
                miniTag("Fragments", score.fragmentationPenalty)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func miniTag(_ title: String, _ penalty: Int) -> some View {
        Text("\(title) −\(penalty)")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(penalty > 0 ? Color.orange.opacity(0.2) : Color.green.opacity(0.15))
            .clipShape(Capsule())
    }

    private func colorForScore(_ value: Int) -> Color {
        switch value {
        case 80...: return .green
        case 60..<80: return SleepTheme.accent
        default: return .orange
        }
    }
}
