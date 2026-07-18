import CoreLocation
import Foundation

/// Arrêts bus/tram via OpenStreetMap (Overpass) — couvre liO, réseaux locaux, Lourdes/Tarbes…
actor OverpassTransportService {

    static let shared = OverpassTransportService()
    private let network = NetworkManager.shared

    func nearbyStops(from coordinate: CLLocationCoordinate2D, radiusMeters: Int = 4_000) async -> [Place] {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let query = """
        [out:json][timeout:20];
        (
          node["highway"="bus_stop"](around:\(radiusMeters),\(lat),\(lon));
          node["public_transport"="platform"]["bus"="yes"](around:\(radiusMeters),\(lat),\(lon));
          node["amenity"="bus_station"](around:\(radiusMeters),\(lat),\(lon));
          node["public_transport"="stop_position"]["bus"="yes"](around:\(radiusMeters),\(lat),\(lon));
        );
        out body 50;
        """

        guard let url = URL(string: AppConstants.overpassBaseURL) else { return [] }

        do {
            let data = try await network.post(
                url: url,
                body: query,
                contentType: "text/plain; charset=utf-8",
                formField: nil,
                cacheDuration: 180
            )
            let response = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return response.elements.compactMap { mapElement($0) }
        } catch {
            return []
        }
    }

    private func mapElement(_ element: OverpassResponse.Element) -> Place? {
        guard let lat = element.lat, let lon = element.lon else { return nil }
        let name = element.tags?["name"]
            ?? element.tags?["ref"]
            ?? element.tags?["stop_name"]
            ?? "Arrêt bus"

        return Place(
            id: "osm-node-\(element.id)",
            name: name,
            type: .stopPoint,
            coordinate: Place.Coordinate(lat: lat, lon: lon),
            city: element.tags?["addr:city"],
            postalCode: element.tags?["addr:postcode"],
            administrativeRegion: element.tags?["network"] ?? "Bus"
        )
    }

    struct OverpassResponse: Decodable {
        let elements: [Element]

        struct Element: Decodable {
            let id: Int64
            let lat: Double?
            let lon: Double?
            let tags: [String: String]?
        }
    }
}
