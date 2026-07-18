import Foundation

enum QuestionnaireStep: Int, CaseIterable {
    case profil = 1
    case symptomes = 2
    case medicaments = 3
    case contextes = 4
    case resultats = 5

    var label: String {
        switch self {
        case .profil: return "Profil"
        case .symptomes: return "Symptômes"
        case .medicaments: return "Médicaments"
        case .contextes: return "Contextes"
        case .resultats: return "Résultats"
        }
    }

    static let totalEtapes = 5
}

enum QuestionnaireResume {
    static func etapeCourante(draft: QuestionnaireDraft?) -> QuestionnaireStep? {
        guard let draft else { return nil }
        guard draft.profil != nil else { return .profil }
        let selections = draft.symptomeSelections ?? draft.symptomes.map { SymptomeSelection(symptomeId: $0) }
        guard !selections.isEmpty else { return .symptomes }
        if !draft.aucunMedicament && draft.medicaments.isEmpty { return .medicaments }
        if !draft.aucunContexte && draft.contextes.isEmpty { return .contextes }
        return .contextes
    }

    static func messageReprise(pour etape: QuestionnaireStep) -> String {
        switch etape {
        case .profil: return "Continuez votre profil"
        case .symptomes: return "Continuez le questionnaire symptômes"
        case .medicaments: return "Indiquez vos médicaments"
        case .contextes: return "Précisez votre contexte médical"
        case .resultats: return "Finalisez votre bilan"
        }
    }

    static func minutesEstimees(restantesDepuis etape: QuestionnaireStep) -> Int {
        switch etape {
        case .profil: return 4
        case .symptomes: return 3
        case .medicaments: return 1
        case .contextes: return 1
        case .resultats: return 1
        }
    }
}

extension QuestionnaireViewModel {
    var draftCourant: QuestionnaireDraft? {
        ResultsStorage.loadDraft()
    }

    var etapeReprise: QuestionnaireStep? {
        QuestionnaireResume.etapeCourante(draft: draftCourant)
    }

    func categorieAction(pour carenceId: String) -> ActionCategory {
        if carenceId == "fer" || CarenceDatabase.carence(for: carenceId)?.prescriptionObligatoire == true {
            return .urgence
        }
        if carenceId == "tryptophane" { return .urgence }
        if ["vitamine_b12", "iode", "selenium"].contains(carenceId) { return .pharmacieOrdonnance }
        return .alimentation
    }
}
