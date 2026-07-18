import Foundation
import UserNotifications

enum SmartNotificationService {

    static let smartTipId = "carencescan.smart.tip"

    @MainActor
    static func evaluateAndSchedule(tracker: SymptomTrackerViewModel) async {
        guard SymptomJournalStorage.loadSettings().notificationsEnabled else { return }
        guard await NotificationService.shared.authorizationGranted else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [smartTipId])

        guard let tip = buildTip(tracker: tracker) else { return }

        let content = UNMutableNotificationContent()
        content.title = "CarenceScan — conseil"
        content.body = tip
        content.sound = .default

        var date = DateComponents()
        date.hour = 10
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let request = UNNotificationRequest(identifier: smartTipId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    @MainActor
    private static func buildTip(tracker: SymptomTrackerViewModel) -> String? {
        let ids = tracker.trackedSymptomeIds
        let fatigueIds = ["fatigue_intense", "fatigue_matin", "somnolence_journee"]
        let fatigueDays = fatigueIds.flatMap { id in
            SymptomJournalStorage.entries(for: id, lastDays: 7).filter(\.present)
        }.count

        if fatigueDays >= 3, let payload = ResultsStorage.load(),
           payload.scores.contains(where: { $0.carenceId == "fer" && $0.niveau != .possible }) {
            return "Fatigue notée plusieurs fois cette semaine — un bilan ferritine + NFS peut être utile."
        }

        let checkedToday = ids.compactMap { tracker.isPresentToday(symptomeId: $0) }
        if !ids.isEmpty, checkedToday.isEmpty,
           Calendar.current.component(.hour, from: Date()) >= 18 {
            return "N'oubliez pas votre check-in symptômes du jour (30 secondes)."
        }

        let checkedIds = ListeCoursesStorage.loadCheckedIds()
        if let payload = ResultsStorage.load() {
            let liste = ListeCoursesEngine.genererListe(
                depuis: payload.scores,
                symptomesDetectes: payload.symptomeSelections.map(\.symptomeId)
            )
            let allItems = liste.pharmacie + liste.supermarche
            let total = allItems.count
            let done = allItems.filter { checkedIds.contains($0.id) }.count
            if total > 3, done < total / 2 {
                return "Il vous reste des articles sur votre liste de courses CarenceScan."
            }
        }

        return nil
    }
}
