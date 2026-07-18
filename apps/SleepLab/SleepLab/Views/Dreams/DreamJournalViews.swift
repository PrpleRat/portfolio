import Charts
import SwiftData
import SwiftUI

// MARK: - Liste principale

struct DreamJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamEntry.dreamDate, order: .reverse) private var dreams: [DreamEntry]

    @State private var filter: DreamFilter = .all
    @State private var showEditor = false
    @State private var searchText = ""
    @State private var journalStats = DreamJournalStats.empty

    private var dreamsSignature: String {
        "\(dreams.count)-\(dreams.first?.id.uuidString ?? "")-\(dreams.last?.id.uuidString ?? "")"
    }

    private var filtered: [DreamEntry] {
        dreams.filter { dream in
            let matchesFilter: Bool = {
                switch filter {
                case .all: return true
                case .lucid: return dream.isLucid || dream.category == .lucid
                case .nightmare: return dream.category == .nightmare
                case .positive: return dream.emotions.allSatisfy(\.isPositive) && !dream.emotions.isEmpty
                case .difficult: return dream.emotions.contains { !$0.isPositive }
                case .emotion(let e): return dream.emotions.contains(e)
                }
            }()
            let matchesSearch = searchText.isEmpty
                || dream.title.localizedCaseInsensitiveContains(searchText)
                || dream.narrative.localizedCaseInsensitiveContains(searchText)
                || dream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !dreams.isEmpty {
                        statsHeader
                        emotionChart
                    }
                    filterChips
                    if filtered.isEmpty {
                        emptyBlock
                    } else {
                        dreamList
                    }
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Carnet de rêves")
            .searchable(text: $searchText, prompt: "Rechercher un rêve…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                DreamEditorView(session: nil)
            }
            .onAppear { refreshStats() }
            .onChange(of: dreamsSignature) { _, _ in refreshStats() }
        }
    }

    private func refreshStats() {
        journalStats = DreamJournalAnalytics.stats(from: dreams)
    }

    private var statsHeader: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatTile(title: "Rêves notés", value: "\(journalStats.total)", footnote: nil)
            StatTile(
                title: "Lucides",
                value: journalStats.total > 0 ? "\(Int(Double(journalStats.lucidCount) / Double(journalStats.total) * 100)) %" : "—",
                footnote: "\(journalStats.lucidCount) rêve(s)"
            )
            StatTile(title: "Cauchemars", value: "\(journalStats.nightmareCount)", footnote: nil, accent: .orange)
            StatTile(
                title: "Clarté moy.",
                value: String(format: "%.1f/5", journalStats.avgClarity),
                footnote: journalStats.linkedToSleepCount > 0 ? "\(journalStats.linkedToSleepCount) liés au tracking" : nil
            )
        }
    }

    private var emotionChart: some View {
        Group {
            if !journalStats.emotionBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Émotions dominantes")
                        .font(.subheadline.bold())
                    Chart(journalStats.emotionBreakdown.prefix(6)) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Émotion", item.emotion.displayName)
                        )
                        .foregroundStyle(emotionColor(item.emotion).gradient)
                        .cornerRadius(4)
                    }
                    .chartAnimation(nil)
                    .frame(height: CGFloat(min(180, journalStats.emotionBreakdown.count * 28 + 40)))
                }
                .padding()
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Tous", filter == .all) { filter = .all }
                chip("Lucides", filter == .lucid) { filter = .lucid }
                chip("Cauchemars", filter == .nightmare) { filter = .nightmare }
                chip("Positifs", filter == .positive) { filter = .positive }
                chip("Difficiles", filter == .difficult) { filter = .difficult }
                ForEach(DreamEmotion.allCases.filter(\.isPositive).prefix(4)) { e in
                    chip(e.displayName, filter == .emotion(e)) { filter = .emotion(e) }
                }
            }
        }
    }

    private var dreamList: some View {
        VStack(spacing: 12) {
            ForEach(filtered, id: \.id) { dream in
                NavigationLink {
                    DreamDetailView(dream: dream)
                } label: {
                    DreamRow(dream: dream)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyBlock: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(SleepTheme.accent)
            Text("Ton journal est vide")
                .font(.headline)
            Text("Note tes rêves au réveil — émotions, symboles, lien avec la nuit \(AppBrand.displayName).")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                showEditor = true
            } label: {
                Label("Premier rêve", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(SleepTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func chip(_ title: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? SleepTheme.accent.opacity(0.35) : SleepTheme.card)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? SleepTheme.accent : SleepTheme.textPrimary)
    }
}

private enum DreamFilter: Equatable {
    case all, lucid, nightmare, positive, difficult
    case emotion(DreamEmotion)
}

// MARK: - Ligne liste

private struct DreamRow: View {
    let dream: DreamEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: dream.category.sfSymbol)
                    .foregroundStyle(SleepTheme.accent)
                Text(dream.dreamDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                Spacer()
                if dream.isLucid {
                    Label("Lucide", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            Text(dream.preview)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(SleepTheme.textPrimary)
            HStack(spacing: 6) {
                ForEach(dream.emotions.prefix(4), id: \.self) { e in
                    Text(e.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(emotionColor(e).opacity(0.25))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Détail

struct DreamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var dream: DreamEntry

    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: dream.category.sfSymbol)
                        .font(.largeTitle)
                        .foregroundStyle(SleepTheme.accent)
                    VStack(alignment: .leading) {
                        Text(dream.title.isEmpty ? "Rêve" : dream.title)
                            .font(.title2.bold())
                        Text(dream.category.displayName)
                            .font(.caption)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }

                metaGrid

                if !dream.emotions.isEmpty {
                    Text("Émotions").font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(dream.emotions, id: \.self) { e in
                            Label(e.displayName, systemImage: e.sfSymbol)
                                .font(.caption)
                                .padding(8)
                                .background(emotionColor(e).opacity(0.3))
                                .clipShape(Capsule())
                        }
                    }
                }

                Text("Récit").font(.headline)
                Text(dream.narrative.isEmpty ? "—" : dream.narrative)
                    .font(.body)

                if !dream.tags.isEmpty {
                    Text("Tags").font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(dream.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(8)
                                .background(SleepTheme.card)
                                .clipShape(Capsule())
                        }
                    }
                }

                if let session = dream.session {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nuit liée").font(.headline)
                        HStack {
                            Text("Score sommeil : \(session.overallScore)")
                            Spacer()
                            Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(SleepTheme.textSecondary)
                        }
                        .padding()
                        .background(SleepTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Rêve")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifier") { showEdit = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    modelContext.delete(dream)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            DreamEditorView(existing: dream, session: dream.session)
        }
    }

    private var metaGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            meta("Clarté", "\(dream.clarity)/5")
            meta("Vivacité", "\(dream.vividness)/5")
            meta("Humeur réveil", "\(dream.moodOnWake)/10")
            if dream.isRecurring { meta("Récurrent", "Oui") }
        }
    }

    private func meta(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading) {
            Text(t).font(.caption2).foregroundStyle(SleepTheme.textSecondary)
            Text(v).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(SleepTheme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Éditeur

struct DreamEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    ) private var sessions: [SleepSession]

    var existing: DreamEntry?
    var session: SleepSession?

    @State private var dreamDate = Date()
    @State private var title = ""
    @State private var narrative = ""
    @State private var category: DreamCategory = .ordinary
    @State private var selectedEmotions: Set<DreamEmotion> = []
    @State private var selectedTags: Set<String> = []
    @State private var clarity: Double = 3
    @State private var vividness: Double = 3
    @State private var moodOnWake: Double = 5
    @State private var isLucid = false
    @State private var isRecurring = false
    @State private var linkedSession: SleepSession?

    var body: some View {
        NavigationStack {
            Form {
                Section("Quand") {
                    DatePicker("Matin du", selection: $dreamDate, displayedComponents: .date)
                    Picker("Nuit \(AppBrand.displayName)", selection: $linkedSession) {
                        Text("Aucune").tag(nil as SleepSession?)
                        ForEach(sessions) { s in
                            Text("\(s.startTime.formatted(date: .abbreviated, time: .omitted)) · score \(s.overallScore)")
                                .tag(s as SleepSession?)
                        }
                    }
                }

                Section("Récit") {
                    TextField("Titre (optionnel)", text: $title)
                    TextEditor(text: $narrative)
                        .frame(minHeight: 120)
                }

                Section("Type") {
                    Picker("Catégorie", selection: $category) {
                        ForEach(DreamCategory.allCases) { c in
                            Label(c.displayName, systemImage: c.sfSymbol).tag(c)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Toggle("Rêve lucide", isOn: $isLucid)
                        .onChange(of: isLucid) { _, on in
                            if on { category = .lucid }
                        }
                    Toggle("Récurrent", isOn: $isRecurring)
                }

                Section("Émotions (plusieurs)") {
                    emotionGrid
                }

                Section("Intensité") {
                    VStack(alignment: .leading) {
                        Text("Clarté du souvenir : \(Int(clarity))")
                        Slider(value: $clarity, in: 1...5, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Vivacité : \(Int(vividness))")
                        Slider(value: $vividness, in: 1...5, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Humeur au réveil : \(Int(moodOnWake))")
                        Slider(value: $moodOnWake, in: 1...10, step: 1)
                    }
                }

                Section("Symboles & tags") {
                    tagGrid
                }
            }
            .scrollContentBackground(.hidden)
            .background(SleepTheme.background)
            .navigationTitle(existing == nil ? "Nouveau rêve" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .fontWeight(.semibold)
                        .disabled(narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && title.isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private var emotionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(DreamEmotion.allCases) { emotion in
                let on = selectedEmotions.contains(emotion)
                Button {
                    if on { selectedEmotions.remove(emotion) } else { selectedEmotions.insert(emotion) }
                } label: {
                    Label(emotion.displayName, systemImage: emotion.sfSymbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(on ? emotionColor(emotion).opacity(0.4) : SleepTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .foregroundStyle(on ? emotionColor(emotion) : SleepTheme.textSecondary)
            }
        }
    }

    private var tagGrid: some View {
        FlowLayout(spacing: 8) {
            ForEach(DreamTagSuggestions.common, id: \.self) { tag in
                let on = selectedTags.contains(tag)
                Button {
                    if on { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                } label: {
                    Text(on ? "✓ \(tag)" : tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(on ? SleepTheme.accent.opacity(0.3) : SleepTheme.card)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadExisting() {
        guard let e = existing else {
            linkedSession = session
            if session != nil { dreamDate = Date() }
            return
        }
        dreamDate = e.dreamDate
        title = e.title
        narrative = e.narrative
        category = e.category
        selectedEmotions = Set(e.emotions)
        selectedTags = Set(e.tags)
        clarity = Double(e.clarity)
        vividness = Double(e.vividness)
        moodOnWake = Double(e.moodOnWake)
        isLucid = e.isLucid
        isRecurring = e.isRecurring
        linkedSession = e.session
    }

    private func save() {
        let target = existing ?? DreamEntry()
        target.dreamDate = dreamDate
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.narrative = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        target.category = category
        target.emotions = Array(selectedEmotions)
        target.tags = Array(selectedTags)
        target.clarity = Int(clarity)
        target.vividness = Int(vividness)
        target.moodOnWake = Int(moodOnWake)
        target.isLucid = isLucid || category == .lucid
        target.isRecurring = isRecurring || category == .recurring
        target.session = linkedSession ?? session

        if existing == nil {
            modelContext.insert(target)
        }
        try? modelContext.save()
        if let night = linkedSession ?? session {
            WidgetBridge.syncDream(target, lastSession: night)
        } else {
            WidgetBridge.syncDream(target, lastSession: nil)
        }
        dismiss()
    }
}

// MARK: - Couleurs émotions

func emotionColor(_ emotion: DreamEmotion) -> Color {
    switch emotion {
    case .joy, .excitement: return .yellow
    case .peace, .love: return .mint
    case .surprise: return .cyan
    case .sadness: return .blue
    case .fear, .anxiety: return .purple
    case .anger: return .red
    case .disgust: return .brown
    case .confusion: return .gray
    case .shame: return .pink
    }
}
