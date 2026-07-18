import BackgroundTasks
import Foundation

/// Tâche de fond pour maintenir l'analyse nocturne (BGProcessingTask)
enum SleepBackgroundTask {
    static let identifier = "com.prple.sleeplab.night.processing"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            handle(task: task as! BGProcessingTask)
        }
    }

    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(task: BGProcessingTask) {
        schedule()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        // Point d'extension : persister l'état du tracker, relancer analyse motion/audio
        task.setTaskCompleted(success: true)
    }
}
