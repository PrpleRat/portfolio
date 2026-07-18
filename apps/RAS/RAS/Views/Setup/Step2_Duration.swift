import SwiftUI

struct Step2_Duration: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Intervalle de vérification")
                .font(.headline)

            Picker("Durée", selection: $vm.intervalMinutes) {
                ForEach(AppConstants.availableDurations, id: \.self) { minutes in
                    Text(vm.durationLabel(for: minutes)).tag(minutes)
                }
            }
            .pickerStyle(.wheel)

            Text("Tu devras te vérifier toutes les \(vm.durationLabel(for: vm.intervalMinutes)).")
                .foregroundStyle(.secondary)

            Text("Délai de grâce : \(AppConstants.gracePeriodMinutes) min après l'échéance avant l'alerte.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}
