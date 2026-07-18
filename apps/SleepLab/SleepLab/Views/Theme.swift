import SwiftUI

/// Couleurs UI — suivent le thème actif via ThemeReader / ThemePaletteResolver.
enum SleepTheme {
    static var background: Color { ThemePaletteResolver.current.background }
    static var card: Color { ThemePaletteResolver.current.card }
    static var accent: Color { ThemePaletteResolver.current.accent }
    static var textPrimary: Color { ThemePaletteResolver.current.textPrimary }
    static var textSecondary: Color { ThemePaletteResolver.current.textSecondary }

    static let phaseDeep = Color(red: 0.45, green: 0.25, blue: 0.75)
    static let phaseLight = Color(red: 0.25, green: 0.45, blue: 0.85)
    static let phaseREM = Color(red: 0.95, green: 0.75, blue: 0.25)
    static let phaseAwake = Color(red: 0.9, green: 0.35, blue: 0.35)

    static func phaseColor(_ type: SleepPhaseType) -> Color {
        switch type {
        case .deep: return phaseDeep
        case .light: return phaseLight
        case .rem: return phaseREM
        case .awake: return phaseAwake
        }
    }
}

struct MedicalDisclaimer: View {
    var body: some View {
        Text("\(AppBrand.displayName) est un outil de bien-être, pas un dispositif médical. Consulte un professionnel de santé pour tout problème de sommeil.")
            .font(.caption2)
            .foregroundStyle(SleepTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}
