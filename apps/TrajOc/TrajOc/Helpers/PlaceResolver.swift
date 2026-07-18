import CoreLocation
import Foundation

/// Résout un texte saisi en Place (gares embarquées, BAN, SNCF, Nominatim)
enum PlaceResolver {
    private static let addressSearch = AddressSearchService.shared

    static func resolve(
        text: String,
        existing: Place?,
        near: CLLocationCoordinate2D?
    ) async throws -> Place {
        try await addressSearch.resolve(text: text, existing: existing, near: near)
    }

    static func nearbyStations(from coordinate: CLLocationCoordinate2D, radiusMeters: Double = 1500) -> [Place] {
        StationCatalog.nearby(to: coordinate, radiusMeters: radiusMeters)
    }
}

enum PlaceResolverError: LocalizedError {
    case empty
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Saisis une adresse ou choisis une suggestion."
        case .notFound(let query):
            return "Lieu introuvable : « \(query) ». Essaie une gare ou une adresse plus précise."
        }
    }
}
