import SwiftUI

struct QuestionCheckView: View {
    let question: String
    @Binding var answer: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question)
                .font(.headline)

            TextField("Ta réponse", text: $answer)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Valider", action: onSubmit)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }
}
