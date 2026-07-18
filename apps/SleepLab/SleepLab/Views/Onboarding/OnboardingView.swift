import AVFoundation
import CoreLocation
import SwiftData
import SwiftUI

/// Premier lancement : explications + autorisations (notifications, micro, localisation, Santé).
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var onComplete: () -> Void

    @StateObject private var healthKit = HealthKitService()
    @State private var step = 0
    @State private var isImporting = false
    @State private var statusMessage: String?
    @State private var importedFields: [String] = []
    @State private var wantsAudioClips = false
    @State private var notificationsGranted = false
    @State private var microphoneGranted = false
    @State private var locationRequested = false

    private let totalSteps = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    progressDots
                    stepContent
                    if let statusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    navigationButtons
                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Bienvenue")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { ensureProfile() }
            .task { await refreshPermissionFlags() }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: welcomeStep
        case 1: notificationsStep
        case 2: microphoneStep
        case 3: locationStep
        case 4: healthStep
        default: EmptyView()
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= step ? SleepTheme.accent : SleepTheme.card)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundStyle(SleepTheme.accent)
            Text("\(AppBrand.displayName) t’aide à mieux dormir : lance une nuit, regarde ton score le lendemain.")
                .font(.title3.bold())
            Text("**3 étapes** : autoriser le micro (pour le suivi), lancer une nuit, consulter ton résumé. Le reste (journal, sieste, analyses) est optionnel.")
                .foregroundStyle(SleepTheme.textSecondary)
        }
    }

    private var notificationsStep: some View {
        permissionBlock(
            icon: "bell.badge.fill",
            title: "Notifications",
            why: "Pour le **réveil de secours** si l’app est en arrière-plan. Le réveil intelligent principal reste dans l’app pendant la nuit.",
            status: notificationsGranted ? "Autorisé" : "Pas encore",
            statusOK: notificationsGranted
        ) {
            Task {
                notificationsGranted = await AppPermissions.requestNotifications()
            }
        }
    }

    private var microphoneStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            permissionBlock(
                icon: "mic.fill",
                title: "Microphone",
                why: "Pour détecter **toux, ronflements et bruits** pendant la nuit. L’analyse se fait sur ton iPhone ; rien n’est envoyé sur Internet.",
                status: microphoneStatusLabel,
                statusOK: microphoneGranted
            ) {
                Task {
                    microphoneGranted = await AppPermissions.requestMicrophone()
                }
            }

            Toggle(isOn: $wantsAudioClips) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enregistrer des extraits audio")
                        .font(.subheadline.bold())
                    Text("Désactivé par défaut. Sans cette option, on détecte les sons mais on **ne garde pas** d’enregistrement à réécouter. Tu pourras changer dans Profil.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
            .tint(SleepTheme.accent)
            .padding()
            .background(SleepTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var locationStep: some View {
        permissionBlock(
            icon: "location.fill",
            title: "Localisation (optionnel)",
            why: "Uniquement pour associer **température et humidité** de la nuit à ton rapport — pas de suivi en continu ni de partage de position.",
            status: locationRequested ? "Demande envoyée" : "Optionnel",
            statusOK: true
        ) {
            locationRequested = true
            AppPermissions.requestLocationWhenInUse()
        }
    }

    private var healthStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Santé (optionnel)")
                .font(.headline)
            Text("Âge, sexe, poids, règles — pour personnaliser scores et cycle. Refusable.")
                .foregroundStyle(SleepTheme.textSecondary)

            if !healthKit.isAvailable {
                Label("Santé n’est pas disponible sur cet appareil.", systemImage: "heart.slash")
                    .foregroundStyle(.orange)
            }

            if !importedFields.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Importé")
                        .font(.subheadline.bold())
                        .foregroundStyle(SleepTheme.accent)
                    ForEach(importedFields, id: \.self) { field in
                        Label(field, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                    }
                }
                .padding()
                .background(SleepTheme.card.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                Task { await importHealth() }
            } label: {
                Label("Importer depuis Santé", systemImage: "heart.text.square.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SleepTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isImporting || !healthKit.isAvailable)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Retour") { step -= 1 }
                    .buttonStyle(.bordered)
                    .tint(SleepTheme.accent)
            }
            Button(step < totalSteps - 1 ? "Suivant" : "C’est parti") {
                if step < totalSteps - 1 {
                    step += 1
                } else {
                    finishOnboarding()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(SleepTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var microphoneStatusLabel: String {
        switch AppPermissions.microphoneStatus() {
        case .granted: return "Autorisé"
        case .denied: return "Refusé — Réglages → \(AppBrand.displayName) → Micro"
        case .undetermined: return "Pas encore"
        @unknown default: return "—"
        }
    }

    private func permissionBlock(
        icon: String,
        title: String,
        why: String,
        status: String,
        statusOK: Bool,
        requestAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(why)
                .foregroundStyle(SleepTheme.textSecondary)
            HStack {
                Text(status)
                    .font(.caption.bold())
                    .foregroundStyle(statusOK ? .green : SleepTheme.textSecondary)
                Spacer()
                Button("Autoriser", action: requestAction)
                    .buttonStyle(.borderedProminent)
                    .tint(SleepTheme.accent)
            }
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ensureProfile() {
        if profiles.isEmpty {
            modelContext.insert(UserProfile())
            modelContext.insert(AlarmConfig())
            try? modelContext.save()
        }
    }

    private func refreshPermissionFlags() async {
        let notif = await AppPermissions.notificationStatus()
        notificationsGranted = notif == .authorized || notif == .provisional
        microphoneGranted = AppPermissions.microphoneStatus() == .granted
    }

    private func importHealth() async {
        guard let profile = profiles.first else { return }
        isImporting = true
        statusMessage = nil
        let result = await healthKit.importProfile(into: profile)
        try? modelContext.save()
        importedFields = result.updatedFields
        statusMessage = result.message
        isImporting = false
    }

    private func finishOnboarding() {
        if let profile = profiles.first {
            profile.storeNightAudioClips = wantsAudioClips
            try? modelContext.save()
        }
        onComplete()
    }
}
