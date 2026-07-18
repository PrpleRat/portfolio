import SwiftUI

struct PasswordCheckView: View {
    @Binding var password: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            SecureField("Mot de passe", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.go)
                .onSubmit(onSubmit)

            Button("Valider", action: onSubmit)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }
}
