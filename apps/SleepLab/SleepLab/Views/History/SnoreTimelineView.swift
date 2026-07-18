import SwiftData
import SwiftUI

/// Barre horizontale : segments rouges = ronflement (Core ML).
struct SnoreTimelineView: View {
    @Environment(\.modelContext) private var modelContext

    let session: SleepSession
    private let prefetchedEvents: [SnoreEvent]?

    @State private var events: [SnoreEvent] = []

    init(session: SleepSession, events: [SnoreEvent]? = nil) {
        self.session = session
        self.prefetchedEvents = events
        _events = State(initialValue: events ?? [])
    }

    private var nightEnd: Date {
        session.endTime ?? session.startTime.addingTimeInterval(max(session.totalDuration, 1))
    }

    private var segments: [SnoreTimelineSegment] {
        SnoreAnalytics.mergedSegments(
            events: events,
            sessionStart: session.startTime,
            sessionEnd: nightEnd
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            timelineBar
            axisLabels
            if events.isEmpty {
                Text("Aucun ronflement détecté cette nuit (seuil confiance 88 %).")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task(id: session.id) {
            guard prefetchedEvents == nil else { return }
            await loadEvents()
        }
    }

    @MainActor
    private func loadEvents() async {
        let sessionId = session.id
        var descriptor = FetchDescriptor<SnoreEvent>(
            predicate: #Predicate<SnoreEvent> { $0.session?.id == sessionId },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        descriptor.fetchLimit = 12_000
        events = (try? modelContext.fetch(descriptor)) ?? []
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Ronflements (IA)", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Text("Bêta")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.25))
                    .clipShape(Capsule())
                Spacer()
                if !events.isEmpty {
                    Text("\(events.count) détection\(events.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
            HStack(spacing: 16) {
                statBlock(
                    title: "Temps total",
                    value: SnoreAnalytics.formatDuration(session.cappedSnoreDuration)
                )
                statBlock(
                    title: "Part de la nuit",
                    value: String(format: "%.1f %%", session.snorePercentOfNight)
                )
            }
            Text("Bêta — seuil relevé. Les durées sont plafonnées pour éviter les surestimations. L’audio n’est pas stocké sans ton accord.")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }

    private var timelineBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let duration = max(session.totalDuration, 1)
            let drawn = segments
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(SleepTheme.background.opacity(0.6))
                ForEach(drawn) { segment in
                    let x = width * CGFloat(segment.startOffset / duration)
                    let w = max(2, width * CGFloat((segment.endOffset - segment.startOffset) / duration))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.75 + segment.averageConfidence * 0.2))
                        .frame(width: w, height: geo.size.height)
                        .offset(x: x)
                }
            }
        }
        .frame(height: 28)
    }

    private var axisLabels: some View {
        HStack {
            Text(session.startTime.formatted(date: .omitted, time: .shortened))
            Spacer()
            Text(nightEnd.formatted(date: .omitted, time: .shortened))
        }
        .font(.caption2)
        .foregroundStyle(SleepTheme.textSecondary)
    }
}
