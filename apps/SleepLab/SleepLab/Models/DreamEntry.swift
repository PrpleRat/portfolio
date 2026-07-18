import Foundation
import SwiftData

/// Type de rêve (classification subjective).
enum DreamCategory: String, Codable, CaseIterable, Identifiable {
    case ordinary, lucid, nightmare, recurring, healing, surreal, prophetic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ordinary: return "Ordinaire"
        case .lucid: return "Lucide"
        case .nightmare: return "Cauchemar"
        case .recurring: return "Récurrent"
        case .healing: return "Guérison"
        case .surreal: return "Surréaliste"
        case .prophetic: return "Prémonitoire"
        }
    }

    var sfSymbol: String {
        switch self {
        case .ordinary: return "moon.stars"
        case .lucid: return "sparkles"
        case .nightmare: return "cloud.bolt.fill"
        case .recurring: return "arrow.triangle.2.circlepath"
        case .healing: return "heart.fill"
        case .surreal: return "eye.trianglebadge.exclamationmark"
        case .prophetic: return "crystal.ball"
        }
    }
}

/// Émotion dominante ou ressentie dans le rêve.
enum DreamEmotion: String, Codable, CaseIterable, Identifiable {
    case joy, peace, love, surprise, excitement
    case sadness, fear, anxiety, anger, disgust, confusion, shame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .joy: return "Joie"
        case .peace: return "Paix"
        case .love: return "Amour"
        case .surprise: return "Surprise"
        case .excitement: return "Excitation"
        case .sadness: return "Tristesse"
        case .fear: return "Peur"
        case .anxiety: return "Anxiété"
        case .anger: return "Colère"
        case .disgust: return "Dégoût"
        case .confusion: return "Confusion"
        case .shame: return "Honte"
        }
    }

    var sfSymbol: String {
        switch self {
        case .joy: return "face.smiling"
        case .peace: return "leaf.fill"
        case .love: return "heart.fill"
        case .surprise: return "exclamationmark.circle"
        case .excitement: return "bolt.heart.fill"
        case .sadness: return "cloud.rain.fill"
        case .fear: return "eye.fill"
        case .anxiety: return "wind"
        case .anger: return "flame.fill"
        case .disgust: return "hand.thumbsdown.fill"
        case .confusion: return "questionmark.circle"
        case .shame: return "eye.slash.fill"
        }
    }

    /// Valence pour nuage / filtres (positif vs difficile).
    var isPositive: Bool {
        switch self {
        case .joy, .peace, .love, .surprise, .excitement: return true
        default: return false
        }
    }
}

@Model
final class DreamEntry {
    var id: UUID
    var createdAt: Date
    /// Date du matin (nuit concernée).
    var dreamDate: Date
    var title: String
    var narrative: String
    /// 1 = flou … 5 = très net
    var clarity: Int
    var vividness: Int
    var isLucid: Bool
    var isRecurring: Bool
    var categoryRaw: String
    var emotionsData: String
    var tagsData: String
    var symbolsData: String
    /// Humeur au réveil 1–10
    var moodOnWake: Int

    var session: SleepSession?

    var category: DreamCategory {
        get { DreamCategory(rawValue: categoryRaw) ?? .ordinary }
        set { categoryRaw = newValue.rawValue }
    }

    var emotions: [DreamEmotion] {
        get {
            emotionsData.split(separator: "|").compactMap { DreamEmotion(rawValue: String($0)) }
        }
        set {
            emotionsData = newValue.map(\.rawValue).joined(separator: "|")
        }
    }

    var tags: [String] {
        get { tagsData.split(separator: "|").map(String.init).filter { !$0.isEmpty } }
        set { tagsData = newValue.joined(separator: "|") }
    }

    var symbols: [String] {
        get { symbolsData.split(separator: "|").map(String.init).filter { !$0.isEmpty } }
        set { symbolsData = newValue.joined(separator: "|") }
    }

    init(
        dreamDate: Date = Date(),
        title: String = "",
        narrative: String = "",
        category: DreamCategory = .ordinary,
        emotions: [DreamEmotion] = [],
        session: SleepSession? = nil
    ) {
        id = UUID()
        createdAt = Date()
        self.dreamDate = dreamDate
        self.title = title
        self.narrative = narrative
        clarity = 3
        vividness = 3
        isLucid = category == .lucid
        isRecurring = category == .recurring
        categoryRaw = category.rawValue
        emotionsData = emotions.map(\.rawValue).joined(separator: "|")
        tagsData = ""
        symbolsData = ""
        moodOnWake = 5
        self.session = session
    }

    var preview: String {
        if !title.isEmpty { return title }
        let text = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 80 { return String(text.prefix(80)) + "…" }
        return text.isEmpty ? "Sans description" : text
    }

    var primaryEmotion: DreamEmotion? { emotions.first }
}

extension DreamEntry: Identifiable {}
