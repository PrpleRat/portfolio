import Foundation
import SwiftUI

enum LicenseType: String, Codable, CaseIterable, Identifiable {
    case mp3Lease
    case wavLease
    case trackoutLease
    case exclusive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mp3Lease: return "MP3 Lease"
        case .wavLease: return "WAV Lease"
        case .trackoutLease: return "Trackout Lease"
        case .exclusive: return "Exclusive"
        }
    }

    var shortDescription: String {
        switch self {
        case .mp3Lease: return "Non-exclusif · MP3 uniquement · 2 500 streams max"
        case .wavLease: return "Non-exclusif · WAV + MP3 · 10 000 streams max"
        case .trackoutLease: return "Non-exclusif · Stems séparés · 50 000 streams max"
        case .exclusive: return "Exclusif complet · Tous formats · Droits illimités"
        }
    }

    var defaultPrice: Int {
        switch self {
        case .mp3Lease: return 29
        case .wavLease: return 49
        case .trackoutLease: return 99
        case .exclusive: return 299
        }
    }

    var defaultMaxStreams: Int {
        switch self {
        case .mp3Lease: return 2_500
        case .wavLease: return 10_000
        case .trackoutLease: return 50_000
        case .exclusive: return Int.max
        }
    }

    var formats: String {
        switch self {
        case .mp3Lease: return "MP3"
        case .wavLease: return "WAV + MP3"
        case .trackoutLease: return "Stems (WAV)"
        case .exclusive: return "Tous formats + stems"
        }
    }

    var isExclusive: Bool {
        self == .exclusive
    }

    var distributionLabel: String {
        isExclusive ? "exclusive" : "non-exclusive"
    }

    var iconName: String {
        switch self {
        case .mp3Lease: return "waveform"
        case .wavLease: return "waveform.path"
        case .trackoutLease: return "slider.horizontal.3"
        case .exclusive: return "crown.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .mp3Lease: return BeatDealColors.textSecondary
        case .wavLease: return BeatDealColors.accentLight
        case .trackoutLease: return BeatDealColors.accent
        case .exclusive: return BeatDealColors.success
        }
    }

    var defaultRights: ContractRights {
        switch self {
        case .mp3Lease:
            return ContractRights(
                streaming: true,
                digitalDistribution: true,
                monetizedYouTube: true,
                livePerformance: true,
                commercialRadio: false,
                sync: false,
                remix: false
            )
        case .wavLease:
            return ContractRights(
                streaming: true,
                digitalDistribution: true,
                monetizedYouTube: true,
                livePerformance: true,
                commercialRadio: false,
                sync: false,
                remix: false
            )
        case .trackoutLease:
            return ContractRights(
                streaming: true,
                digitalDistribution: true,
                monetizedYouTube: true,
                livePerformance: true,
                commercialRadio: true,
                sync: false,
                remix: false
            )
        case .exclusive:
            return ContractRights(
                streaming: true,
                digitalDistribution: true,
                monetizedYouTube: true,
                livePerformance: true,
                commercialRadio: true,
                sync: true,
                remix: true
            )
        }
    }
}

struct ContractRights: Codable, Equatable {
    var streaming: Bool
    var digitalDistribution: Bool
    var monetizedYouTube: Bool
    var livePerformance: Bool
    var commercialRadio: Bool
    var sync: Bool
    var remix: Bool

    static let allLabels: [(keyPath: WritableKeyPath<ContractRights, Bool>, label: String)] = [
        (\.streaming, "Streaming (Spotify, Apple Music, etc.)"),
        (\.digitalDistribution, "Distribution digitale (DistroKid, TuneCore, etc.)"),
        (\.monetizedYouTube, "YouTube monétisé"),
        (\.livePerformance, "Lives & performances scéniques"),
        (\.commercialRadio, "Radio commerciale"),
        (\.sync, "Synchronisation (film, pub, série)"),
        (\.remix, "Remix & interpolation")
    ]
}

struct LicenseTemplate: Codable, Identifiable {
    var id: String { licenseType.rawValue }
    var licenseType: LicenseType
    var defaultPrice: Int
    var maxStreams: Int
    var defaultRights: ContractRights
    var defaultClause: String

    static func defaultTemplates() -> [LicenseTemplate] {
        LicenseType.allCases.map { type in
            LicenseTemplate(
                licenseType: type,
                defaultPrice: type.defaultPrice,
                maxStreams: type.defaultMaxStreams,
                defaultRights: type.defaultRights,
                defaultClause: ""
            )
        }
    }
}
