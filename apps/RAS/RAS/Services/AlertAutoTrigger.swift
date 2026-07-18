import Foundation
import SwiftData

/// Déclenche les alertes sans passer par le bouton manuel « Déclencher ».
@MainActor
enum AlertAutoTrigger {

    static func dispatchIfNeeded(
        sessionId: UUID,
        modelContext: ModelContext
    ) async -> Bool {
        let sessionDescriptor = FetchDescriptor<SafeSession>()
        guard
            let sessions = try? modelContext.fetch(sessionDescriptor),
            let session = sessions.first(where: { $0.id == sessionId }),
            session.isActive,
            !session.wasAlertTriggered
        else { return false }

        let configDescriptor = FetchDescriptor<AlertConfig>()
        guard
            let configs = try? modelContext.fetch(configDescriptor),
            let configId = session.alertConfigId,
            let config = configs.first(where: { $0.id == configId })
        else { return false }

        let vm = CheckInViewModel()
        await vm.triggerAlert(session: session, config: config)
        try? modelContext.save()
        return true
    }

    static func dispatchIfNeeded(
        userInfo: [AnyHashable: Any],
        modelContext: ModelContext
    ) async -> Bool {
        guard
            let isAlert = userInfo["isAlert"] as? Bool,
            isAlert,
            let sessionIdStr = userInfo["sessionId"] as? String,
            let sessionId = UUID(uuidString: sessionIdStr)
        else { return false }

        return await dispatchIfNeeded(sessionId: sessionId, modelContext: modelContext)
    }
}
