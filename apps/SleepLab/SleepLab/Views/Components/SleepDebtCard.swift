import SwiftUI

struct SleepDebtCard: View {
    let report: SleepDebtEngine.SleepDebtReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: report.status.sfSymbol)
                    .foregroundStyle(statusColor)
                Text("Dette de sommeil")
                    .font(.headline)
                Spacer()
                Text(report.status.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .clipShape(Capsule())
            }

            if report.netDebtHours > 0.25 {
                Text(SleepDebtEngine.formatHours(report.netDebtHours))
                    .font(.title.bold())
                    .monospacedDigit()
            } else {
                Text("À jour")
                    .font(.title.bold())
                    .foregroundStyle(.green)
            }

            Text(report.summaryLine)
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textSecondary)

            Text(report.detailLine)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)

            if report.nightlyBalances.count >= 2 {
                debtSparkline
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusColor: Color {
        switch report.status {
        case .surplus, .balanced: return .green
        case .mild: return SleepTheme.accent
        case .moderate: return .orange
        case .high: return SleepTheme.phaseAwake
        }
    }

    private var debtSparkline: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(report.nightlyBalances.reversed()) { night in
                let h = barHeight(for: night.balanceHours)
                RoundedRectangle(cornerRadius: 2)
                    .fill(night.balanceHours >= 0 ? Color.green.opacity(0.7) : Color.orange.opacity(0.8))
                    .frame(width: 12, height: h)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for balanceHours: Double) -> CGFloat {
        let normalized = min(1, abs(balanceHours) / 2.5)
        return max(6, CGFloat(normalized) * 36)
    }
}
