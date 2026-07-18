import SwiftUI

struct ExpandableSection<Content: View>: View {
    let title: String
    var systemImage: String? = nil
    var startsExpanded: Bool = false
    var background: Color = CarenceColors.surface
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(
        title: String,
        systemImage: String? = nil,
        startsExpanded: Bool = false,
        background: Color = CarenceColors.surface,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.startsExpanded = startsExpanded
        self.background = background
        self.content = content
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.subheadline)
                            .foregroundStyle(CarenceColors.primary)
                    }
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CarenceColors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.top, 12)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }
}
