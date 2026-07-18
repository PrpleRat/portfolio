import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [String: Bool] = [:]
    @State private var showAddSymptom = false
    @State private var ficheSymptomeId: String?

    private var baselineIds: [String] { tracker.baselineSymptomeIds }
    private var addedIds: [String] { tracker.addedSymptomeIds }
    private var allIds: [String] { tracker.trackedSymptomeIds }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if allIds.isEmpty {
                    emptyState
                } else {
                    if !baselineIds.isEmpty {
                        sectionHeader("Symptômes de votre bilan")
                        ForEach(baselineIds, id: \.self) { id in
                            checkInRow(symptomeId: id)
                        }
                    }

                    if !addedIds.isEmpty {
                        sectionHeader("Symptômes ajoutés")
                        ForEach(addedIds, id: \.self) { id in
                            checkInRow(symptomeId: id, removable: true)
                        }
                    }

                    Button {
                        showAddSymptom = true
                    } label: {
                        Label("Ajouter un symptôme", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(CarenceColors.primary)

                    Button {
                        saveAll()
                        dismiss()
                        tabRouter.showCheckInSheet = false
                    } label: {
                        Text("Enregistrer le check-in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CarenceColors.primary)
                    .disabled(answers.count < allIds.count)
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Aujourd'hui")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fermer") {
                    dismiss()
                    tabRouter.showCheckInSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddSymptom) {
            AddSymptomCheckInView(existingIds: Set(allIds)) { id in
                tracker.addTrackedSymptom(id)
                showAddSymptom = false
            }
        }
        .sheet(isPresented: Binding(
            get: { ficheSymptomeId != nil },
            set: { if !$0 { ficheSymptomeId = nil } }
        )) {
            if let id = ficheSymptomeId {
                NavigationStack {
                    SymptomeFicheView(symptomeId: id)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Fermer") { ficheSymptomeId = nil }
                            }
                        }
                }
            }
        }
        .onAppear {
            loadTodayAnswers()
        }
        .onChange(of: tracker.trackedSymptomeIds) { _, _ in
            loadTodayAnswers()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check-in du jour")
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)

            if tracker.isFirstCheckIn {
                infoBanner(
                    icon: "info.circle.fill",
                    text: "Votre bilan complet sert de référence initiale. Chaque jour, indiquez simplement si vous avez eu ces symptômes — oui ou non."
                )
            } else {
                Text("Avez-vous eu ces symptômes aujourd'hui ? Après 2 semaines de suivi, l'app estime si chaque symptôme est fréquent, occasionnel ou résolu.")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Aucun symptôme à suivre",
                systemImage: "list.bullet.clipboard",
                description: Text("Faites d'abord un bilan complet, ou ajoutez un symptôme manuellement.")
            )
            Button {
                showAddSymptom = true
            } label: {
                Label("Ajouter un symptôme", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(CarenceColors.textPrimary)
            .padding(.top, 4)
    }

    private func infoBanner(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(CarenceColors.primary)
            Text(text)
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(12)
        .background(CarenceColors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func checkInRow(symptomeId: String, removable: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(CarenceDatabase.symptomeLabel(for: symptomeId))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CarenceColors.textPrimary)
                Spacer()
                if let freq = tracker.journalFrequence(for: symptomeId) {
                    Text("\(freq.emoji) \(freq.label)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(freqBackground(freq))
                        .clipShape(Capsule())
                }
                Button {
                    ficheSymptomeId = symptomeId
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(CarenceColors.primary)
                }
                .buttonStyle(.plain)
                if removable {
                    Button {
                        tracker.removeTrackedSymptom(symptomeId)
                        answers.removeValue(forKey: symptomeId)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                toggleButton(title: "Oui", selected: answers[symptomeId] == true) {
                    answers[symptomeId] = true
                }
                toggleButton(title: "Non", selected: answers[symptomeId] == false) {
                    answers[symptomeId] = false
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private func freqBackground(_ freq: JournalFrequence) -> Color {
        switch freq {
        case .jamais: return CarenceColors.primary.opacity(0.12)
        case .occasionnel: return CarenceColors.border.opacity(0.5)
        case .frequent: return CarenceColors.warning.opacity(0.15)
        case .constant: return CarenceColors.alert.opacity(0.12)
        }
    }

    private func toggleButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selected ? CarenceColors.primary : CarenceColors.border.opacity(0.35))
                .foregroundStyle(selected ? Color.white : CarenceColors.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func loadTodayAnswers() {
        for id in allIds {
            if let value = tracker.isPresentToday(symptomeId: id) {
                answers[id] = value
            }
        }
    }

    private func saveAll() {
        for (id, present) in answers {
            tracker.record(symptomeId: id, present: present)
        }
        tracker.markFirstCheckInCompleted()
        StreakEngine.mettreAJourRecord(tracker: tracker)
    }
}

// MARK: - Ajout symptôme

struct AddSymptomCheckInView: View {
    let existingIds: Set<String>
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var recherche = ""

    private var candidats: [Symptome] {
        let all = CarenceDatabase.shared.symptomes
        let q = recherche.trimmingCharacters(in: .whitespaces).lowercased()
        return all.filter { symptome in
            !existingIds.contains(symptome.id)
                && (q.isEmpty
                    || symptome.label.lowercased().contains(q)
                    || symptome.id.lowercased().contains(q))
        }
        .sorted { $0.label < $1.label }
    }

    var body: some View {
        NavigationStack {
            List(candidats) { symptome in
                Button {
                    onSelect(symptome.id)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(symptome.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CarenceColors.textPrimary)
                        if let cat = SymptomCategory(rawValue: symptome.categorie) {
                            Text(cat.title)
                                .font(.caption)
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                    }
                }
            }
            .searchable(text: $recherche, prompt: "Rechercher un symptôme")
            .navigationTitle("Ajouter un symptôme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
