import SwiftUI
import SwiftData

@main
struct TrajOcApp: App {
    init() {
        DisruptionMonitor.shared.registerBackgroundTask()
        DisruptionMonitor.shared.scheduleNextRefresh()
        Task {
            await DisruptionMonitor.shared.requestNotificationPermission()
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FavoriteJourney.self, RecentSearch.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Impossible de créer le ModelContainer : \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
