import SwiftUI

enum AppTab: Hashable {
    case accueil
    case bilan
    case suivi
    case journal
    case courses
}

enum CoursesHubSection: Hashable {
    case liste
    case recettes
}

@MainActor
final class AppTabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .accueil
    @Published var highlightSummaryOnBilan = false
    @Published var coursesSection: CoursesHubSection = .liste
    @Published var showCheckInSheet = false

    /// Demande différée (notification) — consommée quand la scène est active.
    @Published private(set) var pendingCheckIn = false

    func openBilanSummary() {
        selectedTab = .bilan
        highlightSummaryOnBilan = true
    }

    func openCourses(section: CoursesHubSection = .liste) {
        coursesSection = section
        selectedTab = .courses
    }

    func openRecettes() {
        openCourses(section: .recettes)
    }

    func openSuivi() {
        selectedTab = .suivi
    }

    func openJournal() {
        selectedTab = .journal
    }

    /// Ouvre le check-in via sheet (évite les crashs NavigationLink au cold start).
    func openCheckIn(deferred: Bool = false) {
        selectedTab = .suivi
        let delay = deferred ? 0.55 : 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.showCheckInSheet = true
        }
    }

    func requestCheckInFromNotification() {
        pendingCheckIn = true
    }

    func consumePendingCheckInIfNeeded() {
        guard pendingCheckIn else { return }
        pendingCheckIn = false
        openCheckIn(deferred: true)
    }
}
