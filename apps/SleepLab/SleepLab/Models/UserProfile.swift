import Foundation
import SwiftData

enum BiologicalSex: String, Codable, CaseIterable {
    case male, female, other

    var displayName: String {
        switch self {
        case .male: return "Homme"
        case .female: return "Femme"
        case .other: return "Autre"
        }
    }
}

enum Chronotype: String, Codable, CaseIterable {
    case earlyBird, neutral, nightOwl

    var displayName: String {
        switch self {
        case .earlyBird: return "Lève-tôt"
        case .neutral: return "Neutre"
        case .nightOwl: return "Couche-tard"
        }
    }
}

@Model
final class UserProfile {
    var birthDate: Date?
    var biologicalSexRaw: String
    var weight: Double?
    var height: Double?

    var chronicConditionsData: String
    var medicationsData: String
    var hasApneaDiagnosed: Bool

    /// Enregistrer des extraits audio la nuit (désactivé par défaut — confidentialité).
    var storeNightAudioClips: Bool
    var tracksMenstrualCycle: Bool
    var averageCycleLength: Int
    var averagePeriodLength: Int?
    var lastPeriodStart: Date?

    var targetSleepDuration: Double
    var targetBedtimeHour: Int
    var targetBedtimeMinute: Int
    /// Ne pas recommander un coucher avant cette heure (ex. 22:30).
    var minimumBedtimeHour: Int = 22
    var minimumBedtimeMinute: Int = 30
    var chronotypeRaw: String
    var caffeineMetabolism: Int

    /// 1.0 = défaut. >1 = plus sensible aux micro-mouvements (moins de profond estimé).
    var motionThresholdScale: Double = 1.0

    var biologicalSex: BiologicalSex {
        get { BiologicalSex(rawValue: biologicalSexRaw) ?? .other }
        set { biologicalSexRaw = newValue.rawValue }
    }

    var chronotype: Chronotype {
        get { Chronotype(rawValue: chronotypeRaw) ?? .neutral }
        set { chronotypeRaw = newValue.rawValue }
    }

    var chronicConditions: [String] {
        get { chronicConditionsData.split(separator: "|").map(String.init).filter { !$0.isEmpty } }
        set { chronicConditionsData = newValue.joined(separator: "|") }
    }

    var medications: [String] {
        get { medicationsData.split(separator: "|").map(String.init).filter { !$0.isEmpty } }
        set { medicationsData = newValue.joined(separator: "|") }
    }

    var targetBedtime: Date? {
        get {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            c.hour = targetBedtimeHour
            c.minute = targetBedtimeMinute
            return Calendar.current.date(from: c)
        }
        set {
            guard let d = newValue else { return }
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            targetBedtimeHour = c.hour ?? 23
            targetBedtimeMinute = c.minute ?? 0
        }
    }

    var minimumBedtime: Date {
        get {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            c.hour = minimumBedtimeHour
            c.minute = minimumBedtimeMinute
            return Calendar.current.date(from: c) ?? Date()
        }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            minimumBedtimeHour = c.hour ?? 22
            minimumBedtimeMinute = c.minute ?? 30
        }
    }

    init() {
        biologicalSexRaw = BiologicalSex.other.rawValue
        chronicConditionsData = ""
        medicationsData = ""
        hasApneaDiagnosed = false
        storeNightAudioClips = false
        tracksMenstrualCycle = false
        averageCycleLength = 28
        averagePeriodLength = 5
        targetSleepDuration = 8
        targetBedtimeHour = 23
        targetBedtimeMinute = 0
        minimumBedtimeHour = 22
        minimumBedtimeMinute = 30
        chronotypeRaw = Chronotype.neutral.rawValue
        caffeineMetabolism = 3
        motionThresholdScale = 1.0
    }

    var effectivePeriodLength: Int {
        get { averagePeriodLength ?? 5 }
        set { averagePeriodLength = newValue }
    }

    /// Jour du cycle (1+) si suivi activé
    func currentCycleDay(on date: Date = Date()) -> Int? {
        guard tracksMenstrualCycle, let start = lastPeriodStart else { return nil }
        let days = Calendar.current.dateComponents([.day], from: start, to: date).day ?? 0
        let day = (days % averageCycleLength) + 1
        return max(1, day)
    }

    enum MenstrualPhase: String {
        case menstrual, follicular, ovulation, luteal

        var displayName: String {
            switch self {
            case .menstrual: return "Menstruelle"
            case .follicular: return "Folliculaire"
            case .ovulation: return "Ovulation"
            case .luteal: return "Lutéale"
            }
        }
    }

    func menstrualPhase(for cycleDay: Int) -> MenstrualPhase {
        switch cycleDay {
        case 1...5: return .menstrual
        case 6...13: return .follicular
        case 14...16: return .ovulation
        default: return .luteal
        }
    }

    /// Ajustement moyen constaté du besoin de sommeil selon sexe biologique.
    /// L'objectif personnalisé de l'utilisatrice/utilisateur reste prioritaire.
    var biologicalSleepNeedAdjustmentHours: Double {
        switch biologicalSex {
        case .female: return 0.35
        case .male: return 0.0
        case .other: return 0.15
        }
    }
}
