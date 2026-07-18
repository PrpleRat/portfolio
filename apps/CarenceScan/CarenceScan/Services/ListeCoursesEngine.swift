import Foundation

enum ListeCoursesEngine {

    private static let complexeBCarences: Set<String> = [
        "vitamine_b1", "vitamine_b2_b3", "vitamine_b6", "vitamine_b9"
    ]

    static func genererListe(
        depuis resultats: [ScoreResult],
        symptomesDetectes: [String],
        database: CarenceDatabaseFile = CarenceDatabase.shared
    ) -> ListeCourses {
        let carencesActives = resultats
            .filter { $0.niveau != .possible }
            .prefix(10)

        var itemsPharmacie: [ListeItem] = []
        var itemsSupermarche: [ListeItem] = []
        var alimentsVus = Set<String>()

        let bVitaminesActives = carencesActives.filter { complexeBCarences.contains($0.carenceId) }
        let utiliserComplexeB = bVitaminesActives.count >= 2
        if utiliserComplexeB {
            itemsPharmacie.append(ListeItem(
                id: "complexe_b",
                nom: "Complexe B (B1, B2, B3, B6, B9)",
                detail: "1 comprimé le matin avec un repas — couvre B1, B2/B3, B6 et B9",
                prix: "8-12 EUR/mois",
                carencesLiees: bVitaminesActives.map(\.carenceId),
                categorie: .pharmacie,
                urgence: bVitaminesActives.contains(where: { $0.niveau == .quasiCertaine }) ? .urgent : .important
            ))
        }

        for resultat in carencesActives {
            guard let carence = database.carences.first(where: { $0.id == resultat.carenceId }) else { continue }
            let complement = carence.complement
            let nomComplement = complement.nom.lowercased()

            if utiliserComplexeB, complexeBCarences.contains(carence.id) {
                continue
            }

            if nomComplement.contains("complexe b") {
                if !itemsPharmacie.contains(where: { $0.id == "complexe_b" }) {
                    itemsPharmacie.append(ListeItem(
                        id: "complexe_b",
                        nom: "Complexe B (B1, B2, B3, B6, B9)",
                        detail: "1 comprimé le matin avec un repas — couvre B1, B2/B3, B6 et B9",
                        prix: "8-12 EUR/mois",
                        carencesLiees: Array(complexeBCarences),
                        categorie: .pharmacie,
                        urgence: .important
                    ))
                }
                continue
            }

            if carence.id == "fer" {
                if !itemsPharmacie.contains(where: { $0.id == "fer_bilan" }) {
                    itemsPharmacie.append(ListeItem(
                        id: "fer_bilan",
                        nom: "⚠️ Fer — Bilan sanguin OBLIGATOIRE",
                        detail: "Ne pas acheter en pharmacie sans ordonnance. Demander ferritine + NFS à votre médecin",
                        prix: "Remboursé SS sur ordonnance",
                        carencesLiees: ["fer"],
                        categorie: .pharmacie,
                        urgence: .urgent
                    ))
                }
                continue
            }

            if carence.id == "tryptophane" {
                if !itemsPharmacie.contains(where: { $0.id == "tryptophane_item" }) {
                    itemsPharmacie.append(ListeItem(
                        id: "tryptophane_item",
                        nom: "⚠️ 5-HTP — Consultation médicale avant achat",
                        detail: "Contre-indiqué avec les antidépresseurs ISRS (sertraline, fluoxétine...)",
                        prix: "10-20 EUR/mois",
                        carencesLiees: ["tryptophane"],
                        categorie: .pharmacie,
                        urgence: .urgent
                    ))
                }
                continue
            }

            if carence.id == "vitamine_d" {
                if !itemsPharmacie.contains(where: { $0.id == "vitamine_d3_k2" }) {
                    itemsPharmacie.append(ListeItem(
                        id: "vitamine_d3_k2",
                        nom: "Vitamine D3 + K2 en gouttes",
                        detail: "2000 UI/jour avec un repas gras — prendre D3 et K2 ensemble",
                        prix: complement.prixMois,
                        carencesLiees: ["vitamine_d", "vitamine_k"],
                        categorie: .pharmacie,
                        urgence: determinerUrgence(niveau: resultat.niveau)
                    ))
                }
                continue
            }

            if carence.id == "vitamine_k",
               itemsPharmacie.contains(where: { $0.id == "vitamine_d3_k2" }) {
                continue
            }

            if !itemsPharmacie.contains(where: { $0.id == carence.id }) {
                itemsPharmacie.append(ListeItem(
                    id: carence.id,
                    nom: complement.nom,
                    detail: complement.posologie,
                    prix: complement.prixMois,
                    carencesLiees: [carence.id],
                    categorie: .pharmacie,
                    urgence: determinerUrgence(niveau: resultat.niveau)
                ))
            }
        }

        for soin in database.soinsLocaux {
            let pertinents = soin.symptomesCibles.filter { symptomesDetectes.contains($0) }
            guard !pertinents.isEmpty else { continue }
            let soinId = "soin_\(soin.id)"
            guard !itemsPharmacie.contains(where: { $0.id == soinId }) else { continue }
            itemsPharmacie.append(ListeItem(
                id: soinId,
                nom: soin.nom,
                detail: soin.utilisation,
                prix: soin.prix,
                carencesLiees: [],
                categorie: .pharmacie,
                urgence: .complementaire
            ))
        }

        for resultat in carencesActives {
            guard let carence = database.carences.first(where: { $0.id == resultat.carenceId }) else { continue }
            for aliment in carence.alimentsCles.prefix(3) {
                let normalise = normaliserCleAliment(aliment)
                guard !alimentsVus.contains(normalise) else { continue }
                alimentsVus.insert(normalise)
                itemsSupermarche.append(ListeItem(
                    id: "alim_\(normalise)",
                    nom: aliment,
                    detail: nil,
                    prix: nil,
                    carencesLiees: [carence.id],
                    categorie: .supermarche,
                    urgence: determinerUrgence(niveau: resultat.niveau)
                ))
            }
        }

        let extras = ListeCoursesStorage.loadExtraSupermarcheItems()
        for extra in extras where !itemsSupermarche.contains(where: { $0.id == extra.id }) {
            itemsSupermarche.append(extra)
        }

        return ListeCourses(
            pharmacie: itemsPharmacie.sorted { urgenceOrder($0.urgence) < urgenceOrder($1.urgence) },
            supermarche: itemsSupermarche.sorted { urgenceOrder($0.urgence) < urgenceOrder($1.urgence) },
            dateGeneration: Date(),
            carencesBasees: carencesActives.map(\.carenceId)
        )
    }

