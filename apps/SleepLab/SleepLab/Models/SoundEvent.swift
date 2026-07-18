import Foundation
import SwiftData

enum SoundType: String, Codable, CaseIterable {
    case snoring, coughing, talking, breathing, environmentalNoise, unknown

    var displayName: String {
        switch self {
        case .snoring: return "Ronflement"
        case .coughing: return "Toux"
        case .talking: return "Parole"
        case .breathing: return "Respiration"
        case .environmentalNoise: return "Bruit extérieur"
        case .unknown: return "Inconnu"
        }
    }

    var sfSymbol: String {
        switch self {
        case .snoring: return "waveform"
        case .coughing: return "lungs.fill"
        case .talking: return "mouth.fill"
        case .breathing: return "wind"
        case .environmentalNoise: return "car.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

@Model
final class SoundEvent {
    var id: UUID
    var timestamp: Date
    var typeRaw: String
    var decibelLevel: Double
    var duration: TimeInterval
    var clipFileName: String?

    var session: SleepSession?

    var soundType: SoundType {
        get { SoundType(rawValue: typeRaw) ?? .unknown }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date,
        soundType: SoundType,
        decibelLevel: Double,
        duration: TimeInterval = 1,
        clipFileName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.typeRaw = soundType.rawValue
        self.decibelLevel = decibelLevel
        self.duration = duration
        self.clipFileName = clipFileName
    }
}
