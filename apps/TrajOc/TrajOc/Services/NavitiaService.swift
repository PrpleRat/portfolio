import CoreLocation
import Foundation

// MARK: - Structures de décodage JSON Navitia

struct NavitiaJourneysResponse: Decodable {
    let journeys: [NavitiaJourney]?
    let error: NavitiaAPIErrorBody?

    struct NavitiaAPIErrorBody: Decodable {
        let id: String?
        let message: String?
    }

    struct NavitiaJourney: Decodable {
        let duration: Int
        let nbTransfers: Int?
        let departureDateTime: String
        let arrivalDateTime: String
        let waitingDuration: Int?
        let walkingDuration: Int?
        let sections: [NavitiaSection]
        let co2Emission: CO2?
        let fare: NavitiaFare?
        let status: String?

        struct CO2: Decodable {
            let value: Double
            let unit: String
        }

        struct NavitiaFare: Decodable {
            let total: NavitiaAmount?
            let found: Bool?

            struct NavitiaAmount: Decodable {
                let value: String
                let currency: String
            }
        }
    }

    struct NavitiaSection: Decodable {
        let type: String
        let from: NavitiaPlace
        let to: NavitiaPlace
        let departureDateTime: String?
        let arrivalDateTime: String?
        let duration: Int?
        let mode: String?
        let displayInformations: DisplayInfo?
        let stopDateTimes: [StopDateTime]?
        let geojson: GeoJSON?
        let path: [PathInstruction]?

        struct DisplayInfo: Decodable {
            let commercialMode: String?
            let physicalMode: String?
            let network: String?
            let direction: String?
            let label: String?
            let color: String?
            let textColor: String?
            let code: String?
            let name: String?
        }

        struct StopDateTime: Decodable {
            let stopPoint: NavitiaPlace
            let departureDateTime: String?
            let arrivalDateTime: String?
        }

        struct GeoJSON: Decodable {
            let coordinates: [[Double]]
        }

        struct PathInstruction: Decodable {
            let length: Int?
            let name: String?
            let duration: Int?
            let direction: Int?
        }
    }

    struct NavitiaPlace: Decodable {
        let id: String?
        let name: String?
        let embeddedType: String?
        let stopArea: StopArea?
        let address: Address?
        let stopPoint: StopPoint?

        struct StopArea: Decodable {
            let id: String
            let name: String
            let coord: NavitiaCoord
            let administrativeRegions: [AdminRegion]?
        }

        struct StopPoint: Decodable {
            let id: String
            let name: String
            let coord: NavitiaCoord
        }

        struct Address: Decodable {
            let id: String?
            let name: String?
            let label: String?
            let coord: NavitiaCoord
            let houseNumber: Int?
            let administrativeRegions: [AdminRegion]?
        }

        struct NavitiaCoord: Decodable {
            let lat: String
            let lon: String

            var latitude: Double { Double(lat) ?? 0 }
            var longitude: Double { Double(lon) ?? 0 }
        }

        struct AdminRegion: Decodable {
            let name: String
            let level: Int
        }
    }
}

struct NavitiaPlacesResponse: Decodable {
    let places: [NavitiaRawPlace]

    struct NavitiaRawPlace: Decodable {
        let id: String
        let name: String
        let quality: Int
        let embeddedType: String
        let stopArea: NavitiaJourneysResponse.NavitiaPlace.StopArea?
        let address: NavitiaJourneysResponse.NavitiaPlace.Address?
    }
}

struct NavitiaPlacesNearbyResponse: Decodable {
    let placesNearby: [NavitiaPlacesResponse.NavitiaRawPlace]
}

struct NavitiaDeparturesResponse: Decodable {
    let departures: [NavitiaDeparture]

    struct NavitiaDeparture: Decodable {
        let stopDateTime: StopDT
        let route: NavitiaRoute
        let displayInformations: NavitiaJourneysResponse.NavitiaSection.DisplayInfo

        struct StopDT: Decodable {
            let departureDateTime: String
            let baseDateTime: String?
        }

        struct NavitiaRoute: Decodable {
            let id: String
            let name: String
            let direction: NavitiaPlacesResponse.NavitiaRawPlace
        }
    }
}

struct NavitiaDisruptionsResponse: Decodable {
    let disruptions: [NavitiaRawDisruption]

    struct NavitiaRawDisruption: Decodable {
        let id: String
        let status: String
        let severity: Severity
        let messages: [DisruptionMessage]
        let applicationPeriods: [Period]
        let updatedAt: String
        let impactedObjects: [ImpactedObject]?

        struct Severity: Decodable {
            let effect: String
            let name: String
            let color: String?
        }

        struct DisruptionMessage: Decodable {
            let text: String
            let channel: Channel

