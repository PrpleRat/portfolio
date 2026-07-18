import Foundation
import CoreLocation

/// Itinéraire complet retourné par Navitia ou ORS
struct Journey: Identifiable, Codable, Equatable {
    let id: UUID
    let departureTime: Date
    let arrivalTime: Date
    let duration: Int
    let waitingDuration: Int
    let walkingDuration: Int
    let transfers: Int
    let co2EmissionsGrams: Double
    let sections: [JourneySection]
    let fare: Fare?
    var hasDisruptions: Bool

    var totalDistanceMeters: Double {
        sections.compactMap(\.distanceMeters).reduce(0, +)
    }

    var transportModes: [TransportMode] {
        sections
            .filter { $0.type == .publicTransport || $0.type == .streetNetwork }
            .map(\.mode)
            .removingDuplicates()
    }
}

struct Fare: Codable, Equatable {
    let total: Double
    let currency: String
    let found: Bool
}
