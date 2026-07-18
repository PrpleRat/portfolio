import Foundation

enum AppConstants {

    static let appName = "RAS"
    static let appTagline = "Fusée de détresse"
    static let appFullTitle = "RAS — Fusée de détresse"

    static let availableDurations: [Int] = [
        15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720, 1440
    ]

    static let warningWindowMinutes: Int = 5
    static let gracePeriodMinutes: Int = 3
    static let maxScheduledNotifications: Int = 50

    static let pinLength: Int = 6
    static let maxPINAttempts: Int = 3
    static let pinLockoutDuration: TimeInterval = 30

    static let checkInNotifPrefix = "ras.checkin."
    static let warningNotifPrefix = "ras.warning."
    static let alertNotifPrefix = "ras.alert."

    static let bgTaskIdentifier = "com.ras.session-monitor"

    static let pinHashKey = "ras.pin.hash"
    static let pinSaltKey = "ras.pin.salt"
    static let questionKey = "ras.question"
    static let answerHashKey = "ras.answer.hash"
}
