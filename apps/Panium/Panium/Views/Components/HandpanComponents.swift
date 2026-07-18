import SwiftUI

struct SettingsButton: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOpen ? "xmark" : "slider.horizontal.3")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(HandpanColors.icon)
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(HandpanColors.border.opacity(0.8), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
    }
}

struct ScaleTitle: View {
    let name: String

    var body: some View {
        Text(name)
            .font(HandpanTypography.scaleTitle)
            .foregroundStyle(HandpanColors.text)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }
}

struct StatusBadgeView: View {
    let status: AudioStatus

    var body: some View {
        if status == .ready {
            EmptyView()
        } else {
            Text(status == .loading ? "Loading sounds…" : "Sounds unavailable")
                .font(HandpanTypography.status)
                .foregroundStyle(HandpanColors.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(HandpanColors.border.opacity(0.7), lineWidth: 0.8)
                }
        }
    }
}
