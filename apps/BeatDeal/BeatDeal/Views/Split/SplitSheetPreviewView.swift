import SwiftUI
import WebKit

struct SplitSheetPreviewView: View {
    let split: SplitSheet
    let pdfURL: URL?
    let onDismiss: () -> Void
    var onEdit: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    @State private var showContract = false
    @State private var beatBillMissing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SplitHTMLWebView(html: SplitSheetHTMLBuilder.buildHTML(for: split))
                    .frame(maxHeight: .infinity)

                VStack(spacing: BeatDealSpacing.sm) {
                    Button("Partager le PDF") { showShare = true }
                        .buttonStyle(PrimaryButtonStyle())

                    if onEdit != nil {
                        Button("Modifier le split") {
                            dismiss()
                            onEdit?()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Button("Créer un contrat de licence") {
                        showContract = true
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Facturer avec BeatBill") {
                        if !BeatBillLink.openInvoice(from: split) {
                            beatBillMissing = true
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(BeatDealSpacing.md)
                .background(BeatDealColors.card)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle("Aperçu split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                if let pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
            .sheet(isPresented: $showContract) {
                NewContractView(splitImport: split.asSplitPadImport())
            }
            .alert("BeatBill introuvable", isPresented: $beatBillMissing) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Installe BeatBill pour facturer depuis ce split.")
            }
        }
    }
}

private extension SplitSheet {
    func asSplitPadImport() -> SplitPadImport {
        let coProd = collaborators.dropFirst().first
        return SplitPadImport(
            ref: ref,
            title: title,
            artist: artist,
            coProducerName: coProd?.name,
            coProducerSharePercent: coProd?.masterShare
        )
    }
}

private struct SplitHTMLWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
