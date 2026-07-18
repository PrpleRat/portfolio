import Foundation
import SwiftData

/// Type de phase de sommeil détectée
enum SleepPhaseType: String, Codable, CaseIterable {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    case rem = "rem"

    var displayName: String {
        switch self {
        case .awake: return "Éveil"
        case .light: return "Léger"
        case .deep: return "Profond"
        case .rem: return "REM"
        }
    }

    var chartOrder: Int {
        switch self {
        case .awake: return 0
        case .light: return 1
        case .deep: return 2
        case .rem: return 3
        }
    }

    var colorName: String {
        switch self {
        case .awake: return "phaseAwake"
        case .light: return "phaseLight"
        case .deep: return "phaseDeep"
        case .rem: return "phaseREM"
        }
    }
}

/// Segment de phase enregistré toutes les ~5 minutes
@Model
final class SleepPhase {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var phaseTypeRaw: String
    var movementScore: Double
    var heartRate: Double?

    var session: SleepSession?

    var phaseType: SleepPhaseType {
        get { SleepPhaseType(rawValue: phaseTypeRaw) ?? .light }
        set { phaseTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        phaseType: SleepPhaseType,
        movementScore: Double = 0,
        heartRate: Double? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.phaseTypeRaw = phaseType.rawValue
        self.movementScore = movementScore
        self.heartRate = heartRate
    }

    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}
