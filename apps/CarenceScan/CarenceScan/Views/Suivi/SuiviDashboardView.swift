import SwiftUI

struct SuiviDashboardView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var showEvolution = false

    private var ids: [String] { tracker.trackedSymptomeIds }
    private var evolutif: EvolutiveBilanResult? {
        EvolutiveBilanEngine.calculerDepuisStockage(tracker: tracker)
    }
    private var streak: Int { StreakEngine.streakActuel(tracker: tracker) }
    private var badges: [GamificationBadge] {
        StreakEngine.badges(tracker: tracker, evolutif: evolutif)
    }
    private var profil: ProfilUtilisateur? { ResultsStorage.load()?.profil }
    private var showPregnancyMode: Bool {
        profil?.situationHormonale == .enceinte || profil?.situationHormonale == .allaitante
    }

    private var todayDone: Int {
        ids.filter { tracker.isPresentToday(symptomeId: $0) != nil }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showPregnancyMode, let profil, let payload = ResultsStorage.load() {
                    PregnancySuiviCard(profil: profil, scores: payload.scores)
                }

                statsGrid
                badgesSection
                checkInCard
                evolutifCard
                evolutionCard
                symptomesCard
                exportCard
                settingsCard
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Suivi")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showEvolution) {
            SymptomEvolutionView()
        }
        .onAppear {
            tracker.reloadJournal()
            Task { await SmartNotificationService.evaluateAndSchedule(tracker: tracker) }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statTile(
                valeur: "\(todayDone)/\(max(ids.count, 1))",
                label: "Check-in aujourd'hui",
                icon: "calendar.badge.checkmark",
                color: CarenceColors.primary
            )
            statTile(
                valeur: "\(streak)",
                label: "Série en cours",
                icon: "flame.fill",
                color: CarenceColors.warning
            )
            statTile(
                valeur: "\(tracker.settings.longestStreak)",
                label: "Record",
                icon: "trophy.fill",
                color: CarenceColors.primary
            )
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(badges) { badge in
                        badgeTile(badge)
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func badgeTile(_ badge: GamificationBadge) -> some View {
        VStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.title3)
                .foregroundStyle(badge.obtenu ? CarenceColors.warning : CarenceColors.border)
            Text(badge.titre)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(badge.obtenu ? CarenceColors.textPrimary : CarenceColors.textSecondary)
        }
        .frame(width: 88)
        .padding(.vertical, 10)
        .background(badge.obtenu ? CarenceColors.warning.opacity(0.12) : CarenceColors.border.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(badge.obtenu ? 1 : 0.55)
    }

    private func statTile(valeur: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(valeur)
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check-in du jour")
                .font(.headline)
            Text("Bilan complet une fois · puis oui/non chaque jour. Vous pouvez ajouter des symptômes.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            Button {
                tabRouter.openCheckIn()
            } label: {
                Label("Commencer le check-in", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)
            .disabled(ids.isEmpty && ResultsStorage.load() == nil)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var evolutifCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bilan évolutif")
                .font(.headline)
            if let evolutif {
                Text(evolutif.estPret
                     ? "Carences recalculées en combinant votre bilan de référence et \(evolutif.joursSuivi) j de journal."
                     : "Encore \(max(0, SymptomFrequencyEngine.minDaysForEstimate - evolutif.joursSuivi)) j de check-in pour activer le recalcul.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
            NavigationLink {
                EvolutiveBilanView()
            } label: {
                Label("Voir le bilan évolutif", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
            .disabled(ResultsStorage.load() == nil)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var evolutionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Évolution")
                .font(.headline)
            Button {
                showEvolution = true
            } label: {
                Label("Voir tous mes symptômes", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
            .disabled(ids.isEmpty)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var symptomesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symptômes actifs (7 jours)")
                .font(.headline)

            if ids.isEmpty {
                Text("Complétez un bilan pour activer le suivi automatique.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                Button("Aller au bilan") { tabRouter.selectedTab = .bilan }
                    .font(.caption.weight(.semibold))
            } else {
                ForEach(ids.prefix(6), id: \.self) { id in
                    let days = tracker.presentDaysCount(symptomeId: id, lastDays: 7)
                    HStack {
                        Text(CarenceDatabase.symptomeLabel(for: id))
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        if let freq = tracker.journalFrequence(for: id) {
                            Text(freq.emoji)
                                .font(.caption)
                        }
                        Text("\(days)/7 j")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(days >= 4 ? CarenceColors.alert : CarenceColors.primary)
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export médical")
                .font(.headline)
            Text("PDF avec bilan de référence, journal 14 j, bilan évolutif et contexte grossesse/allaitement.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            TrackingExportButton()
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var settingsCard: some View {
        NavigationLink {
            TrackingSettingsView()
        } label: {
            Label("Rappels et notifications", systemImage: "bell.badge")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .tint(CarenceColors.primary)
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
