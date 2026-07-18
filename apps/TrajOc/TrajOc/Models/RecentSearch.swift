import Foundation
import SwiftData

/// Recherche récente persistée localement
@Model
final class RecentSearch {
    var id: UUID
    var query: String
    var placeName: String
    var placeId: String
    var latitude: Double
    var longitude: Double
    var searchedAt: Date

    init(place: Place) {
        self.id = UUID()
        self.query = place.name
        self.placeName = place.name
        self.placeId = place.id
        self.latitude = place.coordinate.lat
        self.longitude = place.coordinate.lon
        self.searchedAt = Date()
    }

    var place: Place {
        Place(
            id: placeId,
            name: placeName,
            type: .address,
            coordinate: Place.Coordinate(lat: latitude, lon: longitude),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }
}
