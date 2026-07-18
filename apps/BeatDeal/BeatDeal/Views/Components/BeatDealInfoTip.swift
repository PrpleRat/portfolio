import SwiftUI

struct BeatDealInfoTip: View {
    let title: String
    let text: String

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(BeatDealColors.accentLight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Aide : \(title)")
        .alert(title, isPresented: $isPresented) {
            Button("Compris", role: .cancel) {}
        } message: {
            Text(text)
        }
    }
}
