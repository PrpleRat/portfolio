import Foundation
import CoreLocation

/// Section d'un itinéraire (transport en commun, marche, attente, etc.)
struct JourneySection: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SectionType
    let mode: TransportMode
    let from: Place
    let to: Place
    let departureTime: Date?
    let arrivalTime: Date?
    let duration: Int
    let distanceMeters: Double?
    let line: TransitLine?
    let stopPoints: [Place]
    let turnInstructions: [String]
    let encodedPolyline: String?
    let boardingPosition: String?
    var disruptions: [Disruption]
}

enum SectionType: String, Codable {
    case publicTransport = "public_transport"
    case streetNetwork = "street_network"
    case waiting = "waiting"
    case transfer = "transfer"
    case boarding = "boarding"
    case alighting = "alighting"
    case ridesharing = "ridesharing"
}

enum TransportMode: String, Codable, CaseIterable {
    case train = "train"
    case ter = "ter"
    case intercity = "intercity"
    case bus = "bus"
    case coach = "coach"
    case tram = "tramway"
    case metro = "metro"
    case walk = "walking"
    case bike = "bike"
    case bikeShare = "bike_sharing"
    case car = "car"
    case taxi = "taxi"

    var displayName: String {
        switch self {
        case .train: return "Train"
        case .ter: return "TER"
        case .intercity: return "Intercités"
        case .bus: return "Bus"
        case .coach: return "Car régional"
        case .tram: return "Tramway"
        case .metro: return "Métro"
        case .walk: return "Marche"
        case .bike: return "Vélo"
        case .bikeShare: return "Vélo en libre-service"
        case .car: return "Voiture"
        case .taxi: return "Taxi"
        }
    }

    var sfSymbol: String {
        switch self {
        case .train, .ter, .intercity: return "train.side.front.car"
        case .bus, .coach: return "bus"
        case .tram: return "tram"
        case .metro: return "tram.fill"
        case .walk: return "figure.walk"
        case .bike, .bikeShare: return "bicycle"
        case .car: return "car.fill"
        case .taxi: return "car.badge.plus"
        }
    }

    var colorHex: String {
        switch self {
        case .train, .ter, .intercity: return "#C0392B"
        case .bus, .coach: return "#2980B9"
        case .tram: return "#8E44AD"
        case .metro: return "#F39C12"
        case .walk: return "#7F8C8D"
        case .bike, .bikeShare: return "#27AE60"
        case .car: return "#2C3E50"
        case .taxi: return "#F1C40F"
        }
    }

    /// Filtres UI — regroupe les modes Navitia
    static var filterGroups: [(label: String, modes: [TransportMode])] {
        [
            ("TER/Train", [.ter, .train, .intercity]),
            ("Bus/Car", [.bus, .coach]),
            ("Tram", [.tram]),
            ("Métro", [.metro]),
            ("Marche", [.walk]),
            ("Vélo", [.bike, .bikeShare]),
            ("Voiture", [.car])
        ]
    }
}

extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for item in self where !result.contains(item) {
            result.append(item)
        }
        return result
    }
}
