import Foundation

enum SymptomJournalStorage {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func loadEntries() -> [SymptomJournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.journalStorageKey),
              let entries = try? decoder.decode([SymptomJournalEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func saveEntries(_ entries: [SymptomJournalEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.journalStorageKey)
    }

    static func upsertEntry(symptomeId: String, present: Bool, date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        var entries = loadEntries()
        entries.removeAll {
            $0.symptomeId == symptomeId
                && Calendar.current.isDate($0.date, inSameDayAs: day)
        }
        entries.append(SymptomJournalEntry(date: day, symptomeId: symptomeId, present: present))
        saveEntries(entries)
    }

    static func entries(for symptomeId: String, lastDays: Int = 30) -> [SymptomJournalEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -lastDays, to: Date()) ?? Date()
        return loadEntries()
            .filter { $0.symptomeId == symptomeId && $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    static func loadSettings() -> SymptomTrackingSettings {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.trackingSettingsKey),
              let settings = try? decoder.decode(SymptomTrackingSettings.self, from: data)
        else { return .default }
        return settings
    }

    static func saveSettings(_ settings: SymptomTrackingSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.trackingSettingsKey)
    }

    static func appendBilanHistory(_ payload: SavedResultsPayload) {
        var history = loadBilanHistory()
        history.append(payload)
        if history.count > 24 {
            history = Array(history.suffix(24))
        }
        guard let data = try? encoder.encode(history) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.bilanHistoryKey)
    }

    static func loadBilanHistory() -> [SavedResultsPayload] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.bilanHistoryKey),
              let history = try? decoder.decode([SavedResultsPayload].self, from: data)
        else { return [] }
        return history.sorted { $0.date < $1.date }
    }
}
