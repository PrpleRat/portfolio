import Charts
import SwiftUI

// MARK: - Cartes réutilisables

struct InsightsSectionHeader: View {
    let title: String
    let icon: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }
}

struct InsightsCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SleepTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let footnote: String?
    var accent: Color = SleepTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(accent)
            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SleepTheme.card.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Vue d’ensemble

struct OverviewStatsGrid: View {
    let overview: OverviewStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatTile(
                title: "Score moyen (7 j)",
                value: overview.avgScore7d.map { "\(Int($0))" } ?? "—",
                footnote: overview.scoreTrendDelta7d.map { delta in
                    delta >= 0 ? "+\(Int(delta)) pts vs début semaine" : "\(Int(delta)) pts vs début semaine"
                },
                accent: trendColor(overview.scoreTrendDelta7d)
            )
            StatTile(
                title: "Durée moyenne",
                value: String(format: "%.1f h", overview.avgDurationHours),
                footnote: "Par nuit enregistrée"
            )
            StatTile(
                title: "Nuits suivies",
                value: "\(overview.totalNights)",
                footnote: overview.trackingStreak > 0 ? "Série : \(overview.trackingStreak) j" : nil
            )
            StatTile(
                title: "Efficacité",
                value: "\(Int(overview.avgEfficiency)) %",
                footnote: "Temps endormi / au lit"
            )
        }
    }

    private func trendColor(_ delta: Double?) -> Color {
        guard let delta else { return SleepTheme.accent }
        if delta > 2 { return .green }
        if delta < -2 { return .orange }
        return SleepTheme.accent
    }
}

// MARK: - Graphiques

struct ScoreTrendChart: View {
    let points: [NightlyScorePoint]
    let average: Double

    var body: some View {
        Chart {
            ForEach(points) { p in
                LineMark(
                    x: .value("Date", p.date, unit: .day),
                    y: .value("Score", p.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(SleepTheme.accent)

                PointMark(
                    x: .value("Date", p.date, unit: .day),
                    y: .value("Score", p.score)
                )
                .foregroundStyle(SleepTheme.accent)
                .symbolSize(30)
            }
            RuleMark(y: .value("Moyenne", average))
                .foregroundStyle(SleepTheme.textSecondary.opacity(0.6))
                .lineStyle(StrokeStyle(dash: [4, 4]))
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine().foregroundStyle(SleepTheme.textSecondary.opacity(0.2))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(height: 200)
    }
}

struct DurationTrendChart: View {
    let points: [NightlyDurationPoint]

    var body: some View {
        Chart(points) { p in
            BarMark(
                x: .value("Date", p.date, unit: .day),
                y: .value("Heures", p.hours)
            )
            .foregroundStyle(SleepTheme.phaseLight.gradient)
            .cornerRadius(4)
        }
        .chartYAxisLabel("h")
        .frame(height: 160)
    }
}

struct WeekdayScoreChart: View {
    let data: [WeekdayScore]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Jour", item.shortName),
                y: .value("Score", item.averageScore)
            )
            .foregroundStyle(barColor(item.averageScore))
            .cornerRadius(6)
        }
        .chartYScale(domain: 0...100)
        .frame(height: 180)
    }

    private func barColor(_ score: Double) -> Color {
        if score >= 75 { return .green.opacity(0.85) }
        if score >= 55 { return SleepTheme.accent }
        return .orange.opacity(0.85)
    }
}

struct PhaseStackedChart: View {
    let bars: [NightlyPhaseBars]

    var body: some View {
        Chart(bars) { night in
            BarMark(
                x: .value("Nuit", night.date, unit: .day),
                y: .value("Profond", night.deep),
                stacking: .normalized
            )
            .foregroundStyle(SleepTheme.phaseDeep)

            BarMark(
                x: .value("Nuit", night.date, unit: .day),
                y: .value("REM", night.rem),
                stacking: .normalized
            )
            .foregroundStyle(SleepTheme.phaseREM)

            BarMark(
                x: .value("Nuit", night.date, unit: .day),
                y: .value("Léger", night.light),
                stacking: .normalized
            )
            .foregroundStyle(SleepTheme.phaseLight)
        }
        .chartYAxis {
            AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(1))
        }
        .frame(height: 200)
    }
}

struct PhaseDonutRow: View {
    let averages: PhaseAverages

    var body: some View {
        HStack(spacing: 16) {
            phaseRing(percent: averages.deepPercent, color: SleepTheme.phaseDeep, label: "Profond")
            phaseRing(percent: averages.remPercent, color: SleepTheme.phaseREM, label: "REM")
            phaseRing(percent: averages.lightPercent, color: SleepTheme.phaseLight, label: "Léger")
        }
    }

    private func phaseRing(percent: Double, color: Color, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(1, percent / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percent))%")
                    .font(.caption.bold())
            }
            .frame(width: 64, height: 64)
            Text(label)
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FactorUsageChart: View {
    let usage: [FactorUsageCount]

    var body: some View {
        Chart(usage) { item in
            BarMark(
                x: .value("Nuits", item.count),
                y: .value("Facteur", item.factor.displayName)
            )
            .foregroundStyle(SleepTheme.accent.gradient)
            .cornerRadius(4)
        }
        .chartXAxisLabel("fois noté")
        .frame(height: CGFloat(max(120, usage.count * 28)))
    }
}

struct FactorComparisonRow: View {
    let comparison: FactorComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: comparison.factor.sfSymbol)
                    .foregroundStyle(SleepTheme.accent)
                Text(comparison.factor.displayName)
                    .font(.subheadline.bold())
                Spacer()
                Text(deltaLabel)
                    .font(.caption.bold())
                    .foregroundStyle(comparison.delta >= 0 ? .green : .orange)
            }
            HStack(spacing: 12) {
                barBlock(title: "Avec", score: comparison.avgWith, widthRatio: comparison.avgWith / 100)
                    .frame(maxWidth: .infinity)
                barBlock(title: "Sans", score: comparison.avgWithout, widthRatio: comparison.avgWithout / 100)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 36)
            Text("\(comparison.nightsWith) nuits avec · \(comparison.nightsWithout) sans")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding(12)
        .background(SleepTheme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var deltaLabel: String {
        let sign = comparison.delta >= 0 ? "+" : ""
        return "\(sign)\(Int(comparison.delta)) pts"
    }

    private func barBlock(title: String, score: Double, widthRatio: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) · \(Int(score))")
                .font(.caption2)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(SleepTheme.accent.opacity(0.35))
                    .frame(width: geo.size.width * CGFloat(min(1, widthRatio)))
            }
            .frame(height: 8)
        }
    }
}

struct RecordsRow: View {
    let records: PersonalRecords

    var body: some View {
        VStack(spacing: 10) {
            recordItem(icon: "trophy.fill", title: "Meilleur score", value: "\(records.bestScore)", date: records.bestScoreDate)
            recordItem(icon: "clock.fill", title: "Plus longue nuit", value: String(format: "%.1f h", records.longestHours), date: records.longestDate)
            recordItem(icon: "moon.zzz.fill", title: "Max sommeil profond", value: "\(records.mostDeepMinutes) min", date: records.mostDeepDate)
        }
    }

    private func recordItem(icon: String, title: String, value: String, date: Date?) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(SleepTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundStyle(SleepTheme.textSecondary)
                Text(value).font(.headline)
            }
            Spacer()
            if let date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }
}

struct TipsList: View {
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(SleepTheme.textPrimary)
                }
            }
        }
    }
}
