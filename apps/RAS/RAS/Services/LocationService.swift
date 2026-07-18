import CoreLocation
import Foundation

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((CLLocation?) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        onUpdate?(locations.last)
        onUpdate = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onUpdate?(nil)
        onUpdate = nil
    }
}

actor LocationService {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private let delegate = LocationDelegate()

    private init() {
        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    nonisolated func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func currentLocation(timeout: TimeInterval = 8) async -> CLLocation? {
        let status = manager.authorizationStatus
        guard CLLocationManager.locationServicesEnabled(),
              status == .authorizedWhenInUse || status == .authorizedAlways
        else { return nil }

        return await withCheckedContinuation { continuation in
            delegate.onUpdate = { location in
                continuation.resume(returning: location)
            }
            manager.requestLocation()

            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if delegate.onUpdate != nil {
                    delegate.onUpdate = nil
                    continuation.resume(returning: manager.location)
                }
            }
        }
    }
}
