import Foundation

enum ResultsStorage {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static var hasSavedResults: Bool {
        load() != nil
    }

    static func save(_ payload: SavedResultsPayload) {
        guard let data = try? encoder.encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.resultsStorageKey)
    }

    static func load() -> SavedResultsPayload? {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.resultsStorageKey) else { return nil }
        return try? decoder.decode(SavedResultsPayload.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: AppConstants.resultsStorageKey)
    }

    static func saveDraft(
        profil: ProfilUtilisateur?,
        symptomeSelections: [SymptomeSelection],
        medicaments: Set<String>,
        contextes: Set<String>,
        aucunMedicament: Bool,
        aucunContexte: Bool
    ) {
        let draft = QuestionnaireDraft(
            profil: profil,
            symptomeSelections: symptomeSelections,
            symptomes: symptomeSelections.map(\.symptomeId),
            medicaments: Array(medicaments),
            contextes: Array(contextes),
            aucunMedicament: aucunMedicament,
            aucunContexte: aucunContexte
        )
        guard let data = try? encoder.encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.questionnaireStorageKey)
    }

    static func loadDraft() -> QuestionnaireDraft? {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.questionnaireStorageKey) else { return nil }
        return try? decoder.decode(QuestionnaireDraft.self, from: data)
    }

    static func clearDraft() {
        UserDefaults.standard.removeObject(forKey: AppConstants.questionnaireStorageKey)
    }
}

struct QuestionnaireDraft: Codable {
    var profil: ProfilUtilisateur?
    var symptomeSelections: [SymptomeSelection]?
    var symptomes: [String]
    var medicaments: [String]
    var contextes: [String]
    var aucunMedicament: Bool
    var aucunContexte: Bool

    init(
        profil: ProfilUtilisateur?,
        symptomeSelections: [SymptomeSelection],
        symptomes: [String],
        medicaments: [String],
        contextes: [String],
        aucunMedicament: Bool,
        aucunContexte: Bool
    ) {
        self.profil = profil
        self.symptomeSelections = symptomeSelections
        self.symptomes = symptomes
        self.medicaments = medicaments
        self.contextes = contextes
        self.aucunMedicament = aucunMedicament
        self.aucunContexte = aucunContexte
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profil = try c.decodeIfPresent(ProfilUtilisateur.self, forKey: .profil)
        symptomeSelections = try c.decodeIfPresent([SymptomeSelection].self, forKey: .symptomeSelections)
        symptomes = try c.decodeIfPresent([String].self, forKey: .symptomes) ?? []
        medicaments = try c.decodeIfPresent([String].self, forKey: .medicaments) ?? []
        contextes = try c.decodeIfPresent([String].self, forKey: .contextes) ?? []
        aucunMedicament = try c.decodeIfPresent(Bool.self, forKey: .aucunMedicament) ?? false
        aucunContexte = try c.decodeIfPresent(Bool.self, forKey: .aucunContexte) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case profil, symptomeSelections, symptomes, medicaments, contextes, aucunMedicament, aucunContexte
    }
}
