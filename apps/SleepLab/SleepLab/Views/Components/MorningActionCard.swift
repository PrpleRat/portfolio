import SwiftUI

struct MorningActionCard: View {
    let action: MorningActionEngine.MorningAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Action du jour", systemImage: "sun.max.fill")
                .font(.caption.bold())
                .foregroundStyle(SleepTheme.accent)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: action.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(SleepTheme.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(action.headline)
                        .font(.headline)
                    Text(action.instruction)
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(action.rationale)
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SleepTheme.accent.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SleepTheme.accent.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
