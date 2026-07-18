import XCTest
@testable import CarenceScan

final class RecettesListeCoursesTests: XCTestCase {

    private func score(_ carenceId: String, niveau: ProbabilityLevel, symptomes: [String] = ["fatigue_intense"]) -> ScoreResult {
        ScoreResult(
            carenceId: carenceId,
            score: 70,
            niveau: niveau,
            symptomesDetectes: symptomes
        )
    }

    func testSaumonEpinardsTopRecette() {
        let scores = [
            score("vitamine_d", niveau: .tresProbable),
            score("omega3", niveau: .tresProbable),
            score("fer", niveau: .probable)
        ]
        let recettes = RecettesEngine.suggererRecettes(depuis: scores)
        let ids = recettes.map(\.recette.id)
        XCTAssertTrue(
            ids.contains("saumon_epinards_citron") || ids.contains("pasta_saumon_epinards"),
            "Saumon + épinards attendu pour D, oméga-3 et fer"
        )
    }

    func testPasAssociationAbsurdeSardinesOranges() {
        let scores = [
            score("vitamine_c", niveau: .tresProbable),
            score("omega3", niveau: .probable)
        ]
        let recettes = RecettesEngine.suggererRecettes(depuis: scores)
        XCTAssertFalse(recettes.contains { $0.recette.ingredientsCles.contains("sardines") && $0.recette.ingredientsCles.contains("oranges") })
    }

    func testDiversificationSaumon() {
        let scores = [
            score("vitamine_d", niveau: .quasiCertaine),
            score("omega3", niveau: .quasiCertaine),
            score("fer", niveau: .tresProbable),
            score("magnesium", niveau: .probable)
        ]
        let recettes = RecettesEngine.suggererRecettes(depuis: scores, limite: 8)
        let saumonCount = recettes.filter { $0.recette.ingredientsCles.first == "saumon" }.count
        XCTAssertLessThanOrEqual(saumonCount, 2)
    }

    func testComplexeBUnique() {
        let scores = [
            score("vitamine_b1", niveau: .probable),
            score("vitamine_b2_b3", niveau: .probable),
            score("vitamine_b6", niveau: .probable),
            score("vitamine_b9", niveau: .probable)
        ]
        let liste = ListeCoursesEngine.genererListe(depuis: scores, symptomesDetectes: [])
        let complexe = liste.pharmacie.filter { $0.id == "complexe_b" }
        XCTAssertEqual(complexe.count, 1)
        let bIndividuels = liste.pharmacie.filter {
            ["vitamine_b1", "vitamine_b2_b3", "vitamine_b6", "vitamine_b9"].contains($0.id)
        }
        XCTAssertTrue(bIndividuels.isEmpty)
    }

    func testFerBilanObligatoire() {
        let scores = [score("fer", niveau: .quasiCertaine)]
        let liste = ListeCoursesEngine.genererListe(depuis: scores, symptomesDetectes: [])
        let fer = liste.pharmacie.first { $0.carencesLiees.contains("fer") }
        XCTAssertNotNil(fer)
        XCTAssertTrue(fer?.nom.contains("⚠️") == true)
        XCTAssertTrue(fer?.detail?.lowercased().contains("bilan") == true)
    }

    func testTextePartage() {
        let scores = [score("magnesium", niveau: .probable)]
        let liste = ListeCoursesEngine.genererListe(depuis: scores, symptomesDetectes: [])
        let texte = ListeCoursesEngine.genererTextePartage(liste: liste)
        XCTAssertTrue(texte.contains("☐"))
        XCTAssertTrue(texte.contains("PHARMACIE"))
        XCTAssertTrue(texte.contains("SUPERMARCHÉ"))
    }
}
