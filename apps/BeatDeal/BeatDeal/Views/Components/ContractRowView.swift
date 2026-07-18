import SwiftUI

struct ContractRowView: View {
    let contract: Contract
    var onOpen: () -> Void
    var onShare: () -> Void
    var onDelete: (() -> Void)?

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        return formatter.string(from: contract.createdAt)
    }

    var body: some View {
        HStack(spacing: BeatDealSpacing.md) {
            Button(action: onOpen) {
                HStack(spacing: BeatDealSpacing.md) {
                    VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
                        Text(contract.displayBeatTitle)
                            .font(BeatDealTypography.headline)
                            .foregroundStyle(BeatDealColors.text)
                            .lineLimit(1)

                        Text(contract.artistName)
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: BeatDealSpacing.sm) {
                            Text(contract.licenseType.title)
                                .font(BeatDealTypography.badge)
                                .foregroundStyle(contract.licenseType.badgeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(BeatDealColors.separator)
                                .clipShape(Capsule())

                            Text(dateLabel)
                                .font(BeatDealTypography.caption)
                                .foregroundStyle(BeatDealColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Button(action: onShare) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(BeatDealColors.accentLight)
                    .padding(10)
                    .background(BeatDealColors.separator)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .beatDealCard()
        .contextMenu {
            if let onDelete {
                Button("Supprimer", systemImage: "trash", role: .destructive, action: onDelete)
            }
        }
    }
}
