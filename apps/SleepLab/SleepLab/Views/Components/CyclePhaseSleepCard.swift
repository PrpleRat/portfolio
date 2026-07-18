import SwiftUI

struct CyclePhaseSleepCard: View {
    let comparison: CycleSleepAnalytics.PhaseComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sommeil par phase", systemImage: "circle.hexagongrid.fill")
                .font(.headline)
            Text(comparison.insight)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            ForEach(comparison.stats) { stat in
                HStack {
                    Text(stat.phase.displayName)
                        .font(.caption)
                        .frame(width: 88, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(phaseColor(stat.phase))
                            .frame(width: geo.size.width * CGFloat(stat.averageScore / 100))
                    }
                    .frame(height: 8)
                    Text("\(Int(stat.averageScore))")
                        .font(.caption.bold())
                        .frame(width: 28, alignment: .trailing)
                    Text("(\(stat.nightCount))")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func phaseColor(_ phase: CyclePhase) -> Color {
        let c = phase.timelineColor
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}
