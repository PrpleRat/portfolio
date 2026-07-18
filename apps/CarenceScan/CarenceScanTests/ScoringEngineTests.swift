import XCTest
@testable import CarenceScan

final class ScoringEngineTests: XCTestCase {

    private let validationSymptoms: Set<String> = [
        "gencives_douloureuses",
        "coins_levres_craques",
        "crevasses_doigts",
        "peau_seche_oreilles",
        "fatigue_intense",
        "travail_nuit"
    ]

    func testValidationScenarioV1() {
        let scores = ScoringEngine.calculerScores(symptomesSelectionnes: validationSymptoms, medicamentsSelectionnes: [])
        let regles = ScoringEngine.detecterCombinaisonsSpeciales(
            symptomesSelectionnes: validationSymptoms,
            regles: CarenceDatabase.shared.reglesCombinatoiresSpeciales
        )

        XCTAssertNotNil(scores.first { $0.carenceId == "vitamine_c" })
        XCTAssertEqual(scores.first { $0.carenceId == "zinc" }?.niveau, .quasiCertaine)
        XCTAssertTrue(regles.contains { $0.id == "combo_peau_muqueuses" })
    }

    func testFemmeReglesAbondantesFer() {
        let profil = ProfilUtilisateur(sexe: .femme, age: .vingt6_35, situationHormonale: .reglesAbondantes)
        let selections = [
            SymptomeSelection(symptomeId: "fatigue_intense"),
            SymptomeSelection(symptomeId: "jambes_lourdes")
        ]
        let scores = ScoringEngine.calculerScores(selections: selections, profil: profil)
        let fer = scores.first { $0.carenceId == "fer" }
        XCTAssertNotNil(fer)
        XCTAssertEqual(fer?.niveau, .quasiCertaine)
        XCTAssertGreaterThan(fer?.score ?? 0, 75)
        XCTAssertTrue(fer?.alertesProfil.contains(where: { $0.contains("règles abondantes") }) == true)
    }

    func testFemmeEnceintePriorites() {
        let profil = ProfilUtilisateur(sexe: .femme, age: .vingt6_35, situationHormonale: .enceinte)
        let selections = [SymptomeSelection(symptomeId: "fatigue_intense")]
        let scores = ScoringEngine.calculerScores(selections: selections, profil: profil)
        let ids = Set(scores.map(\.carenceId))
        XCTAssertTrue(ids.contains("vitamine_b9"))
        XCTAssertTrue(ids.contains("fer"))
        XCTAssertTrue(ids.contains("iode"))
        let b9 = scores.first { $0.carenceId == "vitamine_b9" }
        XCTAssertTrue(b9?.alertesProfil.contains(where: { $0.contains("GROSSESSE") }) == true)
    }

    func testHomme65VitamineDB12() {
        let profil = ProfilUtilisateur(sexe: .homme, age: .plus65, situationHormonale: .nonApplicable)
        let selections = [
            SymptomeSelection(symptomeId: "fatigue_intense"),
            SymptomeSelection(symptomeId: "brouillard_mental")
        ]
        let scores = ScoringEngine.calculerScores(selections: selections, profil: profil)
        let vitD = scores.first { $0.carenceId == "vitamine_d" }
        let b12 = scores.first { $0.carenceId == "vitamine_b12" }
        XCTAssertNotNil(vitD)
        XCTAssertNotNil(b12)
        XCTAssertGreaterThanOrEqual(vitD?.score ?? 0, 45)
        XCTAssertGreaterThanOrEqual(b12?.score ?? 0, 45)
    }

