import Foundation

/// Formate une durée en secondes → "1h 23min" ou "45 min"
enum DurationFormatter {
    static func format(seconds: Int) -> String {
        guard seconds > 0 else { return "0 min" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)min" : "\(hours)h"
        }
        return "\(max(minutes, 1)) min"
    }

    static func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func relativeMinutes(until date: Date) -> String {
        let minutes = Int(date.timeIntervalSinceNow / 60)
        if minutes <= 0 { return "maintenant" }
        if minutes < 60 { return "dans \(minutes) min" }
        return format(date: date)
    }
}
