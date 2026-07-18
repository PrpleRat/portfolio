import SwiftUI

struct MultiStopEditor: View {
    @Binding var stops: [Place]
    @Binding var texts: [String]
    let onAdd: () -> Void
    let onRemove: (Int) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stops.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                    TextField("Étape \(index + 1)", text: binding(for: index))
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button(role: .destructive) {
                        onRemove(index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                }
            }
            .onMove(perform: onMove)

            if stops.count < AppConstants.maxIntermediateStops {
                Button(action: onAdd) {
                    Label("Ajouter une étape", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { texts.indices.contains(index) ? texts[index] : "" },
            set: { newValue in
                if texts.indices.contains(index) { texts[index] = newValue }
            }
        )
    }
}
