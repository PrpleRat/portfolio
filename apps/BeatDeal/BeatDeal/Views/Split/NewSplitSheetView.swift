import SwiftUI

struct NewSplitSheetView: View {
    var splitImport: SplitPadImport? = nil
    var editingSplit: SplitSheet? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileStorage = ProfileStorage.shared
    @ObservedObject private var splitStorage = SplitSheetStorage.shared

    @State private var draft = SplitSheetDraft()
    @State private var previewSheet: SplitSheet?
    @State private var previewURL: URL?
    @State private var alertMessage: String?
    @State private var didLoadDraft = false

    private var totalMaster: Int {
        draft.collaborators.reduce(0) { $0 + $1.masterShare }
    }

    private var totalPublishing: Int {
        draft.collaborators.reduce(0) { $0 + $1.publishingShare }
    }

    private var canGenerate: Bool {
        !draft.title.trimmingCharacters(in: .whitespaces).isEmpty
            && totalMaster == 100
            && (draft.splitType == .masterOnly || totalPublishing == 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BeatDealSpacing.md) {
                    FormSectionHeader(title: "Morceau")
                    BeatDealTextField(title: "Titre", text: $draft.title, required: true)
                    BeatDealTextField(title: "Artiste principal", text: $draft.artist)
                    BeatDealTextField(title: "ISRC", text: $draft.isrc)
                    BeatDealTextField(title: "Montant convenu (€)", text: $draft.agreedPrice, keyboard: .numberPad)

                    SplitGenrePicker(genre: $draft.genre, subgenre: $draft.subgenre)

                    splitTypeSection

                    FormSectionHeader(title: "Collaborateurs")
                    ForEach($draft.collaborators) { $collab in
                        SplitCollaboratorEditor(
                            collaborator: $collab,
                            splitType: draft.splitType,
                            canRemove: draft.collaborators.count > 1,
                            onRemove: {
                                draft.collaborators.removeAll { $0.id == collab.id }
                            }
                        )
                    }

                    Button {
                        draft.collaborators.append(SplitCollaborator.empty())
                    } label: {
                        Label("Ajouter un collaborateur", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    FormSectionHeader(title: "Clauses")
                    ForEach(Array(draft.clauses.enumerated()), id: \.offset) { index, _ in
                        BeatDealTextField(
                            title: "Clause \(index + 1)",
                            text: Binding(
                                get: { draft.clauses[index] },
                                set: { draft.clauses[index] = $0 }
                            )
                        )
                    }
                    BeatDealTextField(title: "Notes", text: $draft.notes)

                    SplitTotalIndicator(label: "Master", total: totalMaster, target: 100)
                    if draft.splitType == .masterAndPublishing {
                        SplitTotalIndicator(label: "Publishing", total: totalPublishing, target: 100)
                    }

                    Button(draft.isEditing ? "Mettre à jour le PDF" : "Générer le PDF") { generate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canGenerate)
                        .opacity(canGenerate ? 1 : 0.5)
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(draft.isEditing ? "Modifier le split" : "Split en 90s")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear(perform: loadDraftIfNeeded)
            .sheet(item: $previewSheet) { sheet in
                SplitSheetPreviewView(
                    split: sheet,
                    pdfURL: previewURL,
                    onDismiss: { dismiss() },
                    onEdit: { previewSheet = nil }
                )
            }
            .alert("BeatDeal", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.sm) {
            HStack(spacing: BeatDealSpacing.xs) {
                FormSectionHeader(title: "Type de split")
                BeatDealInfoTip(
                    title: SplitConstants.Help.splitType.title,
                    text: SplitConstants.Help.splitType.text
                )
            }

            HStack(spacing: BeatDealSpacing.sm) {
                ForEach(SplitSheetType.allCases) { type in
                    Button(type.label) { draft.splitType = type }
                        .font(BeatDealTypography.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(draft.splitType == type ? BeatDealColors.accent : BeatDealColors.card)
                        .foregroundStyle(BeatDealColors.text)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func loadDraftIfNeeded() {
        guard !didLoadDraft else { return }
        didLoadDraft = true
        if let editingSplit {
            draft.applySheet(editingSplit)
        } else {
            draft.applyProfile(profileStorage.profile)
            if let splitImport {
                draft.applyImport(splitImport)
            }
        }
    }

    private func generate() {
        guard let sheet = draft.buildSheet() else {
            alertMessage = "Vérifie le titre et les pourcentages (100%)."
            return
        }
        do {
            let url = try SplitSheetPDFGenerator.generatePDF(for: sheet)
            splitStorage.save(sheet)
            previewURL = url
            previewSheet = sheet
        } catch {
            alertMessage = "Erreur PDF : \(error.localizedDescription)"
        }
    }
}
