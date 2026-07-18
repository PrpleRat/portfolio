import BackgroundTasks
import Foundation
import SwiftData

/// Tente un envoi d'alerte en arrière-plan à l'heure prévue (best-effort — iOS peut retarder).
enum BGAlertScheduler {

    private static let pendingKey = "ras.pendingBgAlerts"

    struct PendingAlert: Codable {
        let sessionId: UUID
        let cycle: Int
        let fireAt: TimeInterval
    }

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppConstants.bgTaskIdentifier,
            using: nil
        ) { task in
            guard let processing = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            processing.expirationHandler = {
                processing.setTaskCompleted(success: false)
            }
            Task { @MainActor in
                let ok = await runDueAlerts()
                processing.setTaskCompleted(success: ok)
            }
        }
    }

    static func schedule(sessionId: UUID, cycle: Int, at date: Date) {
        guard date > Date() else { return }

        var pending = loadPending()
        pending.removeAll { $0.sessionId == sessionId && $0.cycle == cycle }
        pending.append(PendingAlert(sessionId: sessionId, cycle: cycle, fireAt: date.timeIntervalSince1970))
        savePending(pending)

        let request = BGProcessingTaskRequest(identifier: AppConstants.bgTaskIdentifier)
        request.earliestBeginDate = date
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    static func cancel(sessionId: UUID) {
        var pending = loadPending()
        pending.removeAll { $0.sessionId == sessionId }
        savePending(pending)
    }

    @MainActor
    private static func runDueAlerts() async -> Bool {
        let now = Date().timeIntervalSince1970
        let due = loadPending().filter { $0.fireAt <= now }
        guard !due.isEmpty else { return true }

        guard let container = RASModelContainer.shared else { return false }
        let context = ModelContext(container)
        var anySuccess = false

        for item in due {
            if await AlertAutoTrigger.dispatchIfNeeded(sessionId: item.sessionId, modelContext: context) {
                anySuccess = true
            }
        }

        var remaining = loadPending().filter { $0.fireAt > now }
        savePending(remaining)
        return anySuccess || due.isEmpty
    }

    private static func loadPending() -> [PendingAlert] {
        guard
            let data = UserDefaults.standard.data(forKey: pendingKey),
            let decoded = try? JSONDecoder().decode([PendingAlert].self, from: data)
        else { return [] }
        return decoded
    }

    private static func savePending(_ items: [PendingAlert]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: pendingKey)
    }
}

/// Conteneur SwiftData partagé (app + tâche background).
enum RASModelContainer {
    static var shared: ModelContainer?
}
