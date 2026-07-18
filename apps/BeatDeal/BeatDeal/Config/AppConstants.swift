import Foundation

enum AppConstants {
    static let appName = "BeatDeal"
    static let appTagline = "Splits · Licences · Studio"
    static let bundleIdentifier = "com.cashthetrain.beatdeal"
    static let privacyPolicyURL = "https://beatdeal.app/privacy"
    static let appStorePriceEUR = 4.99

    static let storageKeyContracts = "beatdeal.contracts"
    static let storageKeyProfile = "beatdeal.profile"
    static let storageKeyTemplates = "beatdeal.templates"
    static let storageKeyCatalog = "beatdeal.catalog"
    static let storageKeyPacks = "beatdeal.packs"
    static let storageKeySplits = "beatdeal.splits"

    static let streamAlertThreshold = 0.8
    static let licenseExpiryWarningDays = 14
    static let defaultLeaseDurationMonths = 12

    static let notificationCategoryUpgrade = "LICENSE_UPGRADE"
}

enum Currency: String, Codable, CaseIterable, Identifiable {
    case eur = "€"
    case usd = "$"
    case gbp = "£"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .eur: return "EUR"
        case .usd: return "USD"
        case .gbp: return "GBP"
        }
    }

    var label: String {
        switch self {
        case .eur: return "Euro (€)"
        case .usd: return "Dollar ($)"
        case .gbp: return "Livre (£)"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case paypal = "PayPal"
    case virement = "Virement"
    case lydia = "Lydia"
    case especes = "Espèces"
    case autre = "Autre"

    var id: String { rawValue }
}

enum MusicalKey: String, CaseIterable, Identifiable {
    case c, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b

    var id: String { rawValue }

    var label: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }
}

enum KeyMode: String, CaseIterable, Identifiable {
    case major = "Maj"
    case minor = "Min"

    var id: String { rawValue }
}
