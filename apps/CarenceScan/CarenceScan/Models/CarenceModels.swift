import Foundation

struct CarenceDatabaseFile: Codable {
    let version: String
    let description: String
    let lastUpdated: String
    let symptomes: [Symptome]
    let medicamentsDepleteurs: [MedicamentDepleteur]
    let carences: [Carence]
    let reglesCombinatoiresSpeciales: [RegleCombination]
    let soinsLocaux: [SoinLocal]
    let bilansSanguinsRecommandes: [BilanSanguin]
    let contextesMedicaux: [ContexteMedical]
    let avertissements: Avertissements

    enum CodingKeys: String, CodingKey {
        case version, description, symptomes, carences, avertissements
        case lastUpdated = "last_updated"
        case medicamentsDepleteurs = "medicaments_depleteurs"
        case reglesCombinatoiresSpeciales = "regles_combinatoires_speciales"
        case soinsLocaux = "soins_locaux"
        case bilansSanguinsRecommandes = "bilans_sanguins_recommandes"
        case contextesMedicaux = "contextes_medicaux"
    }
}

struct ContexteSource: Codable, Hashable, Identifiable {
    var id: String { url }
    let label: String
    let url: String
}

struct ExplicationAggraveDetail: Codable, Hashable {
    let explication: String
    let sources: [ContexteSource]
}

struct ContexteMedical: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let emoji: String
    let description: String
    let symptomesConfondus: [String]
    let coefficientReduction: Double
    let carencesAggravees: [String]
    let bonusAggravation: Int
    let messageConfond: String
    let messageAggrave: String
    let conseil: String
    let explicationConfond: String?
    let sourcesConfond: [ContexteSource]
    let explicationsAggrave: [String: ExplicationAggraveDetail]
    let bilanRecommande: String?
    let bilanObligatoire: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, emoji, description, conseil
        case symptomesConfondus = "symptomes_confondus"
        case coefficientReduction = "coefficient_reduction"
        case carencesAggravees = "carences_aggravees"
        case bonusAggravation = "bonus_aggravation"
        case messageConfond = "message_confond"
        case messageAggrave = "message_aggrave"
        case explicationConfond = "explication_confond"
        case sourcesConfond = "sources_confond"
        case explicationsAggrave = "explications_aggrave"
        case bilanRecommande = "bilan_recommande"
        case bilanObligatoire = "bilan_obligatoire"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        emoji = try c.decode(String.self, forKey: .emoji)
        description = try c.decode(String.self, forKey: .description)
        symptomesConfondus = try c.decode([String].self, forKey: .symptomesConfondus)
        coefficientReduction = try c.decode(Double.self, forKey: .coefficientReduction)
        carencesAggravees = try c.decode([String].self, forKey: .carencesAggravees)
        bonusAggravation = try c.decode(Int.self, forKey: .bonusAggravation)
        messageConfond = try c.decode(String.self, forKey: .messageConfond)
        messageAggrave = try c.decode(String.self, forKey: .messageAggrave)
        conseil = try c.decode(String.self, forKey: .conseil)
        explicationConfond = try c.decodeIfPresent(String.self, forKey: .explicationConfond)
        sourcesConfond = try c.decodeIfPresent([ContexteSource].self, forKey: .sourcesConfond) ?? []
        explicationsAggrave = try c.decodeIfPresent([String: ExplicationAggraveDetail].self, forKey: .explicationsAggrave) ?? [:]
        bilanRecommande = try c.decodeIfPresent(String.self, forKey: .bilanRecommande)
        bilanObligatoire = try c.decodeIfPresent(Bool.self, forKey: .bilanObligatoire)
    }
}

struct Symptome: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let categorie: String
}

struct MedicamentDepleteur: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let carencesInduites: [String]
    let note: String

    enum CodingKeys: String, CodingKey {
        case id, label, note
        case carencesInduites = "carences_induites"
    }
}

