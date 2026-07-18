import Foundation

enum RecettesEngine {

    static let limiteCatalogue = 73

    private static let base: RecetteBaseFile? = {
        guard let url = Bundle.main.url(forResource: "recettes_v2", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(RecetteBaseFile.self, from: data)
    }()

    static var nombreRecettesDansBase: Int {
        base?.recettes.count ?? 0
    }

    static func suggererRecettes(
        depuis resultats: [ScoreResult],
        carencesBase: [Carence] = CarenceDatabase.shared.carences,
        limite: Int = limiteCatalogue
    ) -> [RecetteScoree] {
        guard let base else { return [] }

        let carencesActives = resultats.filter { $0.niveau != .possible }
        let carencesActivesIds = Set(carencesActives.map(\.carenceId))

        var alimentsUtilisateur = Set<String>()
        var alimentsParCarence: [String: [String]] = [:]

        for resultat in carencesActives {
            guard let carence = carencesBase.first(where: { $0.id == resultat.carenceId }) else { continue }
            let normalises = carence.alimentsCles.map { AlimentNormalizer.normaliser($0) }
            alimentsParCarence[carence.id] = normalises
            alimentsUtilisateur.formUnion(normalises)
        }

        var scorees = base.recettes.compactMap { recette -> RecetteScoree? in
            guard !contientPairesIncompatibles(recette, compat: base.compatibilitesCulinaires) else {
                return nil
            }
            let score = calculerScore(
                recette: recette,
                alimentsUtilisateur: alimentsUtilisateur,
                alimentsParCarence: alimentsParCarence,
                carencesActives: carencesActivesIds
            )
            let ingredientsMatches = recette.ingredientsCles.filter { alimentsUtilisateur.contains($0) }
            let carencesMatchees = recette.carencesCouvertes.filter { carencesActivesIds.contains($0) }
            guard score >= 2, !ingredientsMatches.isEmpty || !carencesMatchees.isEmpty else { return nil }
            return RecetteScoree(
                recette: recette,
                scorePertinence: score,
                carencesMatchees: carencesMatchees,
                ingredientsMatches: ingredientsMatches
            )
        }

        scorees.sort { $0.scorePertinence > $1.scorePertinence }
        let classees = limite <= 12 ? diversifier(recettes: scorees) : scorees
        return Array(classees.prefix(limite))
    }

    static func listerToutesLesRecettes(
        depuis resultats: [ScoreResult] = [],
        carencesBase: [Carence] = CarenceDatabase.shared.carences
    ) -> [RecetteScoree] {
        guard let base else { return [] }

        let carencesActives = resultats.filter { $0.niveau != .possible }
        let carencesActivesIds = Set(carencesActives.map(\.carenceId))

        var alimentsUtilisateur = Set<String>()
        var alimentsParCarence: [String: [String]] = [:]
        for resultat in carencesActives {
            guard let carence = carencesBase.first(where: { $0.id == resultat.carenceId }) else { continue }
            let normalises = carence.alimentsCles.map { AlimentNormalizer.normaliser($0) }
            alimentsParCarence[carence.id] = normalises
            alimentsUtilisateur.formUnion(normalises)
        }

        let scorees = base.recettes.compactMap { recette -> RecetteScoree? in
            guard !contientPairesIncompatibles(recette, compat: base.compatibilitesCulinaires) else {
                return nil
            }
            let ingredientsMatches = recette.ingredientsCles.filter { alimentsUtilisateur.contains($0) }
            let carencesMatchees = recette.carencesCouvertes.filter { carencesActivesIds.contains($0) }
            let score = carencesActivesIds.isEmpty
                ? recette.scoreBase
                : calculerScore(
                    recette: recette,
                    alimentsUtilisateur: alimentsUtilisateur,
                    alimentsParCarence: alimentsParCarence,
                    carencesActives: carencesActivesIds
                )
            return RecetteScoree(
                recette: recette,
                scorePertinence: score,
                carencesMatchees: carencesMatchees,
                ingredientsMatches: ingredientsMatches
            )
        }

        return scorees.sorted {
            if $0.scorePertinence != $1.scorePertinence { return $0.scorePertinence > $1.scorePertinence }
            return $0.recette.titre.localizedCaseInsensitiveCompare($1.recette.titre) == .orderedAscending
        }
    }

    static func carenceNom(for id: String) -> String {
        CarenceDatabase.carence(for: id)?.nom ?? id
    }

    private static func calculerScore(
        recette: Recette,
        alimentsUtilisateur: Set<String>,
        alimentsParCarence: [String: [String]],
        carencesActives: Set<String>
    ) -> Int {
        var score = 0
        let matchsIngredients = recette.ingredientsCles.filter { alimentsUtilisateur.contains($0) }
        score += matchsIngredients.count * 3

        let carencesMatchees = recette.carencesCouvertes.filter { carencesActives.contains($0) }
        score += carencesMatchees.count * 2

        var carencesDifferentes = Set<String>()
        for ingredient in recette.ingredientsCles {
            for (carenceId, aliments) in alimentsParCarence where aliments.contains(ingredient) {
                carencesDifferentes.insert(carenceId)
            }
        }
        if carencesDifferentes.count >= 2 { score += 4 }
        if carencesDifferentes.count >= 3 { score += 2 }

        score += recette.scoreBase / 2
        return score
    }

    private static func diversifier(recettes: [RecetteScoree]) -> [RecetteScoree] {
        var resultat: [RecetteScoree] = []
        var compteurs: [String: Int] = [:]
        for item in recettes {
            let dominant = item.recette.ingredientsCles.first ?? ""
            let compteur = compteurs[dominant] ?? 0
            if compteur < 2 {
                resultat.append(item)
                compteurs[dominant] = compteur + 1
            }
        }
        return resultat
    }

    private static func contientPairesIncompatibles(
        _ recette: Recette,
        compat: CompatibilitesCulinaires
    ) -> Bool {
        let keys = Set(recette.ingredientsCles)
        for paire in compat.pairesIncompatibles where paire.count >= 2 {
            if keys.contains(paire[0]), keys.contains(paire[1]) {
                return true
            }
        }
        return false
    }
}
