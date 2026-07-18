import SwiftUI

struct TransportBadge: View {
    let mode: TransportMode
    var label: String?
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode.sfSymbol)
            if let label, !compact {
                Text(label)
            }
        }
        .font(compact ? .caption2 : .caption.weight(.semibold))
        .padding(.horizontal, compact ? 4 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(TransportStyle.color(for: mode).opacity(0.15))
        .foregroundStyle(TransportStyle.color(for: mode))
        .clipShape(Capsule())
    }
}
