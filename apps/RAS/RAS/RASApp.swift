import BackgroundTasks
import SwiftData
import SwiftUI
import UserNotifications

@main
struct RASApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    private let modelContainer: ModelContainer = {
        let container = try! ModelContainer(for: SafeSession.self, AlertConfig.self, Contact.self)
        RASModelContainer.shared = container
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var pendingCheckInSessionId: UUID?
    @Published var pendingCycle: Int = 1
    @Published var showCheckIn = false
    @Published var showAlertFlow = false
    /// Déclenchement auto après notification d'alerte.
    @Published var pendingAutoAlertUserInfo: [AnyHashable: Any]?

    init() {
        NotificationCenter.default.addObserver(
            forName: .openCheckIn,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.applyNotificationUserInfo(note.userInfo)
                self?.showCheckIn = true
            }
        }
        NotificationCenter.default.addObserver(
            forName: .alertTriggered,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.applyNotificationUserInfo(note.userInfo)
                self?.showAlertFlow = true
            }
        }
        NotificationCenter.default.addObserver(
            forName: .quickCheckIn,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.applyNotificationUserInfo(note.userInfo)
                self?.showCheckIn = true
            }
        }
        NotificationCenter.default.addObserver(
            forName: .autoDispatchAlert,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.pendingAutoAlertUserInfo = note.userInfo
            }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "ras",
              url.host == "checkin",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionIdStr = components.queryItems?.first(where: { $0.name == "sessionId" })?.value,
              let sessionId = UUID(uuidString: sessionIdStr)
        else { return }

        pendingCheckInSessionId = sessionId
        if let cycleStr = components.queryItems?.first(where: { $0.name == "cycle" })?.value,
           let cycle = Int(cycleStr) {
            pendingCycle = cycle
        }
        showCheckIn = true
    }

    private func applyNotificationUserInfo(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo else { return }
        if let sessionIdStr = userInfo["sessionId"] as? String,
           let sessionId = UUID(uuidString: sessionIdStr) {
            pendingCheckInSessionId = sessionId
        }
        if let cycle = userInfo["cycle"] as? Int {
            pendingCycle = cycle
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BGAlertScheduler.register()
        NotificationScheduler.shared.registerNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
        Task {
            _ = await NotificationScheduler.shared.requestPermission()
            await LocationService.shared.requestPermission()
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let isAlert = userInfo["isAlert"] as? Bool, isAlert {
            NotificationCenter.default.post(
                name: .autoDispatchAlert,
                object: nil,
                userInfo: userInfo
            )
        }
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "CHECKIN_NOW":
            NotificationCenter.default.post(name: .quickCheckIn, object: nil, userInfo: userInfo)
        case "CANCEL_ALERT":
            NotificationCenter.default.post(name: .openCheckIn, object: nil, userInfo: userInfo)
        case UNNotificationDefaultActionIdentifier:
            if let isAlert = userInfo["isAlert"] as? Bool, isAlert {
                NotificationCenter.default.post(
                    name: .autoDispatchAlert,
                    object: nil,
                    userInfo: userInfo
                )
                NotificationCenter.default.post(name: .alertTriggered, object: nil, userInfo: userInfo)
            } else {
                NotificationCenter.default.post(name: .openCheckIn, object: nil, userInfo: userInfo)
            }
        default:
            break
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let quickCheckIn = Notification.Name("ras.quickCheckIn")
    static let openCheckIn = Notification.Name("ras.openCheckIn")
    static let alertTriggered = Notification.Name("ras.alertTriggered")
    static let autoDispatchAlert = Notification.Name("ras.autoDispatchAlert")
}
