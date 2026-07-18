import Combine
import CoreLocation
import Foundation

enum NearbyFilter: String, CaseIterable {
    case all = "Tout"
    case gares = "Gares"
    case bus = "Bus"
    case tram = "Tram"
    case metro = "Métro"
    case bikes = "Vélos"
}

@MainActor
final class NearbyViewModel: ObservableObject {
    @Published var stops: [Place] = []
    @Published var bikeStations: [BikeStation] = []
    @Published var selectedStop: Place?
    @Published var departures: [Departure] = []
    @Published var filter: NearbyFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userCoordinate: CLLocationCoordinate2D?

    private let navitia = NavitiaService.shared
    private let overpass = OverpassTransportService.shared
    private let bikes = BikeService.shared
    private let location = LocationManager.shared
    private var refreshTask: Task<Void, Never>?

    func loadNearby() {
        isLoading = true
        errorMessage = nil
        location.requestPermission()
        location.startUpdating()

        Task {
            defer { isLoading = false }

            let coord = await location.waitForCoordinate(timeout: 12)
                ?? location.coordinate
                ?? AppConstants.occitanieCenter
            userCoordinate = coord

            let localGares = StationCatalog.nearby(to: coord, radiusMeters: 30_000, limit: 25)
            let osmBusStops = await overpass.nearbyStops(from: coord, radiusMeters: 5_000)

            var apiStops: [Place] = []
            var apiError: String?

            if APIKeysValidator.isConfigured {
                do {
                    apiStops = try await navitia.nearbyStops(from: coord, radius: 8_000, includeStopPoints: true)
                    bikeStations = (try? await bikes.nearbyStations(from: coord)) ?? []
                } catch {
                    apiError = error.localizedDescription
                    bikeStations = []
                }
            } else {
                bikeStations = []
                apiError = "Clés API absentes — gares et arrêts OpenStreetMap affichés."
            }

            stops = sortByDistance(
                StationCatalog.mergePlaces([apiStops, localGares, osmBusStops], limit: 60),
                from: coord
            )

            if stops.isEmpty {
                errorMessage = apiError ?? "Aucun arrêt trouvé. Autorise la localisation et tire pour rafraîchir."
            } else if apiStops.isEmpty, let apiError {
                let busCount = osmBusStops.count
                let gareCount = localGares.count
                errorMessage = "\(gareCount) gare(s), \(busCount) arrêt(s) bus (OpenStreetMap). SNCF : \(apiError)"
            } else {
                errorMessage = nil
            }
        }
    }

    var filteredStops: [Place] {
        switch filter {
        case .all, .bikes:
            return stops
        case .gares:
            return stops.filter { $0.type == .stopArea || $0.type == .gare }
        case .bus:
            return stops.filter {
                $0.type == .stopPoint
                    || $0.administrativeRegion?.localizedCaseInsensitiveContains("bus") == true
                    || $0.name.localizedCaseInsensitiveContains("bus")
                    || $0.id.hasPrefix("osm-")
            }
        case .tram:
            return stops.filter { $0.name.localizedCaseInsensitiveContains("tram") }
        case .metro:
            return stops.filter {
                $0.name.localizedCaseInsensitiveContains("métro")
                    || $0.name.localizedCaseInsensitiveContains("metro")
            }
        }
    }

    func selectStop(_ stop: Place) {
        selectedStop = stop
        loadDepartures(for: stop)
        startAutoRefresh(for: stop)
    }

    func loadDepartures(for stop: Place) {
        Task {
            if stop.id.hasPrefix("osm-") {
                departures = []
                return
            }
            if APIKeysValidator.isConfigured {
                let resolved = await PlaceRoutingPreparer.shared.prepare(stop)
                departures = (try? await navitia.departures(for: resolved.place)) ?? []
            }
        }
    }

    private func sortByDistance(_ places: [Place], from coord: CLLocationCoordinate2D) -> [Place] {
        let user = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return places.sorted {
            distance(user, $0) < distance(user, $1)
        }
    }

    private func distance(_ user: CLLocation, _ place: Place) -> CLLocationDistance {
        let target = CLLocation(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
        return user.distance(from: target)
    }

    private func startAutoRefresh(for stop: Place) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                loadDepartures(for: stop)
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }
}
