import SwiftUI

struct SleepScoreView: View {
    let score: Int
    let label: String
    @State private var animatedScore: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(SleepTheme.card, lineWidth: 12)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: CGFloat(animatedScore) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [SleepTheme.accent, SleepTheme.phaseDeep],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)
                    .animation(.easeOut(duration: 1.2), value: animatedScore)

                Text("\(animatedScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(SleepTheme.textPrimary)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, new in
            withAnimation { animatedScore = new }
        }
    }
}
