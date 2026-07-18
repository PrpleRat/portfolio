import Foundation

struct RevenuePeriodStats: Equatable {
    var totalEUR: Int
    var contractCount: Int
    var byLicenseType: [LicenseType: Int]
}

struct RevenueDashboard: Equatable {
    var thisMonth: RevenuePeriodStats
    var thisQuarter: RevenuePeriodStats
    var allTime: RevenuePeriodStats
}

enum RevenueStatsEngine {

    static func dashboard(from contracts: [Contract], now: Date = Date()) -> RevenueDashboard {
        RevenueDashboard(
            thisMonth: stats(for: contracts, in: .month, now: now),
            thisQuarter: stats(for: contracts, in: .quarter, now: now),
            allTime: stats(for: contracts, in: .all, now: now)
        )
    }

    enum Period {
        case month, quarter, all
    }

    static func stats(for contracts: [Contract], in period: Period, now: Date = Date()) -> RevenuePeriodStats {
        let filtered = contracts.filter { contract in
            switch period {
            case .all: return true
            case .month: return Calendar.current.isDate(contract.createdAt, equalTo: now, toGranularity: .month)
            case .quarter:
                let q1 = Calendar.current.component(.quarter, from: contract.createdAt)
                let q2 = Calendar.current.component(.quarter, from: now)
                let y1 = Calendar.current.component(.year, from: contract.createdAt)
                let y2 = Calendar.current.component(.year, from: now)
                return q1 == q2 && y1 == y2
            }
        }

        var byType: [LicenseType: Int] = [:]
        for type in LicenseType.allCases {
            byType[type] = 0
        }
        var total = 0
        for contract in filtered {
            total += contract.price
            byType[contract.licenseType, default: 0] += 1
        }

        return RevenuePeriodStats(
            totalEUR: total,
            contractCount: filtered.count,
            byLicenseType: byType
        )
    }
}

extension Contract {

    var streamsUsed: Int { streamsReported ?? 0 }

    var streamUsageRatio: Double? {
        guard !licenseType.isExclusive, maxStreams > 0, maxStreams < Int.max else { return nil }
        return Double(streamsUsed) / Double(maxStreams)
    }

    var isApproachingStreamLimit: Bool {
        guard let ratio = streamUsageRatio else { return false }
        return ratio >= AppConstants.streamAlertThreshold
    }

    var isExpiredOrExpiringSoon: Bool {
        guard let expiresAt else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return days <= AppConstants.licenseExpiryWarningDays
    }

    var needsLicenseAlert: Bool {
        if licenseType.isExclusive { return false }
        return isApproachingStreamLimit || isExpiredOrExpiringSoon
    }

    var suggestedUpgradeLicense: LicenseType? {
        switch licenseType {
        case .mp3Lease: return .wavLease
        case .wavLease: return .trackoutLease
        case .trackoutLease: return .exclusive
        case .exclusive: return nil
        }
    }

    var licenseStatusLabel: String {
        if licenseType.isExclusive { return "Exclusif — illimité" }
        if let expiresAt, expiresAt < Date() { return "Expiré" }
        if isApproachingStreamLimit {
            return "\(streamsUsed.formatted()) / \(maxStreams.formatted()) streams"
        }
        if let expiresAt {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateStyle = .medium
            return "Expire le \(formatter.string(from: expiresAt))"
        }
        return "\(streamsUsed.formatted()) / \(maxStreams.formatted()) streams"
    }

    static func defaultExpiresAt(from createdAt: Date, licenseType: LicenseType) -> Date? {
        guard !licenseType.isExclusive else { return nil }
        return Calendar.current.date(byAdding: .month, value: AppConstants.defaultLeaseDurationMonths, to: createdAt)
    }
}
