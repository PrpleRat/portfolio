import Foundation

struct AjustementProfil {
    let carenceId: String
    let multiplicateurScore: Double
    let bonusFixe: Int
    let alerteSpecifique: String?
    let urgenceRenforcee: Bool
}

enum NoteContexteType: String, Codable {
    case confusion
    case aggravation
}

struct NoteContexte: Codable, Hashable, Identifiable {
    var id: String { "\(type.rawValue)|\(contexteLabel)|\(symptomeId ?? "")|\(message)" }
    let type: NoteContexteType
    let contexteLabel: String
    let contexteEmoji: String
    let message: String
    let symptomeId: String?
    let explication: String?
    let sources: [ContexteSource]

    init(
        type: NoteContexteType,
        contexteLabel: String,
        contexteEmoji: String,
        message: String,
        symptomeId: String? = nil,
        explication: String? = nil,
        sources: [ContexteSource] = []
    ) {
        self.type = type
        self.contexteLabel = contexteLabel
        self.contexteEmoji = contexteEmoji
        self.message = message
        self.symptomeId = symptomeId
        self.explication = explication
        self.sources = sources
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(NoteContexteType.self, forKey: .type)
        contexteLabel = try c.decode(String.self, forKey: .contexteLabel)
        contexteEmoji = try c.decode(String.self, forKey: .contexteEmoji)
        message = try c.decode(String.self, forKey: .message)
        symptomeId = try c.decodeIfPresent(String.self, forKey: .symptomeId)
        explication = try c.decodeIfPresent(String.self, forKey: .explication)
        sources = try c.decodeIfPresent([ContexteSource].self, forKey: .sources) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case type, contexteLabel, contexteEmoji, message, symptomeId, explication, sources
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(contexteLabel, forKey: .contexteLabel)
        try c.encode(contexteEmoji, forKey: .contexteEmoji)
        try c.encode(message, forKey: .message)
        try c.encodeIfPresent(symptomeId, forKey: .symptomeId)
        try c.encodeIfPresent(explication, forKey: .explication)
        try c.encode(sources, forKey: .sources)
    }
}

struct NoteContexteGroupe: Identifiable {
    let id: String
    let emoji: String
    let label: String
    let notesConfusion: [NoteContexte]
    let notesAggravation: [NoteContexte]
}

extension Array where Element == NoteContexte {
    var groupedByContexte: [NoteContexteGroupe] {
        let labels = Set(map(\.contexteLabel))
        return labels.sorted().compactMap { label in
            let notes = filter { $0.contexteLabel == label }
            guard let first = notes.first else { return nil }
            return NoteContexteGroupe(
                id: label,
                emoji: first.contexteEmoji,
                label: label,
                notesConfusion: notes.filter { $0.type == .confusion },
                notesAggravation: notes.filter { $0.type == .aggravation }
            )
        }
    }
}

enum ScoringEngine {

    private static let medicamentBonus = 20