struct Carence: Codable, Identifiable {
    let id: String
    let nom: String
    let description: String
    let symptomesPrimaires: [String]
    let symptomesSecondaires: [String]
    let symptomesContextuels: [String]
    let scoreParSymptome: [String: Int]
    let seuilProbable: Int
    let seuilTresProbable: Int
    let seuilQuasiCertain: Int
    let combinaisonsAmplificatrices: [CombinaisonAmplificatrice]
    let alimentsCles: [String]
    let complement: ComplementInfo
    let urgence: String
    let quandSinquieter: String?
    let signesAlerte: [String]?
    let prescriptionObligatoire: Bool?
    let interactionsMedicaments: [String]?

    enum CodingKeys: String, CodingKey {
        case id, nom, description, complement, urgence
        case symptomesPrimaires = "symptomes_primaires"
        case symptomesSecondaires = "symptomes_secondaires"
        case symptomesContextuels = "symptomes_contextuels"
        case scoreParSymptome = "score_par_symptome"
        case seuilProbable = "seuil_probable"
        case seuilTresProbable = "seuil_tres_probable"
        case seuilQuasiCertain = "seuil_quasi_certain"
        case combinaisonsAmplificatrices = "combinaisons_amplificatrices"
        case alimentsCles = "aliments_cles"
        case quandSinquieter = "quand_sinquieter"
        case signesAlerte = "signes_alerte"
        case prescriptionObligatoire = "prescription_obligatoire"
        case interactionsMedicaments = "interactions_medicaments"
    }
}

struct CombinaisonAmplificatrice: Codable {
    let symptomes: [String]
    let bonus: Int
}

struct ComplementInfo: Codable {
    let nom: String
    let posologie: String
    let formeRecommandee: String
    let prixMois: String
    let ouAcheter: String
    let precautions: String

    enum CodingKeys: String, CodingKey {
        case nom, posologie, precautions
        case formeRecommandee = "forme_recommandee"
        case prixMois = "prix_mois"
        case ouAcheter = "ou_acheter"
    }
}

struct RegleCombination: Codable, Identifiable {
    let id: String
    let label: String
    let description: String
    let symptomesRequis: [String]
    let carencesAmplifiees: [String]
    let bonusScore: Int
    let messageAlerte: String
    let bilanMedicalRequis: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, description
        case symptomesRequis = "symptomes_requis"
        case carencesAmplifiees = "carences_amplifiees"
        case bonusScore = "bonus_score"
        case messageAlerte = "message_alerte"
        case bilanMedicalRequis = "bilan_medical_requis"
    }
}

struct SoinLocal: Codable, Identifiable {
    let id: String
    let nom: String
    let utilisation: String
    let prix: String
    let symptomesCibles: [String]

    enum CodingKeys: String, CodingKey {
        case id, nom, utilisation, prix
        case symptomesCibles = "symptomes_cibles"
    }
}

struct BilanSanguin: Codable, Identifiable {
    let id: String
    let label: String
    let analyses: [String]
    let indication: String
    let remboursement: String
}

struct Avertissements: Codable {
    let general: String
    let medicaments: String
    let interactionsCritiques: [String]

    enum CodingKeys: String, CodingKey {
        case general, medicaments
        case interactionsCritiques = "interactions_critiques"
    }
}

struct ScoreResult: Identifiable, Codable, Hashable {
    var id: String { carenceId }
    let carenceId: String
    let score: Int
    let niveau: ProbabilityLevel
    let symptomesDetectes: [String]
    let alertes: [String]
    let bonusCombinations: Int
    let notesContexte: [NoteContexte]
    let alertesProfil: [String]

    init(
        carenceId: String,
        score: Int,
        niveau: ProbabilityLevel,
        symptomesDetectes: [String],
        alertes: [String],
        bonusCombinations: Int,
        notesContexte: [NoteContexte] = [],
        alertesProfil: [String] = []
    ) {
        self.carenceId = carenceId
        self.score = score
        self.niveau = niveau
        self.symptomesDetectes = symptomesDetectes
        self.alertes = alertes
        self.bonusCombinations = bonusCombinations
        self.notesContexte = notesContexte
        self.alertesProfil = alertesProfil
    }

