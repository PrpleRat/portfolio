import Foundation

struct SnoreTimelineSegment: Identifiable {
    let startOffset: TimeInterval
    let endOffset: TimeInterval
    let averageConfidence: Double

    var id: String {
        "\(Int(startOffset * 1000))-\(Int(endOffset * 1000))"
    }
}

enum SnoreAnalytics {
    /// Limite le nombre de rectangles dessinés (évite freeze / crash sur grosses nuits).
    static let maxDisplaySegments = 280

    /// Fusionne les événements 1 s consécutifs pour l’affichage timeline.
    static func mergedSegments(
        events: [SnoreEvent],
        sessionStart: Date,
        sessionEnd: Date
    ) -> [SnoreTimelineSegment] {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        guard !sorted.isEmpty else { return [] }

        let nightEnd = sessionEnd
        var segments: [SnoreTimelineSegment] = []
        var clusterStart: Date?
        var clusterEnd: Date?
        var confidences: [Double] = []

        func flush() {
            guard let start = clusterStart, let end = clusterEnd else { return }
            let avg = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Double(confidences.count)
            segments.append(
                SnoreTimelineSegment(
                    startOffset: max(0, start.timeIntervalSince(sessionStart)),
                    endOffset: min(nightEnd.timeIntervalSince(sessionStart), end.timeIntervalSince(sessionStart)),
                    averageConfidence: avg
                )
            )
            clusterStart = nil
            clusterEnd = nil
            confidences = []
        }

        for event in sorted {
            let cappedDuration = min(event.duration, 12)
            let eventEnd = event.timestamp.addingTimeInterval(cappedDuration)
            if let end = clusterEnd, event.timestamp.timeIntervalSince(end) <= 2 {
                clusterEnd = eventEnd
                confidences.append(event.confidence)
            } else {
                flush()
                clusterStart = event.timestamp
                clusterEnd = eventEnd
                confidences = [event.confidence]
            }
        }
        flush()
        return downsampleIfNeeded(segments)
    }

    private static func downsampleIfNeeded(_ segments: [SnoreTimelineSegment]) -> [SnoreTimelineSegment] {
        guard segments.count > maxDisplaySegments else { return segments }
        let step = Double(segments.count) / Double(maxDisplaySegments)
        var result: [SnoreTimelineSegment] = []
        var index = 0.0
        while Int(index) < segments.count, result.count < maxDisplaySegments {
            let i = Int(index)
            let endIndex = min(segments.count, Int(index + step))
            let chunk = segments[i..<endIndex]
            guard let first = chunk.first, let last = chunk.last else { break }
            let avgConf = chunk.map(\.averageConfidence).reduce(0, +) / Double(chunk.count)
            result.append(
                SnoreTimelineSegment(
                    startOffset: first.startOffset,
                    endOffset: last.endOffset,
                    averageConfidence: avgConf
                )
            )
            index += step
        }
        return result
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        if s < 60 { return "\(s) s" }
        let m = s / 60
        let rem = s % 60
        if rem == 0 { return "\(m) min" }
        return "\(m) min \(rem) s"
    }
}
