@preconcurrency import CoreLocation
import Foundation

/// Météo nocturne via Open-Meteo (gratuit, sans clé API)
actor WeatherService {
    struct NightWeather {
        var temperature: Double?
        var humidity: Double?
        var pressure: Double?
    }

    func fetchNightWeather(for date: Date, latitude: Double, longitude: Double) async -> NightWeather? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: date)

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,surface_pressure"),
            URLQueryItem(name: "start_date", value: day),
            URLQueryItem(name: "end_date", value: day),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            guard let hourly = decoded.hourly else { return nil }

            // Moyenne sur les heures 22h-6h (indices approximatifs)
            let nightIndices = hourly.time.indices.filter { idx in
                guard idx < hourly.time.count else { return false }
                let t = hourly.time[idx]
                return t.contains("T22") || t.contains("T23") || t.contains("T0") ||
                    t.contains("T01") || t.contains("T02") || t.contains("T03") ||
                    t.contains("T04") || t.contains("T05") || t.contains("T06")
            }

            func avg(_ arr: [Double]?, indices: [Int]) -> Double? {
                guard let arr else { return nil }
                let vals = indices.compactMap { i -> Double? in
                    guard i < arr.count else { return nil }
                    return arr[i]
                }
                guard !vals.isEmpty else { return nil }
                return vals.reduce(0, +) / Double(vals.count)
            }

            return NightWeather(
                temperature: avg(hourly.temperature2m, indices: Array(nightIndices)),
                humidity: avg(hourly.relativeHumidity2m, indices: Array(nightIndices)),
                pressure: avg(hourly.surfacePressure, indices: Array(nightIndices))
            )
        } catch {
            return nil
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let hourly: HourlyData?

    enum CodingKeys: String, CodingKey {
        case hourly
    }
}

private struct HourlyData: Decodable {
    let time: [String]
    let temperature2m: [Double]?
    let relativeHumidity2m: [Double]?
    let surfacePressure: [Double]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case surfacePressure = "surface_pressure"
    }
}

/// Géolocalisation simple pour la météo
@MainActor
final class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var latitude: Double?
    @Published var longitude: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            break
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        Task { @MainActor [weak self] in
            self?.manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        DispatchQueue.main.async { [weak self] in
            self?.latitude = lat
            self?.longitude = lon
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
