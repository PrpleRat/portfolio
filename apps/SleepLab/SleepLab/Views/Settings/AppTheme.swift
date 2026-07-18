import SwiftUI

/// Thème applicatif (stocké via `ThemeManager` / AppStorage `appTheme`).
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case dark
    case night
    case aurora
    case ember
    case lavender
    case forest
    case ink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Système"
        case .dark: return "Sombre"
        case .night: return "Nuit"
        case .aurora: return "Aurore"
        case .ember: return "Braise"
        case .lavender: return "Lavande"
        case .forest: return "Forêt"
        case .ink: return "Encre"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Suit iOS clair / sombre"
        case .dark: return "Bleu nuit classique"
        case .night: return "Ambre AMOLED, chambre sombre"
        case .aurora: return "Cyan & violet — rêve lucide"
        case .ember: return "Corail & charbon — réveil doux"
        case .lavender: return "Brume violette — calme"
        case .forest: return "Mousse & sapin — nature"
        case .ink: return "Monochrome rouge — focus"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        default: return .dark
        }
    }

    func palette(for systemColorScheme: ColorScheme) -> ThemePalette {
        switch self {
        case .system:
            return systemColorScheme == .dark ? .standardDark : .standardLight
        case .dark: return .standardDark
        case .night: return .nightAMOLED
        case .aurora: return .aurora
        case .ember: return .ember
        case .lavender: return .lavender
        case .forest: return .forest
        case .ink: return .ink
        }
    }
}

struct ThemePalette: Equatable {
    var background: Color
    var card: Color
    var accent: Color
    var textPrimary: Color
    var textSecondary: Color

    static let standardLight = ThemePalette(
        background: Color(red: 0.96, green: 0.97, blue: 0.99),
        card: Color.white,
        accent: Color(red: 0.35, green: 0.45, blue: 0.88),
        textPrimary: Color(red: 0.08, green: 0.09, blue: 0.12),
        textSecondary: Color(red: 0.4, green: 0.42, blue: 0.48)
    )

    static let standardDark = ThemePalette(
        background: Color(red: 0.06, green: 0.07, blue: 0.12),
        card: Color(red: 0.11, green: 0.12, blue: 0.18),
        accent: Color(red: 0.45, green: 0.55, blue: 0.95),
        textPrimary: .white,
        textSecondary: Color(white: 0.65)
    )

    static let nightAMOLED = ThemePalette(
        background: Color(red: 0x0D / 255.0, green: 0x0D / 255.0, blue: 0x0D / 255.0),
        card: Color(red: 0.14, green: 0.10, blue: 0.09),
        accent: Color(red: 0xA0 / 255.0, green: 0x52 / 255.0, blue: 0x2D / 255.0),
        textPrimary: Color(red: 1.0, green: 0.96, blue: 0.90),
        textSecondary: Color(red: 0.75, green: 0.68, blue: 0.62)
    )

    static let aurora = ThemePalette(
        background: Color(red: 0.04, green: 0.06, blue: 0.14),
        card: Color(red: 0.08, green: 0.12, blue: 0.22),
        accent: Color(red: 0.35, green: 0.92, blue: 0.85),
        textPrimary: Color(red: 0.92, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.55, green: 0.65, blue: 0.82)
    )

    static let ember = ThemePalette(
        background: Color(red: 0.09, green: 0.05, blue: 0.05),
        card: Color(red: 0.16, green: 0.08, blue: 0.08),
        accent: Color(red: 1.0, green: 0.45, blue: 0.32),
        textPrimary: Color(red: 1.0, green: 0.94, blue: 0.88),
        textSecondary: Color(red: 0.78, green: 0.55, blue: 0.48)
    )

    static let lavender = ThemePalette(
        background: Color(red: 0.07, green: 0.05, blue: 0.12),
        card: Color(red: 0.12, green: 0.09, blue: 0.18),
        accent: Color(red: 0.72, green: 0.55, blue: 0.98),
        textPrimary: Color(red: 0.96, green: 0.93, blue: 1.0),
        textSecondary: Color(red: 0.68, green: 0.62, blue: 0.78)
    )

    static let forest = ThemePalette(
        background: Color(red: 0.04, green: 0.08, blue: 0.06),
        card: Color(red: 0.09, green: 0.14, blue: 0.11),
        accent: Color(red: 0.42, green: 0.82, blue: 0.52),
        textPrimary: Color(red: 0.9, green: 0.97, blue: 0.92),
        textSecondary: Color(red: 0.55, green: 0.7, blue: 0.6)
    )

    static let ink = ThemePalette(
        background: Color(red: 0.02, green: 0.02, blue: 0.02),
        card: Color(red: 0.08, green: 0.08, blue: 0.08),
        accent: Color(red: 0.95, green: 0.22, blue: 0.28),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 0.95),
        textSecondary: Color(red: 0.55, green: 0.55, blue: 0.55)
    )
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette.standardDark
}

extension EnvironmentValues {
    var themePalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

/// Source de vérité — force le re-render de toute l’app quand le thème change.
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var palette: ThemePalette = .standardDark
    @Published private(set) var revision: Int = 0
    @Published private(set) var appTheme: AppTheme = .system

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppTheme.system.rawValue
        appTheme = AppTheme(rawValue: raw) ?? .system
        applyResolved(theme: appTheme, systemScheme: .dark)
    }

    static let storageKey = "appTheme"

    func setTheme(_ theme: AppTheme, systemColorScheme: ColorScheme) {
        appTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
        applyResolved(theme: theme, systemScheme: systemColorScheme)
    }

    func refresh(systemColorScheme: ColorScheme) {
        applyResolved(theme: appTheme, systemScheme: systemColorScheme)
    }

    private func applyResolved(theme: AppTheme, systemScheme: ColorScheme) {
        let resolved = theme.palette(for: systemScheme)
        palette = resolved
        ThemePaletteResolver.apply(resolved)
        revision &+= 1
    }
}

struct ThemeReader<Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.themePalette, themeManager.palette)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.appTheme.preferredColorScheme)
            .tint(themeManager.palette.accent)
            .onAppear {
                themeManager.refresh(systemColorScheme: systemColorScheme)
            }
            .onChange(of: systemColorScheme) { _, scheme in
                themeManager.refresh(systemColorScheme: scheme)
            }
    }
}

enum ThemePaletteResolver {
    private(set) static var current: ThemePalette = .standardDark

    static func apply(_ palette: ThemePalette) {
        current = palette
    }
}
