import BackgroundTasks
import UserNotifications

/// Surveillance des perturbations via BGAppRefreshTask
final class DisruptionMonitor {

    static let shared = DisruptionMonitor()
    static let taskIdentifier = "com.trajoc.disruption-check"

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1800)
        try? BGTaskScheduler.shared.submit(request)
    }

    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleNextRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                let disruptions = try await NavitiaService.shared.disruptions()
                let active = disruptions.filter { $0.status == .active }

                if let first = active.first {
                    let content = UNMutableNotificationContent()
                    content.title = "⚠️ Perturbation sur votre réseau"
                    content.body = first.title
                    content.sound = .default

                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil
                    )
                    try? await UNUserNotificationCenter.current().add(request)
                }

                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
