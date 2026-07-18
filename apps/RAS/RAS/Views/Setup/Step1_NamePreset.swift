import SwiftUI

struct Step1_NamePreset: View {
    @ObservedObject var vm: SetupViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Type d'activité")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SessionPreset.all) { preset in
                        Button {
                            vm.applyPreset(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(preset.emoji) \(preset.name)")
                                    .font(.subheadline.bold())
                                    .multilineTextAlignment(.leading)
                                Text(vm.durationLabel(for: preset.defaultIntervalMinutes))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                vm.selectedPreset.id == preset.id
                                    ? Color.safeGreen.opacity(0.15)
                                    : Color.safeCard
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("Nom de la session", text: $vm.sessionName)
                    .textFieldStyle(.roundedBorder)

                if !vm.selectedPreset.warningText.isEmpty {
                    Text(vm.selectedPreset.warningText)
                        .font(.caption)
                        .foregroundStyle(.safeOrange)
                        .padding()
                        .background(Color.safeOrange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}