    enum CodingKeys: String, CodingKey {
        case carenceId, score, niveau, symptomesDetectes, alertes, bonusCombinations, notesContexte, alertesProfil
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        carenceId = try c.decode(String.self, forKey: .carenceId)
        score = try c.decode(Int.self, forKey: .score)
        niveau = try c.decode(ProbabilityLevel.self, forKey: .niveau)
        symptomesDetectes = try c.decode([String].self, forKey: .symptomesDetectes)
        alertes = try c.decode([String].self, forKey: .alertes)
        bonusCombinations = try c.decode(Int.self, forKey: .bonusCombinations)
        notesContexte = try c.decodeIfPresent([NoteContexte].self, forKey: .notesContexte) ?? []
        alertesProfil = try c.decodeIfPresent([String].self, forKey: .alertesProfil) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(carenceId, forKey: .carenceId)
        try c.encode(score, forKey: .score)
        try c.encode(niveau, forKey: .niveau)
        try c.encode(symptomesDetectes, forKey: .symptomesDetectes)
        try c.encode(alertes, forKey: .alertes)
        try c.encode(bonusCombinations, forKey: .bonusCombinations)
        try c.encode(notesContexte, forKey: .notesContexte)
        try c.encode(alertesProfil, forKey: .alertesProfil)
    }
}

struct SavedResultsPayload: Codable {
    let date: Date
    let symptomesSelectionnes: [String]
    let symptomeSelections: [SymptomeSelection]
    let medicamentsSelectionnes: [String]
    let contextesSelectionnes: [String]
    let profil: ProfilUtilisateur?
    let scores: [ScoreResult]
    let reglesDetectees: [String]
    let conseilsContexte: [String]

    init(
        date: Date,
        symptomeSelections: [SymptomeSelection],
        medicamentsSelectionnes: [String],
        contextesSelectionnes: [String],
        profil: ProfilUtilisateur?,
        scores: [ScoreResult],
        reglesDetectees: [String],
        conseilsContexte: [String]
    ) {
        self.date = date
        self.symptomeSelections = symptomeSelections
        self.symptomesSelectionnes = symptomeSelections.map(\.symptomeId)
        self.medicamentsSelectionnes = medicamentsSelectionnes
        self.contextesSelectionnes = contextesSelectionnes
        self.profil = profil
        self.scores = scores
        self.reglesDetectees = reglesDetectees
        self.conseilsContexte = conseilsContexte
    }

    enum CodingKeys: String, CodingKey {
        case date, scores, profil, reglesDetectees, conseilsContexte
        case symptomesSelectionnes, symptomeSelections, medicamentsSelectionnes, contextesSelectionnes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(Date.self, forKey: .date)
        medicamentsSelectionnes = try c.decode([String].self, forKey: .medicamentsSelectionnes)
        scores = try c.decode([ScoreResult].self, forKey: .scores)
        reglesDetectees = try c.decode([String].self, forKey: .reglesDetectees)
        profil = try c.decodeIfPresent(ProfilUtilisateur.self, forKey: .profil)
        contextesSelectionnes = try c.decodeIfPresent([String].self, forKey: .contextesSelectionnes) ?? []
        conseilsContexte = try c.decodeIfPresent([String].self, forKey: .conseilsContexte) ?? []
        if let selections = try c.decodeIfPresent([SymptomeSelection].self, forKey: .symptomeSelections) {
            symptomeSelections = selections
            symptomesSelectionnes = selections.map(\.symptomeId)
        } else {
            let legacy = try c.decode([String].self, forKey: .symptomesSelectionnes)
            symptomesSelectionnes = legacy
            symptomeSelections = legacy.map { SymptomeSelection(symptomeId: $0) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(date, forKey: .date)
        try c.encode(symptomesSelectionnes, forKey: .symptomesSelectionnes)
        try c.encode(symptomeSelections, forKey: .symptomeSelections)
        try c.encode(medicamentsSelectionnes, forKey: .medicamentsSelectionnes)
        try c.encode(contextesSelectionnes, forKey: .contextesSelectionnes)
        try c.encode(profil, forKey: .profil)
        try c.encode(scores, forKey: .scores)
        try c.encode(reglesDetectees, forKey: .reglesDetectees)
        try c.encode(conseilsContexte, forKey: .conseilsContexte)
    }
}
