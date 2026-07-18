import XCTest
@testable import CarenceScan

@MainActor
final class NutritionV18Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppConstants.journalAlimentaireKey)
    }

    func testJournalScoreApresAliments() {
        let engine = JournalEngine()
        engine.toggleAliment("sardines")
        engine.toggleAliment("epinards")
        engine.toggleAliment("kiwis")

        let analyse = engine.calculerCarencesCouvertes(
            date: Date(),
            aliments: NutritionDataLoader.alimentsTrackables,
            carencesUtilisateur: ["omega3", "vitamine_d", "vitamine_b12", "fer", "vitamine_c"]
        )

        XCTAssertTrue(analyse.carencesCouvertes.contains("omega3"))
        XCTAssertTrue(analyse.carencesCouvertes.contains("vitamine_d"))
        XCTAssertTrue(analyse.carencesCouvertes.contains("vitamine_b12"))
        XCTAssertTrue(analyse.carencesCouvertes.contains("fer"))
        XCTAssertTrue(analyse.carencesCouvertes.contains("vitamine_c"))
        XCTAssertGreaterThan(analyse.scoreJournee, 50)
    }

    func testSuggestionGrainesCourge() {
        let engine = JournalEngine()
        let analyse = engine.calculerCarencesCouvertes(
            date: Date(),
            aliments: NutritionDataLoader.alimentsTrackables,
            carencesUtilisateur: ["zinc", "magnesium"]
        )
        XCTAssertEqual(analyse.suggestionDuJour?.id, "graines_courge")
    }

    func testSynergieMagnesiumVitamineD() {
        let actives: Set<String> = ["magnesium", "vitamine_d"]
        let found = NutritionDataLoader.synergiesDetectees(carencesActives: actives)
        XCTAssertTrue(found.contains { $0.id == "magnesium_vitamine_d" })
    }

    func testAntagonismeFerZinc() {
        let actives: Set<String> = ["fer", "zinc"]
        let found = NutritionDataLoader.synergiesDetectees(carencesActives: actives)
        XCTAssertTrue(found.contains { $0.id == "zinc_fer_antagonisme" })
    }

    func testRecettesV2Charge73() {
        XCTAssertEqual(RecettesEngine.nombreRecettesDansBase, 73)
        let scores = [
            ScoreResult(carenceId: "zinc", score: 70, niveau: .probable, symptomesDetectes: [])
        ]
        let recettes = RecettesEngine.suggererRecettes(depuis: scores)
        XCTAssertGreaterThan(recettes.count, 8, "Plus de 8 recettes doivent matcher le zinc")
        XCTAssertEqual(RecettesEngine.listerToutesLesRecettes().count, 73)
    }

    func testAjustementPortionsRecette() {
        let base = ["4 œufs", "100g d'épinards", "1/2 brocoli", "Jus d'1 citron"]
        let x2 = RecettePortionsScaler.ingredientsAjustes(base, portionsBase: 2, portionsVoulues: 4)
        XCTAssertTrue(x2[0].contains("8"))
        XCTAssertTrue(x2[1].contains("200"))
        XCTAssertTrue(x2[2].contains("1") && !x2[2].contains("/"))
        XCTAssertTrue(x2[3].contains("2"))
    }
}
