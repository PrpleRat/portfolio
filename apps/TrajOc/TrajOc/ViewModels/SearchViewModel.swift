import Combine
import CoreLocation
import Foundation

/// État de la recherche d'itinéraire
enum SearchState: Equatable {
    case idle
    case searching
    case results([Journey])
    case error(String)
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var originText = ""
    @Published var destinationText = ""
    @Published var origin: Place?
    @Published var destination: Place?
    @Published var intermediateStops: [Place] = []
    @Published var intermediateTexts: [String] = []
    @Published var shouldOptimizeStops = false
    @Published var departAt = true
    @Published var selectedDate = Date()
    @Published var enabledModes: Set<TransportMode> = [.ter, .train, .bus, .coach, .tram, .metro, .walk]
    @Published var state: SearchState = .idle
    @Published var suggestions: [Place] = []
    @Published var isSearchingSuggestions = false
    /// Champ en cours d'édition — `nil` = panneau suggestions masqué
    @Published var activeField: SearchField?

    enum SearchField: Equatable { case origin, destination, intermediate(Int) }

    enum SearchFocusTarget: Hashable { case origin, destination }

    private let navitia = NavitiaService.shared
    private let addressSearch = AddressSearchService.shared
    private let ban = BanAddressService.shared
    private let geocoding = GeocodingService.shared
    private let ors = OpenRouteService.shared
    private let optimizer = RouteOptimizer.shared
    private let locationManager = LocationManager.shared
    private var suggestionTask: Task<Void, Never>?
    private var suppressSearch = false

    func beginEditing(_ field: SearchField) {
        activeField = field
        let query = queryText(for: field)
        if query.isEmpty {
            searchSuggestions(for: "")
        } else {
            searchSuggestions(for: query)
        }
    }

    func dismissSuggestions() {
        suggestionTask?.cancel()
        activeField = nil
        suggestions = []
        isSearchingSuggestions = false
    }

    private func queryText(for field: SearchField) -> String {
        switch field {
        case .origin: return originText
        case .destination: return destinationText
        case .intermediate(let index):
            return intermediateTexts.indices.contains(index) ? intermediateTexts[index] : ""
        }
    }

    func useCurrentLocationForOrigin() {
        Task {
            dismissSuggestions()

            guard await locationManager.ensureAuthorization() else {
                state = .error("Autorise la localisation dans Réglages iPhone → TrajOc.")
                return
            }

            guard let coord = await locationManager.waitForCoordinate() else {
                state = .error("Position GPS indisponible. Réessaie dehors ou près d'une fenêtre.")
                return
            }

            let place: Place
            if let geocoded = try? await ban.reverseGeocode(coord) {
                place = geocoded
            } else if let geocoded = try? await geocoding.reverseGeocode(coord) {
                place = geocoded
            } else {
                place = Place(
                    id: "gps-\(coord.latitude)-\(coord.longitude)",
                    name: "Ma position",
                    type: .address,
                    coordinate: Place.Coordinate(lat: coord.latitude, lon: coord.longitude),
                    city: nil,
                    postalCode: nil,
                    administrativeRegion: nil
                )
            }

            origin = place
            originText = place.name
            dismissSuggestions()
        }
    }

    func swapEndpoints() {
        swap(&originText, &destinationText)
        swap(&origin, &destination)
    }

    func addIntermediateStop() {
        guard intermediateStops.count < AppConstants.maxIntermediateStops else { return }
        intermediateStops.append(Place(
            id: UUID().uuidString,
            name: "",
            type: .address,
            coordinate: Place.Coordinate(lat: 0, lon: 0),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        ))
        intermediateTexts.append("")
    }

    func removeIntermediate(at index: Int) {
        guard intermediateStops.indices.contains(index) else { return }
        intermediateStops.remove(at: index)
        intermediateTexts.remove(at: index)
    }

    func moveIntermediate(from source: IndexSet, to destination: Int) {
        intermediateStops.move(fromOffsets: source, toOffset: destination)
        intermediateTexts.move(fromOffsets: source, toOffset: destination)
    }

    func searchSuggestions(for query: String) {
        if suppressSearch { return }
        guard activeField != nil else { return }

        suggestionTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            isSearchingSuggestions = false
            let center = locationManager.coordinate ?? AppConstants.occitanieCenter
            suggestions = StationCatalog.nearby(to: center, radiusMeters: 50_000, limit: 10)
            return
        }

        if trimmed.count < 2 {
            isSearchingSuggestions = false
            suggestions = StationCatalog.search(query: trimmed, near: locationManager.coordinate, limit: 10)
            return
        }

