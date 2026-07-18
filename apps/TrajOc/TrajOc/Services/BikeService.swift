import CoreLocation
import Foundation

/// Données vélos en libre-service — API JCDecaux
actor BikeService {

    static let shared = BikeService()
    private let network = NetworkManager.shared
    private let base = AppConstants.jcDecauxBaseURL

    func stations(contract: String) async throws -> [BikeStation] {
        guard let url = URL(string: "\(base)/stations?contract=\(contract)&apiKey=\(APIKeys.jcDecaux)") else {
            throw NetworkError.invalidResponse
        }
        let data = try await network.get(url: url, cacheDuration: 120)
        let raw = try JSONDecoder().decode([RawStation].self, from: data)
        return raw.map { BikeStation(raw: $0, contract: contract) }
    }

    func nearbyStations(from: CLLocationCoordinate2D, radius: Double = 500) async throws -> [BikeStation] {
        var all: [BikeStation] = []
        for contract in AppConstants.bikeContracts {
            let stations = (try? await stations(contract: contract)) ?? []
            let nearby = stations.filter { station in
                let stationLoc = CLLocation(latitude: station.latitude, longitude: station.longitude)
                let userLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
                return stationLoc.distance(from: userLoc) <= radius
            }
            all.append(contentsOf: nearby)
        }
        return all.sorted { $0.availableBikes > $1.availableBikes }
    }

    struct RawStation: Decodable {
        let number: Int
        let name: String
        let address: String
        let position: Position
        let status: String
        let bikestands: Int
        let availableBikestands: Int
        let availableBikes: Int
        let lastUpdate: Double?
        let banking: Bool
        let bonus: Bool

        struct Position: Decodable { let lat: Double; let lng: Double }
    }
}

extension BikeStation {
    init(raw: BikeService.RawStation, contract: String) {
        self.id = raw.number
        self.name = raw.name.components(separatedBy: " - ").last ?? raw.name
        self.address = raw.address
        self.latitude = raw.position.lat
        self.longitude = raw.position.lng
        self.totalStands = raw.bikestands
        self.availableBikes = raw.availableBikes
        self.availableStands = raw.availableBikestands
        self.isOpen = raw.status == "OPEN"
        self.hasCardPayment = raw.banking
        self.lastUpdate = raw.lastUpdate.map { Date(timeIntervalSince1970: $0 / 1000) }
        self.contract = contract
    }
}
