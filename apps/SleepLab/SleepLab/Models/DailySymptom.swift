import Foundation
import SwiftData

/// Humeur rapide du jour (symptômes cycle).
enum DailyMood: String, Codable, CaseIterable, Identifiable {
    case low, neutral, high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Bas"
        case .neutral: return "Neutre"
        case .high: return "Bien"
        }
    }

    var sfSymbol: String {
        switch self {
        case .low: return "cloud.rain.fill"
        case .neutral: return "minus.circle"
        case .high: return "sun.max.fill"
        }
    }
}

/// Symptômes quotidiens liés au cycle, rattachés au calendrier (nuits du même jour).
@Model
final class DailySymptom {
    var id: UUID
    /// Début de journée civile (00:00 locale).
    var dayStart: Date
    var hotFlash: Bool
    var cramps: Bool
    var moodRaw: String
    var updatedAt: Date

    var mood: DailyMood {
        get { DailyMood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    init(dayStart: Date = Calendar.current.startOfDay(for: Date()), mood: DailyMood = .neutral) {
        id = UUID()
        self.dayStart = Calendar.current.startOfDay(for: dayStart)
        hotFlash = false
        cramps = false
        moodRaw = mood.rawValue
        updatedAt = Date()
    }

    func touch() {
        updatedAt = Date()
    }
}

extension DailySymptom: Identifiable {}
