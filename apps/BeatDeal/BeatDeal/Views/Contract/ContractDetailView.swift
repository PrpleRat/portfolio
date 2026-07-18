import SwiftUI

/// Réouvre un contrat enregistré (PDF, DM Kit, checklist livraison).
struct ContractDetailView: View {
    let contract: Contract

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = ContractStorage.shared
    @State private var pdfURL: URL?
    @State private var loadError: String?
    @State private var showEdit = false

    var body: some View {
        Group {
            if let pdfURL {
                ContractPreviewView(
                    contract: contract,
                    pdfURL: pdfURL,
                    allowEdit: false,
                    onEdit: { showEdit = true },
                    onSaved: { dismiss() },
                    onDelete: { storage.delete(contract) }
                )
            } else if let loadError {
                VStack(spacing: BeatDealSpacing.md) {
                    Text(loadError)
                        .font(BeatDealTypography.body)
                        .foregroundStyle(BeatDealColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Fermer") { dismiss() }
                        .buttonStyle(SecondaryButtonStyle())
                }
                .padding(BeatDealSpacing.lg)
            } else {
                ProgressView("Chargement du contrat…")
                    .tint(BeatDealColors.accent)
            }
        }
        .task {
            do {
                pdfURL = try PDFGenerator.generatePDF(for: contract)
            } catch {
                loadError = "Impossible de charger le PDF."
            }
        }
        .sheet(isPresented: $showEdit) {
            NewContractView(editingContract: contract)
        }
    }
}