    static func calculerScores(
        selections: [SymptomeSelection],
        medicamentsSelectionnes: Set<String> = [],
        profil: ProfilUtilisateur? = nil,
        contextesActifs: [ContexteMedical] = [],
        database: CarenceDatabaseFile = CarenceDatabase.shared
    ) -> [ScoreResult] {
        let symptomeIds = Set(selections.map(\.symptomeId))
        let frequenceParSymptome = Dictionary(uniqueKeysWithValues: selections.map { ($0.symptomeId, $0.frequence) })

        let reglesActives = detecterCombinaisonsSpeciales(
            symptomesSelectionnes: symptomeIds,
            regles: database.reglesCombinatoiresSpeciales
        )

        var bonusSpeciauxParCarence: [String: Int] = [:]
        for regle in reglesActives {
            for carenceId in regle.carencesAmplifiees {
                bonusSpeciauxParCarence[carenceId, default: 0] += regle.bonusScore
            }
        }

        let ajustementsProfil = profil.map { calculerAjustementsProfil(profil: $0) } ?? []

        var resultats: [ScoreResult] = []

        for carence in database.carences {
            var score = 0.0
            var bonusCombinations = 0
            var symptomesDetectes: [String] = []
            var alertes: [String] = []
            var alertesProfil: [String] = []
            var urgenceRenforcee = false

            for selection in selections {
                guard let scoreSymptome = carence.scoreParSymptome[selection.symptomeId] else { continue }
                let scoreAjuste = Double(scoreSymptome) * selection.frequence.coefficient
                score += scoreAjuste
                symptomesDetectes.append(selection.symptomeId)
            }

            for combo in carence.combinaisonsAmplificatrices {
                let tousPresents = combo.symptomes.allSatisfy { symptomeIds.contains($0) }
                guard tousPresents else { continue }
                let coeffs = combo.symptomes.compactMap { frequenceParSymptome[$0]?.coefficient }
                let coefficientMoyen = coeffs.isEmpty ? 1.0 : coeffs.reduce(0, +) / Double(coeffs.count)
                let bonus = Double(combo.bonus) * coefficientMoyen
                bonusCombinations += Int(bonus.rounded())
                score += bonus
            }

            if let bonusSpecial = bonusSpeciauxParCarence[carence.id] {
                bonusCombinations += bonusSpecial
                score += Double(bonusSpecial)
            }

            for medicamentId in medicamentsSelectionnes {
                guard let medicament = database.medicamentsDepleteurs.first(where: { $0.id == medicamentId }),
                      medicament.carencesInduites.contains(carence.id)
                else { continue }
                score += Double(medicamentBonus)
                alertes.append("Induit par \(medicament.label)")
            }

            for ajustement in ajustementsProfil where ajustement.carenceId == carence.id {
                score += Double(ajustement.bonusFixe) * ajustement.multiplicateurScore
                if let alerte = ajustement.alerteSpecifique {
                    alertesProfil.append(alerte)
                }
                if ajustement.urgenceRenforcee {
                    urgenceRenforcee = true
                }
            }

            let notesContexte = appliquerContextes(
                score: &score,
                selections: selections,
                contextes: contextesActifs,
                carence: carence
            )

            let scoreInt = max(0, Int(score.rounded()))
            var niveau = niveauPour(score: scoreInt, carence: carence)
            guard var niveau else { continue }

            if urgenceRenforcee, niveau == .probable {
                niveau = .tresProbable
            }

            alertes.append(contentsOf: alertesProfil)

            resultats.append(
                ScoreResult(
                    carenceId: carence.id,
                    score: scoreInt,
                    niveau: niveau,
                    symptomesDetectes: symptomesDetectes,
                    alertes: alertes,
                    bonusCombinations: bonusCombinations,
                    notesContexte: notesContexte,
                    alertesProfil: alertesProfil
                )
            )
        }

        return resultats.sorted { lhs, rhs in
            if lhs.niveau.sortOrder != rhs.niveau.sortOrder {
                return lhs.niveau.sortOrder > rhs.niveau.sortOrder
            }
            return lhs.score > rhs.score
        }
    }

    /// Compatibilité v1 — symptômes sans fréquence explicite (= fréquent).
    static func calculerScores(
        symptomesSelectionnes: Set<String>,
        medicamentsSelectionnes: Set<String> = [],
        database: CarenceDatabaseFile = CarenceDatabase.shared
    ) -> [ScoreResult] {
        let selections = symptomesSelectionnes.map { SymptomeSelection(symptomeId: $0) }
        return calculerScores(
            selections: selections,
            medicamentsSelectionnes: medicamentsSelectionnes,
            database: database
        )
    }

    static func detecterCombinaisonsSpeciales(
        symptomesSelectionnes: Set<String>,
        regles: [RegleCombination]
    ) -> [RegleCombination] {
        regles.filter { regle in
            regle.symptomesRequis.allSatisfy { symptomesSelectionnes.contains($0) }
        }
    }

