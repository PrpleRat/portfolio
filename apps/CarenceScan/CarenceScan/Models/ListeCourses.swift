import Foundation

struct ListeItem: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let detail: String?
    let prix: String?
    let carencesLiees: [String]
    let categorie: ListeCategorie
    let urgence: UrgenceItem

    enum CodingKeys: String, CodingKey {
        case id, nom, detail, prix, categorie, urgence
        case carencesLiees = "carences_liees"
    }
}

enum ListeCategorie: String, Codable {
    case pharmacie
    case supermarche
}

enum UrgenceItem: String, Codable, CaseIterable {
    case urgent
    case important
    case complementaire

    var label: String {
        switch self {
        case .urgent: return "Priorité haute — cette semaine"
        case .important: return "Semaine 1–2"
        case .complementaire: return "À compléter"
        }
    }
}

struct ListeCourses {
    let pharmacie: [ListeItem]
    let supermarche: [ListeItem]
    let dateGeneration: Date
    let carencesBasees: [String]
}
