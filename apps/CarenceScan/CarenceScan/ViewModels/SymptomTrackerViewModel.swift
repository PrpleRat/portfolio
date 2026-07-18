import Foundation
import SwiftUI

@MainActor
final class SymptomTrackerViewModel: ObservableObject {

    static let shared = SymptomTrackerViewModel()

    @Published var settings: SymptomTrackingSettings
    @Published private(set) var journalEntries: [SymptomJournalEntry] = []

    private init() {
        settings = SymptomJournalStorage.loadSettings()
        reloadJournal()
    }

    func reloadJournal() {
        journalEntries = SymptomJournalStorage.loadEntries()
    }

    var trackedSymptomeIds: [String] {
        if !settings.trackedSymptomeIds.isEmpty {
            return settings.trackedSymptomeIds
        }
        return ResultsStorage.load()?.symptomeSelections.map(\.symptomeId) ?? []
    }

    var baselineSymptomeIds: [String] {
        let added = Set(settings.addedSymptomeIds)
        return trackedSymptomeIds.filter { !added.contains($0) }
    }

    var addedSymptomeIds: [String] {
        settings.addedSymptomeIds.filter { trackedSymptomeIds.contains($0) }
    }

    var isFirstCheckIn: Bool {
        !settings.hasCompletedFirstCheckIn
    }

    func syncTrackedSymptoms(from selections: [SymptomeSelection]) {
        guard settings.trackedSymptomeIds.isEmpty else { return }
        settings.trackedSymptomeIds = selections.map(\.symptomeId)
        settings.trackingStartDate = Date()
        persistSettings()
    }

    func addTrackedSymptom(_ id: String) {
        guard !settings.trackedSymptomeIds.contains(id) else { return }
        settings.trackedSymptomeIds.append(id)
        if !settings.addedSymptomeIds.contains(id) {
            settings.addedSymptomeIds.append(id)
        }
        if settings.trackingStartDate == nil {
            settings.trackingStartDate = Date()
        }
        persistSettings()
    }

    func removeTrackedSymptom(_ id: String) {
        settings.trackedSymptomeIds.removeAll { $0 == id }
        settings.addedSymptomeIds.removeAll { $0 == id }
        persistSettings()
    }

    func setTrackedSymptoms(_ ids: [String]) {
        settings.trackedSymptomeIds = ids
        persistSettings()
    }

    func isPresentToday(symptomeId: String) -> Bool? {
        let today = Calendar.current.startOfDay(for: Date())
        return journalEntries.first {
            $0.symptomeId == symptomeId && Calendar.current.isDate($0.date, inSameDayAs: today)
        }?.present
    }

    func record(symptomeId: String, present: Bool) {
        SymptomJournalStorage.upsertEntry(symptomeId: symptomeId, present: present)
        reloadJournal()
    }

    func markFirstCheckInCompleted() {
        guard !settings.hasCompletedFirstCheckIn else { return }
        settings.hasCompletedFirstCheckIn = true
        if settings.trackingStartDate == nil {
            settings.trackingStartDate = Date()
        }
        persistSettings()
    }

    func presentDaysCount(symptomeId: String, lastDays: Int) -> Int {
        SymptomJournalStorage.entries(for: symptomeId, lastDays: lastDays).filter(\.present).count
    }

    func journalFrequence(for symptomeId: String) -> JournalFrequence? {
        SymptomFrequencyEngine.frequence(symptomeId: symptomeId)
    }

    func daysWithData(lastDays: Int) -> [Date] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -(lastDays - 1), to: Calendar.current.startOfDay(for: Date()))!
        return (0..<lastDays).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: cutoff) }
    }

    func persistSettings() {
        SymptomJournalStorage.saveSettings(settings)
    }

    func updateNotificationsEnabled(_ enabled: Bool) async {
        settings.notificationsEnabled = enabled
        persistSettings()
        if enabled {
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                await NotificationService.shared.scheduleDailyReminder(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute
                )
                await SmartNotificationService.evaluateAndSchedule(tracker: self)
            } else {
                settings.notificationsEnabled = false
                persistSettings()
            }
        } else {
            NotificationService.shared.cancelDailyReminder()
        }
    }

    func updateReminderTime(hour: Int, minute: Int) async {
        settings.reminderHour = hour
        settings.reminderMinute = minute
        persistSettings()
        if settings.notificationsEnabled {
            await NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
        }
    }
}