    static func calculerAjustementsProfil(profil: ProfilUtilisateur) -> [AjustementProfil] {
        var ajustements: [AjustementProfil] = []

        if profil.sexe == .femme {
            switch profil.situationHormonale {
            case .reglesAbondantes:
                ajustements.append(AjustementProfil(
                    carenceId: "fer",
                    multiplicateurScore: 1.0,
                    bonusFixe: 45,
                    alerteSpecifique: "Les règles abondantes sont la première cause de carence en fer chez la femme. Une ferritine < 30 µg/L confirme la carence. Bilan sanguin indispensable (Source : ACOG 2024, WHO 2020).",
                    urgenceRenforcee: true
                ))
                ajustements.append(AjustementProfil(
                    carenceId: "vitamine_b9",
                    multiplicateurScore: 1.0,
                    bonusFixe: 15,
                    alerteSpecifique: "Les pertes menstruelles abondantes augmentent aussi les besoins en acide folique.",
                    urgenceRenforcee: false
                ))
            case .reglesRegulieres:
                ajustements.append(AjustementProfil(
                    carenceId: "fer",
                    multiplicateurScore: 1.0,
                    bonusFixe: 20,
                    alerteSpecifique: "Les femmes menstruées ont des besoins en fer 2x supérieurs aux hommes (18mg/j vs 8mg/j selon l'OMS). Une carence en fer est fréquente même sans règles abondantes.",
                    urgenceRenforcee: false
                ))
            case .contraceptif:
                ajustements.append(AjustementProfil(
                    carenceId: "vitamine_b6",
                    multiplicateurScore: 1.0,
                    bonusFixe: 20,
                    alerteSpecifique: "Les contraceptifs hormonaux réduisent l'absorption des vitamines B6, B9, B12 et du magnésium. Ce contexte augmente la probabilité de ces carences.",
                    urgenceRenforcee: false
                ))
                ajustements.append(AjustementProfil(carenceId: "magnesium", multiplicateurScore: 1.0, bonusFixe: 15, alerteSpecifique: nil, urgenceRenforcee: false))
                ajustements.append(AjustementProfil(carenceId: "vitamine_b9", multiplicateurScore: 1.0, bonusFixe: 15, alerteSpecifique: nil, urgenceRenforcee: false))
                ajustements.append(AjustementProfil(carenceId: "vitamine_c", multiplicateurScore: 1.0, bonusFixe: 10, alerteSpecifique: nil, urgenceRenforcee: false))
            case .enceinte:
                ajustements.append(contentsOf: [
                    AjustementProfil(carenceId: "vitamine_b9", multiplicateurScore: 1.0, bonusFixe: 50, alerteSpecifique: "⚠️ GROSSESSE — L'acide folique est CRITIQUE en début de grossesse pour prévenir les malformations du tube neural. 400µg/j minimum, idéalement 600µg/j. Consultez votre sage-femme ou médecin immédiatement.", urgenceRenforcee: true),
                    AjustementProfil(carenceId: "fer", multiplicateurScore: 1.0, bonusFixe: 50, alerteSpecifique: "⚠️ GROSSESSE — La carence en fer est la plus fréquente de la grossesse. Bilan ferritine + NFS obligatoire. Ne pas se supplémenter sans prescription (dose adaptée selon le bilan). Source : Cochrane 2024.", urgenceRenforcee: true),
                    AjustementProfil(carenceId: "iode", multiplicateurScore: 1.0, bonusFixe: 40, alerteSpecifique: "⚠️ GROSSESSE — L'iode est essentiel au développement neurologique du fœtus. Besoins augmentés à 220µg/j. Consultez votre médecin.", urgenceRenforcee: true),
                    AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 30, alerteSpecifique: "⚠️ GROSSESSE — La vitamine D est recommandée systématiquement pendant la grossesse.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "omega3", multiplicateurScore: 1.0, bonusFixe: 25, alerteSpecifique: "⚠️ GROSSESSE — Les oméga-3 (DHA) sont essentiels au développement cérébral du fœtus. Minimum 200mg DHA/j recommandé.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "magnesium", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "⚠️ GROSSESSE — RDA magnésium augmenté à 350mg/j pendant la grossesse (vs 310mg hors grossesse). Source : Linus Pauling Institute 2024.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "zinc", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "⚠️ GROSSESSE — RDA zinc augmenté à 11mg/j pendant la grossesse. Crucial pour le développement fœtal.", urgenceRenforcee: false)
                ])
            case .allaitante:
                ajustements.append(contentsOf: [
                    AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 30, alerteSpecifique: "⚠️ ALLAITEMENT — La vitamine D est insuffisante dans le lait maternel. Supplémentation du nourrisson souvent nécessaire en parallèle. Consultez votre pédiatre.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "iode", multiplicateurScore: 1.0, bonusFixe: 35, alerteSpecifique: "⚠️ ALLAITEMENT — Les besoins en iode sont augmentés à 290µg/j. Le lait maternel est la source principale d'iode pour le nourrisson.", urgenceRenforcee: true),
                    AjustementProfil(carenceId: "vitamine_b12", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "⚠️ ALLAITEMENT — La B12 passe dans le lait maternel. Carence maternelle = carence du nourrisson. Supplémentation essentielle si alimentation végétale.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "omega3", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "⚠️ ALLAITEMENT — Le DHA passe dans le lait et est crucial pour le développement cérébral du bébé.", urgenceRenforcee: false)
                ])
            case .menopause:
                ajustements.append(contentsOf: [
                    AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 30, alerteSpecifique: "La ménopause et la carence en vitamine D augmentent ensemble le risque de perte osseuse. Source : revue systématique 37 RCTs (43 397 femmes), European Journal of Medical Research 2025.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "magnesium", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "Le magnésium joue un rôle clé dans la santé osseuse et la régulation hormonale pendant la ménopause.", urgenceRenforcee: false),
                    AjustementProfil(carenceId: "omega3", multiplicateurScore: 1.0, bonusFixe: 15, alerteSpecifique: "Les oméga-3 sont particulièrement bénéfiques pendant la ménopause pour la santé cardiovasculaire.", urgenceRenforcee: false)
                ])
            case .amenorrhee, .nonApplicable:
                break
            }
        }

        if profil.age == .plus65 {
            ajustements.append(contentsOf: [
                AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 25, alerteSpecifique: "Après 65 ans, la synthèse cutanée de vitamine D diminue de 75% et l'absorption intestinale se réduit. La RDA passe à 800 UI/j selon l'Endocrine Society (2024).", urgenceRenforcee: false),
                AjustementProfil(carenceId: "vitamine_b12", multiplicateurScore: 1.0, bonusFixe: 20, alerteSpecifique: "L'absorption de la B12 diminue avec l'âge (atrophie gastrique). La prévalence de carence en B12 dépasse 20% après 65 ans.", urgenceRenforcee: false),
                AjustementProfil(carenceId: "magnesium", multiplicateurScore: 1.0, bonusFixe: 15, alerteSpecifique: "L'absorption du magnésium diminue et l'excrétion urinaire augmente avec l'âge.", urgenceRenforcee: false)
            ])
        }

        if profil.age == .quarante6_55 || profil.age == .cinquante6_65 {
            ajustements.append(AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 10, alerteSpecifique: nil, urgenceRenforcee: false))
        }

