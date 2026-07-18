import Foundation

struct CoursesWeekSnapshot: Codable, Identifiable, Hashable {
    var id: String { weekKey }
    let weekKey: String
    let weekStart: Date
    let checkedCount: Int
    let totalCount: Int
}

enum ListeCoursesWeekStorage {

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

    static func currentWeekKey() -> String {
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.yearForWeekOfYear, from: Date())
        return "\(year)-W\(week)"
    }

    static func weekStartDate() -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    /// Réinitialise les coches si nouvelle semaine ; archive la semaine précédente.
    static func rolloverIfNeeded(checkedIds: Set<String>, totalCount: Int) -> Set<String> {
        let current = currentWeekKey()
        let stored = UserDefaults.standard.string(forKey: AppConstants.listeCoursesWeekKey)
        if stored == nil {
            UserDefaults.standard.set(current, forKey: AppConstants.listeCoursesWeekKey)
            return checkedIds
        }
        guard stored != current else { return checkedIds }

        if let stored {
            var history = loadHistory()
            let snapshot = CoursesWeekSnapshot(
                weekKey: stored,
                weekStart: weekStartDate(forKey: stored),
                checkedCount: checkedIds.count,
                totalCount: totalCount
            )
            history.removeAll { $0.weekKey == stored }
            history.insert(snapshot, at: 0)
            if history.count > 8 { history = Array(history.prefix(8)) }
            saveHistory(history)
        }

        UserDefaults.standard.set(current, forKey: AppConstants.listeCoursesWeekKey)
        ListeCoursesStorage.clearCheckedIds()
        return []
    }

    static func loadHistory() -> [CoursesWeekSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.listeCoursesWeekHistoryKey),
              let items = try? decoder.decode([CoursesWeekSnapshot].self, from: data)
        else { return [] }
        return items
    }

    private static func saveHistory(_ items: [CoursesWeekSnapshot]) {
        guard let data = try? encoder.encode(items) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.listeCoursesWeekHistoryKey)
    }

    private static func weekStartDate(forKey key: String) -> Date {
        let parts = key.split(separator: "-W")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let week = Int(parts[1])
        else { return Date() }
        var comps = DateComponents()
        comps.yearForWeekOfYear = year
        comps.weekOfYear = week
        comps.weekday = 2
        return Calendar.current.date(from: comps) ?? Date()
    }
}
