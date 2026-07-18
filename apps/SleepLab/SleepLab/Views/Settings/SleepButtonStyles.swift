import SwiftUI

/// Zone tactile = toute la surface du label (pas seulement le texte).
struct FullAreaTapButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

extension ButtonStyle where Self == FullAreaTapButtonStyle {
    static var fullAreaTap: FullAreaTapButtonStyle { FullAreaTapButtonStyle() }

    static func fullAreaTap(cornerRadius: CGFloat) -> FullAreaTapButtonStyle {
        FullAreaTapButtonStyle(cornerRadius: cornerRadius)
    }
}

/// Puces du catalogue (forme capsule).
struct CapsuleTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

extension ButtonStyle where Self == CapsuleTapButtonStyle {
    static var capsuleTap: CapsuleTapButtonStyle { CapsuleTapButtonStyle() }
}
