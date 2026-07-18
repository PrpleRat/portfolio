import Foundation
import UserNotifications

enum AlarmNotificationScheduler {
    static func scheduleFallback(at wakeTime: Date, sound: AlarmSound) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.sound, .alert]) { _, _ in }

        center.removePendingNotificationRequests(withIdentifiers: ["sleeplab.alarm.fallback"])

        let content = UNMutableNotificationContent()
        content.title = AppBrand.displayName
        content.body = "C’est l’heure de te réveiller."
        content.sound = sound.notificationUNSound()

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: wakeTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sleeplab.alarm.fallback",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func cancelFallback() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["sleeplab.alarm.fallback"])
    }
}
