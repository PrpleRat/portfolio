import SwiftUI
import WebKit

struct NewContractView: View {
    var splitImport: SplitPadImport? = nil
    var editingContract: Contract? = nil
    var upgradeFromContract: Contract? = nil
    var prefillBeat: CatalogBeat? = nil
    var prefillPack: BeatPack? = nil
    var prefillLicense: LicenseType? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileStorage = ProfileStorage.shared
    @ObservedObject private var templateStorage = TemplateStorage.shared
    @ObservedObject private var catalogStorage = BeatCatalogStorage.shared

    @State private var draft = ContractDraft()
    @State private var previewContract: Contract?
    @State private var previewPDFURL: URL?
    @State private var isGenerating = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepProgressView(currentStep: draft.step, totalSteps: 3)
                    .padding(.horizontal, BeatDealSpacing.md)
                    .padding(.top, BeatDealSpacing.sm)

                ScrollView {
                    VStack(spacing: BeatDealSpacing.md) {
                        switch draft.step {
                        case 1: step1Content
                        case 2: step2Content
                        default: step3Content
                        }
                    }
                    .padding(BeatDealSpacing.md)
                }

                navigationBar
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(draft.contractId != nil ? "Modifier le contrat" : "Nouveau contrat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .sheet(item: $previewContract) { contract in
                ContractPreviewView(
                    contract: contract,
                    pdfURL: previewPDFURL,
                    onEdit: {
                        previewContract = nil
                    },
                    onSaved: {
                        previewContract = nil
                        dismiss()
                    }
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
            .onAppear(perform: loadInitialDraft)
        }
    }

    // MARK: - Step 1

