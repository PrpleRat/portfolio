import SwiftUI

struct TrackingExportButton: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @State private var shareItem: SharePDFItem?
    @State private var exportError = false

    var body: some View {
        Button {
            exportPDF()
        } label: {
            Label("Exporter suivi pour mon médecin", systemImage: "doc.richtext")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(CarenceColors.warning)
        .accessibilityLabel("Exporter le suivi symptômes pour le médecin")
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
        guard let baseline = ResultsStorage.load() else {
            exportError = true
            return
        }
        let evolutif = EvolutiveBilanEngine.calculerDepuisStockage(tracker: tracker)
        guard let data = TrackingDoctorExportService.generatePDF(
            baseline: baseline,
            evolutif: evolutif,
            tracker: tracker
        ) else {
            exportError = true
            return
        }
        let filename = "CarenceScan-Suivi-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            shareItem = SharePDFItem(url: url)
        } catch {
            exportError = true
        }
    }
}
