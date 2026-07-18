import CoreLocation
import Foundation

/// Service ORS — calcul itinéraires voiture, vélo, marche
actor OpenRouteService {

    static let shared = OpenRouteService()
    private let network = NetworkManager.shared
    private let base = AppConstants.orsBaseURL

    enum ORSProfile: String {
        case drivingCar = "driving-car"
        case cyclingRegular = "cycling-regular"
        case footWalking = "foot-walking"
    }

    func directions(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        profile: ORSProfile
    ) async throws -> Journey {
        guard let url = URL(string: "\(base)/v2/directions/\(profile.rawValue)/geojson?start=\(from.longitude),\(from.latitude)&end=\(to.longitude),\(to.latitude)") else {
            throw NetworkError.invalidResponse
        }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": APIKeys.openRouteService],
            cacheDuration: AppConstants.cacheExpiry
        )
        let response = try JSONDecoder().decode(ORSResponse.self, from: data)
        return ORSMapper.map(response, profile: profile)
    }

    struct ORSResponse: Decodable {
        let features: [Feature]

        struct Feature: Decodable {
            let properties: Properties
            let geometry: Geometry

            struct Properties: Decodable {
                let summary: Summary
                let segments: [Segment]

                struct Summary: Decodable {
                    let distance: Double
                    let duration: Double
                }

                struct Segment: Decodable {
                    let distance: Double
                    let duration: Double
                    let steps: [Step]

                    struct Step: Decodable {
                        let distance: Double
                        let duration: Double
                        let instruction: String
                        let name: String
                        let type: Int
                    }
                }
            }

            struct Geometry: Decodable {
                let coordinates: [[Double]]
            }
        }
    }
}
