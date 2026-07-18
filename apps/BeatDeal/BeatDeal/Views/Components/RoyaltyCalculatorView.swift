import SwiftUI

struct RoyaltyCalculatorView: View {
    let licenseType: LicenseType
    let licensePrice: Int

    @State private var projectedStreams: Double = 50_000
    @State private var selectedPlatformId: String = RoyaltyRates.shared.defaultPlatformId

    private var platform: StreamingPlatform {
        RoyaltyRates.platform(id: selectedPlatformId) ?? RoyaltyRates.defaultPlatform
    }

    private var projection: RoyaltyProjection {
        RoyaltyCalculator.project(
            platform: platform,
            projectedStreams: Int(projectedStreams),
            licensePrice: licensePrice,
            licenseTitle: licenseType.title
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(BeatDealColors.accentLight)
                Text("Calculateur de royalties")
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Plateforme")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                Picker("Plateforme", selection: $selectedPlatformId) {
                    ForEach(RoyaltyRates.shared.platforms) { platform in
                        Text(platform.name).tag(platform.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(BeatDealColors.accentLight)
            }

            VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
                HStack {
                    Text("Streams projetés")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                    Spacer()
                    Text(Int(projectedStreams).formatted())
                        .font(BeatDealTypography.headline)
                        .foregroundStyle(BeatDealColors.accentLight)
                }
                Slider(value: $projectedStreams, in: 1_000...500_000, step: 1_000)
                    .tint(BeatDealColors.accent)
            }

            VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
                Text(projection.summaryLine)
                    .font(BeatDealTypography.body)
                    .foregroundStyle(BeatDealColors.text)

                Text(projection.breakEvenLine)
                    .font(BeatDealTypography.body)
                    .foregroundStyle(BeatDealColors.textSecondary)

                if projection.isProfitable {
                    Label("Rentable à ce volume", systemImage: "checkmark.circle.fill")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.success)
                } else {
                    Label("En dessous du seuil de rentabilité", systemImage: "info.circle")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                }
            }
        }
        .beatDealCard(selected: false)
    }
}

#Preview {
    RoyaltyCalculatorView(licenseType: .wavLease, licensePrice: 49)
        .padding()
        .background(BeatDealColors.background)
        .preferredColorScheme(.dark)
}
