import SwiftUI

struct AlerteBanner: View {
    enum Style {
        case alert, warning
    }

    let message: String
    var style: Style = .alert

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style == .alert ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(style == .alert ? CarenceColors.alert : CarenceColors.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style == .alert ? CarenceColors.alertBackground : CarenceColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(message)
    }
}
