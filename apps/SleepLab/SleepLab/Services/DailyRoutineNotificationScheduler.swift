import Foundation
import UserNotifications

/// Rappels prises quotidiennes : créneaux matin/midi/soir, relance unique +2 h si oubli.
enum DailyRoutineNotificationScheduler {
    private static let prefix = "noctavia.dailyRoutine"
    private static let followUpSuffix = ".followup"
    private static let missedSuffix = ".missed"
    /// Délai après l’heure prévue avant relance « oublié ? »
    private static let followUpDelay: TimeInterval = 2 * 3600

    @MainActor
    static func refreshForDay(
        day: Date,
        routines: [DailySubstanceRoutine],
        allFactors: [SleepFactor],
        dayLogs: [DailyRoutineDayLog] = []
    ) {
        let center = UNUserNotificationCenter.current()
        let dayKey = dayStamp(day)
        var ids: [String] = []
        for routine in routines {
            routine.ensureDefaultSlots()
            for slot in routine.enabledSlots() {
                ids.append(identifier(routineId: routine.id, slotId: slot.id, dayKey: dayKey))
                ids.append(identifier(routineId: routine.id, slotId: slot.id, dayKey: dayKey) + followUpSuffix)
                ids.append(identifier(routineId: routine.id, slotId: slot.id, dayKey: dayKey) + missedSuffix)
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        Task {
            let status = await AppPermissions.notificationStatus()
            if status == .notDetermined {
                _ = await AppPermissions.requestNotifications()
            }
            let refreshedStatus = await AppPermissions.notificationStatus()
            guard refreshedStatus == .authorized || refreshedStatus == .provisional else { return }

            for routine in routines where routine.isActive {
                if isIntentionallySkipped(routine: routine, day: day, dayLogs: dayLogs) { continue }

                routine.ensureDefaultSlots()
                for slot in routine.enabledSlots() {
                    if hasTaken(routine: routine, slot: slot, on: day, factors: allFactors) { continue }

                    let scheduled = slot.scheduledDate(on: day)
                    let primaryWhen = slot.reminderDate(on: day)
                    if primaryWhen > Date() {
                        schedule(
                            id: identifier(routineId: routine.id, slotId: slot.id, dayKey: dayKey),
                            title: "Rappel \(slot.slot.displayName.lowercased())",
                            body: "\(routine.type.displayName) — \(reminderLabel(slot: slot, scheduled: scheduled)).",
                            at: primaryWhen
                        )
                    }

                    let followUpWhen = scheduled.addingTimeInterval(followUpDelay)
                    if followUpWhen > Date() {
                        schedule(
                            id: identifier(routineId: routine.id, slotId: slot.id, dayKey: dayKey) + followUpSuffix,
                            title: "Oublié de prendre ?",
                            body: "\(routine.type.displayName) était prévu vers \(timeString(scheduled)). Une seule relance — coche quand c’est fait.",
                            at: followUpWhen
                        )
                    }
                }
            }
        }
    }

    @MainActor
    static func scheduleBedtimeReminder(recommendation: BedtimeAdvisor.BedtimeRecommendation) {
        let center = UNUserNotificationCenter.current()
        let id = "\(prefix).bedtime"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard recommendation.idealBedtime > Date() else { return }

        Task {
            let status = await AppPermissions.notificationStatus()
            guard status == .authorized || status == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = "Coucher idéal"
            content.body = recommendation.message
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: recommendation.idealBedtime.addingTimeInterval(-45 * 60)
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(
                UNNotificationRequest(identifier: id, content: content, trigger: trigger),
                withCompletionHandler: nil
            )
        }
    }

    private static func schedule(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger),
            withCompletionHandler: nil
        )
    }

    private static func isIntentionallySkipped(
        routine: DailySubstanceRoutine,
        day: Date,
        dayLogs: [DailyRoutineDayLog]
    ) -> Bool {
        let start = Calendar.current.startOfDay(for: day)
        return dayLogs.contains {
            $0.routineId == routine.id
                && Calendar.current.isDate($0.dayStart, inSameDayAs: start)
                && $0.status == .intentionalSkip
        }
    }

    private static func hasTaken(
        routine: DailySubstanceRoutine,
        slot: DailyRoutineSlot,
        on day: Date,
        factors: [SleepFactor]
    ) -> Bool {
        let link = DailyRoutineMarkers.linkKey(routineId: routine.id, slot: slot.slot)
        return factors.contains { factor in
            Calendar.current.isDate(factor.consumedAt, inSameDayAs: day)
                && !DailyRoutineMarkers.isSkipped(factor)
                && (
                    factor.routineLinkRaw == link
                        || DailyRoutineMarkers.matchesRoutine(factor, routineId: routine.id, slot: slot.slot)
                )
        }
    }

    private static func reminderLabel(slot: DailyRoutineSlot, scheduled: Date) -> String {
        let base = timeString(scheduled)
        let mins = slot.reminderOffsetMinutes
        switch slot.reminderTiming {
        case .before: return "rappel \(mins) min avant (\(base))"
        case .atTime: return "rappel à l’heure (\(base))"
        case .after: return "rappel \(mins) min après (\(base))"
        }
    }

    private static func identifier(routineId: UUID, slotId: UUID, dayKey: String) -> String {
        "\(prefix).\(routineId.uuidString).\(slotId.uuidString).\(dayKey)"
    }

    private static func dayStamp(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private static func timeString(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