            struct Channel: Decodable { let name: String }
        }

        struct Period: Decodable {
            let begin: String
            let end: String
        }

        struct ImpactedObject: Decodable {
            let type: String
            let ptObject: PTObject?

            struct PTObject: Decodable {
                let id: String
                let name: String
                let embeddedType: String
            }
        }
    }
}

/// Service principal — API Navitia.io
actor NavitiaService {

    static let shared = NavitiaService()
    private let network = NetworkManager.shared
    private let base = AppConstants.navitiaBaseURL

    private var authHeader: String {
        let credentials = "\(APIKeys.navitia):"
        let encoded = Data(credentials.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    func journeys(
        from origin: Place,
        to destination: Place,
        date: Date = Date(),
        arriveBy: Bool = false,
        forbiddenModes: [TransportMode] = []
    ) async throws -> [Journey] {
        let prepared = await PlaceRoutingPreparer.shared.preparePair(origin: origin, destination: destination)

        do {
            return try await requestJourneys(
                from: prepared.origin.place,
                to: prepared.destination.place,
                date: date,
                arriveBy: arriveBy,
                forbiddenModes: forbiddenModes
            )
        } catch {
            if case NavitiaServiceError.apiMessage(let message) = error {
                let lower = message.lowercased()
                if lower.contains("not reachable") || lower.contains("reachable") {
                    return try await retryViaNearestGares(
                        origin: origin,
                        destination: destination,
                        date: date,
                        arriveBy: arriveBy,
                        forbiddenModes: forbiddenModes
                    )
                }
            }
            throw error
        }
    }

    private func retryViaNearestGares(
        origin: Place,
        destination: Place,
        date: Date,
        arriveBy: Bool,
        forbiddenModes: [TransportMode]
    ) async throws -> [Journey] {
        guard let fromGare = StationCatalog.nearby(to: origin.clCoordinate, radiusMeters: 40_000, limit: 1).first,
              let toGare = StationCatalog.nearby(to: destination.clCoordinate, radiusMeters: 40_000, limit: 1).first else {
            throw NavitiaServiceError.notReachable
        }

        let fromResolved = await PlaceRoutingPreparer.shared.prepare(fromGare)
        let toResolved = await PlaceRoutingPreparer.shared.prepare(toGare)

        return try await requestJourneys(
            from: fromResolved.place,
            to: toResolved.place,
            date: date,
            arriveBy: arriveBy,
            forbiddenModes: forbiddenModes
        )
    }

    private func requestJourneys(
        from origin: Place,
        to destination: Place,
        date: Date,
        arriveBy: Bool,
        forbiddenModes: [TransportMode]
    ) async throws -> [Journey] {
        let fromStr = origin.navitiaLocationRef
        let toStr = destination.navitiaLocationRef
        let dateStr = NavitiaRequestFormatter.journeyDateTime(from: max(date, Date()))

        var components = URLComponents(string: "\(base)/coverage/sncf/journeys")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "from", value: fromStr),
            URLQueryItem(name: "to", value: toStr),
            URLQueryItem(name: "datetime", value: dateStr),
            URLQueryItem(name: "datetime_represents", value: arriveBy ? "arrival" : "departure"),
            URLQueryItem(name: "count", value: "\(AppConstants.navitiaMaxJourneys)"),
            URLQueryItem(name: "max_duration", value: "\(AppConstants.navitiaMaxDuration)"),
            URLQueryItem(name: "min_nb_transfers", value: "0"),
            URLQueryItem(name: "max_nb_transfers", value: "5"),
            URLQueryItem(name: "walking_speed", value: "1.12"),
            URLQueryItem(name: "max_duration_to_depart", value: "3600"),
            URLQueryItem(name: "max_duration_to_arrive", value: "3600"),
            URLQueryItem(name: "first_section_mode[]", value: "walking"),
            URLQueryItem(name: "last_section_mode[]", value: "walking")
        ]

        for mode in forbiddenModes {
            items.append(URLQueryItem(name: "forbidden_uris[]", value: mode.rawValue))
        }
        components.queryItems = items

        guard let url = components.url else { throw NetworkError.invalidResponse }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": authHeader],
            cacheDuration: AppConstants.cacheExpiry
        )

        if let apiError = try? JSONDecoder.navitia.decode(NavitiaJourneysResponse.self, from: data),
           let message = apiError.error?.message, !message.isEmpty,
           (apiError.journeys ?? []).isEmpty {
            throw NavitiaServiceError.apiMessage(message)
        }

        let response: NavitiaJourneysResponse
        do {
            response = try JSONDecoder.navitia.decode(NavitiaJourneysResponse.self, from: data)
        } catch {
            throw NavitiaServiceError.decodingFailed
        }

        let journeys = (response.journeys ?? []).map { JourneyMapper.map($0) }
        guard !journeys.isEmpty else {
            throw NavitiaServiceError.noJourneyFound
        }
        return journeys
    }

    func searchPlaces(query: String, near: CLLocationCoordinate2D? = nil) async throws -> [Place] {
        guard query.count >= 2 else { return [] }

        var components = URLComponents(string: "\(base)/coverage/sncf/places")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type[]", value: "stop_area"),
            URLQueryItem(name: "type[]", value: "stop_point"),
            URLQueryItem(name: "type[]", value: "address"),
            URLQueryItem(name: "type[]", value: "administrative_region"),
            URLQueryItem(name: "count", value: "10")
        ]

        if let coord = near {
            items.append(URLQueryItem(name: "from", value: "\(coord.longitude);\(coord.latitude)"))
        } else {
            items.append(URLQueryItem(name: "from", value: "\(AppConstants.searchBiasLon);\(AppConstants.searchBiasLat)"))
        }
        components.queryItems = items

        guard let url = components.url else { return [] }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": authHeader],
            cacheDuration: 60
        )

        let response = try JSONDecoder.navitia.decode(NavitiaPlacesResponse.self, from: data)
        return response.places.map { PlaceMapper.map($0) }
    }

    func departures(for place: Place, count: Int = 8) async throws -> [Departure] {
        let path = place.navitiaDeparturesPath
        guard let url = URL(string: "\(base)/coverage/sncf/\(path)?count=\(count)&duration=7200&distance=500") else {
            throw NetworkError.invalidResponse
        }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": authHeader],
            cacheDuration: 30
        )

        let response = try JSONDecoder.navitia.decode(NavitiaDeparturesResponse.self, from: data)
        return response.departures.map { DepartureMapper.map($0) }
    }

    /// Compatibilité — préférer `departures(for:)`
    func departures(stopAreaId: String, count: Int = 8) async throws -> [Departure] {
        try await departures(
            for: Place(
                id: stopAreaId,
                name: "",
                type: .stopArea,
                coordinate: Place.Coordinate(lat: 0, lon: 0),
                city: nil,
                postalCode: nil,
                administrativeRegion: nil
            ),
            count: count
        )
    }

    func disruptions() async throws -> [Disruption] {
        let since = ISO8601DateFormatter().string(from: Date())
        guard let url = URL(string: "\(base)/coverage/sncf/disruptions?since=\(since)&count=50") else {
            throw NetworkError.invalidResponse
        }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": authHeader],
            cacheDuration: 120
        )

        let response = try JSONDecoder.navitia.decode(NavitiaDisruptionsResponse.self, from: data)
        return response.disruptions.map { DisruptionMapper.map($0) }
    }

    func nearbyStops(from: CLLocationCoordinate2D, radius: Int = 500, includeStopPoints: Bool = false) async throws -> [Place] {
        var typeParams = "type[]=stop_area"
        if includeStopPoints {
            typeParams += "&type[]=stop_point"
        }
        guard let url = URL(string: "\(base)/coverage/sncf/coords/\(from.longitude);\(from.latitude)/places_nearby?\(typeParams)&radius=\(radius)&count=40") else {
            throw NetworkError.invalidResponse
        }

        let data = try await network.get(
            url: url,
            headers: ["Authorization": authHeader],
            cacheDuration: 60
        )

        let response = try JSONDecoder.navitia.decode(NavitiaPlacesNearbyResponse.self, from: data)
        return response.placesNearby.map { PlaceMapper.map($0) }
    }
}

enum NavitiaServiceError: LocalizedError {
    case noJourneyFound
    case notReachable
    case decodingFailed
    case apiMessage(String)

    var errorDescription: String? {
        switch self {
        case .noJourneyFound:
            return "Aucun trajet trouvé à cet horaire. Essaie une autre heure ou une gare comme point de départ."
        case .notReachable:
            return "Impossible d'accéder au réseau depuis ce point. Choisis une gare (Lourdes, Tarbes, Toulouse Matabiau…) dans les suggestions."
        case .decodingFailed:
            return "Réponse SNCF inattendue. Réessaie en sélectionnant une gare dans la liste."
        case .apiMessage(let message):
            let lower = message.lowercased()
            if lower.contains("entry point") || lower.contains("not valid") {
                return "Gare ou adresse non reconnue. Sélectionne une suggestion dans la liste."
            }
            if lower.contains("not reachable") || lower.contains("reachable") {
                return "Pas d'arrêt de transport accessible à pied (60 min max). Sélectionne une gare proche — Lourdes et Tarbes fonctionnent via la gare TER."
            }
            return message
        }
    }
}
