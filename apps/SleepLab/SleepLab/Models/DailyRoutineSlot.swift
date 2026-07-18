import Foundation
import SwiftData

enum RoutineSlotKind: String, Codable, CaseIterable, Identifiable {
    case morning
    case noon
    case evening

    var displayName: String {
        switch self {
        case .morning: return "Matin"
        case .noon: return "Midi"
        case .evening: return "Soir"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var id: String { rawValue }
}

@Model
final class DailyRoutineSlot {
    var id: UUID
    var slotRaw: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    var reminderTimingRaw: String
    var reminderOffsetMinutes: Int

    var routine: DailySubstanceRoutine?

    var slot: RoutineSlotKind {
        get { RoutineSlotKind(rawValue: slotRaw) ?? .evening }
        set { slotRaw = newValue.rawValue }
    }

    var reminderTiming: DailyRoutineReminderTiming {
        get { DailyRoutineReminderTiming(rawValue: reminderTimingRaw) ?? .after }
        set { reminderTimingRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        slot: RoutineSlotKind,
        hour: Int = 8,
        minute: Int = 0,
        isEnabled: Bool = true,
        reminderTiming: DailyRoutineReminderTiming = .after,
        reminderOffsetMinutes: Int = 45
    ) {
        self.id = id
        self.slotRaw = slot.rawValue
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.reminderTimingRaw = reminderTiming.rawValue
        self.reminderOffsetMinutes = max(0, reminderOffsetMinutes)
    }

    func scheduledDate(on day: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: day)
        c.hour = hour
        c.minute = minute
        c.second = 0
        return Calendar.current.date(from: c) ?? day
    }

    func reminderDate(on day: Date) -> Date {
        let base = scheduledDate(on: day)
        switch reminderTiming {
        case .before:
            return base.addingTimeInterval(-Double(reminderOffsetMinutes) * 60)
        case .atTime:
            return base
        case .after:
            return base.addingTimeInterval(Double(reminderOffsetMinutes) * 60)
        }
    }
}