    private var step1Content: some View {
        VStack(spacing: BeatDealSpacing.sm) {
            Text("Type de licence")
                .font(BeatDealTypography.headline)
                .foregroundStyle(BeatDealColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(LicenseType.allCases) { type in
                let template = templateStorage.template(for: type)
                LicenseCardView(
                    licenseType: type,
                    price: template.defaultPrice,
                    isSelected: draft.licenseType == type
                ) {
                    draft.licenseType = type
                    draft.applyTemplate(template)
                }
            }

            if let licenseType = draft.licenseType {
                let price = Int(draft.price) ?? templateStorage.template(for: licenseType).defaultPrice
                RoyaltyCalculatorView(licenseType: licenseType, licensePrice: price)
            }
        }
    }

    // MARK: - Step 2

    private var step2Content: some View {
        VStack(spacing: BeatDealSpacing.md) {
            FormSectionHeader(title: "Infos artiste / acheteur")
            BeatDealTextField(title: "Nom de l'artiste", text: $draft.artistName, required: true)
            BeatDealTextField(title: "Email de l'artiste", text: $draft.artistEmail, keyboard: .emailAddress, required: true)

            FormSectionHeader(title: "Infos beat")

            if !catalogStorage.beats.isEmpty || !catalogStorage.packs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Depuis le catalogue")
                        .font(BeatDealTypography.caption)
                        .foregroundStyle(BeatDealColors.textSecondary)

                    if !catalogStorage.packs.isEmpty {
                        Picker("Pack", selection: $draft.catalogPackId) {
                            Text("Aucun pack").tag(Optional<String>.none)
                            ForEach(catalogStorage.packs) { pack in
                                Text(pack.title).tag(Optional(pack.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BeatDealColors.accentLight)
                        .onChange(of: draft.catalogPackId) { _, newId in
                            if let pack = catalogStorage.pack(id: newId) {
                                let beats = catalogStorage.beats(for: pack)
                                draft.applyCatalogPack(pack, beats: beats, licenseType: draft.licenseType)
                            }
                        }
                    }

                    if !catalogStorage.beats.isEmpty {
                        Picker("Beat", selection: $draft.catalogBeatId) {
                            Text("Saisie manuelle").tag(Optional<String>.none)
                            ForEach(catalogStorage.beats) { beat in
                                Text(beat.title).tag(Optional(beat.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BeatDealColors.accentLight)
                        .disabled(draft.catalogPackId != nil)
                        .onChange(of: draft.catalogBeatId) { _, newId in
                            if let beat = catalogStorage.beat(id: newId) {
                                draft.applyCatalogBeat(beat, licenseType: draft.licenseType)
                            }
                        }
                    }
                }
            }

            if draft.catalogPackId == nil {
                BeatDealTextField(title: "Titre du beat", text: $draft.beatTitle, required: true)
                BeatDealTextField(title: "BPM", text: $draft.bpm, keyboard: .numberPad)

                HStack(spacing: BeatDealSpacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tonalité")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                        Picker("Tonalité", selection: $draft.selectedKey) {
                            Text("—").tag(Optional<MusicalKey>.none)
                            ForEach(MusicalKey.allCases) { key in
                                Text(key.label).tag(Optional(key))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BeatDealColors.accentLight)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mode")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                        Picker("Mode", selection: $draft.selectedMode) {
                            Text("—").tag(Optional<KeyMode>.none)
                            ForEach(KeyMode.allCases) { mode in
                                Text(mode.rawValue).tag(Optional(mode))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BeatDealColors.accentLight)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else if let items = draft.packBeatItems {
                VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
                    Text(draft.packTitle ?? draft.beatTitle)
                        .font(BeatDealTypography.headline)
                        .foregroundStyle(BeatDealColors.text)
                    ForEach(items) { item in
                        Text("• \(item.title)")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                    }
                }
                .beatDealCard()
            }

            CoProducerEditorView(enabled: $draft.enableCoProducer, coProducer: $draft.coProducer)

            FormSectionHeader(title: "Infos producteur")
            BeatDealTextField(title: "Nom de producteur", text: $draft.producerName, required: true)
            BeatDealTextField(title: "Email", text: $draft.producerEmail, keyboard: .emailAddress, required: true)
            BeatDealTextField(title: "Alias (ex : Prod. by Metro)", text: $draft.producerAlias)

            FormSectionHeader(title: "Prix & paiement")
            BeatDealTextField(title: "Prix final", text: $draft.price, keyboard: .numberPad, required: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Mode de paiement")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                Picker("Mode de paiement", selection: $draft.paymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.menu)
                .tint(BeatDealColors.accentLight)
            }

            BeatDealTextField(title: "Référence de paiement", text: $draft.paymentReference)
        }
    }

    // MARK: - Step 3

    private var step3Content: some View {
        VStack(spacing: BeatDealSpacing.md) {
            Text("Droits accordés")
                .font(BeatDealTypography.headline)
                .foregroundStyle(BeatDealColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            RightsToggleSection(rights: $draft.rights)

            if let licenseType = draft.licenseType, !licenseType.isExclusive {
                BeatDealTextField(
                    title: "Limite de streams",
                    text: Binding(
                        get: { String(draft.maxStreams) },
                        set: { draft.maxStreams = Int($0.filter(\.isNumber)) ?? draft.maxStreams }
                    ),
                    keyboard: .numberPad
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Clauses additionnelles")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                TextField("Ajoute ici des conditions spécifiques…", text: $draft.additionalClauses, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(BeatDealColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(BeatDealColors.separator, lineWidth: 1)
                    )
                    .foregroundStyle(BeatDealColors.text)
            }

            Button {
                Task { await generateContract() }
            } label: {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Générer le contrat PDF")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isGenerating)
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            if draft.step > 1 {
                Button("Retour") { draft.step -= 1 }
                    .foregroundStyle(BeatDealColors.textSecondary)
            }
            Spacer()
            if draft.step < 3 {
                Button("Suivant") { draft.step += 1 }
                    .buttonStyle(.borderedProminent)
                    .tint(BeatDealColors.accent)
                    .disabled(!canProceed)
            }
        }
        .padding(BeatDealSpacing.md)
        .background(BeatDealColors.card)
    }

    private var canProceed: Bool {
        switch draft.step {
        case 1: return draft.canProceedStep1
        case 2: return draft.canProceedStep2
        default: return true
        }
    }

    private func generateContract() async {
        guard let contract = draft.buildContract() else {
            alertMessage = "Vérifie les champs obligatoires."
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let url = try PDFGenerator.generatePDF(for: contract)
            previewPDFURL = url
            previewContract = contract
        } catch {
            alertMessage = "Erreur PDF : \(error.localizedDescription)"
        }
    }

    private func loadInitialDraft() {
        if let editingContract {
            draft.applyContract(editingContract)
            return
        }
        if let upgradeFromContract, let upgrade = upgradeFromContract.suggestedUpgradeLicense {
            draft.applyUpgrade(
                from: upgradeFromContract,
                to: upgrade,
                template: templateStorage.template(for: upgrade),
                catalog: catalogStorage
            )
            return
        }
        draft.applyProfile(profileStorage.profile)
        if let license = prefillLicense {
            draft.licenseType = license
            draft.applyTemplate(templateStorage.template(for: license))
        }
        if let beat = prefillBeat {
            draft.applyCatalogBeat(beat, licenseType: draft.licenseType)
            draft.step = 2
        } else if let pack = prefillPack {
            let beats = catalogStorage.beats(for: pack)
            draft.applyCatalogPack(pack, beats: beats, licenseType: draft.licenseType)
            draft.step = 2
        }
        applySplitImportIfNeeded()
    }

    private func applySplitImportIfNeeded() {
        guard let splitImport else { return }

        draft.beatTitle = splitImport.title
        if let artist = splitImport.artist, !artist.isEmpty {
            draft.artistName = artist
        }

        let splitNote = "Répartition validée via SplitPad (ref \(splitImport.ref))."
        if draft.additionalClauses.isEmpty {
            draft.additionalClauses = splitNote
        } else if !draft.additionalClauses.contains(splitImport.ref) {
            draft.additionalClauses += "\n\n\(splitNote)"
        }

        if let name = splitImport.coProducerName,
           let share = splitImport.coProducerSharePercent,
           share > 0 {
            draft.enableCoProducer = true
            draft.coProducer.name = name
            draft.coProducer.sharePercent = share
        }

        draft.step = 2
    }
}
