import Foundation

struct AlimentTrackable: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let emoji: String
    let categorie: CategorieAliment
    let carencesCouvertes: [String]
    let portionType: String

    enum CodingKeys: String, CodingKey {
        case id, nom, emoji, categorie
        case carencesCouvertes = "carences_couvertes"
        case portionType = "portion_type"
    }
}

enum CategorieAliment: String, Codable, CaseIterable, Identifiable {
    case poissonsFruitsMer = "poissonsFruitsMer"
    case viandesOeufs = "viandesOeufs"
    case legumesVerts = "legumesVerts"
    case legumineuses = "legumineuses"
    case oleagineuxGraines = "oleagineuxGraines"
    case fruitsVitamineC = "fruitsVitamineC"
    case produitsLaitiers = "produitsLaitiers"
    case autresAliments = "autresAliments"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .poissonsFruitsMer: return "Poissons & fruits de mer"
        case .viandesOeufs: return "Viandes & œufs"
        case .legumesVerts: return "Légumes verts"
        case .legumineuses: return "Légumineuses"
        case .oleagineuxGraines: return "Oléagineux & graines"
        case .fruitsVitamineC: return "Fruits riches en vitamine C"
        case .produitsLaitiers: return "Produits laitiers & fermentés"
        case .autresAliments: return "Autres aliments clés"
        }
    }
}

struct EntreeJournal: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let alimentId: String
    let portions: Double
}

struct JourAnalyse: Identifiable {
    var id: Date { date }
    let date: Date
    let alimentsConsommes: [String]
    let carencesCouvertes: Set<String>
    let carencesNonCouvertes: Set<String>
    let scoreJournee: Int
    let suggestionDuJour: AlimentTrackable?
}

enum TypeInteractionNutriment: String, Codable {
    case synergie
    case antagonisme
}

struct SynergieNutriment: Identifiable, Codable, Hashable {
    let id: String
    let type: TypeInteractionNutriment
    let nutrimentA: String
    let nutrimentB: String
    let force: String
    let message: String
    let source: String
    let conseilPratique: String

    enum CodingKeys: String, CodingKey {
        case id, type, message, source, force
        case nutrimentA = "nutriment_a"
        case nutrimentB = "nutriment_b"
        case conseilPratique = "conseil_pratique"
    }
}

struct HorairePrise: Identifiable, Codable, Hashable {
    var id: String { complementId }
    let complementId: String
    let moment: String
    let avec: String
    let eviter: String
    let priorite: Int

    enum CodingKeys: String, CodingKey {
        case moment, avec, eviter, priorite
        case complementId = "complement_id"
    }
}

struct CreneauHoraire: Identifiable {
    let id: String
    let titre: String
    let emoji: String
    let items: [HorairePrise]
}
