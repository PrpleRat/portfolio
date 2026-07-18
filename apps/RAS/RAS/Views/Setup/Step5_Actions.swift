import SwiftUI

struct Step5_Actions: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        Form {
            Section("Actions si pas de réponse") {
                ForEach(AlertAction.allCases) { action in
                    Toggle(isOn: binding(for: action)) {
                        HStack {
                            Image(systemName: action.sfSymbol)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(action.displayName)
                                    if action.worksOffline {
                                        Text("Sans internet")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.safeGreen.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(action.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Message personnalisé (optionnel)") {
                TextEditor(text: $vm.customMessage)
                    .frame(minHeight: 80)
            }

            Section("Aperçu du message") {
                Text(previewMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var previewMessage: String {
        let base = vm.customMessage.isEmpty
            ? "⚠️ RAS : \(vm.sessionName) — Pas de réponse au check-in."
            : vm.customMessage
        return base + "\n— Envoyé automatiquement par RAS"
    }

    private func binding(for action: AlertAction) -> Binding<Bool> {
        Binding(
            get: { vm.selectedActions.contains(action) },
            set: { isOn in
                if isOn { vm.selectedActions.insert(action) }
                else { vm.selectedActions.remove(action) }
            }
        )
    }
}
