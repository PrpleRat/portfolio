import SwiftUI

struct TransportFilterView: View {
    @Binding var enabledModes: Set<TransportMode>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modes de transport")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransportMode.filterGroups, id: \.label) { group in
                        let isOn = group.modes.allSatisfy { enabledModes.contains($0) }
                        Button {
                            toggleGroup(group.modes)
                        } label: {
                            Text(group.label)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isOn ? TransportStyle.occitanieRed() : Color(.secondarySystemBackground))
                                .foregroundStyle(isOn ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func toggleGroup(_ modes: [TransportMode]) {
        if modes.allSatisfy({ enabledModes.contains($0) }) {
            modes.forEach { enabledModes.remove($0) }
        } else {
            modes.forEach { enabledModes.insert($0) }
        }
    }
}
