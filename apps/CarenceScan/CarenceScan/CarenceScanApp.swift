import SwiftUI
import UserNotifications

@main
struct CarenceScanApp: App {
    @StateObject private var questionnaire = QuestionnaireViewModel()
    @StateObject private var tracker = SymptomTrackerViewModel.shared
    @StateObject private var tabRouter = AppTabRouter()
    @StateObject private var journal = JournalEngine.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionnaire)
                .environmentObject(tracker)
                .environmentObject(tabRouter)
                .environmentObject(journal)
                .onAppear {
                    NotificationService.shared.tabRouter = tabRouter
                }
                .task {
                    await NotificationService.shared.refreshAuthorizationStatus()
                    await SmartNotificationService.evaluateAndSchedule(tracker: tracker)
                }
        }
    }
}
