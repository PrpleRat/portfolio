import Foundation
import SwiftData

enum DailyRoutineDayStatusKind: String, Codable {
    case taken
    case missed
    case intentionalSkip

    var displayName: String {
        switch self {
        case .taken: return "Pris"
        case .missed: return "Oublié"
        case .intentionalSkip: return "Pas pris (volontaire)"
        }
    }
}

/// État d’une routine sur un jour (prise, oubli, skip volontaire).
@Model
final class DailyRoutineDayLog {
    var id: UUID
    var routineId: UUID
    var dayStart: Date
    var statusRaw: String

    var status: DailyRoutineDayStatusKind {
        get { DailyRoutineDayStatusKind(rawValue: statusRaw) ?? .missed }
        set { statusRaw = newValue.rawValue }
    }

    init(routineId: UUID, day: Date, status: DailyRoutineDayStatusKind) {
        self.id = UUID()
        self.routineId = routineId
        self.dayStart = Calendar.current.startOfDay(for: day)
        self.statusRaw = status.rawValue
    }
}
