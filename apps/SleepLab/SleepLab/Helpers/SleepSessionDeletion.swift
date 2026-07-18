import Foundation
import SwiftData

enum SleepSessionDeletion {
    @MainActor
    static func delete(_ session: SleepSession, in context: ModelContext) {
        for event in session.soundEvents {
            if let name = event.clipFileName {
                let url = AudioHelpers.clipURL(fileName: name)
                try? FileManager.default.removeItem(at: url)
            }
        }

        for dream in dreamsLinked(to: session, in: context) {
            dream.session = nil
        }

        context.delete(session)
        try? context.save()
        refreshWidgetAfterDeletion(in: context)
    }

    @MainActor
    private static func dreamsLinked(to session: SleepSession, in context: ModelContext) -> [DreamEntry] {
        let descriptor = FetchDescriptor<DreamEntry>()
        guard let dreams = try? context.fetch(descriptor) else { return [] }
        return dreams.filter { $0.session?.id == session.id }
    }

    @MainActor
    private static func refreshWidgetAfterDeletion(in context: ModelContext) {
        var descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { $0.endTime != nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let latest = try? context.fetch(descriptor).first {
            WidgetBridge.syncSession(latest)
        }
    }
}
