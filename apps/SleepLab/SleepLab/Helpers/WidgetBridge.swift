import Foundation
import WidgetKit

/// Clés App Group partagées app ↔ widget.
enum WidgetSharedKeys {
    static let suiteName = "group.com.prple.sleeplab"
    static let score = "widget_score"
    static let dreamTitle = "widget_dreamTitle"
    static let emotionEmoji = "widget_emotionEmoji"
    static let date = "widget_date"
    static let durationHours = "lastNightDurationHours"
    // legacy
    static let lastNightScore = "lastNightScore"
}

/// Pont app → widget
enum WidgetBridge {
    static func syncSession(_ session: SleepSession, latestDream: DreamEntry? = nil) {
        guard let defaults = UserDefaults(suiteName: WidgetSharedKeys.suiteName) else { return }

        defaults.set(session.overallScore, forKey: WidgetSharedKeys.score)
        defaults.set(session.overallScore, forKey: WidgetSharedKeys.lastNightScore)
        defaults.set(session.totalDuration / 3600, forKey: WidgetSharedKeys.durationHours)
        defaults.set(Date(), forKey: WidgetSharedKeys.date)

        if let dream = latestDream {
            defaults.set(dream.preview, forKey: WidgetSharedKeys.dreamTitle)
            defaults.set(emotionEmoji(for: dream), forKey: WidgetSharedKeys.emotionEmoji)
        } else {
            defaults.set("Aucun rêve noté", forKey: WidgetSharedKeys.dreamTitle)
            defaults.set("🌙", forKey: WidgetSharedKeys.emotionEmoji)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncDream(_ dream: DreamEntry, lastSession: SleepSession?) {
        guard let defaults = UserDefaults(suiteName: WidgetSharedKeys.suiteName) else { return }
        defaults.set(dream.preview, forKey: WidgetSharedKeys.dreamTitle)
        defaults.set(emotionEmoji(for: dream), forKey: WidgetSharedKeys.emotionEmoji)
        if let session = lastSession {
            defaults.set(session.overallScore, forKey: WidgetSharedKeys.score)
        }
        defaults.set(dream.dreamDate, forKey: WidgetSharedKeys.date)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func emotionEmoji(for dream: DreamEntry) -> String {
        guard let e = dream.primaryEmotion ?? dream.emotions.first else { return "🌙" }
        switch e {
        case .joy, .excitement: return "😊"
        case .peace, .love: return "😌"
        case .surprise: return "😮"
        case .sadness: return "😢"
        case .fear, .anxiety: return "😰"
        case .anger: return "😠"
        case .disgust: return "🤢"
        case .confusion: return "😕"
        case .shame: return "😳"
        }
    }
}
