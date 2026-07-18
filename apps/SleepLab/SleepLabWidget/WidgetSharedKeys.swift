import Foundation
import WidgetKit

enum WidgetSharedKeys {
    static let suiteName = "group.com.prple.sleeplab"
    static let score = "widget_score"
    static let dreamTitle = "widget_dreamTitle"
    static let emotionEmoji = "widget_emotionEmoji"
    static let date = "widget_date"
}

struct SleepWidgetEntryData: Equatable {
    var score: Int
    var dreamTitle: String
    var emotionEmoji: String
    var date: Date

    static let placeholder = SleepWidgetEntryData(
        score: 78,
        dreamTitle: "Vol au-dessus de la mer",
        emotionEmoji: "😌",
        date: Date()
    )

    static func load() -> SleepWidgetEntryData? {
        guard let defaults = UserDefaults(suiteName: WidgetSharedKeys.suiteName),
              defaults.object(forKey: WidgetSharedKeys.score) != nil else { return nil }
        return SleepWidgetEntryData(
            score: defaults.integer(forKey: WidgetSharedKeys.score),
            dreamTitle: defaults.string(forKey: WidgetSharedKeys.dreamTitle) ?? "—",
            emotionEmoji: defaults.string(forKey: WidgetSharedKeys.emotionEmoji) ?? "🌙",
            date: defaults.object(forKey: WidgetSharedKeys.date) as? Date ?? Date()
        )
    }
}

struct SleepWidgetEntry: TimelineEntry {
    let date: Date
    let data: SleepWidgetEntryData?
}
