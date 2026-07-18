import Foundation

enum NutritionDataLoader {

    private static let decoder = JSONDecoder()

    static let alimentsTrackables: [AlimentTrackable] = load("aliments_trackables") ?? []
    static let synergies: [SynergieNutriment] = load("synergies_nutriments") ?? []
    static let horairesPrise: [HorairePrise] = load("horaires_prise") ?? []

    private static func load<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    static func carencesActivesIds(from scores: [ScoreResult]) -> [String] {
        scores.filter { $0.niveau != .possible }.map(\.carenceId)
    }

    static func synergiesDetectees(carencesActives: Set<String>) -> [SynergieNutriment] {
        synergies.filter { s in
            guard carencesActives.contains(s.nutrimentA) else { return false }
            if s.nutrimentB == "tous" { return true }
            return carencesActives.contains(s.nutrimentB)
        }
    }

    static func labelComplement(_ id: String) -> String {
        switch id {
        case "vitamine_d3_k2": return "Vitamine D3 + K2"
        case "magnesium": return "Magnésium"
        case "zinc": return "Zinc"
        case "vitamine_c": return "Vitamine C"
        case "omega3": return "Oméga-3"
        case "complexe_b": return "Complexe B"
        case "vitamine_b12": return "Vitamine B12"
        case "fer": return "Fer"
        case "probiotiques": return "Probiotiques"
        default: return id.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    static func horairesPourCarences(_ carenceIds: Set<String>) -> [HorairePrise] {
        let mapping: [String: String] = [
            "vitamine_d": "vitamine_d3_k2",
            "magnesium": "magnesium",
            "zinc": "zinc",
            "vitamine_c": "vitamine_c",
            "omega3": "omega3",
            "vitamine_b1": "complexe_b",
            "vitamine_b2_b3": "complexe_b",
            "vitamine_b6": "complexe_b",
            "vitamine_b9": "complexe_b",
            "vitamine_b12": "vitamine_b12",
            "fer": "fer",
            "probiotiques": "probiotiques"
        ]
        var seen = Set<String>()
        var result: [HorairePrise] = []
        for carenceId in carenceIds {
            guard let complementKey = mapping[carenceId],
                  let horaire = horairesPrise.first(where: { $0.complementId == complementKey }),
                  !seen.contains(horaire.complementId)
            else { continue }
            seen.insert(horaire.complementId)
            result.append(horaire)
        }
        return result.sorted { $0.priorite < $1.priorite }
    }

    static func creneauxJournaliers(pour horaires: [HorairePrise]) -> [CreneauHoraire] {
        let slots: [(String, String, String, Set<String>)] = [
            ("matin", "Matin — avec le petit-déjeuner", "🌅", ["zinc", "vitamine_c", "complexe_b", "vitamine_b12", "probiotiques", "omega3"]),
            ("midi", "Midi — avec le déjeuner", "☀️", ["vitamine_d3_k2"]),
            ("aprem", "Après-midi", "🌤️", ["fer"]),
            ("soir", "Soir — avant le coucher", "🌙", ["magnesium"]),
        ]
        return slots.compactMap { id, titre, emoji, ids in
            let items = horaires.filter { ids.contains($0.complementId) }
            guard !items.isEmpty else { return nil }
            return CreneauHoraire(id: id, titre: titre, emoji: emoji, items: items)
        }
    }

    static func avertissementsAntagonismes(carencesActives: Set<String>) -> [String] {
        var msgs: [String] = []
        if carencesActives.contains("fer") && carencesActives.contains("zinc") {
            msgs.append("Ne jamais prendre Fer et Zinc au même repas — minimum 2h d'écart.")
        }
        if carencesActives.contains("fer") && carencesActives.contains("calcium") {
            msgs.append("Ne jamais prendre Calcium et Fer au même repas — le calcium réduit l'absorption du fer.")
        }
        if carencesActives.contains("fer") {
            msgs.append("Si fer prescrit : évitez café et thé dans l'heure qui suit la prise.")
        }
        return msgs
    }
}
