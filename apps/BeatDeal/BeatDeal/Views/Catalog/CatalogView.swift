import SwiftUI

struct CatalogView: View {
    @ObservedObject private var catalog = BeatCatalogStorage.shared
    @State private var segment = 0
    @State private var editingBeat: CatalogBeat?
    @State private var editingPack: BeatPack?
    @State private var showNewBeat = false
    @State private var showNewPack = false
    @State private var sellContext: SellFromCatalogContext?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $segment) {
                    Text("Beats").tag(0)
                    Text("Packs").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(BeatDealSpacing.md)

                if segment == 0 {
                    beatsList
                } else {
                    packsList
                }
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle("Catalogue")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if segment == 0 { showNewBeat = true } else { showNewPack = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingBeat) { beat in
                CatalogBeatEditorView(beat: beat) { catalog.save($0) }
            }
            .sheet(isPresented: $showNewBeat) {
                CatalogBeatEditorView(beat: newBeat()) { catalog.save($0) }
            }
            .sheet(item: $editingPack) { pack in
                BeatPackEditorView(pack: pack, beats: catalog.beats) { catalog.save($0) }
            }
            .sheet(isPresented: $showNewPack) {
                BeatPackEditorView(pack: newPack(), beats: catalog.beats) { catalog.save($0) }
            }
            .sheet(item: $sellContext) { context in
                SellFromCatalogSheet(context: context)
            }
        }
    }

    @ViewBuilder
    private var beatsList: some View {
        if catalog.beats.isEmpty {
            emptyBeats
        } else {
            List {
                ForEach(catalog.beats) { beat in
                    Button { editingBeat = beat } label: { catalogRow(beat) }
                        .listRowBackground(BeatDealColors.card)
                        .contextMenu {
                            Button("Vendre ce beat", systemImage: "doc.badge.plus") {
                                sellContext = SellFromCatalogContext(beat: beat, pack: nil)
                            }
                        }
                }
                .onDelete(perform: deleteBeats)
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var packsList: some View {
        if catalog.packs.isEmpty {
            emptyPacks
        } else {
            List {
                ForEach(catalog.packs) { pack in
                    Button { editingPack = pack } label: { packRow(pack) }
                        .listRowBackground(BeatDealColors.card)
                        .contextMenu {
                            Button("Vendre ce pack", systemImage: "doc.badge.plus") {
                                sellContext = SellFromCatalogContext(beat: nil, pack: pack)
                            }
                        }
                }
                .onDelete(perform: deletePacks)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyBeats: some View {
        catalogEmpty(
            icon: "music.note.list",
            message: "Ajoute tes beats disponibles",
            action: "+ Ajouter un beat"
        ) { showNewBeat = true }
    }

    private var emptyPacks: some View {
        catalogEmpty(
            icon: "square.stack.3d.up.fill",
            message: "Groupe tes beats en packs",
            action: "+ Créer un pack"
        ) { showNewPack = true }
    }

    private func catalogEmpty(icon: String, message: String, action: String, onTap: @escaping () -> Void) -> some View {
        VStack(spacing: BeatDealSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(BeatDealColors.accent.opacity(0.6))
            Text(message)
                .font(BeatDealTypography.body)
                .foregroundStyle(BeatDealColors.textSecondary)
            Button(action, action: onTap)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, BeatDealSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func catalogRow(_ beat: CatalogBeat) -> some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
            HStack {
                Text(beat.title)
                    .font(BeatDealTypography.headline)
                    .foregroundStyle(BeatDealColors.text)
                if beat.coProducer?.isValid == true {
                    Text("co-prod")
                        .font(BeatDealTypography.badge)
                        .foregroundStyle(BeatDealColors.accentLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BeatDealColors.separator)
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: BeatDealSpacing.sm) {
                if let bpm = beat.bpm { Text("\(bpm) BPM") }
                if let tonalite = beat.tonaliteLabel { Text(tonalite) }
                Text(beat.genre.label)
            }
            .font(BeatDealTypography.caption)
            .foregroundStyle(BeatDealColors.textSecondary)
            Text("MP3 \(beat.prices.mp3Lease) € · WAV \(beat.prices.wavLease) € · Excl. \(beat.prices.exclusive) €")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.accentLight)
        }
        .padding(.vertical, 4)
    }

    private func packRow(_ pack: BeatPack) -> some View {
        VStack(alignment: .leading, spacing: BeatDealSpacing.xs) {
            Text(pack.title)
                .font(BeatDealTypography.headline)
                .foregroundStyle(BeatDealColors.text)
            Text(pack.beatCountLabel)
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)
            Text("Pack WAV \(pack.prices.wavLease) € · Excl. \(pack.prices.exclusive) €")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.accentLight)
        }
        .padding(.vertical, 4)
    }

    private func newBeat() -> CatalogBeat {
        CatalogBeat(
            id: UUID().uuidString,
            title: "",
            bpm: nil,
            musicalKey: nil,
            keyMode: nil,
            genre: .trap,
            prices: .defaults(),
            createdAt: Date(),
            coProducer: nil
        )
    }

    private func newPack() -> BeatPack {
        BeatPack(
            id: UUID().uuidString,
            title: "",
            beatIds: [],
            prices: .defaults(),
            createdAt: Date()
        )
    }

    private func deleteBeats(at offsets: IndexSet) {
        offsets.forEach { catalog.delete(catalog.beats[$0]) }
    }

    private func deletePacks(at offsets: IndexSet) {
        offsets.forEach { catalog.delete(catalog.packs[$0]) }
    }
}

struct CatalogBeatEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var beat: CatalogBeat
    var onSave: (CatalogBeat) -> Void

    @State private var bpmText = ""
    @State private var selectedKey: MusicalKey?
    @State private var selectedMode: KeyMode?
    @State private var priceTexts: [LicenseType: String] = [:]
    @State private var enableCoProducer = false
    @State private var coProducer = CoProducer()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    BeatDealTextField(title: "Titre", text: $beat.title, required: true)
                    BeatDealTextField(title: "BPM", text: $bpmText, keyboard: .numberPad)

                    genrePicker
                    keyPickers

                    FormSectionHeader(title: "Prix par type de licence")
                    ForEach(LicenseType.allCases) { type in
                        BeatDealTextField(title: type.title, text: bindingPrice(for: type), keyboard: .numberPad)
                    }

                    CoProducerEditorView(enabled: $enableCoProducer, coProducer: $coProducer)
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(beat.title.isEmpty ? "Nouveau beat" : beat.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveBeat() }
                        .disabled(beat.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { syncFromBeat() }
        }
    }

    private var genrePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Genre")
                .font(BeatDealTypography.caption)
                .foregroundStyle(BeatDealColors.textSecondary)
            Picker("Genre", selection: $beat.genre) {
                ForEach(BeatGenre.allCases) { genre in
                    Text(genre.label).tag(genre)
                }
            }
            .pickerStyle(.menu)
            .tint(BeatDealColors.accentLight)
        }
    }

    private var keyPickers: some View {
        HStack(spacing: BeatDealSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tonalité")
                    .font(BeatDealTypography.caption)
                    .foregroundStyle(BeatDealColors.textSecondary)
                Picker("Tonalité", selection: $selectedKey) {
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
                Picker("Mode", selection: $selectedMode) {
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
    }

    private func bindingPrice(for type: LicenseType) -> Binding<String> {
        Binding(
            get: { priceTexts[type] ?? String(beat.prices.price(for: type)) },
            set: { priceTexts[type] = $0 }
        )
    }

    private func syncFromBeat() {
        bpmText = beat.bpm.map(String.init) ?? ""
        selectedKey = beat.musicalKey.flatMap { key in MusicalKey.allCases.first { $0.label == key } }
        selectedMode = beat.keyMode.flatMap { mode in KeyMode.allCases.first { $0.rawValue == mode } }
        for type in LicenseType.allCases {
            priceTexts[type] = String(beat.prices.price(for: type))
        }
        if let co = beat.coProducer, co.isValid {
            enableCoProducer = true
            coProducer = co
        }
    }

    private func saveBeat() {
        beat.bpm = Int(bpmText.trimmingCharacters(in: .whitespaces))
        beat.musicalKey = selectedKey?.label
        beat.keyMode = selectedMode?.rawValue
        for type in LicenseType.allCases {
            if let text = priceTexts[type], let value = Int(text) {
                beat.prices.setPrice(value, for: type)
            }
        }
        beat.coProducer = enableCoProducer && coProducer.isValid ? coProducer : nil
        onSave(beat)
        dismiss()
    }
}

struct BeatPackEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var pack: BeatPack
    let beats: [CatalogBeat]
    var onSave: (BeatPack) -> Void

    @State private var priceTexts: [LicenseType: String] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BeatDealSpacing.md) {
                    BeatDealTextField(title: "Titre du pack", text: $pack.title, required: true)

                    FormSectionHeader(title: "Beats inclus (min. 2)")
                    if beats.isEmpty {
                        Text("Ajoute d'abord des beats au catalogue.")
                            .font(BeatDealTypography.caption)
                            .foregroundStyle(BeatDealColors.textSecondary)
                    } else {
                        ForEach(beats) { beat in
                            Toggle(isOn: bindingSelected(beat.id)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(beat.title)
                                        .font(BeatDealTypography.body)
                                        .foregroundStyle(BeatDealColors.text)
                                    if let bpm = beat.bpm {
                                        Text("\(bpm) BPM")
                                            .font(BeatDealTypography.caption)
                                            .foregroundStyle(BeatDealColors.textSecondary)
                                    }
                                }
                            }
                            .tint(BeatDealColors.accent)
                        }
                    }

                    FormSectionHeader(title: "Prix pack par licence")
                    ForEach(LicenseType.allCases) { type in
                        BeatDealTextField(title: type.title, text: bindingPrice(for: type), keyboard: .numberPad)
                    }
                }
                .padding(BeatDealSpacing.md)
            }
            .background(BeatDealColors.background.ignoresSafeArea())
            .navigationTitle(pack.title.isEmpty ? "Nouveau pack" : pack.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { savePack() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                for type in LicenseType.allCases {
                    priceTexts[type] = String(pack.prices.price(for: type))
                }
            }
        }
    }

    private var canSave: Bool {
        !pack.title.trimmingCharacters(in: .whitespaces).isEmpty && pack.beatIds.count >= 2
    }

    private func bindingSelected(_ beatId: String) -> Binding<Bool> {
        Binding(
            get: { pack.beatIds.contains(beatId) },
            set: { selected in
                if selected {
                    if !pack.beatIds.contains(beatId) { pack.beatIds.append(beatId) }
                } else {
                    pack.beatIds.removeAll { $0 == beatId }
                }
            }
        )
    }

    private func bindingPrice(for type: LicenseType) -> Binding<String> {
        Binding(
            get: { priceTexts[type] ?? String(pack.prices.price(for: type)) },
            set: { priceTexts[type] = $0 }
        )
    }

    private func savePack() {
        for type in LicenseType.allCases {
            if let text = priceTexts[type], let value = Int(text) {
                pack.prices.setPrice(value, for: type)
            }
        }
        onSave(pack)
        dismiss()
    }
}

#Preview {
    CatalogView()
        .preferredColorScheme(.dark)
}
