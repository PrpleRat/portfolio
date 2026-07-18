import SwiftUI

struct ProbabilityBar: View {
    let level: ProbabilityLevel
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Score \(score)")
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                Spacer()
                Text(level.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(level.color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CarenceColors.border)
                    Capsule()
                        .fill(level.color)
                        .frame(width: geo.size.width * level.barFill)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Probabilité \(level.label), score \(score)")
    }
}
