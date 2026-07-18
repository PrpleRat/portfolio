import SwiftData
import SwiftUI

@main
struct SleepLabApp: App {
    @StateObject private var sleepTracker = SleepTracker()

    init() {
        SleepBackgroundTask.register()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            SleepPhase.self,
            SleepFactor.self,
            SoundEvent.self,
            SnoreEvent.self,
            PeriodDayLog.self,
            UserProfile.self,
            AlarmConfig.self,
            DreamEntry.self,
            DailySymptom.self,
            DailySubstanceRoutine.self,
            DailyRoutineSlot.self,
            DailyRoutineDayLog.self
        ])
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
                .environmentObject(sleepTracker)
                .environmentObject(ThemeManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
