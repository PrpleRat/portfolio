import Foundation

enum ListeCoursesStorage {

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func loadCheckedIds() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.listeCoursesCheckedKey),
              let ids = try? decoder.decode([String].self, from: data)
        else { return [] }
        return Set(ids)
    }

    static func saveCheckedIds(_ ids: Set<String>) {
        guard let data = try? encoder.encode(Array(ids)) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.listeCoursesCheckedKey)
    }

    static func clearCheckedIds() {
        UserDefaults.standard.removeObject(forKey: AppConstants.listeCoursesCheckedKey)
    }

    static func loadExtraSupermarcheItems() -> [ListeItem] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.listeCoursesExtraKey),
              let items = try? decoder.decode([ListeItem].self, from: data)
        else { return [] }
        return items
    }

    static func saveExtraSupermarcheItems(_ items: [ListeItem]) {
        guard let data = try? encoder.encode(items) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.listeCoursesExtraKey)
    }

    static func ajouterIngredientsRecette(_ noms: [String], carencesLiees: [String]) {
        var extras = loadExtraSupermarcheItems()
        var ids = Set(extras.map(\.id))
        for nom in noms {
            let cle = AlimentNormalizer.normaliser(nom)
            let itemId = "alim_\(cle)"
            guard !ids.contains(itemId) else { continue }
            extras.append(ListeItem(
                id: itemId,
                nom: nom,
                detail: "Ajouté depuis une recette",
                prix: nil,
                carencesLiees: carencesLiees,
                categorie: .supermarche,
                urgence: .complementaire
            ))
            ids.insert(itemId)
        }
        saveExtraSupermarcheItems(extras)
    }
}
