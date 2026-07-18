import SwiftUI

struct DateTimePicker: View {
    @Binding var departAt: Bool
    @Binding var selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Horodatage", selection: $departAt) {
                Text("Départ").tag(true)
                Text("Arrivée à").tag(false)
            }
            .pickerStyle(.segmented)

            DatePicker(
                departAt ? "Heure de départ" : "Heure d'arrivée",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
