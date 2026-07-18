import Foundation
import UserNotifications

actor NotificationScheduler {

    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        do {
            // Pas de .criticalAlert — nécessite entitlement + approbation Apple (voir docs/TESTFLIGHT.md)
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleSession(_ session: SafeSession) async {
        await cancelSession(session)
        guard session.isActive else { return }

        let intervalSeconds = TimeInterval(session.intervalMinutes * 60)
        let warningSeconds = TimeInterval(AppConstants.warningWindowMinutes * 60)
        let graceSeconds = TimeInterval(AppConstants.gracePeriodMinutes * 60)

        let lastCheckIn = session.checkIns.sorted(by: { $0.date < $1.date }).last?.date
        let baseDate = lastCheckIn ?? session.startTime

        let maxCycles = AppConstants.maxScheduledNotifications / 3
        var requests: [UNNotificationRequest] = []

        for cycle in 1...maxCycles {
            let cycleOffset = intervalSeconds * Double(cycle)
            let deadlineDate = baseDate.addingTimeInterval(cycleOffset)
            let warningDate = deadlineDate.addingTimeInterval(-warningSeconds)
            let alertDate = deadlineDate.addingTimeInterval(graceSeconds)

            guard deadlineDate > Date() else { continue }

            if warningDate > Date() {
                requests.append(
                    makeNotification(
                        identifier: "\(AppConstants.warningNotifPrefix)\(session.id.uuidString)-\(cycle)",
                        title: "⏰ Vérification dans \(AppConstants.warningWindowMinutes) min",
                        body: "RAS : \(session.name) — Prépare-toi à confirmer que tu vas bien.",
                        date: warningDate,
                        sound: .default,
                        interruption: .timeSensitive
                    )
                )
            }

            requests.append(
                makeNotification(
                    identifier: "\(AppConstants.checkInNotifPrefix)\(session.id.uuidString)-\(cycle)",
                    title: "✋ Vérification requise",
                    body: "RAS : \(session.name) — Confirme que tu vas bien maintenant.",
                    date: deadlineDate,
                    sound: .default,
                    interruption: .timeSensitive,
                    categoryIdentifier: "CHECKIN_ACTION",
                    userInfo: ["sessionId": session.id.uuidString, "cycle": cycle]
                )
            )

            requests.append(
                makeNotification(
                    identifier: "\(AppConstants.alertNotifPrefix)\(session.id.uuidString)-\(cycle)",
                    title: "🚨 ALERTE — Aucune réponse",
                    body: "RAS contacte tes proches. Appuie sur Envoyer dans Messages (obligatoire iOS).",
                    date: alertDate,
                    sound: .default,
                    interruption: .timeSensitive,
                    categoryIdentifier: "ALERT_ACTION",
                    userInfo: [
                        "sessionId": session.id.uuidString,
                        "cycle": cycle,
                        "isAlert": true,
                    ]
                )
            )

            BGAlertScheduler.schedule(sessionId: session.id, cycle: cycle, at: alertDate)
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    func cancelSession(_ session: SafeSession) async {
        let pending = await center.pendingNotificationRequests()
        let sessionIds = pending
            .filter { $0.identifier.contains(session.id.uuidString) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: sessionIds)
        BGAlertScheduler.cancel(sessionId: session.id)
    }

    func cancelAlerts(for session: SafeSession, cycle: Int) async {
        let alertId = "\(AppConstants.alertNotifPrefix)\(session.id.uuidString)-\(cycle)"
        center.removePendingNotificationRequests(withIdentifiers: [alertId])
    }

    nonisolated func registerNotificationCategories() {
        let checkInAction = UNNotificationAction(
            identifier: "CHECKIN_NOW",
            title: "✅ RAS",
            options: [.authenticationRequired]
        )

        let cancelAlertAction = UNNotificationAction(
            identifier: "CANCEL_ALERT",
            title: "⛔ Annuler l'alerte",
            options: [.authenticationRequired, .destructive]
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "CHECKIN_ACTION",
            actions: [checkInAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let alertCategory = UNNotificationCategory(
            identifier: "ALERT_ACTION",
            actions: [cancelAlertAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([checkInCategory, alertCategory])
    }

    private func makeNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        sound: UNNotificationSound,
        interruption: UNNotificationInterruptionLevel = .active,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.interruptionLevel = interruption
        content.badge = 1
        if let cat = categoryIdentifier { content.categoryIdentifier = cat }
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

}
