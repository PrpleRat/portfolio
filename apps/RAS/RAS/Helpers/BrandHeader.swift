import SwiftUI

/// En-tête marque : RAS + sous-titre Fusée de détresse
struct BrandHeader: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 2 : 4) {
            Text(AppConstants.appName)
                .font(compact ? .headline.bold() : .largeTitle.bold())
            Text(AppConstants.appTagline)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    BrandHeader()
}
