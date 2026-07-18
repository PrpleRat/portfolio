import Foundation
import SwiftData

enum DailyRoutineReminderTiming: String, Codable, CaseIterable {
    case before
    case atTime
    case after

    var displayName: String {
        switch self {
        case .before: return "X min avant"
        case .atTime: return "À l’heure"
        case .after: return "X min après"
        }
    }
}

@Model
final class DailySubstanceRoutine {
    var id: UUID
    var typeRaw: String
    var defaultValue: Double
    var hour: Int
    var minute: Int
    var isActive: Bool
    var notes: String?
    var reminderTimingRaw: String
    var reminderOffsetMinutes: Int

    @Relationship(deleteRule: .cascade, inverse: \DailyRoutineSlot.routine)
    var slots: [DailyRoutineSlot]?

    var type: FactorType {
        get { FactorType(rawValue: typeRaw) ?? .ssri }
        set { typeRaw = newValue.rawValue }
    }

    var reminderTiming: DailyRoutineReminderTiming {
        get { DailyRoutineReminderTiming(rawValue: reminderTimingRaw) ?? .after }
        set { reminderTimingRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: FactorType,
        defaultValue: Double = 1,
        hour: Int = 8,
        minute: Int = 0,
        isActive: Bool = true,
        notes: String? = nil,
        reminderTiming: DailyRoutineReminderTiming = .after,
        reminderOffsetMinutes: Int = 45
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.defaultValue = defaultValue
        self.hour = hour
        self.minute = minute
        self.isActive = isActive
        self.notes = notes
        self.reminderTimingRaw = reminderTiming.rawValue
        self.reminderOffsetMinutes = max(0, reminderOffsetMinutes)
        self.slots = []
    }

    /// Créneaux actifs (matin / midi / soir). Migre depuis l’heure unique si besoin.
    func enabledSlots() -> [DailyRoutineSlot] {
        if let slots, !slots.isEmpty {
            return slots.filter(\.isEnabled).sorted { $0.slot.sortOrder < $1.slot.sortOrder }
        }
        let legacy = DailyRoutineSlot(
            slot: .evening,
            hour: hour,
            minute: minute,
            isEnabled: true,
            reminderTiming: reminderTiming,
            reminderOffsetMinutes: reminderOffsetMinutes
        )
        return [legacy]
    }

    func ensureDefaultSlots() {
        if slots == nil { slots = [] }
        guard slots?.isEmpty == true else { return }
        let evening = DailyRoutineSlot(
            slot: .evening,
            hour: hour,
            minute: minute,
            isEnabled: true,
            reminderTiming: reminderTiming,
            reminderOffsetMinutes: reminderOffsetMinutes
        )
        evening.routine = self
        slots?.append(evening)
    }

    func scheduledDate(on day: Date) -> Date {
        enabledSlots().first?.scheduledDate(on: day)
            ?? Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day)
            ?? day
    }

    func reminderDate(on day: Date) -> Date {
        enabledSlots().first?.reminderDate(on: day) ?? scheduledDate(on: day)
    }
}

extension RoutineSlotKind {
    var sortOrder: Int {
        switch self {
        case .morning: return 0
        case .noon: return 1
        case .evening: return 2
        }
    }
}

enum DailyRoutineMarkers {
    static func linkKey(routineId: UUID, slot: RoutineSlotKind) -> String {
        "\(routineId.uuidString):\(slot.rawValue)"
    }

    static func legacyTakenMarker(routineId: UUID, slot: RoutineSlotKind? = nil) -> String {
        if let slot {
            return "__routine:\(routineId.uuidString):\(slot.rawValue)"
        }
        return "__routine:\(routineId.uuidString)"
    }

    static func legacySkippedMarker(routineId: UUID) -> String {
        "__skipped:\(routineId.uuidString)"
    }

    static func matchesRoutine(_ factor: SleepFactor, routineId: UUID, slot: RoutineSlotKind? = nil) -> Bool {
        if let link = factor.routineLinkRaw {
            if link.hasPrefix("\(routineId.uuidString)") {
                if let slot {
                    return link == linkKey(routineId: routineId, slot: slot)
                }
                return true
            }
            return false
        }
        guard let notes = factor.notes else { return false }
        if let slot {
            return notes.contains(legacyTakenMarker(routineId: routineId, slot: slot))
                || notes.contains(legacyTakenMarker(routineId: routineId))
        }
        return notes.contains("__routine:\(routineId.uuidString)")
            || notes.contains(legacySkippedMarker(routineId: routineId))
    }

    static func isSkipped(_ factor: SleepFactor) -> Bool {
        factor.notes?.contains("__skipped:") == true
    }

    static func isRoutineMarker(_ notes: String?) -> Bool {
        guard let notes, !notes.isEmpty else { return false }
        return notes.contains("__routine:") || notes.contains("__skipped:")
    }

    /// Texte affiché à l’utilisateur (sans identifiants internes).
    static func userFacingNotes(_ notes: String?) -> String? {
        guard let notes, !notes.isEmpty else { return nil }
        let cleaned = notes
            .split(separator: " ")
            .filter { token in
                let s = String(token)
                return !s.hasPrefix("__routine:") && !s.hasPrefix("__skipped:")
            }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    /// Migre les anciennes notes contenant un marqueur vers `routineLinkRaw`.
    static func migrateLegacyMarkerIfNeeded(_ factor: SleepFactor, routineId: UUID, slot: RoutineSlotKind) {
        guard factor.routineLinkRaw == nil, let notes = factor.notes else { return }
        let key = linkKey(routineId: routineId, slot: slot)
        if notes.contains(legacyTakenMarker(routineId: routineId, slot: slot))
            || notes.contains(legacyTakenMarker(routineId: routineId)) {
            factor.routineLinkRaw = key
            factor.notes = userFacingNotes(notes)
        }
    }
}

extension DailySubstanceRoutine: Identifiable {}
