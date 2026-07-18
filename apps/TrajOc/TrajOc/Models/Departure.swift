import Foundation

/// Prochain départ d'un arrêt
struct Departure: Identifiable, Equatable {
    let id: String
    let line: TransitLine
    let direction: String
    let scheduledTime: Date
    let realTime: Date
    let hasDisruption: Bool

    var delayMinutes: Int {
        Int(realTime.timeIntervalSince(scheduledTime) / 60)
    }

    var isDelayed: Bool {
        delayMinutes > 2
    }
}
