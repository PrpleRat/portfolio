import SwiftUI

struct RevenueDashboardView: View {
    @ObservedObject private var storage = ContractStorage.shared
    @ObservedObject private var profileStorage = ProfileStorage.shared

    private var currencySymbol: String { profileStorage.profile.currency.rawValue }

    private var dashboard: RevenueDashboard {
        RevenueStatsEngine.dashboard(from: storage.contracts)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    periodCard(title: "Ce mois", stats: dashboard.thisMonth)
                    periodCard(title: "Ce trimestre", stats: dashboard.thisQuarter)
                    periodCard(title: "Depuis le début", stats: dashboard.allTime, highlight: true)
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle("Revenus")
        }
    }

    private func periodCard(title: String, stats: RevenuePeriodStats, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
            Text(title)
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                Text("\(stats.totalEUR) \(currencySymbol)")
                    .font(highlight ? BeatDealTypography.title : BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
                Spacer()
                Text("\(stats.contractCount) contrat\(stats.contractCount > 1 ? "s" : "")")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
            }

            if stats.contractCount > 0 {
                VStack(spacing: BeatDealSpacing.sm) {
                    ForEach(LicenseType.allCases) { type in
                        let count = stats.byLicenseType[type] ?? 0
                        if count > 0 {
                            licenseRow(type: type, count: count, total: stats.contractCount)
                        }
                    }
                }
            }
        }
        .beatDealCard(selected: highlight)
    }

    private func licenseRow(type: LicenseType, count: Int, total: Int) -> some View {
        HStack {
            Text(type.title)
                .font(BeatDealTypography.body)
                .foregroundStyle(BeatDealColors.text)
            Spacer()
            Text("\(count)")
                .font(BeatDealTypography.headline)
                .foregroundStyle(type.badgeColor)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BeatDealColors.separator)
                    Capsule()
                        .fill(type.badgeColor)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(total, 1)))
                }
            }
            .frame(width: 80, height: 6)
        }
    }
}

#Preview {
    RevenueDashboardView()
        .preferredColorScheme(.dark)
}
