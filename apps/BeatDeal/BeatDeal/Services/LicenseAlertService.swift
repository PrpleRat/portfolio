import Foundation
import UserNotifications

@MainActor
final class LicenseAlertService: ObservableObject {
    static let shared = LicenseAlertService()

    @Published private(set) var authorizationGranted = false

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            do {
                authorizationGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                authorizationGranted = false
            }
        } else {
            authorizationGranted = settings.authorizationStatus == .authorized
        }
        registerCategories()
    }

    func refreshAlerts(for contracts: [Contract]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("beatdeal.license.") }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard authorizationGranted else { return }

        for contract in contracts where contract.needsLicenseAlert {
            await scheduleAlert(for: contract)
        }
    }

    private func scheduleAlert(for contract: Contract) async {
        let content = UNMutableNotificationContent()
        content.title = "Licence à surveiller"
        content.sound = .default
        content.categoryIdentifier = AppConstants.notificationCategoryUpgrade
        content.userInfo = ["contractId": contract.id]

        if contract.isApproachingStreamLimit {
            let upgrade = contract.suggestedUpgradeLicense?.title ?? "un upgrade"
            content.body = "\(contract.artistName) — « \(contract.beatTitle) » approche la limite (\(contract.streamsUsed.formatted())/\(contract.maxStreams.formatted()) streams). Propose \(upgrade) !"
        } else if let expiresAt = contract.expiresAt {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateStyle = .medium
            content.body = "\(contract.artistName) — « \(contract.beatTitle) » expire le \(formatter.string(from: expiresAt)). Propose un renouvellement ou upgrade !"
        } else {
            return
        }

        let trigger: UNNotificationTrigger
        if let expiresAt = contract.expiresAt {
            let alertDate = Calendar.current.date(
                byAdding: .day,
                value: -AppConstants.licenseExpiryWarningDays,
                to: expiresAt
            ) ?? expiresAt
            if alertDate > Date() {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            }
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }
        let request = UNNotificationRequest(
            identifier: "beatdeal.license.\(contract.id)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func registerCategories() {
        let upgrade = UNNotificationAction(
            identifier: "VIEW_LICENSE",
            title: "Voir la licence",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryUpgrade,
            actions: [upgrade],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
