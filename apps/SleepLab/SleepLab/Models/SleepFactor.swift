import Foundation
import SwiftData

enum FactorCategory: String, Codable, CaseIterable {
    case stimulant, substance, supplement, food, activity, wellbeing, medical, environment, circadian

    var displayName: String {
        switch self {
        case .stimulant: return "Stimulants"
        case .substance: return "Substances"
        case .supplement: return "Compléments"
        case .food: return "Alimentation"
        case .activity: return "Activité"
        case .wellbeing: return "Bien-être"
        case .medical: return "Médical"
        case .environment: return "Environnement"
        case .circadian: return "Rythme circadien"
        }
    }
}

enum FactorType: String, Codable, CaseIterable {
    // Stimulants
    case caffeine, nicotine, vapingNicotine, theanine, chocolate, energyDrink
    // Substances
    case alcohol, cannabis, cbdOil, otherSubstance
    // Compléments / pharmacologie courante
    case melatonin, magnesium, valerian
    case medicationSleep, medicationStimulant, benzodiazepine, ssri
    case antihistamineSedative, betaBlocker, corticosteroid, opioidAnalgesic
    // Alimentation
    case lateEating, heavyMeal, spicyMeal, highGlycemicEvening, hydration
    // Activité & hygiène
    case exercise, eveningIntenseExercise, lateNap, screenTime, sunExposure
    case brightLightEvening, mindfulness, hotShowerBeforeBed
    // Bien-être
    case stressLevel, anxietyLevel, mood, rumination, socialJetLag
    // Médical
    case pain, illness, allergySymptoms, gerdSymptoms, restlessLegs, apneaSymptoms
    // Environnement
    case roomTemperature, noisyEnvironment, newEnvironment, partnerSnoring
    case petInBed, poorAirQuality
    // Circadien & hormonal
    case shiftWork, jetLag, menstrualDiscomfort, hotFlash

    var displayName: String {
        switch self {
        case .caffeine: return "Caféine"
        case .nicotine: return "Cigarette / tabac"
        case .vapingNicotine: return "Vape nicotine"
        case .theanine: return "Thé (théanine)"
        case .chocolate: return "Chocolat"
        case .energyDrink: return "Boisson énergisante"
        case .alcohol: return "Alcool"
        case .cannabis: return "Cannabis"
        case .cbdOil: return "CBD"
        case .otherSubstance: return "Autre substance"
        case .melatonin: return "Mélatonine"
        case .magnesium: return "Magnésium"
        case .valerian: return "Valériane"
        case .medicationSleep: return "Somnifère (autre)"
        case .medicationStimulant: return "Stimulant prescrit"
        case .benzodiazepine: return "Benzodiazépine"
        case .ssri: return "Antidépresseur (ISRS)"
        case .antihistamineSedative: return "Antihistaminique sédatif"
        case .betaBlocker: return "Bêta-bloquant"
        case .corticosteroid: return "Corticoïde"
        case .opioidAnalgesic: return "Opioïde / antalgique fort"
        case .lateEating: return "Repas tardif"
        case .heavyMeal: return "Repas lourd"
        case .spicyMeal: return "Repas épicé"
        case .highGlycemicEvening: return "Dîner sucré / IG élevé"
        case .hydration: return "Hydratation tardive"
        case .exercise: return "Exercice (journée)"
        case .eveningIntenseExercise: return "Sport intense tardif"
        case .lateNap: return "Sieste tardive"
        case .screenTime: return "Écran avant le lit"
        case .sunExposure: return "Lumière naturelle (jour)"
        case .brightLightEvening: return "Lumière vive le soir"
        case .mindfulness: return "Méditation / relaxation"
        case .hotShowerBeforeBed: return "Douche/bain chaud"
        case .stressLevel: return "Stress"
        case .anxietyLevel: return "Anxiété"
        case .mood: return "Humeur"
        case .rumination: return "Ruminations"
        case .socialJetLag: return "Décalage week-end"
        case .pain: return "Douleur"
        case .illness: return "Maladie / fièvre"
        case .allergySymptoms: return "Allergies"
        case .gerdSymptoms: return "Reflux (brûlures)"
        case .restlessLegs: return "Jambes sans repos"
        case .apneaSymptoms: return "Symptômes d’apnée"
        case .roomTemperature: return "Chambre trop chaude"
        case .noisyEnvironment: return "Bruit"
        case .newEnvironment: return "Lit / lieu inhabituel"
        case .partnerSnoring: return "Ronflement partenaire"
        case .petInBed: return "Animal dans le lit"
        case .poorAirQuality: return "Air sec / pollué"
        case .shiftWork: return "Travail de nuit / posté"
        case .jetLag: return "Jet lag / voyage"
        case .menstrualDiscomfort: return "Gêne menstruelle"
        case .hotFlash: return "Bouffée de chaleur"
        }
    }

