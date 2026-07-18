import Foundation

enum AppConstants {

    static let appName = "CarenceScan"
    static let appTagline = "Carences & solutions"
    static let appFullTitle = "CarenceScan — Carences & solutions"

    static let disclaimerPrincipal =
        "Cet outil est un guide d'orientation basé sur vos symptômes déclarés. Il ne constitue pas un diagnostic médical. Consultez un professionnel de santé avant toute supplémentation."

    static let alerteMedicaments =
        "Vous prenez des médicaments sur ordonnance. Consultez votre médecin ou pharmacien avant de démarrer tout complément alimentaire."

    static let alerteFer =
        "⚠️ Le fer ne doit JAMAIS être supplémenté sans bilan sanguin (ferritine + NFS). Un surdosage en fer est dangereux."

    static let alerte5HTP =
        "⚠️ Si vous prenez un antidépresseur ISRS (sertraline, fluoxétine...), NE PAS prendre de 5-HTP ou tryptophane sans avis médical — risque de syndrome sérotoninergique."

    static let resultsStorageKey = "carencescan.lastResults"
    static let questionnaireStorageKey = "carencescan.questionnaire.draft"
    static let journalStorageKey = "carencescan.symptom.journal"
    static let trackingSettingsKey = "carencescan.tracking.settings"
    static let bilanHistoryKey = "carencescan.bilan.history"
    static let listeCoursesCheckedKey = "carencescan.liste.checked"
    static let listeCoursesExtraKey = "carencescan.liste.extra"
    static let listeCoursesWeekKey = "carencescan.liste.week"
    static let listeCoursesWeekHistoryKey = "carencescan.liste.week.history"
    static let journalAlimentaireKey = "carencescan.journal.alimentaire.v1"

    static let dailyReminderNotificationId = "carencescan.daily.symptoms"
    static let notificationPermissionMessage =
        "CarenceScan peut vous rappeler chaque jour de noter vos symptômes pour suivre leur évolution dans le temps."

    /// Sources scientifiques — journal, synergies et horaires de prise (v1.8).
    static let sourcesScientifiquesNutrition = """
    Magnésium + vitamine D : Zittermann et al. (2024, Eur J Nutrition); Dai et al. (Am J Clin Nutr 2018).
    Zinc + fer : Cambridge Nutrition Reviews (2000); ACS Omega (2022).
    Vitamine C + fer : ACS Omega (2022).
    Vitamine D + K2 : van Ballegooijen et al. (Int J Endocrinology, 2017).
    Prévalences : NHANES / Linus Pauling Institute (2024).
    Microbiote : Barone et al. (BioFactors, 2022).
    """
}
