import SwiftData
import SwiftUI

struct PreSleepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [AlarmConfig]
    @Query(sort: \SleepFactor.consumedAt, order: .reverse) private var allFactors: [SleepFactor]

    @EnvironmentObject private var tracker: SleepTracker

    var onStart: () -> Void

    @State private var startError: String?
    @State private var isStarting = false

    @State private var stressLevel: Double = 5
    @State private var moodLevel: Double = 5
    @State private var anxietyLevel: Double = 5
    @State private var didExercise = false
    @State private var screenOverHour = false
    @State private var hasPain = false
    @State private var painLocation = ""
    @State private var tookMedication = false
    @State private var showRumination = false

    @State private var alarmEnabled = true
    @State private var plannedBedtime = Date()
    @State private var selectedWakeTime = Date()
    @State private var windowMinutes = 20

    private var profile: UserProfile? { profiles.first }

    private var wakeSuggestions: [WakeTimeAdvisor.Suggestion] {
        WakeTimeAdvisor.suggestions(bedtime: plannedBedtime, profile: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    simplePathBanner
                    BedtimeWakePlanner(
                        alarmEnabled: $alarmEnabled,
                        plannedBedtime: $plannedBedtime,
                        selectedWakeTime: $selectedWakeTime,
                        windowMinutes: $windowMinutes,
                        profile: profile,
                        suggestions: wakeSuggestions
                    )
                    journalLinkSection
                    wellbeingSection
                    if let profile, !profile.chronicConditions.isEmpty || profile.hasApneaDiagnosed {
                        medicalTogglesSection
                    }
                    if profile?.tracksMenstrualCycle == true {
                        cycleSection
                    }
                    if !tracker.soundMonitor.checkBatteryAndWarn() {
                        batteryWarning
                    }
                    MedicalDisclaimer()
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Avant de dormir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bonne nuit") { startNight() }
                        .fontWeight(.semibold)
                        .disabled(isStarting)
                }
            }
            .onAppear {
                loadAlarmSettings()
                tracker.configure(
                    context: modelContext,
                    profile: profiles.first,
                    alarm: alarms.first
                )
            }
            .onChange(of: plannedBedtime) { _, _ in
                guard alarmEnabled else { return }
                selectedWakeTime = WakeTimeAdvisor.defaultWakeTime(
                    bedtime: plannedBedtime,
                    profile: profile
                )
            }
            .alert("Impossible de démarrer", isPresented: Binding(
                get: { startError != nil },
                set: { if !$0 { startError = nil } }
            )) {
                Button("OK", role: .cancel) { startError = nil }
            } message: {
                Text(startError ?? "")
            }
        }
    }

    private func loadAlarmSettings() {
        plannedBedtime = Date()
        guard let alarm = alarms.first else {
            selectedWakeTime = WakeTimeAdvisor.defaultWakeTime(
                bedtime: plannedBedtime,
                profile: profile
            )
            return
        }
        alarmEnabled = alarm.isEnabled
        windowMinutes = alarm.windowMinutes
        selectedWakeTime = WakeTimeAdvisor.defaultWakeTime(
            bedtime: plannedBedtime,
            profile: profile
        )
        if alarm.isEnabled {
            let stored = alarm.nextWakeTime(relativeTo: plannedBedtime)
            if stored > plannedBedtime.addingTimeInterval(3600) {
                selectedWakeTime = stored
            }
        }
    }

    private func persistAlarmSettings() {
        guard let alarm = alarms.first else { return }
        alarm.isEnabled = alarmEnabled
        alarm.windowMinutes = windowMinutes
        if alarmEnabled {
            alarm.targetWakeTime = selectedWakeTime
        }
        try? modelContext.save()
    }

    private var journalOrphanCount: Int {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
        return allFactors.filter { $0.session == nil && $0.consumedAt >= cutoff }.count
    }

    private var simplePathBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mode simple")
                .font(.caption.bold())
                .foregroundStyle(SleepTheme.accent)
            Text("Règle le réveil si besoin, puis « Bonne nuit ». Le journal substances est optionnel — tu peux l’ouvrir plus tard.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SleepTheme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var journalLinkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Substances & repas")
                .font(.headline)
            Text("Caféine, alcool, médicaments… se remplissent dans le journal, à tout moment de la journée.")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            if journalOrphanCount > 0 {
                Text("\(journalOrphanCount) entrée(s) récente(s) seront reliées à cette nuit.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.accent)
            }
            NavigationLink {
                FactorJournalView()
            } label: {
                Label("Ouvrir le journal", systemImage: "list.bullet.clipboard.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(SleepTheme.accent)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var wellbeingSection: some View {
        factorSection(title: "Bien-être", icon: "heart.fill") {
            sliderRow("Stress", value: $stressLevel, emoji: stressEmoji)
            sliderRow("Anxiété", value: $anxietyLevel, emoji: "😟")
            sliderRow("Humeur", value: $moodLevel, emoji: moodEmoji)
            Toggle("Ruminations / pensées intrusives", isOn: $showRumination)
            Toggle("Exercice aujourd'hui", isOn: $didExercise)
            Toggle("Écran > 1h avant le lit", isOn: $screenOverHour)
        }
    }

    private var medicalTogglesSection: some View {
        factorSection(title: "Médical (profil)", icon: "cross.case.fill") {
            Toggle("Douleur", isOn: $hasPain)
            if hasPain {
                TextField("Localisation", text: $painLocation)
                    .textFieldStyle(.roundedBorder)
            }
            Toggle("Médicament pris", isOn: $tookMedication)
        }
    }

    private var cycleSection: some View {
        factorSection(title: "Cycle", icon: "circle.dotted") {
            if let profile, let day = profile.currentCycleDay() {
                let phase = profile.menstrualPhase(for: day)
                Text("Jour \(day) — \(phase.displayName)")
                    .font(.headline)
                Text(cycleBedtimeHint(phase: phase, day: day))
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
                Button("Gêne menstruelle ce soir") {
                    logTonightFactor(.menstrualDiscomfort, value: 1)
                }
                .buttonStyle(.bordered)
                .tint(SleepTheme.accent)
                Button("J’ai mes règles ce soir") {
                    if let p = profiles.first {
                        CyclePeriodEngine.setPeriodDay(Date(), flow: .medium, in: modelContext)
                        p.tracksMenstrualCycle = true
                        try? modelContext.save()
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            } else {
                Text("Marque tes règles dans Profil → Calendrier des règles pour un suivi adapté.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }

    private func cycleBedtimeHint(phase: UserProfile.MenstrualPhase, day: Int) -> String {
        switch phase {
        case .menstrual:
            return "Soirée douce recommandée — fatigue normale."
        case .luteal:
            return day > 22 ? "Règles peut‑être bientôt : privilégie le repos." : "Sommeil parfois plus léger en fin de cycle."
        case .ovulation:
            return "Énergie variable : couche-toi à heure stable."
        case .follicular:
            return "Bonne période pour ancrer une routine de coucher."
        }
    }

    private var batteryWarning: some View {
        Label("Batterie < 20 % — le micro peut s'arrêter.", systemImage: "battery.25")
            .foregroundStyle(.orange)
            .padding()
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func factorSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sliderRow(_ title: String, value: Binding<Double>, emoji: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(emoji).font(.title2)
                Text("\(Int(value.wrappedValue))")
            }
            Slider(value: value, in: 1...10, step: 1)
        }
    }

    private var stressEmoji: String {
        switch Int(stressLevel) {
        case 1...3: return "😌"
        case 4...6: return "😐"
        default: return "😰"
        }
    }

    private var moodEmoji: String {
        switch Int(moodLevel) {
        case 1...3: return "😔"
        case 4...6: return "🙂"
        default: return "😄"
        }
    }

    private func logTonightFactor(_ type: FactorType, value: Double, notes: String? = nil) {
        let factor = SleepFactor(type: type, value: value, consumedAt: Date(), notes: notes)
        modelContext.insert(factor)
        try? modelContext.save()
    }

    private func startNight() {
        isStarting = true
        startError = nil

        if alarmEnabled {
            let minimumWake = Date().addingTimeInterval(90 * 60)
            if selectedWakeTime < minimumWake {
                startError = "Choisis un réveil au moins 1 h 30 après maintenant."
                isStarting = false
                return
            }
        }

        var models: [SleepFactor] = []
        models.append(SleepFactor(type: .stressLevel, value: stressLevel))
        models.append(SleepFactor(type: .anxietyLevel, value: anxietyLevel))
        models.append(SleepFactor(type: .mood, value: moodLevel))
        if showRumination { models.append(SleepFactor(type: .rumination, value: stressLevel)) }
        if didExercise { models.append(SleepFactor(type: .exercise, value: 30)) }
        if screenOverHour { models.append(SleepFactor(type: .screenTime, value: 60)) }
        if hasPain { models.append(SleepFactor(type: .pain, value: 5, notes: painLocation)) }
        if tookMedication { models.append(SleepFactor(type: .medicationSleep, value: 1)) }

        persistAlarmSettings()
        let alarm = alarms.first
        let wake = alarmEnabled ? selectedWakeTime : nil

        Task {
            let ok = await tracker.startNight(
                factors: models,
                alarm: alarmEnabled ? alarm : nil,
                wakeTime: wake
            )
            isStarting = false
            if ok, tracker.isTracking {
                onStart()
            } else {
                startError = tracker.lastStartError
                    ?? tracker.soundMonitor.lastStartError
                    ?? "Le tracking n’a pas pu démarrer. Réessaie ou autorise le micro."
            }
        }
    }
}
