import SwiftUI

extension Color {
    static let safeGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let safeOrange = Color(red: 1.0, green: 0.58, blue: 0.2)
    static let safeRed = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let safeBackground = Color(uiColor: .systemGroupedBackground)
    static let safeCard = Color(uiColor: .secondarySystemGroupedBackground)

    init(securityLevel: CheckInMethod.SecurityLevel) {
        switch securityLevel {
        case .high: self = .safeGreen
        case .medium: self = .blue
        case .low: self = .safeOrange
        case .none: self = .gray
        }
    }
}

/// Permet `.foregroundStyle(.safeGreen)` et `.tint(.safeRed)` (ShapeStyle, pas seulement Color).
extension ShapeStyle where Self == Color {
    static var safeGreen: Color { Color.safeGreen }
    static var safeOrange: Color { Color.safeOrange }
    static var safeRed: Color { Color.safeRed }
    static var safeBackground: Color { Color.safeBackground }
    static var safeCard: Color { Color.safeCard }
}

extension TimeInterval {
    var formattedCountdown: String {
        let total = Int(max(0, self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
