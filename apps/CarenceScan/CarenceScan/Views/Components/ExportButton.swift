import SwiftUI

struct ExportButton: View {
    let payload: SavedResultsPayload
    @State private var shareItem: SharePDFItem?
    @State private var exportError = false

    var body: some View {
        Button {
            exportPDF()
        } label: {
            Label("Exporter ma fiche PDF", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(CarenceColors.primary)
        .accessibilityLabel("Exporter ma fiche PDF")
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
        guard let data = PDFExportService.generatePDF(payload: payload) else {
            exportError = true
            return
        }
        let filename = "CarenceScan-Bilan-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            shareItem = SharePDFItem(url: url)
        } catch {
            exportError = true
        }
    }
}

struct SharePDFItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
