import SwiftUI

struct DisruptionBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.red.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
