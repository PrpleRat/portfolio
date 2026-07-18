import SwiftUI
import UIKit

struct FormSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(BeatDealTypography.caption)
            .foregroundStyle(BeatDealColors.textSecondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, BeatDealSpacing.sm)
    }
}

struct BeatDealTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var required = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(required ? "\(title) *" : title)
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(BeatDealColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BeatDealColors.separator, lineWidth: 1)
                )
                .foregroundStyle(BeatDealColors.text)
        }
    }
}

struct RightsToggleSection: View {
    @Binding var rights: ContractRights

    var body: some View {
        VStack(spacing: BeatDealSpacing.sm) {
            ForEach(Array(ContractRights.allLabels.enumerated()), id: \.offset) { _, item in
                Toggle(isOn: binding(for: item.keyPath)) {
                    Text(item.label)
                        .font(BeatDealTypography.body)
                        .foregroundStyle(BeatDealColors.text)
                }
                .tint(BeatDealColors.accent)
            }
        }
        .padding(BeatDealSpacing.md)
        .beatDealCard()
    }

    private func binding(for keyPath: WritableKeyPath<ContractRights, Bool>) -> Binding<Bool> {
        Binding(
            get: { rights[keyPath: keyPath] },
            set: { rights[keyPath: keyPath] = $0 }
        )
    }
}
