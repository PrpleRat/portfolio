import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [AlarmConfig]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first, let alarm = alarms.first {
                    ProfileFormView(profile: profile, alarm: alarm)
                } else {
                    ProgressView("Chargement…")
                        .onAppear { ensureDefaults() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Réglages")
        }
    }

    private func ensureDefaults() {
        if profiles.isEmpty {
            modelContext.insert(UserProfile())
        }
        if alarms.isEmpty {
            modelContext.insert(AlarmConfig())
        }
        try? modelContext.save()
    }
}

private struct ProfileFormView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(
        filter: #Predicate<SleepSession> { $0.endTime != nil },
        sort: \SleepSession.startTime,
        order: .reverse
    )
    private var completedSessions: [SleepSession]
    @Bindable var profile: UserProfile
    @Bindable var alarm: AlarmConfig

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @StateObject private var healthKit = HealthKitService()
    @State private var importMessage: String?
    @State private var showImportAlert = false
    @State private var isBusy = false

    var body: some View {
        Form {
            Section {
                Text("Tout reste sur ton iPhone. Tu peux exporter une sauvegarde JSON à tout moment.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Toi") {
                DatePicker(
                    "Date de naissance",
                    selection: Binding(
                        get: { profile.birthDate ?? Date() },
                        set: { profile.birthDate = $0 }
                    ),
                    displayedComponents: .date
                )
                Picker("Sexe biologique", selection: $profile.biologicalSexRaw) {
                    ForEach(BiologicalSex.allCases, id: \.rawValue) { sex in
                        Text(sex.displayName).tag(sex.rawValue)
                    }
                }
                HStack {
                    Text("Poids (kg)")
                    TextField("—", value: $profile.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Taille (cm)")
                    TextField("—", value: $profile.height, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Sommeil") {
                Stepper(
                    "Objectif : \(String(format: "%.1f", profile.targetSleepDuration)) h",
                    value: $profile.targetSleepDuration,
                    in: 5...12,
                    step: 0.5
                )
                DatePicker(
                    "Coucher minimum",
                    selection: Binding(
                        get: { profile.minimumBedtime },
                        set: { profile.minimumBedtime = $0 }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                Text("L’app ne recommandera pas un coucher avant cette heure. Utile si la fenêtre calculée te semble trop tôt.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                Picker("Chronotype", selection: $profile.chronotypeRaw) {
                    ForEach(Chronotype.allCases, id: \.rawValue) { c in
                        Text(c.displayName).tag(c.rawValue)
                    }
                }
                Stepper(
                    "Métabolisme caféine : \(profile.caffeineMetabolism)/5",
                    value: $profile.caffeineMetabolism,
                    in: 1...5
                )
                NavigationLink {
                    MotionCalibrationView()
                } label: {
                    Label("Calibrage accéléromètre", systemImage: "gyroscope")
                }
                Text("Les calculs ajoutent un ajustement physiologique léger selon le sexe biologique, puis le cycle menstruel si activé.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Réveil") {
                NavigationLink {
                    AlarmSetupView(config: alarm)
                } label: {
                    Label("Réveil intelligent", systemImage: "alarm")
                }
            }

            Section("Apparence") {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    HStack {
                        Label("Thème", systemImage: "paintpalette")
                        Spacer()
                        Text(themeManager.appTheme.displayName)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }
            }

            Section("Confidentialité") {
                Toggle("Extraits audio la nuit", isOn: $profile.storeNightAudioClips)
                Text("Désactivé par défaut. Le ronflement est analysé sur l’appareil sans enregistrer l’audio.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Santé") {
                Toggle("Apnée diagnostiquée", isOn: $profile.hasApneaDiagnosed)
                Text("Chaque nuit suivie peut être exportée vers l’app Santé. Autorise « Sommeil » pour \(AppBrand.displayName) dans Réglages iOS → Santé.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                Button {
                    Task { await importFromHealth() }
                } label: {
                    Label("Importer le profil depuis Santé", systemImage: "heart.text.square.fill")
                }
                .disabled(isBusy || !healthKit.isAvailable)
                Button {
                    Task { await importSleepFromHealth() }
                } label: {
                    Label("Importer les nuits (30 j)", systemImage: "bed.double.fill")
                }
                .disabled(isBusy || !healthKit.isAvailable)
                Button {
                    Task { await exportNightsToHealth() }
                } label: {
                    Label("Exporter les nuits (14 j)", systemImage: "square.and.arrow.up.on.square")
                }
                .disabled(isBusy || !healthKit.isAvailable)
            }

            Section("Données") {
                NavigationLink {
                    DataBackupView()
                } label: {
                    Label("Sauvegarde & restauration", systemImage: "externaldrive")
                }
                Text("Fichier JSON local : nuits, journal, rêves, profil.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Journal du coucher") {
                NavigationLink {
                    FactorJournalView()
                } label: {
                    Label("Substances & facteurs", systemImage: "list.bullet.clipboard.fill")
                }
                NavigationLink("Liste des facteurs") {
                    FactorsView()
                }
            }

            Section("Cycle menstruel") {
                Toggle("Suivre mon cycle", isOn: $profile.tracksMenstrualCycle)
                if profile.tracksMenstrualCycle {
                    Text("Un onglet Cycle apparaît en bas de l’écran : calendrier, phases et lien avec ton sommeil.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                } else {
                    Text("Active pour afficher l’onglet Cycle (calendrier des règles, conseils sommeil par phase).")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }

            Section("Aide") {
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    Label("Réafficher le bienvenue", systemImage: "hand.wave")
                }
            }

            Section {
                NavigationLink {
                    DeveloperToolsView()
                } label: {
                    Label("Outils développeur", systemImage: "hammer.fill")
                }
            } footer: {
                Text("Tests internes — mot de passe requis.")
            }

            Section {
                MedicalDisclaimer()
            }
        }
        .alert("Santé", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func importFromHealth() async {
        isBusy = true
        defer { isBusy = false }
        let result = await healthKit.importProfile(into: profile)
        try? modelContext.save()
        importMessage = result.message
        showImportAlert = true
    }

    private func exportNightsToHealth() async {
        isBusy = true
        defer { isBusy = false }
        let count = await healthKit.exportRecentSessions(completedSessions, limit: 14)
        importMessage = "\(count) nuit(s) exportée(s) vers Santé."
        showImportAlert = true
    }

    private func importSleepFromHealth() async {
        isBusy = true
        defer { isBusy = false }
        let result = await healthKit.importSleepHistory(into: modelContext, days: 30, profile: profile)
        importMessage = "Importées : \(result.imported). Ignorées : \(result.skipped)."
        showImportAlert = true
    }
}
