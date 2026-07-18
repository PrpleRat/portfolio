import CoreLocation
import Foundation

/// Géocodage France via Base Adresse Nationale (data.gouv.fr)
actor BanAddressService {

    static let shared = BanAddressService()
    private let network = NetworkManager.shared
    private let base = AppConstants.banBaseURL

    func search(query: String, near: CLLocationCoordinate2D? = nil) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let normalized = normalizeQuery(trimmed)
        var results = try await performSearch(query: normalized, near: near)

        if results.isEmpty, normalized != trimmed {
            results = try await performSearch(query: trimmed, near: near)
        }

        if results.isEmpty, looksLikeStreetAddress(trimmed) {
            if let city = cityHint(from: near) {
                results = try await performSearch(query: "\(trimmed) \(city)", near: near)
            }
            if results.isEmpty {
                results = try await performSearch(query: "\(trimmed), France", near: near)
            }
        }

        return results
    }

    private func normalizeQuery(_ query: String) -> String {
        var q = query
        let replacements: [(String, String)] = [
            (" bd ", " boulevard "),
            (" bd.", " boulevard "),
            (" av ", " avenue "),
            (" av. ", " avenue "),
            (" st ", " saint "),
            (" ste ", " sainte ")
        ]
        for (from, to) in replacements {
            q = q.replacingOccurrences(of: from, with: to, options: .caseInsensitive)
        }
        return q.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cityHint(from near: CLLocationCoordinate2D?) -> String? {
        guard let near else { return "Toulouse" }
        let stations = StationCatalog.nearby(to: near, radiusMeters: 30_000, limit: 1)
        return stations.first?.city
    }

    private func looksLikeStreetAddress(_ query: String) -> Bool {
        let q = query.normalizedForSearch
        let hints = ["rue", "boulevard", "avenue", "place", "chemin", "impasse", "allée", "allee", "route"]
        return hints.contains { q.contains($0) } || q.first?.isNumber == true
    }

    private func performSearch(query: String, near: CLLocationCoordinate2D?) async throws -> [Place] {
        var components = URLComponents(string: "\(base)/search/")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "15"),
            URLQueryItem(name: "autocomplete", value: "1")
        ]

        if let near {
            items += [
                URLQueryItem(name: "lat", value: String(format: "%.5f", near.latitude)),
                URLQueryItem(name: "lon", value: String(format: "%.5f", near.longitude))
            ]
        } else {
            items += [
                URLQueryItem(name: "lat", value: "\(AppConstants.searchBiasLat)"),
                URLQueryItem(name: "lon", value: "\(AppConstants.searchBiasLon)")
            ]
        }
        components.queryItems = items

        guard let url = components.url else { return [] }

        let data = try await network.get(url: url, cacheDuration: 120)
        let response = try JSONDecoder().decode(BanResponse.self, from: data)
        return response.features.map { BanMapper.map($0) }
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> Place {
        var components = URLComponents(string: "\(base)/reverse/")!
        components.queryItems = [
            URLQueryItem(name: "lon", value: "\(coordinate.longitude)"),
            URLQueryItem(name: "lat", value: "\(coordinate.latitude)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else { throw NetworkError.invalidResponse }

        let data = try await network.get(url: url, cacheDuration: 60)
        let response = try JSONDecoder().decode(BanResponse.self, from: data)
        guard let feature = response.features.first else {
            throw PlaceResolverError.notFound("position GPS")
        }
        return BanMapper.map(feature)
    }

    struct BanResponse: Decodable {
        let features: [BanFeature]
    }

    struct BanFeature: Decodable {
        let geometry: Geometry
        let properties: Properties

        struct Geometry: Decodable {
            let coordinates: [Double]
        }

        struct Properties: Decodable {
            let label: String
            let score: Double?
            let city: String?
            let postcode: String?
            let id: String?
            let name: String?
            let context: String?
        }
    }
}

enum BanMapper {
    static func map(_ feature: BanAddressService.BanFeature) -> Place {
        let lon = feature.geometry.coordinates.first ?? 0
        let lat = feature.geometry.coordinates.count > 1 ? feature.geometry.coordinates[1] : 0
        let props = feature.properties
        let department = props.context?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .dropFirst()
            .first

        return Place(
            id: props.id ?? "ban-\(lat)-\(lon)",
            name: props.label,
            type: .address,
            coordinate: Place.Coordinate(lat: lat, lon: lon),
            city: props.city,
            postalCode: props.postcode,
            administrativeRegion: department
        )
    }
}
