import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject {

    static let shared = NotificationService()

    @Published private(set) var authorizationGranted = false

    /// Routeur injecté par l'app pour les deep links notification.
    weak var tabRouter: AppTabRouter?

    private override init() {
        super.init()
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationGranted = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationGranted = granted
            return granted
        } catch {
            authorizationGranted = false
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.dailyReminderNotificationId])

        guard authorizationGranted else { return }

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "CarenceScan"
        content.body = "Avez-vous eu vos symptômes aujourd'hui ? Notez-les en 30 secondes."
        content.sound = .default
        content.userInfo = ["action": "daily_checkin"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.dailyReminderNotificationId,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [AppConstants.dailyReminderNotificationId]
        )
    }

    @MainActor
    private func handleNotificationTap() {
        tabRouter?.requestCheckInFromNotification()
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = response.notification.request.content.userInfo["action"] as? String
        guard action == "daily_checkin" || response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
            return
        }
        await NotificationService.shared.handleNotificationTap()
    }
}
