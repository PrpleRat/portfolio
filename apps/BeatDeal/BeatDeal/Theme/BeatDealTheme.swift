import SwiftUI

enum BeatDealColors {
    static let background = Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255)
    static let card = Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255)
    static let accent = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255)
    static let accentLight = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255)
    static let text = Color(red: 248 / 255, green: 248 / 255, blue: 248 / 255)
    static let textSecondary = Color(red: 136 / 255, green: 136 / 255, blue: 136 / 255)
    static let success = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    static let separator = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
}

enum BeatDealTypography {
    static let title = Font.system(size: 28, weight: .bold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let badge = Font.system(size: 11, weight: .semibold)
}

enum BeatDealSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

struct BeatDealCardStyle: ViewModifier {
    var selected = false

    func body(content: Content) -> some View {
        content
            .padding(BeatDealSpacing.md)
            .background(BeatDealColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? BeatDealColors.accent : BeatDealColors.separator, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
}

extension View {
    func beatDealCard(selected: Bool = false) -> some View {
        modifier(BeatDealCardStyle(selected: selected))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BeatDealTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BeatDealColors.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BeatDealTypography.body)
            .foregroundStyle(BeatDealColors.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(BeatDealColors.card.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BeatDealColors.separator, lineWidth: 1)
            )
    }
}
