import Foundation

struct SymptomJournalEntry: Codable, Identifiable, Hashable {
    var id: String { "\(dayKey)|\(symptomeId)" }
    let date: Date
    let symptomeId: String
    let present: Bool

    var dayKey: String {
        Calendar.current.startOfDay(for: date).ISO8601Format()
    }
}

struct SymptomTrackingSettings: Codable, Equatable {
    var notificationsEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var trackedSymptomeIds: [String]
    /// Symptômes ajoutés manuellement pendant le suivi quotidien (hors bilan initial).
    var addedSymptomeIds: [String]
    /// Date de début du suivi quotidien.
    var trackingStartDate: Date?
    /// Premier check-in quotidien effectué.
    var hasCompletedFirstCheckIn: Bool
    /// Record de jours consécutifs de check-in.
    var longestStreak: Int

    static let `default` = SymptomTrackingSettings(
        notificationsEnabled: false,
        reminderHour: 20,
        reminderMinute: 0,
        trackedSymptomeIds: [],
        addedSymptomeIds: [],
        trackingStartDate: nil,
        hasCompletedFirstCheckIn: false,
        longestStreak: 0
    )

    init(
        notificationsEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        trackedSymptomeIds: [String],
        addedSymptomeIds: [String] = [],
        trackingStartDate: Date? = nil,
        hasCompletedFirstCheckIn: Bool = false,
        longestStreak: Int = 0
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.trackedSymptomeIds = trackedSymptomeIds
        self.addedSymptomeIds = addedSymptomeIds
        self.trackingStartDate = trackingStartDate
        self.hasCompletedFirstCheckIn = hasCompletedFirstCheckIn
        self.longestStreak = longestStreak
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 20
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        trackedSymptomeIds = try c.decodeIfPresent([String].self, forKey: .trackedSymptomeIds) ?? []
        addedSymptomeIds = try c.decodeIfPresent([String].self, forKey: .addedSymptomeIds) ?? []
        trackingStartDate = try c.decodeIfPresent(Date.self, forKey: .trackingStartDate)
        hasCompletedFirstCheckIn = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedFirstCheckIn) ?? false
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case notificationsEnabled, reminderHour, reminderMinute, trackedSymptomeIds
        case addedSymptomeIds, trackingStartDate, hasCompletedFirstCheckIn, longestStreak
    }
}

struct SymptomeCarenceLink: Identifiable, Hashable {
    var id: String { carenceId }
    let carenceId: String
    let carenceNom: String
    let tier: SymptomeCarenceTier
    let score: Int
}

enum SymptomeCarenceTier: String, Hashable, CaseIterable {
    case primaire
    case secondaire
    case contextuel
    case associe

    var label: String {
        switch self {
        case .primaire: return "Symptôme caractéristique"
        case .secondaire: return "Symptôme fréquent"
        case .contextuel: return "Lié au mode de vie"
        case .associe: return "Association possible"
        }
    }

    var emoji: String {
        switch self {
        case .primaire: return "🎯"
        case .secondaire: return "📌"
        case .contextuel: return "🔄"
        case .associe: return "🔗"
        }
    }
}

struct SymptomeFicheDetail {
    let symptomeId: String
    let label: String
    let categorie: String
    let description: String
    let quandSinquieter: String
    let carencesLiees: [SymptomeCarenceLink]
}
