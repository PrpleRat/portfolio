import Foundation
import SwiftData

/// Ronflement détecté on-device (Core ML), sans enregistrement audio par défaut.
@Model
final class SnoreEvent {
    var id: UUID
    var timestamp: Date
    var duration: TimeInterval
    var confidence: Double

    var session: SleepSession?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        duration: TimeInterval = 1.0,
        confidence: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
    }
}

extension SnoreEvent: Identifiable {}
