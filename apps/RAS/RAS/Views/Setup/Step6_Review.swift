import SwiftUI

struct Step6_Review: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                reviewCard("Session", "\(vm.selectedPreset.emoji) \(vm.sessionName)")
                reviewCard("Intervalle", vm.durationLabel(for: vm.intervalMinutes))
                reviewCard("Vérification", vm.checkInMethod.displayName)
                reviewCard("Contacts", "\(vm.contacts.count) contact(s)")
                reviewCard("Actions", vm.selectedActions.map(\.displayName).joined(separator: ", "))

                Toggle("Sauvegarder comme modèle", isOn: $vm.saveAsTemplate)

                Text("Les notifications locales seront planifiées à l'avance. Active les notifications pour RAS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func reviewCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.safeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
