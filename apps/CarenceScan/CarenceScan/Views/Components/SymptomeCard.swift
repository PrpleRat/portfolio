import SwiftUI

struct SymptomeCard: View {
    let label: String
    let isSelected: Bool
    let frequence: Frequence
    let onToggle: () -> Void
    let onFrequenceChange: (Frequence) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isSelected ? CarenceColors.primary : CarenceColors.textSecondary)
                        .font(.title3)

                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if isSelected {
                HStack(spacing: 8) {
                    ForEach(Frequence.allCases, id: \.self) { freq in
                        Button {
                            onFrequenceChange(freq)
                        } label: {
                            VStack(spacing: 2) {
                                Text(freq.emoji)
                                    .font(.caption)
                                Text(freq.label)
                                    .font(.caption2)
                                    .foregroundStyle(frequence == freq ? .white : CarenceColors.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(frequence == freq ? CarenceColors.primary : CarenceColors.border.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Fréquence \(freq.label)")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(isSelected ? CarenceColors.primary.opacity(0.08) : CarenceColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? CarenceColors.primary.opacity(0.4) : CarenceColors.border, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
