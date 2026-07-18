import SwiftUI
import WidgetKit

struct TrajOcWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetBridge.FavoriteSnapshot
}

struct TrajOcProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrajOcWidgetEntry {
        TrajOcWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrajOcWidgetEntry) -> Void) {
        completion(TrajOcWidgetEntry(date: Date(), data: WidgetBridge.loadFavorite() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrajOcWidgetEntry>) -> Void) {
        let data = WidgetBridge.loadFavorite() ?? .placeholder
        let entry = TrajOcWidgetEntry(date: Date(), data: data)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

extension WidgetBridge.FavoriteSnapshot {
    static let placeholder = WidgetBridge.FavoriteSnapshot(
        originName: "Toulouse Matabiau",
        destinationName: "Montpellier St-Roch",
        nextDepartureLabel: "14:32",
        durationLabel: "1h 45min"
    )
}

struct TrajOcWidgetSmallView: View {
    let data: WidgetBridge.FavoriteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🚂 TER · \(data.nextDepartureLabel)")
                .font(.caption.weight(.semibold))
            Text("\(data.durationLabel)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(red: 0.85, green: 0.15, blue: 0.11).opacity(0.15)
        }
        .widgetURL(URL(string: "trajoc://search")!)
    }
}

struct TrajOcWidgetMediumView: View {
    let data: WidgetBridge.FavoriteSnapshot

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(data.originName) →")
                    .font(.caption)
                    .lineLimit(1)
                Text(data.destinationName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(data.nextDepartureLabel) · \(data.durationLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Link(destination: URL(string: "trajoc://search")!) {
                Text("Calculer")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.85, green: 0.15, blue: 0.11))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct TrajOcWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TrajOcWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall, .accessoryInline, .accessoryRectangular:
            TrajOcWidgetSmallView(data: entry.data)
        default:
            TrajOcWidgetMediumView(data: entry.data)
        }
    }
}

struct TrajOcWidget: Widget {
    let kind = "TrajOcWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrajOcProvider()) { entry in
            TrajOcWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TrajOc")
        .description("Prochain trajet favori")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

@main
struct TrajOcWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrajOcWidget()
    }
}
