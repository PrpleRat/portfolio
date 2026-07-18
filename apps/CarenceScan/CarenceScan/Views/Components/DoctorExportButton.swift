import SwiftUI

struct DoctorExportButton: View {
    let payload: SavedResultsPayload
    @State private var shareItem: SharePDFItem?
    @State private var exportError = false

    var body: some View {
        Button {
            exportPDF()
        } label: {
            Label("Exporter pour mon médecin", systemImage: "stethoscope")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(CarenceColors.warning)
        .accessibilityLabel("Exporter une fiche courte pour le médecin")
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert("Export impossible", isPresented: $exportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("La génération du PDF a échoué. Réessayez.")
        }
    }

    private func exportPDF() {
        guard let data = DoctorExportService.generatePDF(payload: payload) else {
            exportError = true
            return
        }
        let filename = "CarenceScan-Medecin-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            shareItem = SharePDFItem(url: url)
        } catch {
            exportError = true
        }
    }
}
