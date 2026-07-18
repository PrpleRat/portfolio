import Foundation

/// Boutons rapides « avant de dormir », alignés sur la littérature sommeil.
enum PreSleepFactorCatalog {

    struct QuickPick: Identifiable {
        let id = UUID()
        let label: String
        let type: FactorType
        let value: Double
        let usesSharedTime: Bool
    }

    static let caffeine: [QuickPick] = [
        QuickPick(label: "Expresso", type: .caffeine, value: 80, usesSharedTime: true),
        QuickPick(label: "Café allongé", type: .caffeine, value: 120, usesSharedTime: true),
        QuickPick(label: "Thé", type: .theanine, value: 50, usesSharedTime: true),
        QuickPick(label: "Coca", type: .caffeine, value: 40, usesSharedTime: true),
        QuickPick(label: "Energy drink", type: .energyDrink, value: 250, usesSharedTime: true),
        QuickPick(label: "Chocolat", type: .chocolate, value: 30, usesSharedTime: true)
    ]

    static let nicotine: [QuickPick] = [
        QuickPick(label: "Cigarette", type: .nicotine, value: 1, usesSharedTime: true),
        QuickPick(label: "Vape", type: .vapingNicotine, value: 1, usesSharedTime: true)
    ]

    static let alcohol: [QuickPick] = [
        QuickPick(label: "Vin", type: .alcohol, value: 15, usesSharedTime: false),
        QuickPick(label: "Bière", type: .alcohol, value: 25, usesSharedTime: false),
        QuickPick(label: "Shot", type: .alcohol, value: 4, usesSharedTime: false),
        QuickPick(label: "Cocktail", type: .alcohol, value: 15, usesSharedTime: false)
    ]

    static let substances: [QuickPick] = [
        QuickPick(label: "Cannabis", type: .cannabis, value: 0.5, usesSharedTime: false),
        QuickPick(label: "CBD", type: .cbdOil, value: 25, usesSharedTime: false),
        QuickPick(label: "Autre", type: .otherSubstance, value: 1, usesSharedTime: false)
    ]

    static let supplements: [QuickPick] = [
        QuickPick(label: "Mélatonine", type: .melatonin, value: 1, usesSharedTime: false),
        QuickPick(label: "Magnésium", type: .magnesium, value: 200, usesSharedTime: false),
        QuickPick(label: "Valériane", type: .valerian, value: 300, usesSharedTime: false),
        QuickPick(label: "Somnifère", type: .medicationSleep, value: 1, usesSharedTime: false),
        QuickPick(label: "Antihistaminique", type: .antihistamineSedative, value: 1, usesSharedTime: false)
    ]

    static let food: [QuickPick] = [
        QuickPick(label: "Repas tardif", type: .lateEating, value: 1, usesSharedTime: false),
        QuickPick(label: "Repas lourd", type: .heavyMeal, value: 1, usesSharedTime: false),
        QuickPick(label: "Épicé", type: .spicyMeal, value: 1, usesSharedTime: false),
        QuickPick(label: "Dîner sucré", type: .highGlycemicEvening, value: 1, usesSharedTime: false),
        QuickPick(label: "Eau tardive", type: .hydration, value: 500, usesSharedTime: false)
    ]

    static let activity: [QuickPick] = [
        QuickPick(label: "Sport intense tard", type: .eveningIntenseExercise, value: 45, usesSharedTime: false),
        QuickPick(label: "Sieste tardive", type: .lateNap, value: 60, usesSharedTime: false),
        QuickPick(label: "Méditation", type: .mindfulness, value: 15, usesSharedTime: false),
        QuickPick(label: "Douche chaude", type: .hotShowerBeforeBed, value: 1, usesSharedTime: false)
    ]

    static let environment: [QuickPick] = [
        QuickPick(label: "Lumière vive", type: .brightLightEvening, value: 1, usesSharedTime: false),
        QuickPick(label: "Chambre chaude", type: .roomTemperature, value: 24, usesSharedTime: false),
        QuickPick(label: "Bruit", type: .noisyEnvironment, value: 1, usesSharedTime: false),
        QuickPick(label: "Ronflement partenaire", type: .partnerSnoring, value: 1, usesSharedTime: false),
        QuickPick(label: "Animal au lit", type: .petInBed, value: 1, usesSharedTime: false),
        QuickPick(label: "Voyage / jet lag", type: .jetLag, value: 1, usesSharedTime: false),
        QuickPick(label: "Travail de nuit", type: .shiftWork, value: 1, usesSharedTime: false)
    ]

    static let medical: [QuickPick] = [
        QuickPick(label: "Reflux", type: .gerdSymptoms, value: 1, usesSharedTime: false),
        QuickPick(label: "Allergies", type: .allergySymptoms, value: 1, usesSharedTime: false),
        QuickPick(label: "Jambes sans repos", type: .restlessLegs, value: 1, usesSharedTime: false),
        QuickPick(label: "ISRS", type: .ssri, value: 1, usesSharedTime: false),
        QuickPick(label: "Benzodiazépine", type: .benzodiazepine, value: 1, usesSharedTime: false)
    ]

    static var allQuickPicks: [QuickPick] {
        caffeine + nicotine + alcohol + substances + supplements + food
            + activity + environment + medical
    }
}
