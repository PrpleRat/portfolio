import ActivityKit
import Foundation

/// Attributs Live Activity — partagés app + extension widget.
struct SleepTrackingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phaseName: String
        var elapsedText: String
        var isPaused: Bool
        var sessionKindTitle: String
    }

    var sessionKindTitle: String
}