    var defaultUnit: String {
        switch self {
        case .caffeine: return "mg"
        case .nicotine, .vapingNicotine: return "mg"
        case .theanine: return "mg"
        case .chocolate: return "g"
        case .energyDrink: return "ml"
        case .alcohol: return "cl"
        case .cannabis: return "g"
        case .cbdOil, .melatonin, .magnesium, .valerian: return "mg"
        case .hydration: return "ml"
        case .exercise, .eveningIntenseExercise, .lateNap, .screenTime, .sunExposure, .mindfulness:
            return "min"
        case .roomTemperature: return "°C"
        case .stressLevel, .anxietyLevel, .mood, .pain, .rumination: return "/10"
        case .lateEating, .heavyMeal, .spicyMeal, .highGlycemicEvening,
             .medicationSleep, .medicationStimulant, .benzodiazepine, .ssri,
             .antihistamineSedative, .betaBlocker, .corticosteroid, .opioidAnalgesic,
             .illness, .allergySymptoms, .gerdSymptoms, .restlessLegs, .apneaSymptoms,
             .noisyEnvironment, .newEnvironment, .partnerSnoring, .petInBed, .poorAirQuality,
             .brightLightEvening, .hotShowerBeforeBed, .socialJetLag, .shiftWork, .jetLag,
             .menstrualDiscomfort, .hotFlash, .otherSubstance:
            return ""
        }
    }

    var sfSymbol: String {
        switch self {
        case .caffeine, .theanine: return "cup.and.saucer.fill"
        case .nicotine, .vapingNicotine: return "smoke.fill"
        case .chocolate: return "square.fill"
        case .energyDrink: return "bolt.fill"
        case .alcohol: return "wineglass.fill"
        case .cannabis, .cbdOil, .valerian, .otherSubstance: return "leaf.fill"
        case .melatonin: return "moon.fill"
        case .magnesium: return "pills.fill"
        case .medicationSleep, .medicationStimulant, .benzodiazepine, .ssri,
             .antihistamineSedative, .betaBlocker, .corticosteroid, .opioidAnalgesic:
            return "cross.vial.fill"
        case .lateEating, .heavyMeal, .spicyMeal, .highGlycemicEvening: return "fork.knife"
        case .hydration: return "drop.fill"
        case .exercise, .eveningIntenseExercise: return "figure.run"
        case .lateNap: return "bed.double.fill"
        case .screenTime, .brightLightEvening: return "iphone"
        case .sunExposure: return "sun.max.fill"
        case .mindfulness: return "brain.head.profile"
        case .hotShowerBeforeBed: return "shower.fill"
        case .stressLevel, .anxietyLevel, .rumination: return "brain.head.profile"
        case .mood: return "face.smiling"
        case .socialJetLag, .jetLag, .shiftWork: return "clock.badge.exclamationmark"
        case .pain, .illness, .restlessLegs: return "cross.case.fill"
        case .allergySymptoms: return "allergens"
        case .gerdSymptoms: return "flame.fill"
        case .apneaSymptoms: return "lungs.fill"
        case .roomTemperature: return "thermometer.medium"
        case .noisyEnvironment, .partnerSnoring: return "speaker.wave.3.fill"
        case .newEnvironment: return "suitcase.fill"
        case .petInBed: return "pawprint.fill"
        case .poorAirQuality: return "aqi.medium"
        case .menstrualDiscomfort, .hotFlash: return "circle.dotted"
        }
    }

    var category: FactorCategory {
        switch self {
        case .caffeine, .nicotine, .vapingNicotine, .theanine, .chocolate, .energyDrink:
            return .stimulant
        case .alcohol, .cannabis, .otherSubstance:
            return .substance
        case .cbdOil, .melatonin, .magnesium, .valerian,
             .medicationSleep, .medicationStimulant, .benzodiazepine, .ssri,
             .antihistamineSedative, .betaBlocker, .corticosteroid, .opioidAnalgesic:
            return .supplement
        case .lateEating, .heavyMeal, .spicyMeal, .highGlycemicEvening, .hydration:
            return .food
        case .exercise, .eveningIntenseExercise, .lateNap, .screenTime, .sunExposure,
             .brightLightEvening, .mindfulness, .hotShowerBeforeBed:
            return .activity
        case .stressLevel, .anxietyLevel, .mood, .rumination, .socialJetLag:
            return .wellbeing
        case .pain, .illness, .allergySymptoms, .gerdSymptoms, .restlessLegs, .apneaSymptoms:
            return .medical
        case .roomTemperature, .noisyEnvironment, .newEnvironment, .partnerSnoring,
             .petInBed, .poorAirQuality:
            return .environment
        case .shiftWork, .jetLag, .menstrualDiscomfort, .hotFlash:
            return .circadian
        }
    }
}

@Model
final class SleepFactor {
    var id: UUID
    var typeRaw: String
    var value: Double
    var unit: String
    var consumedAt: Date
    var hoursBeforeSleep: Double
    var subjectiveImpact: Int?
    var notes: String?
    /// Lien interne routine quotidienne (`routineId` ou `routineId:slot`).
    var routineLinkRaw: String?

    var session: SleepSession?

    var isDailyRoutineEntry: Bool {
        routineLinkRaw != nil || DailyRoutineMarkers.isRoutineMarker(notes)
    }

    var type: FactorType {
        get { FactorType(rawValue: typeRaw) ?? .caffeine }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: FactorType,
        value: Double,
        unit: String? = nil,
        consumedAt: Date = Date(),
        hoursBeforeSleep: Double = 0,
        subjectiveImpact: Int? = nil,
        notes: String? = nil,
        routineLinkRaw: String? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.value = value
        self.unit = unit ?? type.defaultUnit
        self.consumedAt = consumedAt
        self.hoursBeforeSleep = hoursBeforeSleep
        self.subjectiveImpact = subjectiveImpact
        self.notes = notes
        self.routineLinkRaw = routineLinkRaw
    }
}
