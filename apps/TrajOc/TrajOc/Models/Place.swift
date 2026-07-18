import CoreLocation
import Foundation

/// Un lieu : gare, arrêt, adresse, POI
struct Place: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let type: PlaceType
    let coordinate: Coordinate
    let city: String?
    let postalCode: String?
    let administrativeRegion: String?

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
    }

    var displaySubtitle: String {
        [city, administrativeRegion]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    enum PlaceType: String, Codable {
        case stopArea = "stop_area"
        case stopPoint = "stop_point"
        case address = "address"
        case poi = "poi"
        case administrativeRegion = "administrative_region"
        case gare = "gare"
    }

    struct Coordinate: Codable, Equatable, Hashable {
        let lat: Double
        let lon: Double
    }
}

/// Entrée embarquée depuis OccitaniaStations.json
struct EmbeddedStation: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let latitude: Double
    let longitude: Double
    let city: String
    let department: String
    let networks: [String]

    var asPlace: Place {
        Place(
            id: id,
            name: name,
            type: .gare,
            coordinate: Place.Coordinate(lat: latitude, lon: longitude),
            city: city,
            postalCode: nil,
            administrativeRegion: department
        )
    }
}
