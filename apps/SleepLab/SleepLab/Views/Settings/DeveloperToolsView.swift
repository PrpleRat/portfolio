import SwiftData
import SwiftUI

/// Outils QA / démo — accès par mot de passe (build TestFlight & tests internes).
struct DeveloperToolsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sleepTracker: SleepTracker
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [AlarmConfig]

    @State private var password = ""
    @State private var unlocked = false
    @State private var showWrongPassword = false

    @State private var importMessage: String?
    @State private var showImportAlert = false
    @State private var showDemoConfirm = false
    @State private var showShortNightConfirm = false
    @State private var isBusy = false

    private let accessCode = "170520"

    var body: some View {
        Group {
            if unlocked {
                toolsForm
            } else {
                gateView
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Outils développeur")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mot de passe incorrect", isPresented: $showWrongPassword) {
            Button("OK", role: .cancel) {}
        }
        .alert("Résultat", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
        .confirmationDialog(
            "Ajouter 10 nuits de démo ?",
            isPresented: $showDemoConfirm,
            titleVisibility: .visible
        ) {
            Button("Ajouter") { Task { await seedDemo() } }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog(
            "Nuit courte (~3 min) ?",
            isPresented: $showShortNightConfirm,
            titleVisibility: .visible
        ) {
            Button("Démarrer") { Task { await runShortNight() } }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var gateView: some View {
        Form {
            Section {
                SecureField("Mot de passe", text: $password)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Déverrouiller") {
                    attemptUnlock()
                }
                .disabled(password.isEmpty)
            } footer: {
                Text("Réservé aux tests internes avant mise en production.")
            }
        }
    }

    private var toolsForm: some View {
        Form {
            Section {
                Text("Ces actions modifient tes données locales. À utiliser uniquement pour valider l’app avant sortie.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Section("Tests rapides") {
                Button(role: .destructive) {
                    showDemoConfirm = true
                } label: {
                    Label("Ajouter 10 nuits de démo", systemImage: "testtube.2")
                }
                .disabled(isBusy)
            }

            Section {
                Button {
                    Task { await injectTestSounds() }
                } label: {
                    Label("Injecter 5 sons espacés (dernière nuit)", systemImage: "waveform.badge.plus")
                }
                .disabled(isBusy)

                Button {
                    showShortNightConfirm = true
                } label: {
                    Label("Lancer une nuit courte (~3 min)", systemImage: "timer")
                }
                .disabled(isBusy || sleepTracker.isTracking)
            } header: {
                Text("Laboratoire QA")
            } footer: {
                Text("Nuit courte : micro + mouvements + sons test. Garde l’app au premier plan.")
            }

            Section {
                Button(role: .destructive) {
                    unlocked = false
                    password = ""
                } label: {
                    Label("Verrouiller", systemImage: "lock.fill")
                }
            }
        }
    }

    private func attemptUnlock() {
        if password == accessCode {
            unlocked = true
            showWrongPassword = false
        } else {
            showWrongPassword = true
            password = ""
        }
    }

    private func seedDemo() async {
        guard let profile = profiles.first else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let n = try DemoDataSeeder.seedDemoNights(context: modelContext, profile: profile)
            importMessage = "\(n) nuits de démo ajoutées."
            showImportAlert = true
        } catch {
            importMessage = "Erreur : \(error.localizedDescription)"
            showImportAlert = true
        }
    }

    private func injectTestSounds() async {
        isBusy = true
        defer { isBusy = false }
        do {
            importMessage = try NightStressTestHarness.injectSpreadSoundEvents(context: modelContext)
            showImportAlert = true
        } catch {
            importMessage = "Erreur : \(error.localizedDescription)"
            showImportAlert = true
        }
    }

    private func runShortNight() async {
        guard let profile = profiles.first, let alarm = alarms.first else { return }
        isBusy = true
        defer { isBusy = false }
        sleepTracker.configure(context: modelContext, profile: profile, alarm: alarm)
        importMessage = await NightStressTestHarness.runShortNight(
            tracker: sleepTracker,
            context: modelContext,
            profile: profile,
            alarm: alarm
        )
        showImportAlert = true
    }
}