        if profil.age == .moins18 {
            ajustements.append(contentsOf: [
                AjustementProfil(carenceId: "zinc", multiplicateurScore: 1.0, bonusFixe: 15, alerteSpecifique: "Les adolescents en croissance ont des besoins en zinc supérieurs. La carence en zinc peut affecter la croissance et le développement.", urgenceRenforcee: false),
                AjustementProfil(carenceId: "vitamine_d", multiplicateurScore: 1.0, bonusFixe: 10, alerteSpecifique: "Le pic de masse osseuse se construit avant 25 ans — la vitamine D est critique à cet âge. Source : Endocrine Society 2024.", urgenceRenforcee: false)
            ])
        }

        if profil.age == .dix8_25 {
            ajustements.append(AjustementProfil(
                carenceId: "vitamine_d",
                multiplicateurScore: 1.0,
                bonusFixe: 8,
                alerteSpecifique: "Le pic de masse osseuse se construit jusqu'à 25 ans. Un déficit en vitamine D à cet âge a des conséquences osseuses à long terme.",
                urgenceRenforcee: false
            ))
        }

        return ajustements
    }

    static func appliquerContextes(
        score: inout Double,
        selections: [SymptomeSelection],
        contextes: [ContexteMedical],
        carence: Carence
    ) -> [NoteContexte] {
        var notes: [NoteContexte] = []

        for contexte in contextes {
            var noteConfusionAjoutee = false
            for selection in selections where contexte.symptomesConfondus.contains(selection.symptomeId) {
                guard let scoreSymptome = carence.scoreParSymptome[selection.symptomeId] else { continue }
                let scoreBase = Double(scoreSymptome)
                let reduction = scoreBase * selection.frequence.coefficient * (1 - contexte.coefficientReduction)
                score -= reduction

                guard !noteConfusionAjoutee else { continue }
                noteConfusionAjoutee = true
                notes.append(NoteContexte(
                    type: .confusion,
                    contexteLabel: contexte.label,
                    contexteEmoji: contexte.emoji,
                    message: contexte.messageConfond,
                    explication: contexte.explicationConfond,
                    sources: contexte.sourcesConfond
                ))
            }

            if contexte.carencesAggravees.contains(carence.id) {
                score += Double(contexte.bonusAggravation)
                let message = contexte.messageAggrave.replacingOccurrences(of: "{carence}", with: carence.nom)
                let detail = contexte.explicationsAggrave[carence.id]
                notes.append(NoteContexte(
                    type: .aggravation,
                    contexteLabel: contexte.label,
                    contexteEmoji: contexte.emoji,
                    message: message,
                    explication: detail?.explication,
                    sources: detail?.sources ?? []
                ))
            }
        }

        return notes
    }

    private static func niveauPour(score: Int, carence: Carence) -> ProbabilityLevel? {
        if score >= carence.seuilQuasiCertain { return .quasiCertaine }
        if score >= carence.seuilTresProbable { return .tresProbable }
        if score >= carence.seuilProbable { return .probable }
        return nil
    }
}