    func testDepressionContexteNotes() {
        let depression = CarenceDatabase.shared.contextesMedicaux.first { $0.id == "depression_anxiete" }!
        let selections = [
            SymptomeSelection(symptomeId: "fatigue_intense"),
            SymptomeSelection(symptomeId: "tristesse_fond")
        ]
        let scores = ScoringEngine.calculerScores(
            selections: selections,
            contextesActifs: [depression]
        )
        let magnesium = scores.first { $0.carenceId == "magnesium" }
        let omega = scores.first { $0.carenceId == "omega3" }
        XCTAssertNotNil(magnesium ?? omega)
        let avecNotes = scores.filter { !$0.notesContexte.isEmpty }
        XCTAssertFalse(avecNotes.isEmpty)
        XCTAssertTrue(avecNotes.contains { result in
            result.notesContexte.contains { $0.type == .confusion }
        })
        XCTAssertTrue(avecNotes.contains { result in
            result.notesContexte.contains { $0.type == .aggravation }
        })
        if let magnesium {
            let confusions = magnesium.notesContexte.filter { $0.type == .confusion }
            XCTAssertEqual(confusions.count, 1, "Une seule note de confusion par contexte et par carence")
            XCTAssertNotNil(confusions.first?.explication)
            XCTAssertFalse(confusions.first?.sources.isEmpty ?? true)
            let aggravations = magnesium.notesContexte.filter { $0.type == .aggravation }
            XCTAssertNotNil(aggravations.first?.explication)
            XCTAssertFalse(aggravations.first?.sources.isEmpty ?? true)
        }
    }

    func testFrequenceCoefficients() {
        let constant = ScoringEngine.calculerScores(
            selections: [SymptomeSelection(symptomeId: "fatigue_intense", frequence: .constant)]
        )
        let occasionnel = ScoringEngine.calculerScores(
            selections: [SymptomeSelection(symptomeId: "fatigue_intense", frequence: .occasionnel)]
        )
        let magConst = constant.first { $0.carenceId == "magnesium" }?.score
        let magOcc = occasionnel.first { $0.carenceId == "magnesium" }?.score
        XCTAssertNotNil(magConst)
        XCTAssertNotNil(magOcc)
        if let magConst, let magOcc {
            XCTAssertGreaterThan(magConst, magOcc)
            XCTAssertEqual(magConst, Int((15.0 * 1.5).rounded()))
            XCTAssertEqual(magOcc, Int((15.0 * 0.5).rounded()))
        }
    }

    func testMedicamentBonus() {
        let base = ScoringEngine.calculerScores(
            selections: [SymptomeSelection(symptomeId: "fatigue_intense")]
        )
        let withMed = ScoringEngine.calculerScores(
            selections: [
                SymptomeSelection(symptomeId: "fatigue_intense"),
                SymptomeSelection(symptomeId: "irritabilite")
            ],
            medicamentsSelectionnes: ["sertraline"]
        )
        let baseMag = base.first { $0.carenceId == "magnesium" }?.score
        let withMedMag = withMed.first { $0.carenceId == "magnesium" }?.score
        if let baseMag, let withMedMag {
            XCTAssertGreaterThanOrEqual(withMedMag, baseMag + 20)
        }
    }

    func testScoresSortedByNiveauThenScore() {
        let scores = ScoringEngine.calculerScores(
            selections: [
                SymptomeSelection(symptomeId: "fatigue_intense"),
                SymptomeSelection(symptomeId: "gencives_douloureuses"),
                SymptomeSelection(symptomeId: "coins_levres_craques"),
                SymptomeSelection(symptomeId: "ecchymoses_faciles"),
                SymptomeSelection(symptomeId: "crampes_nocturnes"),
                SymptomeSelection(symptomeId: "mauvais_sommeil")
            ]
        )
        guard scores.count >= 2 else { return }
        for index in 0..<(scores.count - 1) {
            let current = scores[index]
            let next = scores[index + 1]
            XCTAssertGreaterThanOrEqual(current.niveau.sortOrder, next.niveau.sortOrder)
            if current.niveau.sortOrder == next.niveau.sortOrder {
                XCTAssertGreaterThanOrEqual(current.score, next.score)
            }
        }
    }
}
