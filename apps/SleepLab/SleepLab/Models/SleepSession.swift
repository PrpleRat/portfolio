import Foundation
import SwiftData

@Model
final class SleepSession: Identifiable {
    var id: UUID
    var kindRaw: String = SleepSessionKind.night.rawValue
    var startTime: Date
    var endTime: Date?
    var totalDuration: TimeInterval

    var awakenings: Int

    var overallScore: Int
    var efficiencyScore: Int
    var deepSleepMinutes: Int
    var remSleepMinutes: Int
    var lightSleepMinutes: Int

    var avgHeartRate: Double?
    var minHeartRate: Double?
    var avgHRV: Double?
    var avgSPO2: Double?
    var respiratoryRate: Double?
    var restingHeartRate: Double?

    var snoringMinutes: Int
    var loudestEvent: Double?

    var nightTemperature: Double?
    var humidity: Double?
    var pressure: Double?

    var alarmTime: Date?
    var actualWakeTime: Date?
    var wakePhaseRaw: String?

    var cycleDay: Int?

    /// Saisie manuelle (historique) — modifiable dans l’app.
    var isManuallyEntered: Bool = false
    /// Nombre de pauses « réveil nocturne » pendant le tracking (une seule nuit).
    var pauseCount: Int = 0
    /// Temps éveillé entre fragments (app tuée, reprise) — exclu de `totalDuration`.
    var excludedPauseDuration: TimeInterval = 0

    @Relationship(deleteRule: .cascade, inverse: \SleepPhase.session)
    var phases: [SleepPhase]

    @Relationship(deleteRule: .cascade, inverse: \SoundEvent.session)
    var soundEvents: [SoundEvent]

    @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session)
    var snoreEvents: [SnoreEvent]

    @Relationship(deleteRule: .cascade, inverse: \SleepFactor.session)
    var factors: [SleepFactor]

    var wakePhase: SleepPhaseType? {
        get {
            guard let raw = wakePhaseRaw else { return nil }
            return SleepPhaseType(rawValue: raw)
        }
        set { wakePhaseRaw = newValue?.rawValue }
    }

    var kind: SleepSessionKind {
        get { SleepSessionKind(rawValue: kindRaw) ?? .night }
        set { kindRaw = newValue.rawValue }
    }

    init(startTime: Date = Date(), kind: SleepSessionKind = .night) {
        id = UUID()
        kindRaw = kind.rawValue
        self.startTime = startTime
        endTime = nil
        totalDuration = 0
        awakenings = 0
        overallScore = 0
        efficiencyScore = 0
        deepSleepMinutes = 0
        remSleepMinutes = 0
        lightSleepMinutes = 0
        snoringMinutes = 0
        phases = []
        soundEvents = []
        snoreEvents = []
        factors = []
    }

    /// Durée totale de ronflement détectée (Core ML), en secondes.
    var totalSnoreDuration: TimeInterval {
        snoreEvents.reduce(0) { $0 + $1.duration }
    }

    /// Plafond réaliste pour l’affichage (évite les surestimations en bêta).
    var cappedSnoreDuration: TimeInterval {
        guard totalDuration > 0 else { return totalSnoreDuration }
        let maxAllowed = totalDuration * 0.35
        return min(totalSnoreDuration, maxAllowed)
    }

    var snorePercentOfNight: Double {
        guard totalDuration > 0 else { return 0 }
        return min(100, (cappedSnoreDuration / totalDuration) * 100)
    }

    func recalculateSnoreMinutes() {
        snoringMinutes = max(0, Int(ceil(cappedSnoreDuration / 60)))
    }

    func finalize(at end: Date = Date()) {
        endTime = end
        let raw = end.timeIntervalSince(startTime)
        totalDuration = max(60, raw - excludedPauseDuration)
        recalculatePhaseMinutes()
    }

    /// Rouvre une nuit finalisée (ex. app tuée puis reprise le même matin).
    func reopenForContinuation(now: Date = Date()) {
        if let end = endTime {
            let gap = now.timeIntervalSince(end)
            if gap > 0 {
                excludedPauseDuration += gap
                pauseCount += 1
            }
        }
        endTime = nil
        actualWakeTime = nil
    }

    func recalculatePhaseMinutes() {
        deepSleepMinutes = 0
        remSleepMinutes = 0
        lightSleepMinutes = 0
        for phase in phases {
            let mins = Int(phase.duration / 60)
            switch phase.phaseType {
            case .deep: deepSleepMinutes += mins
            case .rem: remSleepMinutes += mins
            case .light: lightSleepMinutes += mins
            case .awake: break
            }
        }
    }
}
