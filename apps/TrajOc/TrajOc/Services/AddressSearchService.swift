import CoreLocation
import Foundation

/// Recherche unifiée : gares embarquées + BAN (adresses FR) + SNCF + Nominatim
actor AddressSearchService {

    static let shared = AddressSearchService()
    private let ban = BanAddressService.shared
    private let geocoding = GeocodingService.shared
    private let navitia = NavitiaService.shared

    func search(query: String, near: CLLocationCoordinate2D?) async -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let center = near ?? CLLocationCoordinate2D(latitude: AppConstants.searchBiasLat, longitude: AppConstants.searchBiasLon)
            return StationCatalog.nearby(to: center, radiusMeters: 50_000, limit: 12)
        }

        let local = StationCatalog.search(query: trimmed, near: near, limit: 8)

        async let banTask = ban.search(query: trimmed, near: near)
        async let sncfTask = APIKeysValidator.isConfigured
            ? navitia.searchPlaces(query: trimmed, near: near)
            : emptyPlaces()
        async let nominatimTask = geocoding.search(query: trimmed)

        let banResults = (try? await banTask) ?? []
        let sncfResults = (try? await sncfTask) ?? []
        let nominatimResults = (try? await nominatimTask) ?? []

        let looksLikeAddress = trimmed.first?.isNumber == true
            || ["rue", "boulevard", "bd", "avenue", "place", "chemin"].contains { trimmed.normalizedForSearch.contains($0) }

        if looksLikeAddress {
            return dedupe(banResults + local + sncfResults + nominatimResults)
        }
        return dedupe(local + banResults + sncfResults + nominatimResults)
    }

    func resolve(text: String, existing: Place?, near: CLLocationCoordinate2D?) async throws -> Place {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlaceResolverError.empty }

        if let existing, hasValidCoordinate(existing), textsMatch(trimmed, place: existing) {
            return existing
        }

        let normalized = trimmed.normalizedForSearch
        let stationHint = normalized.contains("gare")
            || normalized.contains("matabiau")
            || normalized.contains("saint-roch")
            || normalized.contains("saint roch")

        if stationHint, let station = StationCatalog.search(query: trimmed, near: near, limit: 1).first {
            return station
        }

        let results = await search(query: trimmed, near: near)

        if stationHint, let station = results.first(where: { $0.isStation }) {
            return station
        }

        if let exact = results.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            return exact
        }

        if let fuzzy = results.first(where: { textsMatch(trimmed, place: $0) }) {
            return fuzzy
        }

        if let first = results.first {
            return first
        }

        throw PlaceResolverError.notFound(trimmed)
    }

    private func emptyPlaces() async -> [Place] { [] }

    private func dedupe(_ places: [Place]) -> [Place] {
        StationCatalog.mergePlaces([places], limit: 15)
    }

    private func hasValidCoordinate(_ place: Place) -> Bool {
        abs(place.coordinate.lat) > 0.01 || abs(place.coordinate.lon) > 0.01
    }

    private func textsMatch(_ text: String, place: Place) -> Bool {
        let a = text.normalizedForSearch
        let b = place.name.normalizedForSearch
        return a == b || a.contains(b) || b.contains(a)
    }
}
