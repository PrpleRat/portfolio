import SwiftUI

enum ActionCategory: String, CaseIterable, Identifiable {
    case urgence
    case pharmacieOrdonnance
    case alimentation
    case suivi

    var id: String { rawValue }

    var label: String {
        switch self {
        case .urgence: return "Urgence / avis médical"
        case .pharmacieOrdonnance: return "Pharmacie (sur ordonnance)"
        case .alimentation: return "Alimentation"
        case .suivi: return "Suivi"
        }
    }

    var icon: String {
        switch self {
        case .urgence: return "exclamationmark.triangle.fill"
        case .pharmacieOrdonnance: return "cross.case.fill"
        case .alimentation: return "leaf.fill"
        case .suivi: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .urgence: return CarenceColors.alert
        case .pharmacieOrdonnance: return CarenceColors.warning
        case .alimentation: return CarenceColors.primary
        case .suivi: return CarenceColors.textSecondary
        }
    }

    var background: Color {
        color.opacity(0.12)
    }
}

struct EtapeMaintenant: Identifiable {
    let id: Int
    let titre: String
    let detail: String
    let categorie: ActionCategory
}

struct BilanResume {
    let phrasePrincipale: String
    let pointsCles: [String]
    let prioriteGlobale: ActionCategory?
    let etapesMaintenant: [EtapeMaintenant]
    let carencesPrioritaires: [ScoreResult]
}
