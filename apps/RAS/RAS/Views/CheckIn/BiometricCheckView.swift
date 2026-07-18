import SwiftUI

struct BiometricCheckView: View {
    let onAuthenticate: () async -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(.safeGreen)

            Button {
                Task {
                    isLoading = true
                    await onAuthenticate()
                    isLoading = false
                }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Se vérifier avec Face ID / Touch ID")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
    }
}