        isSearchingSuggestions = true
        suggestionTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }

            let results = await addressSearch.search(
                query: trimmed,
                near: locationManager.coordinate
            )
            guard !Task.isCancelled else { return }
            suggestions = results
            isSearchingSuggestions = false
        }
    }

    /// Après sélection : masque les suggestions et renvoie le champ suivant à focaliser
    @discardableResult
    func selectSuggestion(_ place: Place, field: SearchField) -> SearchFocusTarget? {
        suggestionTask?.cancel()
        suppressSearch = true

        switch field {
        case .origin:
            origin = place
            originText = place.name
        case .destination:
            destination = place
            destinationText = place.name
        case .intermediate(let index):
            if intermediateStops.indices.contains(index) {
                intermediateStops[index] = place
                intermediateTexts[index] = place.name
            }
        }

        suggestions = []
        isSearchingSuggestions = false
        activeField = nil

        suppressSearch = false

        switch field {
        case .origin:
            return destination == nil || destinationText.isEmpty ? .destination : nil
        case .destination:
            return nil
        case .intermediate:
            return nil
        }
    }

    func selectFrequentStation(_ place: Place, asOrigin: Bool) {
        suppressSearch = true
        if asOrigin {
            origin = place
            originText = place.name
        } else {
            destination = place
            destinationText = place.name
        }
        dismissSuggestions()
        suppressSearch = false
    }

    func calculateJourney() {
        state = .searching

        Task {
            do {
                if !APIKeysValidator.isConfigured {
                    throw NSError(
                        domain: "TrajOc",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Clés API absentes. Ajoute SNCF_API_KEY, ORS_API_KEY et JCDECAUX_API_KEY dans GitHub Secrets puis relance TestFlight."]
                    )
                }

                let resolvedOrigin = try await PlaceResolver.resolve(
                    text: originText,
                    existing: origin,
                    near: locationManager.coordinate
                )
                let resolvedDestination = try await PlaceResolver.resolve(
                    text: destinationText,
                    existing: destination,
                    near: locationManager.coordinate
                )
                origin = resolvedOrigin
                destination = resolvedDestination

                var stops = intermediateStops.filter { $0.coordinate.lat != 0 || $0.coordinate.lon != 0 }
                if shouldOptimizeStops, stops.count > 1 {
                    stops = await optimizer.optimizeStops(
                        origin: resolvedOrigin,
                        destination: resolvedDestination,
                        intermediates: stops
                    )
                }

                var allJourneys: [Journey] = []
                let waypoints = [resolvedOrigin] + stops + [resolvedDestination]

                for i in 0..<(waypoints.count - 1) {
                    let fromPlace = waypoints[i]
                    let toPlace = waypoints[i + 1]

                    if enabledModes.contains(.car) && enabledModes.isSubset(of: [.car, .walk]) {
                        let journey = try await ors.directions(from: fromPlace.clCoordinate, to: toPlace.clCoordinate, profile: .drivingCar)
                        allJourneys.append(journey)
                    } else if enabledModes.contains(.bike) && !enabledModes.contains(.ter) {
                        let journey = try await ors.directions(from: fromPlace.clCoordinate, to: toPlace.clCoordinate, profile: .cyclingRegular)
                        allJourneys.append(journey)
                    } else {
                        let segment = try await navitia.journeys(
                            from: fromPlace,
                            to: toPlace,
                            date: max(selectedDate, Date()),
                            arriveBy: !departAt
                        )
                        allJourneys.append(contentsOf: segment)
                    }
                }

                if allJourneys.isEmpty {
                    state = .error("Aucun itinéraire trouvé. Essaie d'autres modes ou horaires.")
                } else {
                    state = .results(Array(allJourneys.prefix(AppConstants.navitiaMaxJourneys)))
                }
            } catch {
                state = .error(UserFacingError.message(for: error))
            }
        }
    }

    func resetError() {
        if case .error = state { state = .idle }
    }
}

/// Gestionnaire de localisation simplifié
@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoding = GeocodingService.shared

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    /// Attend la première fix GPS (max 10 s)
    func waitForCoordinate(timeout: TimeInterval = 10) async -> CLLocationCoordinate2D? {
        requestPermission()
        startUpdating()

        if let coordinate { return coordinate }

        let steps = Int(timeout / 0.25)
        for _ in 0..<steps {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if let coordinate { return coordinate }
        }
        return coordinate
    }

    func ensureAuthorization() async -> Bool {
        requestPermission()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            return true
        }
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return false
        }
        // Attendre la réponse utilisateur au popup
        for _ in 0..<40 {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                startUpdating()
                return true
            }
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                return false
            }
        }
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func currentPlace() async -> Place? {
        guard let coord = await waitForCoordinate() else { return nil }
        if let geocoded = try? await BanAddressService.shared.reverseGeocode(coord) {
            return geocoded
        }
        if let geocoded = try? await geocoding.reverseGeocode(coord) {
            return geocoded
        }
        return Place(
            id: "current-location",
            name: "Ma position",
            type: .address,
            coordinate: Place.Coordinate(lat: coord.latitude, lon: coord.longitude),
            city: nil,
            postalCode: nil,
            administrativeRegion: nil
        )
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.coordinate = location.coordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
