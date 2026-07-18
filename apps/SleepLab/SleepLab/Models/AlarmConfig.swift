import Foundation
import SwiftData
import UserNotifications

enum AlarmSound: String, Codable, CaseIterable, Identifiable {
    case rain
    case bowl
    case birds
    case ocean
    case gentlePiano

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Pluie"
        case .bowl: return "Bol tibétain"
        case .birds: return "Oiseaux"
        case .ocean: return "Océan"
        case .gentlePiano: return "Piano doux"
        }
    }

    /// Nom du fichier sans extension dans Resources/Sounds
    var fileName: String {
        switch self {
        case .rain: return "rain"
        case .bowl: return "bowl"
        case .birds: return "birds"
        case .ocean: return "ocean"
        case .gentlePiano: return "gentle_piano"
        }
    }

    /// Fichier pour notification locale iOS (≤ 30 s, .wav dans le bundle).
    var notificationWavName: String {
        "\(fileName).wav"
    }

    var sfSymbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .bowl: return "bell.fill"
        case .birds: return "bird.fill"
        case .ocean: return "water.waves"
        case .gentlePiano: return "pianokeys"
        }
    }

    var bundleURL: URL? {
        if let u = Bundle.main.url(forResource: fileName, withExtension: "mp3") { return u }
        if let u = Bundle.main.url(forResource: fileName, withExtension: "wav") { return u }
        if let u = Bundle.main.url(forResource: fileName, withExtension: "caf") { return u }
        return nil
    }

    /// Son pour notification locale (hors MainActor).
    func notificationUNSound() -> UNNotificationSound {
        let wavName = notificationWavName
        if Bundle.main.url(forResource: fileName, withExtension: "wav") != nil {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: wavName))
        }
        if Bundle.main.url(forResource: fileName, withExtension: "caf") != nil {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(fileName).caf"))
        }
        return .default
    }

    init?(filename: String) {
        if let match = AlarmSound.allCases.first(where: { $0.fileName == filename }) {
            self = match
        } else {
            return nil
        }
    }

    /// Migration anciens sons
    static func migrated(from raw: String) -> AlarmSound {
        switch raw {
        case "birdsong": return .birds
        case "tibetanBowl", "tibetan_bowl": return .bowl
        case "gentlePiano", "gentle_piano": return .gentlePiano
        default: return AlarmSound(rawValue: raw) ?? .rain
        }
    }
}

@Model
final class AlarmConfig {
    var isEnabled: Bool
    var targetWakeHour: Int
    var targetWakeMinute: Int
    var windowMinutes: Int
    var soundRaw: String
    var progressiveVolume: Bool
    var progressiveDurationSeconds: Int

    var sound: AlarmSound {
        get { AlarmSound.migrated(from: soundRaw) }
        set { soundRaw = newValue.rawValue }
    }

    /// Heure de réveil sur le calendrier « aujourd’hui » (réglages UI uniquement).
    var targetWakeTime: Date {
        get {
            nextWakeTime(relativeTo: Date())
        }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            targetWakeHour = c.hour ?? 7
            targetWakeMinute = c.minute ?? 0
        }
    }

    /// Prochaine occurrence future de l’heure configurée (ex. 23h → réveil 7h = lendemain 7h).
    func nextWakeTime(relativeTo reference: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: reference)
        components.hour = targetWakeHour
        components.minute = targetWakeMinute
        components.second = 0
        guard var candidate = calendar.date(from: components) else { return reference }
        if candidate <= reference {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    init() {
        isEnabled = true
        targetWakeHour = 7
        targetWakeMinute = 0
        windowMinutes = 20
        soundRaw = AlarmSound.rain.rawValue
        progressiveVolume = true
        progressiveDurationSeconds = 60
    }
}
