import Foundation

enum PhonePosition: String, CaseIterable, Codable {
    case mattress
    case nightstand
    case wallCharger

    var displayName: String {
        switch self {
        case .mattress: return "Sur le matelas"
        case .nightstand: return "Sur la table de nuit"
        case .wallCharger: return "Prise murale / chargeur"
        }
    }

    var sfSymbol: String {
        switch self {
        case .mattress: return "bed.double.fill"
        case .nightstand: return "table.furniture.fill"
        case .wallCharger: return "bolt.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .mattress: return "Écran vers le bas, au centre du lit"
        case .nightstand: return "À côté du lit, téléphone fixe"
        case .wallCharger: return "Vertical, peu de vibrations du matelas"
        }
    }

    /// Facteur de sensibilité pour le seuil adaptatif.
    var sensitivityFactor: Double {
        switch self {
        case .mattress: return 1.0
        case .nightstand: return 3.5
        case .wallCharger: return 5.0
        }
    }
}

enum WakeQuality: String, Codable {
    case rough
    case normal
    case rested

    var displayName: String {
        switch self {
        case .rough: return "Difficile"
        case .normal: return "Normal"
        case .rested: return "Reposé"
        }
    }
}

/// Calibrage accéléromètre optionnel — UserDefaults uniquement, on-device.
@MainActor
@Observable
final class SleepCalibrationManager {
    static let shared = SleepCalibrationManager()

    private enum Keys {
        static let phonePosition = "sleeplab.cal.phonePosition"
        static let awakeBaseline = "sleeplab.cal.awakeBaseline"
        static let multiplier = "sleeplab.cal.multiplier"
        static let nightCount = "sleeplab.cal.nightCount"
        static let isCalibrated = "sleeplab.cal.isCalibrated"
        static let nightHistory = "sleeplab.cal.nightHistory"
    }

    private static let defaultBaseline = 0.06
    private static let multiplierStep = 0.05
    private static let maxFeedbackNights = 14

    private let defaults: UserDefaults

    var phonePosition: PhonePosition {
        didSet { defaults.set(phonePosition.rawValue, forKey: Keys.phonePosition) }
    }

    var awakeVarianceBaseline: Double {
        didSet { defaults.set(awakeVarianceBaseline, forKey: Keys.awakeBaseline) }
    }

    var movementThresholdMultiplier: Double {
        didSet { persistMultiplier() }
    }

    var calibrationNightCount: Int {
        didSet { defaults.set(calibrationNightCount, forKey: Keys.nightCount) }
    }

    var isCalibrated: Bool {
        didSet { defaults.set(isCalibrated, forKey: Keys.isCalibrated) }
    }

    private(set) var nightVarianceHistory: [Double] {
        didSet { defaults.set(nightVarianceHistory, forKey: Keys.nightHistory) }
    }

    var shouldShowMorningFeedback: Bool {
        calibrationNightCount < Self.maxFeedbackNights
    }

    /// Seuil adaptatif : baseline × multiplicateur × position.
    var effectiveMovementThreshold: Double {
        let base = awakeVarianceBaseline > 0 ? awakeVarianceBaseline : Self.defaultBaseline
        let factor = phonePosition.sensitivityFactor
        return max(0.02, base * movementThresholdMultiplier * factor)
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let rawPosition = defaults.string(forKey: Keys.phonePosition) ?? PhonePosition.mattress.rawValue
        phonePosition = PhonePosition(rawValue: rawPosition) ?? .mattress
        awakeVarianceBaseline = defaults.object(forKey: Keys.awakeBaseline) as? Double ?? Self.defaultBaseline
        movementThresholdMultiplier = Self.clampMultiplier(
            defaults.object(forKey: Keys.multiplier) as? Double ?? 1.0
        )
        calibrationNightCount = defaults.integer(forKey: Keys.nightCount)
        isCalibrated = defaults.bool(forKey: Keys.isCalibrated)
        nightVarianceHistory = defaults.array(forKey: Keys.nightHistory) as? [Double] ?? []
    }

    private func persistMultiplier() {
        movementThresholdMultiplier = Self.clampMultiplier(movementThresholdMultiplier)
        defaults.set(movementThresholdMultiplier, forKey: Keys.multiplier)
    }

    func completeAwakeMeasurement(baseline: Double) {
        awakeVarianceBaseline = max(0.02, baseline)
        isCalibrated = true
    }

    func recordFeedback(_ quality: WakeQuality) {
        switch quality {
        case .rough:
            movementThresholdMultiplier += Self.multiplierStep
        case .rested:
            movementThresholdMultiplier -= Self.multiplierStep
        case .normal:
            break
        }
        movementThresholdMultiplier = Self.clampMultiplier(movementThresholdMultiplier)
    }

    /// Moyenne mobile pondérée sur 7 nuits (dernière = 40 %).
    func updateBaselineFromNight(_ samples: [Double]) {
        guard !samples.isEmpty else { return }
        let nightMean = samples.reduce(0, +) / Double(samples.count)
        var history = nightVarianceHistory
        history.append(nightMean)
        if history.count > 7 {
            history.removeFirst(history.count - 7)
        }
        nightVarianceHistory = history
        awakeVarianceBaseline = weightedAverage(history)
        calibrationNightCount += 1
    }

    func resetCalibration() {
        phonePosition = .mattress
        awakeVarianceBaseline = Self.defaultBaseline
        movementThresholdMultiplier = 1.0
        calibrationNightCount = 0
        isCalibrated = false
        nightVarianceHistory = []
    }

    /// Restauration depuis export JSON.
    func restoreFromBackup(
        phonePosition: PhonePosition,
        awakeVarianceBaseline: Double,
        movementThresholdMultiplier: Double,
        calibrationNightCount: Int,
        isCalibrated: Bool,
        nightVarianceHistory: [Double]
    ) {
        self.phonePosition = phonePosition
        self.awakeVarianceBaseline = awakeVarianceBaseline
        self.movementThresholdMultiplier = movementThresholdMultiplier
        self.calibrationNightCount = calibrationNightCount
        self.isCalibrated = isCalibrated
        self.nightVarianceHistory = nightVarianceHistory
    }

    private func weightedAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return Self.defaultBaseline }
        if values.count == 1 { return values[0] }
        let recent = values[values.count - 1]
        let older = values.dropLast()
        let olderWeight = 0.6 / Double(older.count)
        var sum = recent * 0.4
        for value in older {
            sum += value * olderWeight
        }
        return max(0.02, sum)
    }

    private static func clampMultiplier(_ value: Double) -> Double {
        min(2.0, max(0.5, value))
    }
}
