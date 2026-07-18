import SwiftUI

struct ListeCoursesView: View {
    let scores: [ScoreResult]
    let symptomesDetectes: [String]
    var showHomeButton: Bool = true
    var embedded: Bool = false

    @State private var section: ListeCategorie = .supermarche
    @State private var checkedIds: Set<String> = []
    @State private var shareText: ShareTextItem?
    @State private var weekHistory: [CoursesWeekSnapshot] = []

    private var liste: ListeCourses {
        ListeCoursesEngine.genererListe(
            depuis: scores,
            symptomesDetectes: symptomesDetectes
        )
    }

    private var allItems: [ListeItem] { liste.pharmacie + liste.supermarche }
    private var totalCount: Int { allItems.count }
    private var checkedCount: Int { allItems.filter { checkedIds.contains($0.id) }.count }
    private var remainingCount: Int { totalCount - checkedCount }
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            livingStatsHeader

            categoryLegend

            Picker("Section", selection: $section) {
                Text("🥗 Alimentation").tag(ListeCategorie.supermarche)
                Text("💊 Pharmacie").tag(ListeCategorie.pharmacie)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if section == .pharmacie {
                        pharmacieContent
                    } else {
                        supermarcheContent
                    }
                }
                .padding(20)
            }

            footerBudget
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .modifier(ListeCoursesNavigationChrome(
            embedded: embedded,
            showHomeButton: showHomeButton,
            shareAction: {
                shareText = ShareTextItem(text: ListeCoursesEngine.genererTextePartage(liste: liste))
            },
            resetAction: resetAllChecked
        ))
        .sheet(item: $shareText) { item in
            ShareSheet(items: [item.text])
        }
        .onAppear {
            applyWeekRollover()
        }
    }

    private func applyWeekRollover() {
        let loaded = ListeCoursesStorage.loadCheckedIds()
        checkedIds = ListeCoursesWeekStorage.rolloverIfNeeded(
            checkedIds: loaded,
            totalCount: totalCount
        )
        weekHistory = ListeCoursesWeekStorage.loadHistory()
    }

    private var livingStatsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Liste vivante")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CarenceColors.primary)
                    Text("\(checkedCount) coché\(checkedCount > 1 ? "s" : "") · \(remainingCount) restant\(remainingCount > 1 ? "s" : "")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.title3.bold())
                    .foregroundStyle(CarenceColors.primary)
            }
            ProgressView(value: progress)
                .tint(CarenceColors.primary)
            HStack {
                Text("Semaine du \(semaineCourante) · \(ListeCoursesWeekStorage.currentWeekKey())")
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                Spacer()
                if checkedCount > 0 {
                    Button("Tout décocher") {
                        resetAllChecked()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CarenceColors.primary)
                }
            }

            if !weekHistory.isEmpty {
                weekHistorySection
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
    }

    private var weekHistorySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Semaines précédentes")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CarenceColors.textSecondary)
            ForEach(weekHistory.prefix(3)) { snap in
                HStack {
                    Text(snap.weekStart.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                    Spacer()
                    Text("\(snap.checkedCount)/\(snap.totalCount) cochés")
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
            }
            Text("La liste se réinitialise automatiquement chaque lundi.")
                .font(.caption2)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(.top, 4)
    }

    private var semaineCourante: String {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return start.formatted(date: .abbreviated, time: .omitted)
    }

    private var categoryLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ActionCategoryBadge(categorie: .alimentation)
                ActionCategoryBadge(categorie: .pharmacieOrdonnance)
                ActionCategoryBadge(categorie: .urgence)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var pharmacieContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionIntro(
                categorie: .urgence,
                titre: "Urgence — ne pas agir seul",
                detail: "Ces produits nécessitent un avis médical ou un bilan avant achat."
            )
            groupeItems(
                items: liste.pharmacie.filter { $0.nom.contains("⚠️") },
                categorie: .urgence
            )

            sectionIntro(
                categorie: .pharmacieOrdonnance,
                titre: "Pharmacie sur ordonnance",
                detail: "Compléments à valider avec votre médecin ou pharmacien."
            )
            groupeItems(
                titre: "Semaine 1 — Priorité haute",
                items: liste.pharmacie.filter { $0.urgence == .urgent && !$0.nom.contains("⚠️") },
                categorie: .pharmacieOrdonnance
            )
            groupeItems(
                titre: "Semaine 2 — Compléter",
                items: liste.pharmacie.filter { $0.urgence == .important },
                categorie: .pharmacieOrdonnance
            )
            groupeItems(
                titre: "Soins locaux & compléments",
                items: liste.pharmacie.filter { $0.urgence == .complementaire },
                categorie: .pharmacieOrdonnance
            )
        }
    }

    private var supermarcheContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionIntro(
                categorie: .alimentation,
                titre: "Alimentation — votre premier levier",
                detail: "Intégrez ces aliments dans vos repas avant d'envisager des compléments."
            )

            ForEach(grouperSupermarche(liste.supermarche), id: \.categorie) { groupe in
                groupeItems(titre: groupe.categorie, items: groupe.items, categorie: .alimentation)
            }
        }
    }

    private func sectionIntro(categorie: ActionCategory, titre: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ActionCategoryBadge(categorie: categorie)
            Text(titre)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(categorie.color)
            Text(detail)
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(categorie.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categorie.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func groupeItems(
        titre: String? = nil,
        items: [ListeItem],
        categorie: ActionCategory
    ) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if let titre {
                        Text(titre)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(categorie.color)
                    }
                    ForEach(items) { item in
                        listeItemRow(item, categorie: categorie)
                    }
                }
            }
        }
    }

    private func listeItemRow(_ item: ListeItem, categorie: ActionCategory) -> some View {
        Button {
            toggleChecked(item.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: checkedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkedIds.contains(item.id) ? CarenceColors.primary : CarenceColors.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.nom)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                        .strikethrough(checkedIds.contains(item.id))
                    if let detail = item.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                    if let prix = item.prix {
                        Text(prix)
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.primary)
                    }
                    if !item.carencesLiees.isEmpty {
                        Text("Pour : \(item.carencesLiees.map { RecettesEngine.carenceNom(for: $0) }.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(categorie.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(categorie.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footerBudget: some View {
        VStack(spacing: 0) {
            Divider()
            Text("Budget estimé pharmacie : \(ListeCoursesEngine.budgetPharmacieEstime(liste: liste))")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(CarenceColors.surface)
        }
    }

    private func toggleChecked(_ id: String) {
        if checkedIds.contains(id) {
            checkedIds.remove(id)
        } else {
            checkedIds.insert(id)
        }
        ListeCoursesStorage.saveCheckedIds(checkedIds)
    }

    private func resetAllChecked() {
        checkedIds.removeAll()
        ListeCoursesStorage.clearCheckedIds()
    }

    private func grouperSupermarche(_ items: [ListeItem]) -> [(categorie: String, items: [ListeItem])] {
        let ordre = [
            "Poissons & fruits de mer", "Viandes & œufs", "Légumes verts", "Fruits",
            "Légumineuses", "Oléagineux & graines", "Autres"
        ]
        var dict: [String: [ListeItem]] = [:]
        for item in items {
            let cat = categorieCulinaire(item.nom)
            dict[cat, default: []].append(item)
        }
        return ordre.compactMap { cat in
            guard let group = dict[cat], !group.isEmpty else { return nil }
            return (cat, group)
        }
    }

    private func categorieCulinaire(_ nom: String) -> String {
        let l = nom.lowercased()
        if l.contains("saumon") || l.contains("sardine") || l.contains("thon") || l.contains("maquereau") || l.contains("poisson") || l.contains("huître") {
            return "Poissons & fruits de mer"
        }
        if l.contains("viande") || l.contains("poulet") || l.contains("porc") || l.contains("oeuf") || l.contains("foie") || l.contains("boudin") {
            return "Viandes & œufs"
        }
        if l.contains("épinard") || l.contains("epinard") || l.contains("brocoli") || l.contains("poivron") || l.contains("champignon") || l.contains("carotte") {
            return "Légumes verts"
        }
        if l.contains("kiwi") || l.contains("orange") || l.contains("fraise") || l.contains("banane") || l.contains("citron") {
            return "Fruits"
        }
        if l.contains("lentille") || l.contains("pois chiche") || l.contains("légumineuse") {
            return "Légumineuses"
        }
        if l.contains("noix") || l.contains("amande") || l.contains("graine") || l.contains("chocolat") {
            return "Oléagineux & graines"
        }
        return "Autres"
    }
}

struct ShareTextItem: Identifiable {
    let id = UUID()
    let text: String
}

private struct ListeCoursesNavigationChrome: ViewModifier {
    let embedded: Bool
    let showHomeButton: Bool
    let shareAction: () -> Void
    let resetAction: () -> Void

    func body(content: Content) -> some View {
        if embedded {
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: resetAction) {
                            Label("Tout décocher", systemImage: "arrow.counterclockwise")
                        }
                        Button(action: shareAction) {
                            Label("Partager", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Actions liste")
                }
            }
        } else {
            content
                .navigationTitle("Ma liste de courses")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showHomeButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                NavigationHelpers.popToRoot()
                            } label: {
                                Label("Accueil", systemImage: "house.fill")
                            }
                            .accessibilityLabel("Retour à l'accueil")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: resetAction) {
                                Label("Tout décocher", systemImage: "arrow.counterclockwise")
                            }
                            Button(action: shareAction) {
                                Label("Partager", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Actions liste")
                    }
                }
        }
    }
}
