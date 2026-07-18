import SwiftUI

enum CarenceColors {
    static let background = Color(red: 250 / 255, green: 250 / 255, blue: 248 / 255)
    static let primary = Color(red: 74 / 255, green: 124 / 255, blue: 89 / 255)
    static let alert = Color(red: 224 / 255, green: 90 / 255, blue: 78 / 255)
    static let warning = Color(red: 212 / 255, green: 160 / 255, blue: 23 / 255)
    static let surface = Color.white
    static let textPrimary = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let textSecondary = Color(red: 99 / 255, green: 99 / 255, blue: 102 / 255)
    static let border = Color(red: 230 / 255, green: 230 / 255, blue: 228 / 255)
    static let alertBackground = Color(red: 254 / 255, green: 242 / 255, blue: 242 / 255)
    static let warningBackground = Color(red: 255 / 255, green: 251 / 255, blue: 235 / 255)
}

enum SymptomCategory: String, CaseIterable, Identifiable {
    case bouche
    case peau
    case nezSinus = "nez_sinus"
    case energie
    case sommeil
    case humeur
    case membres
    case cheveuxOngles = "cheveux_ongles"
    case digestion
    case autre
    case modeDeVie = "mode_de_vie"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .bouche: return "👄"
        case .peau: return "🫁"
        case .nezSinus: return "👃"
        case .energie: return "🌡️"
        case .sommeil: return "😴"
        case .humeur: return "😟"
        case .membres: return "🦵"
        case .cheveuxOngles: return "💇"
        case .digestion: return "🫃"
        case .autre: return "✨"
        case .modeDeVie: return "💊"
        }
    }

    var title: String {
        switch self {
        case .bouche: return "Bouche & Lèvres"
        case .peau: return "Peau"
        case .nezSinus: return "Nez & Sinus"
        case .energie: return "Énergie & Fatigue"
        case .sommeil: return "Sommeil"
        case .humeur: return "Humeur"
        case .membres: return "Membres & Muscles"
        case .cheveuxOngles: return "Cheveux & Ongles"
        case .digestion: return "Digestion"
        case .autre: return "Autres signes"
        case .modeDeVie: return "Mode de vie"
        }
    }

    /// Catégories affichées dans le questionnaire (ordre UX du prompt + compléments JSON).
    static var questionnaireOrder: [SymptomCategory] {
        [.bouche, .peau, .nezSinus, .energie, .sommeil, .humeur, .membres, .cheveuxOngles, .digestion, .autre, .modeDeVie]
    }
}

enum ProbabilityLevel: String, Codable, CaseIterable {
    case possible
    case probable
    case tresProbable = "tres_probable"
    case quasiCertaine = "quasi_certaine"

    var label: String {
        switch self {
        case .possible: return "Possible"
        case .probable: return "Probable"
        case .tresProbable: return "Très probable"
        case .quasiCertaine: return "Quasi certaine"
        }
    }

    var color: Color {
        switch self {
        case .possible: return CarenceColors.textSecondary
        case .probable: return CarenceColors.primary.opacity(0.7)
        case .tresProbable: return CarenceColors.primary
        case .quasiCertaine: return CarenceColors.primary
        }
    }

    var barFill: Double {
        switch self {
        case .possible: return 0.35
        case .probable: return 0.55
        case .tresProbable: return 0.75
        case .quasiCertaine: return 0.95
        }
    }

    /// Ordre d'affichage : quasi certaine en premier.
    var sortOrder: Int {
        switch self {
        case .quasiCertaine: return 4
        case .tresProbable: return 3
        case .probable: return 2
        case .possible: return 1
        }
    }
}
