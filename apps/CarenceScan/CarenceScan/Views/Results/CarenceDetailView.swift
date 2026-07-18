import SwiftUI

struct CarenceDetailView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    let carenceId: String

    private var carence: Carence? {
        CarenceDatabase.carence(for: carenceId)
    }

    private var score: ScoreResult? {
        vm.scores.first(where: { $0.carenceId == carenceId })
            ?? ResultsStorage.load()?.scores.first(where: { $0.carenceId == carenceId })
    }

    private var hasMedicationInteraction: Bool {
        guard let carence, let interactions = carence.interactionsMedicaments else { return false }
        let meds = vm.medicamentsSelectionnes.isEmpty
            ? Set(ResultsStorage.load()?.medicamentsSelectionnes ?? [])
            : vm.medicamentsSelectionnes
        return meds.contains { med in
            interactions.contains { $0.contains(med) || med.contains("sertraline") && $0.contains("ISRS") }
        } || (carenceId == "tryptophane" && meds.contains("sertraline"))
    }

    var body: some View {
        Group {
            if let carence {
                detailContent(carence: carence, score: score)
            } else {
                ContentUnavailableView(
                    "Carence introuvable",
                    systemImage: "questionmark.circle",
                    description: Text("Ce résultat n'est plus disponible.")
                )
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle(carence?.nom ?? "Détail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    NavigationHelpers.popToRoot()
                } label: {
                    Label("Accueil", systemImage: "house.fill")
                }
                .accessibilityLabel("Retour à l'accueil")
            }
        }
    }

    @ViewBuilder
    private func detailContent(carence: Carence, score: ScoreResult?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBlock(carence: carence, score: score)

                if let score, !score.symptomesDetectes.isEmpty {
                    vosSymptomesSection(symptomeIds: score.symptomesDetectes)
                }

                alimentsSection(carence: carence)
                complementSection(carence: carence)

                secondarySections(carence: carence, score: score)
            }
            .padding(20)
        }
    }

    private func headerBlock(carence: Carence, score: ScoreResult?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(carence.description)
                .font(.body)
                .foregroundStyle(CarenceColors.textSecondary)

            urgenceBadge(carence: carence)

            if let score {
                ProbabilityBar(level: score.niveau, score: score.score)
            }
        }
    }

    private func vosSymptomesSection(symptomeIds: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Vos symptômes")
            VStack(spacing: 0) {
                ForEach(Array(symptomeIds.enumerated()), id: \.element) { index, id in
                    NavigationLink {
                        SymptomeFicheView(symptomeId: id)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CarenceColors.primary)
                            Text(CarenceDatabase.symptomeLabel(for: id))
                                .font(.subheadline)
                                .foregroundStyle(CarenceColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                    }
                    if index < symptomeIds.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CarenceColors.border, lineWidth: 1)
            )
        }
    }

    private func alimentsSection(carence: Carence) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Aliments recommandés")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(carence.alimentsCles, id: \.self) { aliment in
                    HStack(spacing: 8) {
                        Text(foodEmoji(for: aliment))
                            .font(.title3)
                        Text(aliment)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarenceColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(CarenceColors.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func complementSection(carence: Carence) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Complément recommandé")
            complementCard(carence.complement)
        }
    }

    private func complementCard(_ c: ComplementInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundStyle(CarenceColors.primary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.nom)
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text(c.formeRecommandee)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
            }

            Divider()

            complementDetailRow(icon: "clock.fill", title: "Posologie", value: c.posologie)
            complementDetailRow(icon: "cart.fill", title: "Où acheter", value: c.ouAcheter)
            complementDetailRow(icon: "eurosign.circle.fill", title: "Budget mensuel", value: c.prixMois)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.warning)
                Text(c.precautions)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CarenceColors.warningBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.primary.opacity(0.25), lineWidth: 1)
        )
    }

    private func complementDetailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(CarenceColors.primary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CarenceColors.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textPrimary)
            }
        }
    }

    @ViewBuilder
    private func secondarySections(carence: Carence, score: ScoreResult?) -> some View {
        if let score, !score.notesContexte.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Contexte & prévention")
                ForEach(score.notesContexte.groupedByContexte) { groupe in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(groupe.emoji) \(groupe.label)")
                            .font(.caption.bold())
                            .foregroundStyle(CarenceColors.textSecondary)
                        ForEach(groupe.notesConfusion + groupe.notesAggravation, id: \.id) { note in
                            ContexteNoteView(
                                icon: note.type == .confusion ? "⚠️" : "↗️",
                                note: note,
                                background: note.type == .confusion
                                    ? CarenceColors.warning.opacity(0.1)
                                    : CarenceColors.primary.opacity(0.08)
                            )
                        }
                    }
                }
            }
        }

        ExpandableSection(title: "Autres symptômes possibles", systemImage: "list.bullet") {
            symptomTiersContent(carence: carence, highlighted: Set(score?.symptomesDetectes ?? []))
        }

        ExpandableSection(
            title: "Quand s'inquiéter ?",
            systemImage: "questionmark.circle",
            background: CarenceColors.warningBackground.opacity(0.5)
        ) {
            Text(carence.quandSinquieterText)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
        }

        ExpandableSection(
            title: "Signes d'alerte",
            systemImage: "exclamationmark.triangle",
            background: CarenceColors.alertBackground.opacity(0.5)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(carence.signesAlerteItems, id: \.self) { signe in
                    Label(signe, systemImage: "circle.fill")
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(CarenceColors.alert)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }

        if hasMedicationInteraction {
            AlerteBanner(message: AppConstants.alerte5HTP, style: .alert)
        }

        if carence.prescriptionObligatoire == true {
            AlerteBanner(message: AppConstants.alerteFer, style: .alert)
        }

        if let score {
            ForEach(score.alertes, id: \.self) { alerte in
                AlerteBanner(message: alerte, style: .warning)
            }
        }
    }

    private func urgenceBadge(carence: Carence) -> some View {
        Text(carence.urgenceLabel)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(carence.urgenceColor.opacity(0.15))
            .foregroundStyle(carence.urgenceColor)
            .clipShape(Capsule())
    }

    private func symptomTiersContent(carence: Carence, highlighted: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            tierGroup(title: "Caractéristiques", ids: carence.symptomesPrimaires, highlighted: highlighted)
            tierGroup(title: "Fréquents", ids: carence.symptomesSecondaires, highlighted: highlighted)
            tierGroup(title: "Contextuels", ids: carence.symptomesContextuels, highlighted: highlighted)
        }
    }

    private func tierGroup(title: String, ids: [String], highlighted: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            ForEach(ids, id: \.self) { id in
                NavigationLink {
                    SymptomeFicheView(symptomeId: id)
                } label: {
                    HStack {
                        Text(CarenceDatabase.symptomeLabel(for: id))
                            .font(.caption)
                            .foregroundStyle(highlighted.contains(id) ? CarenceColors.primary : CarenceColors.textPrimary)
                        Spacer()
                        if highlighted.contains(id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(CarenceColors.primary)
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(CarenceColors.textPrimary)
            .padding(.top, 4)
    }

    private func foodEmoji(for aliment: String) -> String {
        let lower = aliment.lowercased()
        if lower.contains("kiwi") || lower.contains("orange") || lower.contains("citron") { return "🍊" }
        if lower.contains("poivron") || lower.contains("brocoli") || lower.contains("épinard") { return "🥦" }
        if lower.contains("viande") || lower.contains("porc") || lower.contains("poulet") { return "🥩" }
        if lower.contains("poisson") || lower.contains("saumon") || lower.contains("sardine") { return "🐟" }
        if lower.contains("oeuf") { return "🥚" }
        if lower.contains("noix") || lower.contains("amande") || lower.contains("graine") { return "🌰" }
        if lower.contains("banane") { return "🍌" }
        if lower.contains("chocolat") { return "🍫" }
        if lower.contains("lentille") || lower.contains("légumineuse") { return "🫘" }
        return "🥗"
    }
}

#Preview {
    NavigationStack {
        CarenceDetailView(carenceId: "vitamine_c")
            .environmentObject(QuestionnaireViewModel())
    }
}
