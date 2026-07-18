import Foundation

enum SexeBiologique: String, Codable, CaseIterable {
    case homme
    case femme

    var label: String {
        switch self {
        case .homme: return "Homme"
        case .femme: return "Femme"
        }
    }
}

enum TrancheAge: String, Codable, CaseIterable, Identifiable {
    case moins18 = "moins_18"
    case dix8_25 = "18_25"
    case vingt6_35 = "26_35"
    case trente6_45 = "36_45"
    case quarante6_55 = "46_55"
    case cinquante6_65 = "56_65"
    case plus65 = "plus_65"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moins18: return "< 18 ans"
        case .dix8_25: return "18–25 ans"
        case .vingt6_35: return "26–35 ans"
        case .trente6_45: return "36–45 ans"
        case .quarante6_55: return "46–55 ans"
        case .cinquante6_65: return "56–65 ans"
        case .plus65: return "65+ ans"
        }
    }
}

enum SituationHormonale: String, Codable, CaseIterable, Identifiable {
    case reglesRegulieres = "regles_regulieres"
    case reglesAbondantes = "regles_abondantes"
    case contraceptif
    case enceinte
    case allaitante
    case menopause
    case amenorrhee
    case nonApplicable = "non_applicable"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reglesRegulieres: return "Règles régulières"
        case .reglesAbondantes: return "Règles abondantes"
        case .contraceptif: return "Sous contraceptif hormonal"
        case .enceinte: return "Enceinte"
        case .allaitante: return "Allaitante"
        case .menopause: return "Périménopause / Ménopause"
        case .amenorrhee: return "Aménorrhée"
        case .nonApplicable: return "Non applicable"
        }
    }

    static var optionsFemme: [SituationHormonale] {
        [.reglesRegulieres, .reglesAbondantes, .contraceptif, .enceinte, .allaitante, .menopause, .amenorrhee]
    }
}

struct ProfilUtilisateur: Codable, Equatable {
    var sexe: SexeBiologique
    var age: TrancheAge
    var situationHormonale: SituationHormonale

    static var `default`: ProfilUtilisateur {
        ProfilUtilisateur(sexe: .femme, age: .vingt6_35, situationHormonale: .reglesRegulieres)
    }

    var situationNormalisee: SituationHormonale {
        sexe == .homme ? .nonApplicable : situationHormonale
    }
}
