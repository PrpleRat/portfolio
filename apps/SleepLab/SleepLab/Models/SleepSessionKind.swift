import Foundation

enum SleepSessionKind: String, Codable, CaseIterable {
    case night
    case nap

    var displayName: String {
        switch self {
        case .night: return "Nuit"
        case .nap: return "Sieste"
        }
    }

    var startActionTitle: String {
        switch self {
        case .night: return "Commencer la nuit"
        case .nap: return "Commencer la sieste"
        }
    }

    var trackingTitle: String {
        switch self {
        case .night: return "Tracking nocturne"
        case .nap: return "Sieste en cours"
        }
    }

    var systemImage: String {
        switch self {
        case .night: return "bed.double.fill"
        case .nap: return "sun.horizon.fill"
        }
    }

    /// Objectif de durée pour le score (heures).
    var defaultTargetHours: Double {
        switch self {
        case .night: return 8
        case .nap: return 0.5
        }
    }
}
