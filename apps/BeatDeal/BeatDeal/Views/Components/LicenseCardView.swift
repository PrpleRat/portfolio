import SwiftUI

struct LicenseCardView: View {
    let licenseType: LicenseType
    let price: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: BeatDealSpacing.md) {
                Image(systemName: licenseType.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? BeatDealColors.accentLight : BeatDealColors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
                    HStack {
                        Text(licenseType.title)
                            .font(BeatDealTypography.headline)
                            .foregroundStyle(BeatDealColors.text)
                        Spacer()
                        Text("\(price) €")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.accentLight)
                    }
                    Text(licenseType.shortDescription)
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .beatDealCard(selected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LicenseCardView(licenseType: .wavLease, price: 49, isSelected: true, onTap: {})
        .padding()
        .background(BeatDealColors.background)
        .preferredColorScheme(.dark)
}
