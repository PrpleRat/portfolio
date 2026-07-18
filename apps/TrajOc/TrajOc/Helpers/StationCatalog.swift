import CoreLocation
import Foundation

/// Charge et recherche les gares embarquées Occitanie
enum StationCatalog {
    static let all: [EmbeddedStation] = load()

    /// Alias historique — toutes les gares du JSON
    static var frequent: [EmbeddedStation] { all }

    static func load() -> [EmbeddedStation] {
        guard let url = Bundle.main.url(forResource: "OccitaniaStations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stations = try? JSONDecoder().decode([EmbeddedStation].self, from: data) else {
            return []
        }
        return stations
    }

    private static let stopWords: Set<String> = [
        "gare", "de", "la", "le", "les", "du", "des", "a", "à", "st", "saint", "ste", "sainte"
    ]

    static func match(name: String) -> Place? {
        search(query: name, limit: 1).first
    }

    /// Recherche floue : « gare matabiau » → Toulouse Matabiau
    static func search(query: String, near: CLLocationCoordinate2D? = nil, limit: Int = 8) -> [Place] {
        let normalized = query.normalizedForSearch
        guard normalized.count >= 2 else { return [] }

        let tokens = normalized
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 2 && !stopWords.contains($0) }

        var scored: [(place: Place, score: Int)] = []

        for station in all {
            let name = station.name.normalizedForSearch
            let city = station.city.normalizedForSearch
            var score = 0

            if name == normalized || city == normalized { score += 200 }
            if name.contains(normalized) || normalized.contains(name) { score += 120 }
            if city.contains(normalized) || normalized.contains(city) { score += 80 }

            for token in tokens {
                if name.contains(token) { score += 40 }
                if city.contains(token) { score += 15 }
            }

            if score > 0 {
                scored.append((station.asPlace, score))
            }
        }

        scored.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            guard let near else { return lhs.place.name < rhs.place.name }
            return distance(from: near, to: lhs.place) < distance(from: near, to: rhs.place)
        }

        return Array(scored.prefix(limit).map(\.place))
    }

    static func nearby(to coordinate: CLLocationCoordinate2D, radiusMeters: Double = 20_000, limit: Int = 30) -> [Place] {
        let user = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return all
            .map(\.asPlace)
            .filter { place in
                distance(from: coordinate, to: place) <= radiusMeters
            }
            .sorted { distance(from: coordinate, to: $0) < distance(from: coordinate, to: $1) }
            .prefix(limit)
            .map { $0 }
    }

    static func mergePlaces(_ lists: [[Place]], limit: Int = 30) -> [Place] {
        var seen = Set<String>()
        var output: [Place] = []
        for list in lists {
            for place in list {
                let key = place.id.isEmpty
                    ? "\(place.name)-\(place.coordinate.lat)-\(place.coordinate.lon)"
                    : place.id
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                output.append(place)
            }
        }
        return Array(output.prefix(limit))
    }

    private static func distance(from coordinate: CLLocationCoordinate2D, to place: Place) -> CLLocationDistance {
        let user = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let target = CLLocation(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
        return user.distance(from: target)
    }
}
