import CoreLocation
import Foundation

/// Estimation des émissions CO2 par mode (g/km)
enum CO2Calculator {
    private static let gramsPerKm: [TransportMode: Double] = [
        .walk: 0,
        .bike: 0,
        .bikeShare: 0,
        .bus: 89,
        .coach: 89,
        .tram: 35,
        .metro: 40,
        .ter: 29,
        .train: 29,
        .intercity: 35,
        .car: 192,
        .taxi: 192
    ]

    static func estimate(for sections: [JourneySection]) -> Double {
        sections.reduce(0) { partial, section in
            let km = (section.distanceMeters ?? 0) / 1000
            let factor = gramsPerKm[section.mode] ?? 50
            return partial + km * factor
        }
    }
}
