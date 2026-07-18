import SwiftUI
import WidgetKit

// MARK: - Provider (rafraîchissement 8h)

struct SleepLabProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepWidgetEntry {
        SleepWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepWidgetEntry) -> Void) {
        completion(SleepWidgetEntry(date: Date(), data: SleepWidgetEntryData.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepWidgetEntry>) -> Void) {
        let now = Date()
        let data = SleepWidgetEntryData.load() ?? .placeholder
        let entry = SleepWidgetEntry(date: now, data: data)

        var entries: [SleepWidgetEntry] = [entry]
        if let next8AM = nextMorningRefresh(from: now) {
            entries.append(SleepWidgetEntry(date: next8AM, data: data))
        }

        let policy: TimelineReloadPolicy = entries.count > 1
            ? .after(entries[1].date)
            : .after(Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now)

        completion(Timeline(entries: entries, policy: policy))
    }

    private func nextMorningRefresh(from date: Date) -> Date? {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 8
        comps.minute = 0
        comps.second = 0
        guard var target = Calendar.current.date(from: comps) else { return nil }
        if target <= date {
            target = Calendar.current.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target
    }
}

// MARK: - Small (jauge + score)

struct SleepLabSmallWidgetView: View {
    let data: SleepWidgetEntryData

    var body: some View {
        HStack(spacing: 10) {
            ScoreRingView(score: data.score, lineWidth: 6)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(data.score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("/100")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(red: 0.06, green: 0.07, blue: 0.12)
        }
        .widgetURL(URL(string: "sleeplab://home"))
    }
}

// MARK: - Medium (jauge + rêve)

struct SleepLabMediumWidgetView: View {
    let data: SleepWidgetEntryData

    var body: some View {
        HStack(spacing: 14) {
            ScoreRingView(score: data.score, lineWidth: 8)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(data.emotionEmoji)
                        .font(.title2)
                    Text("Dernier rêve")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(truncatedDream(data.dreamTitle, maxLines: 2))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text("Score \(data.score) · \(data.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(red: 0.06, green: 0.07, blue: 0.12)
        }
        .widgetURL(URL(string: "sleeplab://dreams"))
    }

    private func truncatedDream(_ text: String, maxLines: Int) -> String {
        let maxChars = 72 * maxLines
        if text.count <= maxChars { return text }
        return String(text.prefix(maxChars - 1)) + "…"
    }
}

struct ScoreRingView: View {
    let score: Int
    var lineWidth: CGFloat = 6

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let track = Path(ellipseIn: rect)
            context.stroke(track, with: .color(.white.opacity(0.15)), lineWidth: lineWidth)

            var progress = Path()
            progress.addArc(
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                radius: min(rect.width, rect.height) / 2,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + 360 * Double(min(100, max(0, score))) / 100),
                clockwise: false
            )
            context.stroke(
                progress,
                with: .color(scoreColor(score)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 75 { return .green }
        if score >= 55 { return .yellow }
        return .orange
    }
}

// MARK: - Bundle

@main
struct SleepLabWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepLabScoreWidget()
        SleepLabDreamWidget()
        SleepTrackingLiveActivity()
    }
}

struct SleepLabScoreWidget: Widget {
    let kind = "SleepLabScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepLabProvider()) { entry in
            if let data = entry.data {
                SleepLabSmallWidgetView(data: data)
            } else {
                Text("Aucune nuit")
                    .containerBackground(for: .widget) {
                        Color(red: 0.06, green: 0.07, blue: 0.12)
                    }
                    .widgetURL(URL(string: "sleeplab://home"))
            }
        }
        .configurationDisplayName("Score \(AppBrand.displayName)")
        .description("Score de ta dernière nuit.")
        .supportedFamilies([WidgetFamily.systemSmall])
    }
}

struct SleepLabDreamWidget: Widget {
    let kind = "SleepLabDreamWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepLabProvider()) { entry in
            if let data = entry.data {
                SleepLabMediumWidgetView(data: data)
            } else {
                Text("Ouvre \(AppBrand.displayName) pour synchroniser")
                    .padding()
                    .containerBackground(for: .widget) {
                        Color(red: 0.06, green: 0.07, blue: 0.12)
                    }
                    .widgetURL(URL(string: "sleeplab://home"))
            }
        }
        .configurationDisplayName("Score & rêve")
        .description("Score + extrait du dernier rêve.")
        .supportedFamilies([WidgetFamily.systemMedium])
    }
}