    static func genererTextePartage(liste: ListeCourses) -> String {
        var texte = "🛒 Ma liste CarenceScan — \(liste.dateGeneration.formatted(date: .abbreviated, time: .omitted))\n\n"
        texte += "💊 PHARMACIE\n═══════════\n"
        for item in liste.pharmacie {
            texte += "☐ \(item.nom)\n"
            if let detail = item.detail { texte += "  → \(detail)\n" }
            if let prix = item.prix { texte += "  💶 \(prix)\n" }
            texte += "\n"
        }
        texte += "\n🛒 SUPERMARCHÉ\n══════════════\n"
        for item in liste.supermarche {
            texte += "☐ \(item.nom)\n"
        }
        texte += "\n---\nGénéré par CarenceScan — guide d'orientation, pas un diagnostic médical."
        return texte
    }

    static func budgetPharmacieEstime(liste: ListeCourses) -> String {
        var totalMin = 0
        for item in liste.pharmacie {
            if let prix = item.prix, let min = extrairePrixMin(prix) {
                totalMin += min
            }
        }
        guard totalMin > 0 else { return "Variable selon les compléments" }
        return "~\(totalMin) EUR/mois (estimation basse)"
    }

    private static func extrairePrixMin(_ prix: String) -> Int? {
        let digits = prix.split(whereSeparator: { !$0.isNumber })
        return digits.compactMap { Int($0) }.first
    }

    private static func determinerUrgence(niveau: ProbabilityLevel) -> UrgenceItem {
        switch niveau {
        case .quasiCertaine: return .urgent
        case .tresProbable: return .important
        default: return .complementaire
        }
    }

    private static func urgenceOrder(_ urgence: UrgenceItem) -> Int {
        switch urgence {
        case .urgent: return 0
        case .important: return 1
        case .complementaire: return 2
        }
    }

    static func normaliserCleAliment(_ aliment: String) -> String {
        AlimentNormalizer.normaliser(aliment)
    }
}

enum AlimentNormalizer {
    static func normaliser(_ aliment: String) -> String {
        let mappings: [String: String] = [
            "kiwis": "kiwis", "poivrons rouges": "poivrons", "oranges": "oranges",
            "fraises": "fraises", "persil frais": "persil", "brocolis": "brocolis",
            "oeufs": "oeufs", "oeufs (jaune)": "oeufs", "viande rouge": "viande_rouge",
            "huîtres": "huitres", "graines de courge": "graines_courge",
            "sardines": "sardines", "saumon": "saumon", "champignons": "champignons",
            "thon en boîte": "thon", "thon": "thon", "lentilles": "lentilles",
            "amandes": "amandes", "chocolat noir 70%+": "chocolat_noir",
            "chocolat noir 70%": "chocolat_noir", "bananes": "bananes",
            "épinards": "epinards", "epinards": "epinards", "légumineuses": "lentilles",
            "noix": "noix", "poulet": "poulet", "pommes de terre": "pommes_de_terre",
            "carottes": "carottes", "foie de volaille": "foie_volaille",
            "maquereau": "maquereau", "yaourt nature": "yaourt", "avocat": "avocat",
            "pois chiches": "pois_chiches", "boudin noir": "viande_rouge",
            "viande de porc": "viande_rouge", "dinde": "poulet", "spiruline": "epinards",
            "kéfir": "yaourt", "choucroute crue": "yaourt"
        ]
        let cle = aliment.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr_FR"))
        for (source, cible) in mappings {
            let sourceNorm = source.folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr_FR"))
            if cle.contains(sourceNorm) || sourceNorm.contains(cle) {
                return cible
            }
        }
        return cle.replacingOccurrences(of: " ", with: "_")
    }
}
