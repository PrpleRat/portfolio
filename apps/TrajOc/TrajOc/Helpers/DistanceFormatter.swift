import Foundation

/// Formate une distance en mètres → "1,2 km" ou "350 m"
enum DistanceFormatter {
    static func format(meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return String(format: "%.1f km", km).replacingOccurrences(of: ".", with: ",")
        }
        return "\(Int(meters)) m"
    }
}
