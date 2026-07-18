import Charts
import SwiftUI

struct InsightEngineSection: View {
    let sessions: [SleepSession]
    let dreams: [DreamEntry]

    private var cards: [InsightCard] {
        InsightEngine.build(sessions: sessions, dreams: dreams)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightsSectionHeader(
                title: "Insights moteur",
                icon: "brain.head.profile",
                subtitle: InsightEngine.hasEnoughData(sessions: sessions)
                    ? "Corrélations rêves × sommeil × lifestyle"
                    : "Disponible après \(InsightEngine.minimumNights) nuits complètes"
            )

            if InsightEngine.hasEnoughData(sessions: sessions) {
                if cards.isEmpty {
                    Text("Pas assez de rêves notés pour ces corrélations — continue le carnet.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                } else {
                    ForEach(cards) { card in
                        InsightCardView(card: card)
                    }
                }
            } else {
                InsightPlaceholderCard(
                    nightsDone: sessions.filter { $0.endTime != nil && $0.overallScore > 0 }.count,
                    required: InsightEngine.minimumNights
                )
            }
        }
    }
}

struct InsightCardView: View {
    let card: InsightCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(card.title)
                    .font(.subheadline.bold())
                Spacer()
                ConfidenceBadge(confidence: card.confidence)
            }

            Text(card.description)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !card.chartData.isEmpty {
                Group {
                    switch card.chartKind {
                    case .bar:
                        InsightBarChart(data: card.chartData)
                    case .line:
                        InsightLineChart(data: card.chartData)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100)) %")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(SleepTheme.accent.opacity(0.2))
            .foregroundStyle(SleepTheme.accent)
            .clipShape(Capsule())
    }
}

private struct InsightBarChart: View {
    let data: [InsightChartPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Catégorie", point.label),
                y: .value("Valeur", point.value)
            )
            .foregroundStyle(SleepTheme.accent.gradient)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

private struct IndexedChartPoint: Identifiable {
    let id: Int
    let label: String
    let value: Double
}

private struct InsightLineChart: View {
    let data: [InsightChartPoint]

    private var indexedPoints: [IndexedChartPoint] {
        data.enumerated().map { offset, point in
            IndexedChartPoint(id: offset, label: point.label, value: point.value)
        }
    }

    var body: some View {
        Chart(indexedPoints) { item in
            LineMark(
                x: .value("Index", item.id),
                y: .value("Valeur", item.value)
            )
            .foregroundStyle(SleepTheme.accent)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Index", item.id),
                y: .value("Valeur", item.value)
            )
            .foregroundStyle(SleepTheme.accent)
            .annotation(position: .bottom) {
                Text(item.label)
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }
}

struct InsightPlaceholderCard: View {
    let nightsDone: Int
    let required: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(SleepTheme.accent.opacity(0.5))
            Text("\(nightsDone) / \(required) nuits")
                .font(.headline)
            Text("Enregistre encore \(max(0, required - nightsDone)) nuit(s) pour débloquer les corrélations automatiques.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(SleepTheme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
