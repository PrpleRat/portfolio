import Foundation

enum CheckInMethod: String, Codable, CaseIterable, Identifiable {

    case faceID = "face_id"
    case touchID = "touch_id"
    case biometric = "biometric"
    case pin = "pin"
    case password = "password"
    case customQuestion = "custom_question"
    case tapButton = "tap"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .biometric: return "Biométrie (Face ID / Touch ID)"
        case .pin: return "Code PIN à 6 chiffres"
        case .password: return "Mot de passe"
        case .customQuestion: return "Question personnalisée"
        case .tapButton: return "Simple appui (mode test)"
        }
    }

    var sfSymbol: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .biometric: return "person.badge.shield.checkmark"
        case .pin: return "number.circle.fill"
        case .password: return "lock.fill"
        case .customQuestion: return "questionmark.circle.fill"
        case .tapButton: return "hand.tap.fill"
        }
    }

    var securityLevel: SecurityLevel {
        switch self {
        case .faceID, .touchID, .biometric: return .high
        case .pin, .password: return .medium
        case .customQuestion: return .low
        case .tapButton: return .none
        }
    }

    enum SecurityLevel: String {
        case high = "Très sécurisé"
        case medium = "Sécurisé"
        case low = "Basique"
        case none = "Test uniquement"

        var colorName: String {
            switch self {
            case .high: return "green"
            case .medium: return "blue"
            case .low: return "orange"
            case .none: return "gray"
            }
        }
    }
}
