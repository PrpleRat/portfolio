import Foundation

enum BilanSummaryEngine {

    static func generer(
        scores: [ScoreResult],
        regles: [RegleCombination],
        medicaments: Set<String>
    ) -> BilanResume {
        let actifs = scores.filter { $0.niveau != .possible }
        let top = Array(actifs.prefix(3))
        let nomsTop = top.compactMap { CarenceDatabase.carence(for: $0.carenceId)?.nom }

        let phrase: String
        if top.isEmpty {
            phrase = "Aucune carence nette au-dessus des seuils avec vos symptômes actuels."
        } else if top.count == 1 {
            phrase = "Votre bilan pointe surtout vers une carence en \(nomsTop[0])."
        } else {
            phrase = "Votre bilan met en avant \(nomsTop.prefix(2).joined(separator: " et ")), parmi \(actifs.count) carence\(actifs.count > 1 ? "s" : "") à surveiller."
        }

        var points: [String] = []
        if let first = top.first {
            points.append("Priorité : \(CarenceDatabase.carence(for: first.carenceId)?.nom ?? first.carenceId) (\(first.niveau.label))")
        }
        if actifs.contains(where: { $0.carenceId == "fer" }) {
            points.append("Le fer nécessite un bilan sanguin avant toute supplémentation.")
        }
        if !regles.isEmpty {
            points.append("\(regles.count) alerte\(regles.count > 1 ? "s" : "") combinaison détectée\(regles.count > 1 ? "s" : "") — consultez la section détail.")
        }
        if points.count < 3 {
            points.append("Commencez par l'alimentation, puis validez avec votre médecin.")
        }

        let priorite: ActionCategory? = {
            if actifs.contains(where: { $0.carenceId == "fer" }) { return .urgence }
            if actifs.contains(where: { $0.niveau == .quasiCertaine }) { return .pharmacieOrdonnance }
            return top.isEmpty ? nil : .alimentation
        }()

        var etapes: [EtapeMaintenant] = []
        var step = 1

        if actifs.contains(where: { $0.carenceId == "fer" }) || regles.contains(where: { $0.bilanMedicalRequis == true }) {
            etapes.append(EtapeMaintenant(
                id: step,
                titre: "Demander un bilan sanguin",
                detail: "NFS, ferritine, B12 selon les carences détectées — à présenter à votre médecin.",
                categorie: .urgence
            ))
            step += 1
        }

        etapes.append(EtapeMaintenant(
            id: step,
            titre: "Adapter votre alimentation",
            detail: "Intégrez les aliments clés de votre liste supermarché pendant 2 à 4 semaines.",
            categorie: .alimentation
        ))
        step += 1

        if !actifs.isEmpty {
            etapes.append(EtapeMaintenant(
                id: step,
                titre: "Compléments seulement si validés",
                detail: "Pharmacie sur conseil médical — jamais de fer sans ordonnance ni bilan.",
                categorie: .pharmacieOrdonnance
            ))
            step += 1
        }

        etapes.append(EtapeMaintenant(
            id: step,
            titre: "Suivre vos symptômes 14 jours",
            detail: "Check-in quotidien pour voir si les signes s'améliorent avec l'alimentation.",
            categorie: .suivi
        ))

        return BilanResume(
            phrasePrincipale: phrase,
            pointsCles: Array(points.prefix(3)),
            prioriteGlobale: priorite,
            etapesMaintenant: etapes,
            carencesPrioritaires: top
        )
    }
}
