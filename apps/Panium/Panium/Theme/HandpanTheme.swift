import SwiftUI

enum HandpanColors {
    static let background = Color.black
    static let surface = Color(red: 20 / 255, green: 20 / 255, blue: 24 / 255)
    static let surfaceGlass = Color(red: 20 / 255, green: 20 / 255, blue: 24 / 255).opacity(0.85)
    static let surfaceElevated = Color(red: 30 / 255, green: 30 / 255, blue: 36 / 255)
    static let text = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    static let textSecondary = Color(red: 152 / 255, green: 152 / 255, blue: 168 / 255)
    static let textTertiary = Color(red: 92 / 255, green: 92 / 255, blue: 104 / 255)
    static let icon = Color(red: 232 / 255, green: 232 / 255, blue: 240 / 255)
    static let border = Color(red: 46 / 255, green: 46 / 255, blue: 56 / 255)
    static let accentBlue = Color(red: 91 / 255, green: 141 / 255, blue: 239 / 255)
    static let accentViolet = Color(red: 155 / 255, green: 109 / 255, blue: 255 / 255)
    static let accentBlueDim = Color(red: 61 / 255, green: 90 / 255, blue: 158 / 255)
    static let padIdle = Color(red: 24 / 255, green: 24 / 255, blue: 30 / 255)
    static let padBorder = Color.white.opacity(0.33)
    static let padBorderIdle = Color.white.opacity(0.22)
    static let padLabel = Color(red: 154 / 255, green: 154 / 255, blue: 168 / 255)
}

enum HandpanTypography {
    static let scaleTitle = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let padLabel = Font.system(size: 15, weight: .medium, design: .rounded)
    static let status = Font.system(size: 14, weight: .medium, design: .rounded)
    static let settingsSection = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let settingsLabel = Font.system(size: 15, weight: .regular, design: .rounded)
}
