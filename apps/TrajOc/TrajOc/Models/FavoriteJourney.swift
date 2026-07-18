import Foundation
import SwiftData

/// Trajet favori persisté localement
@Model
final class FavoriteJourney {
    var id: UUID
    var name: String
    var originName: String
    var originLat: Double
    var originLon: Double
    var destinationName: String
    var destinationLat: Double
    var destinationLon: Double
    var createdAt: Date

    init(
        name: String,
        origin: Place,
        destination: Place
    ) {
        self.id = UUID()
        self.name = name
        self.originName = origin.name
        self.originLat = origin.coordinate.lat
        self.originLon = origin.coordinate.lon
        self.destinationName = destination.name
        self.destinationLat = destination.coordinate.lat
        self.destinationLon = destination.coordinate.lon
        self.createdAt = Date()
    }

    var originPlace: Place {
        Place(
            id: "favorite-origin-\(id.uuidString)",
            name: originName,
            type: .address,
            coordinate: Place.Coordinate(lat: originLat, lon: originLon),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }

    var destinationPlace: Place {
        Place(
            id: "favorite-dest-\(id.uuidString)",
            name: destinationName,
            type: .address,
            coordinate: Place.Coordinate(lat: destinationLat, lon: destinationLon),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }
}
