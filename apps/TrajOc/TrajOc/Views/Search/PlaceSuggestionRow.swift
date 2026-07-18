import SwiftUI

struct PlaceSuggestionRow: View {
    let place: Place
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if !place.displaySubtitle.isEmpty {
                        Text(place.displaySubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch place.type {
        case .stopArea, .stopPoint, .gare: return "train.side.front.car"
        case .address: return "mappin.circle.fill"
        default: return "mappin.and.ellipse"
        }
    }

    private var iconBackground: Color {
        place.isStation ? TransportStyle.occitanieRed() : Color(.systemBlue)
    }
}
