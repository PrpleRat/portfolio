import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showImporter = false
    @State private var statusMessage: String?
    @State private var showStatus = false
    @State private var showReplaceConfirm = false
    @State private var pendingImportData: Data?
    @State private var isBusy = false

    var body: some View {
        Form {
            Section {
                Text("Exporte toutes tes nuits, facteurs, rêves, profil et réglages en un fichier JSON sur ton iPhone. Aucun cloud — tu gardes le fichier.")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Exporter") {
                Button {
                    exportBackup()
                } label: {
                    Label("Créer une sauvegarde JSON", systemImage: "square.and.arrow.up")
                }
                .disabled(isBusy)
                Text("Les extraits audio (.m4a) ne sont pas inclus — seulement les métadonnées.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Importer") {
                Button {
                    showImporter = true
                } label: {
                    Label("Restaurer depuis un fichier JSON", systemImage: "square.and.arrow.down")
                }
                .disabled(isBusy)

                Text("Fusion : ajoute les entrées absentes (par identifiant). Remplacer tout efface d’abord les données locales.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Sauvegarde")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet, onDismiss: { exportURL = nil }) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportPicker(result)
        }
        .confirmationDialog(
            "Remplacer toutes les données ?",
            isPresented: $showReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Fusionner (recommandé)") {
                runImport(mode: .merge)
            }
            Button("Tout remplacer", role: .destructive) {
                runImport(mode: .replaceAll)
            }
            Button("Annuler", role: .cancel) {
                pendingImportData = nil
            }
        } message: {
            Text("Tu peux fusionner sans perdre les nuits déjà présentes, ou tout effacer puis importer.")
        }
        .alert("Sauvegarde", isPresented: $showStatus) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func exportBackup() {
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            do {
                let url = try SleepDataBackupService.exportToTemporaryFile(from: modelContext)
                exportURL = url
                showShareSheet = true
            } catch {
                statusMessage = error.localizedDescription
                showStatus = true
            }
        }
    }

    private func handleImportPicker(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            statusMessage = error.localizedDescription
            showStatus = true
        case .success(let urls):
            guard let url = urls.first else { return }
            isBusy = true
            Task { @MainActor in
                defer { isBusy = false }
                do {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    pendingImportData = try Data(contentsOf: url)
                    showReplaceConfirm = true
                } catch {
                    statusMessage = error.localizedDescription
                    showStatus = true
                }
            }
        }
    }

    private func runImport(mode: SleepDataBackupService.ImportMode) {
        guard let data = pendingImportData else { return }
        pendingImportData = nil
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            do {
                let result = try SleepDataBackupService.importBackup(
                    data: data,
                    into: modelContext,
                    mode: mode
                )
                statusMessage = """
                Import terminé.
                Nuits : +\(result.sessionsImported) (ignorées : \(result.sessionsSkipped))
                Facteurs : +\(result.factorsImported)
                Rêves : +\(result.dreamsImported)
                """
                showStatus = true
            } catch {
                statusMessage = error.localizedDescription
                showStatus = true
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
