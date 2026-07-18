import Foundation
import SwiftData

/// Intensité du flux (jour de règles).
enum MenstrualFlowIntensity: String, Codable, CaseIterable, Hashable {
    case spotting, light, medium, heavy

    var displayName: String {
        switch self {
        case .spotting: return "Spotting"
        case .light: return "Léger"
        case .medium: return "Moyen"
        case .heavy: return "Abondant"
        }
    }

    var shortLabel: String {
        switch self {
        case .spotting: return "•"
        case .light: return "○"
        case .medium: return "●"
        case .heavy: return "●●"
        }
    }
}

/// Jour de règles renseigné par l'utilisatrice (calendrier in-app).
@Model
final class PeriodDayLog {
    var id: UUID
    /// Début de journée civile (00:00 locale).
    var dayStart: Date
    var flowIntensityRaw: String
    var updatedAt: Date

    var flowIntensity: MenstrualFlowIntensity {
        get { MenstrualFlowIntensity(rawValue: flowIntensityRaw) ?? .medium }
        set { flowIntensityRaw = newValue.rawValue }
    }

    init(dayStart: Date, flow: MenstrualFlowIntensity = .medium) {
        id = UUID()
        self.dayStart = Calendar.current.startOfDay(for: dayStart)
        flowIntensityRaw = flow.rawValue
        updatedAt = Date()
    }

    func touch() {
        updatedAt = Date()
    }
}

extension PeriodDayLog: Identifiable {}
