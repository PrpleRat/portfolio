import Foundation

struct Recette: Codable, Identifiable, Hashable {
    let id: String
    let titre: String
    let emoji: String
    let temps: String
    let difficulte: String
    let portions: Int
    let ingredientsCles: [String]
    let carencesCouvertes: [String]
    let ingredientsComplets: [String]
    let etapes: [String]
    let conseilNutrition: String
    let scoreBase: Int

    enum CodingKeys: String, CodingKey {
        case id, titre, emoji, temps, difficulte, portions, etapes
        case ingredientsCles = "ingredients_cles"
        case carencesCouvertes = "carences_couvertes"
        case ingredientsComplets = "ingredients_complets"
        case conseilNutrition = "conseil_nutrition"
        case scoreBase = "score_base"
    }
}

struct RecetteScoree: Identifiable, Hashable {
    let recette: Recette
    let scorePertinence: Int
    let carencesMatchees: [String]
    let ingredientsMatches: [String]

    var id: String { recette.id }
}

struct RecetteBaseFile: Codable {
    let version: String
    let recettes: [Recette]
    let compatibilitesCulinaires: CompatibilitesCulinaires

    enum CodingKeys: String, CodingKey {
        case version, recettes
        case compatibilitesCulinaires = "compatibilites_culinaires"
    }
}

struct CompatibilitesCulinaires: Codable {
    let description: String?
    let pairesValides: [[String]]
    let pairesIncompatibles: [[String]]

    enum CodingKeys: String, CodingKey {
        case description
        case pairesValides = "paires_valides"
        case pairesIncompatibles = "paires_incompatibles"
    }
}
