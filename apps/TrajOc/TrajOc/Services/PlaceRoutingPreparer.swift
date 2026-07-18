import CoreLocation
import Foundation

/// Prépare un lieu pour le calcul SNCF : résout les gares embarquées (OIF) en IDs SNCF
/// et accroche les adresses au stop le plus proche du réseau.
actor PlaceRoutingPreparer {

    static let shared = PlaceRoutingPreparer()
    private let navitia = NavitiaService.shared

    struct PreparedEndpoint {
        let place: Place
        let accessNote: String?
    }

    func prepare(_ place: Place) async -> PreparedEndpoint {
        if place.isSNCFNativeID {
            return PreparedEndpoint(place: place, accessNote: nil)
        }

        if APIKeysValidator.isConfigured {
            if place.isStation || place.isLegacyEmbeddedStationID {
                if let resolved = await resolveSNCFStation(named: place.name, near: place.clCoordinate) {
                    let note = resolved.id != place.id
                        ? "Départ via \(resolved.name)"
                        : nil
                    return PreparedEndpoint(place: resolved, accessNote: note)
                }
            }

            if let snapped = await snapToNearestNetworkStop(near: place.clCoordinate, radius: 5_000) {
                let note = "Accès à \(snapped.name) (marche depuis ton adresse)"
                return PreparedEndpoint(place: snapped, accessNote: note)
            }
        }

        if let gare = StationCatalog.nearby(to: place.clCoordinate, radiusMeters: 25_000, limit: 1).first {
            let note = "Accès via \(gare.name) — gare la plus proche"
            return PreparedEndpoint(place: gare, accessNote: note)
        }

        return PreparedEndpoint(place: place, accessNote: nil)
    }

    func preparePair(origin: Place, destination: Place) async -> (origin: PreparedEndpoint, destination: PreparedEndpoint) {
        async let o = prepare(origin)
        async let d = prepare(destination)
        return (await o, await d)
    }

    private func resolveSNCFStation(named name: String, near: CLLocationCoordinate2D) async -> Place? {
        let results = (try? await navitia.searchPlaces(query: name, near: near)) ?? []
        return results.first(where: { $0.isSNCFNativeID })
            ?? results.first(where: { $0.isStation })
    }

    private func snapToNearestNetworkStop(near: CLLocationCoordinate2D, radius: Int) async -> Place? {
        let stops = (try? await navitia.nearbyStops(from: near, radius: radius, includeStopPoints: true)) ?? []
        return stops.first(where: { $0.isSNCFNativeID }) ?? stops.first
    }
}
