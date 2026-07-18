import CoreLocation
import Foundation

/// Geocodage via Nominatim / OpenStreetMap — gratuit, sans clé
actor GeocodingService {

    static let shared = GeocodingService()
    private let network = NetworkManager.shared
    private let base = AppConstants.nominatimBaseURL

    func search(query: String) async throws -> [Place] {
        guard query.count >= 2 else { return [] }

        var components = URLComponents(string: "\(base)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "countrycodes", value: AppConstants.searchCountryCode),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "viewbox", value: "-0.32,44.97,4.84,42.33"),
            URLQueryItem(name: "bounded", value: "0")
        ]

        guard let url = components.url else { return [] }

        let data = try await network.get(url: url, cacheDuration: 60, rateLimitNominatim: true)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let results = try decoder.decode([NominatimResult].self, from: data)
        return results.map { NominatimMapper.map($0) }
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> Place {
        var components = URLComponents(string: "\(base)/reverse")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(coordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(coordinate.longitude)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "addressdetails", value: "1")
        ]

        guard let url = components.url else { throw NetworkError.invalidResponse }

        let data = try await network.get(url: url, cacheDuration: 30, rateLimitNominatim: true)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(NominatimResult.self, from: data)
        return NominatimMapper.map(result)
    }

    struct NominatimResult: Decodable {
        let placeId: Int
        let lat: String
        let lon: String
        let displayName: String
        let type: String
        let importance: Double?
        let address: Address?

        struct Address: Decodable {
            let city: String?
            let town: String?
            let village: String?
            let county: String?
            let stateDistrict: String?
            let state: String?
            let postcode: String?
        }
    }
}
