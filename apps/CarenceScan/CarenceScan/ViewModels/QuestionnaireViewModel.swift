import Foundation
import SwiftUI

@MainActor
final class QuestionnaireViewModel: ObservableObject {

    @Published var profil: ProfilUtilisateur?
    @Published var symptomeSelections: [SymptomeSelection] = []
    @Published var medicamentsSelectionnes: Set<String> = []
    @Published var contextesSelectionnes: Set<String> = []
    @Published var aucunMedicament = false
    @Published var aucunContexte = false
    @Published var scores: [ScoreResult] = []
    @Published var reglesDetectees: [RegleCombination] = []
    @Published var savedPayload: SavedResultsPayload?

    let database = CarenceDatabase.shared

    var symptomesSelectionnes: Set<String> {
        Set(symptomeSelections.map(\.symptomeId))
    }

    var selectedSymptomCount: Int { symptomeSelections.count }

    var profilComplet: Bool {
        guard let profil else { return false }
        if profil.sexe == .femme {
            return true
        }
        return true
    }

    func restoreDraftIfNeeded() {
        guard let draft = ResultsStorage.loadDraft() else { return }
        profil = draft.profil
        if let selections = draft.symptomeSelections, !selections.isEmpty {
            symptomeSelections = selections
        } else {
            symptomeSelections = draft.symptomes.map { SymptomeSelection(symptomeId: $0) }
        }
        medicamentsSelectionnes = Set(draft.medicaments)
        contextesSelectionnes = Set(draft.contextes)
        aucunMedicament = medicamentsSelectionnes.isEmpty && draft.aucunMedicament
        aucunContexte = contextesSelectionnes.isEmpty && draft.aucunContexte
    }

    func setProfil(_ profil: ProfilUtilisateur) {
        var p = profil
        if p.sexe == .homme {
            p.situationHormonale = .nonApplicable
        }
        self.profil = p
        persistDraft()
    }

    func toggleSymptome(_ id: String) {
        if let index = symptomeSelections.firstIndex(where: { $0.symptomeId == id }) {
            symptomeSelections.remove(at: index)
        } else {
            symptomeSelections.append(SymptomeSelection(symptomeId: id))
        }
        persistDraft()
    }

    func setFrequence(symptomeId: String, frequence: Frequence) {
        guard let index = symptomeSelections.firstIndex(where: { $0.symptomeId == symptomeId }) else { return }
        symptomeSelections[index].frequence = frequence
        persistDraft()
    }

    func frequence(for symptomeId: String) -> Frequence {
        symptomeSelections.first(where: { $0.symptomeId == symptomeId })?.frequence ?? .frequent
    }

    func isSymptomeSelected(_ id: String) -> Bool {
        symptomeSelections.contains { $0.symptomeId == id }
    }

    func deselectAllSymptomes() {
        symptomeSelections.removeAll()
        persistDraft()
    }

    func toggleMedicament(_ id: String) {
        aucunMedicament = false
        if medicamentsSelectionnes.contains(id) {
            medicamentsSelectionnes.remove(id)
        } else {
            medicamentsSelectionnes.insert(id)
        }
        persistDraft()
    }

    func selectAucunMedicament() {
        medicamentsSelectionnes.removeAll()
        aucunMedicament = true
        persistDraft()
    }

    func toggleContexte(_ id: String) {
        aucunContexte = false
        if contextesSelectionnes.contains(id) {
            contextesSelectionnes.remove(id)
        } else {
            contextesSelectionnes.insert(id)
        }
        persistDraft()
    }

    func selectAucunContexte() {
        contextesSelectionnes.removeAll()
        aucunContexte = true
        persistDraft()
    }

    func analyser() {
        let contextesActifs = database.contextesMedicaux.filter { contextesSelectionnes.contains($0.id) }
        reglesDetectees = ScoringEngine.detecterCombinaisonsSpeciales(
            symptomesSelectionnes: symptomesSelectionnes,
            regles: database.reglesCombinatoiresSpeciales
        )
        scores = ScoringEngine.calculerScores(
            selections: symptomeSelections,
            medicamentsSelectionnes: medicamentsSelectionnes,
            profil: profil,
            contextesActifs: contextesActifs
        )
        let conseils = contextesActifs.map(\.conseil)
        let payload = SavedResultsPayload(
            date: Date(),
            symptomeSelections: symptomeSelections,
            medicamentsSelectionnes: Array(medicamentsSelectionnes),
            contextesSelectionnes: Array(contextesSelectionnes),
            profil: profil,
            scores: scores,
            reglesDetectees: reglesDetectees.map(\.id),
            conseilsContexte: conseils
        )
        savedPayload = payload
        ResultsStorage.save(payload)
        ResultsStorage.clearDraft()
        SymptomJournalStorage.appendBilanHistory(payload)
        SymptomTrackerViewModel.shared.syncTrackedSymptoms(from: symptomeSelections)
    }

    func loadSavedResults() {
        guard let payload = ResultsStorage.load() else { return }
        savedPayload = payload
        profil = payload.profil
        symptomeSelections = payload.symptomeSelections
        medicamentsSelectionnes = Set(payload.medicamentsSelectionnes)
        contextesSelectionnes = Set(payload.contextesSelectionnes)
        aucunMedicament = medicamentsSelectionnes.isEmpty
        aucunContexte = contextesSelectionnes.isEmpty
        scores = payload.scores
        reglesDetectees = database.reglesCombinatoiresSpeciales.filter {
            payload.reglesDetectees.contains($0.id)
        }
    }

    func resetQuestionnaire() {
        profil = nil
        symptomeSelections.removeAll()
        medicamentsSelectionnes.removeAll()
        contextesSelectionnes.removeAll()
        aucunMedicament = false
        aucunContexte = false
        scores.removeAll()
        reglesDetectees.removeAll()
        savedPayload = nil
        ResultsStorage.clear()
        UserDefaults.standard.removeObject(forKey: AppConstants.questionnaireStorageKey)
    }

    func symptomes(for category: SymptomCategory) -> [Symptome] {
        CarenceDatabase.symptomes(for: category)
    }

    private func persistDraft() {
        ResultsStorage.saveDraft(
            profil: profil,
            symptomeSelections: symptomeSelections,
            medicaments: medicamentsSelectionnes,
            contextes: contextesSelectionnes,
            aucunMedicament: aucunMedicament,
            aucunContexte: aucunContexte
        )
    }
}
