import SwiftData
import SwiftUI

struct DailyRoutineSectionView: View {
    @Environment(\.modelContext) private var modelContext

    let selectedDay: Date
    let allFactors: [SleepFactor]
    let routines: [DailySubstanceRoutine]

    @Query private var dayLogs: [DailyRoutineDayLog]

    @State private var editingRoutine: DailySubstanceRoutine?
    @State private var customTimeRoutine: DailySubstanceRoutine?
    @State private var customTimeSlot: DailyRoutineSlot?
    @State private var customTime: Date = Date()
    @State private var showAddRoutine = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Substances quotidiennes")
                    .font(.headline)
                Spacer()
                if routines.contains(where: \.isActive) {
                    Button("Tout cocher") {
                        markAllAtDefaultTimes()
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    showAddRoutine = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
            }

            if routines.isEmpty {
                Text("Ajoute tes traitements (ex. ISRS le matin, magnésium le soir). Créneaux matin / midi / soir, rappel intelligent si oubli.")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(routines.filter(\.isActive)) { routine in
                    routineCard(routine)
                }
            }
        }
        .sheet(isPresented: $showAddRoutine, onDismiss: refreshNotifications) {
            DailyRoutineEditor()
        }
        .sheet(item: $editingRoutine, onDismiss: refreshNotifications) { routine in
            DailyRoutineEditor(routine: routine)
        }
        .sheet(item: $customTimeRoutine) { routine in
            NavigationStack {
                Form {
                    DatePicker("Heure de prise", selection: $customTime, displayedComponents: [.hourAndMinute])
                }
                .navigationTitle(routine.type.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { customTimeRoutine = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Enregistrer") {
                            if let slot = customTimeSlot {
                                markTaken(routine: routine, slot: slot, at: customTime)
                            } else {
                                markTaken(routine: routine, slot: routine.enabledSlots().first, at: customTime)
                            }
                            customTimeRoutine = nil
                            customTimeSlot = nil
                        }
                    }
                }
            }
        }
        .onAppear { refreshNotifications() }
        .onChange(of: selectedDay) { _, _ in refreshNotifications() }
        .onChange(of: allFactors.count) { _, _ in refreshNotifications() }
        .onChange(of: routines.count) { _, _ in refreshNotifications() }
        .onChange(of: dayLogs.count) { _, _ in refreshNotifications() }
    }

    private func routineCard(_ routine: DailySubstanceRoutine) -> some View {
        let skipped = isIntentionallySkipped(routine)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: routine.type.sfSymbol)
                    .foregroundStyle(SleepTheme.accent)
                Text(routine.type.displayName)
                    .font(.subheadline.bold())
                Spacer()
                if skipped {
                    Text("Pas pris")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Menu {
                    Button("Modifier la routine") { editingRoutine = routine }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            if skipped {
                Text("Marqué volontairement comme non pris — conservé dans l’historique.")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
                Button("Annuler (je l’ai pris)") {
                    clearSkip(routine)
                }
                .font(.caption)
            } else {
                ForEach(routine.enabledSlots(), id: \.id) { slot in
                    slotRow(routine: routine, slot: slot)
                }
                Button("Pas pris aujourd’hui", role: .destructive) {
                    markIntentionalSkip(routine)
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func slotRow(routine: DailySubstanceRoutine, slot: DailyRoutineSlot) -> some View {
        let taken = existingFactor(for: routine, slot: slot)
        return HStack {
            Image(systemName: slot.slot.icon)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.slot.displayName)
                    .font(.caption.bold())
                Text(timeString(slot.scheduledDate(on: selectedDay)))
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            Spacer()
            if let taken {
                Text("Pris \(timeString(taken.consumedAt))")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Button("Modifier") {
                    customTime = taken.consumedAt
                    customTimeRoutine = routine
                    customTimeSlot = slot
                }
                .font(.caption2)
            } else {
                Button("Cocher") {
                    markTaken(routine: routine, slot: slot, at: slot.scheduledDate(on: selectedDay))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private func isIntentionallySkipped(_ routine: DailySubstanceRoutine) -> Bool {
        if routine.enabledSlots().contains(where: { existingFactor(for: routine, slot: $0) != nil }) {
            return false
        }
        let start = Calendar.current.startOfDay(for: selectedDay)
        return dayLogs.contains {
            $0.routineId == routine.id
                && Calendar.current.isDate($0.dayStart, inSameDayAs: start)
                && $0.status == .intentionalSkip
        }
    }

    private func markIntentionalSkip(_ routine: DailySubstanceRoutine) {
        for slot in routine.enabledSlots() {
            if let f = existingFactor(for: routine, slot: slot) {
                modelContext.delete(f)
            }
        }
        upsertDayLog(routine: routine, status: .intentionalSkip)
        try? modelContext.save()
        refreshNotifications()
    }

    private func clearSkip(_ routine: DailySubstanceRoutine) {
        let start = Calendar.current.startOfDay(for: selectedDay)
        for log in dayLogs where log.routineId == routine.id
            && Calendar.current.isDate(log.dayStart, inSameDayAs: start) {
            modelContext.delete(log)
        }
        try? modelContext.save()
        refreshNotifications()
    }

    private func upsertDayLog(routine: DailySubstanceRoutine, status: DailyRoutineDayStatusKind) {
        let start = Calendar.current.startOfDay(for: selectedDay)
        if let existing = dayLogs.first(where: {
            $0.routineId == routine.id && Calendar.current.isDate($0.dayStart, inSameDayAs: start)
        }) {
            existing.status = status
        } else {
            modelContext.insert(DailyRoutineDayLog(routineId: routine.id, day: start, status: status))
        }
    }

    private func existingFactor(for routine: DailySubstanceRoutine, slot: DailyRoutineSlot) -> SleepFactor? {
        let link = DailyRoutineMarkers.linkKey(routineId: routine.id, slot: slot.slot)
        if let match = allFactors.first(where: { factor in
            Calendar.current.isDate(factor.consumedAt, inSameDayAs: selectedDay)
                && factor.routineLinkRaw == link
                && !DailyRoutineMarkers.isSkipped(factor)
        }) {
            return match
        }
        if let legacy = allFactors.first(where: { factor in
            Calendar.current.isDate(factor.consumedAt, inSameDayAs: selectedDay)
                && DailyRoutineMarkers.matchesRoutine(factor, routineId: routine.id, slot: slot.slot)
                && !DailyRoutineMarkers.isSkipped(factor)
        }) {
            DailyRoutineMarkers.migrateLegacyMarkerIfNeeded(legacy, routineId: routine.id, slot: slot.slot)
            legacy.routineLinkRaw = link
            return legacy
        }
        return nil
    }

    private func markTaken(routine: DailySubstanceRoutine, slot: DailyRoutineSlot?, at timestamp: Date) {
        guard let slot else { return }
        let link = DailyRoutineMarkers.linkKey(routineId: routine.id, slot: slot.slot)
        if let existing = existingFactor(for: routine, slot: slot) {
            existing.consumedAt = timestamp
            existing.value = routine.defaultValue
            existing.unit = routine.type.defaultUnit
            existing.routineLinkRaw = link
        } else {
            let factor = SleepFactor(
                type: routine.type,
                value: routine.defaultValue,
                consumedAt: timestamp,
                routineLinkRaw: link
            )
            modelContext.insert(factor)
        }
        upsertDayLog(routine: routine, status: .taken)
        try? modelContext.save()
        refreshNotifications()
    }

    private func markAllAtDefaultTimes() {
        for routine in routines where routine.isActive && !isIntentionallySkipped(routine) {
            routine.ensureDefaultSlots()
            for slot in routine.enabledSlots() {
                if existingFactor(for: routine, slot: slot) == nil {
                    markTaken(routine: routine, slot: slot, at: slot.scheduledDate(on: selectedDay))
                }
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func refreshNotifications() {
        DailyRoutineNotificationScheduler.refreshForDay(
            day: selectedDay,
            routines: routines,
            allFactors: allFactors,
            dayLogs: dayLogs
        )
    }
}

private struct DailyRoutineEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var routine: DailySubstanceRoutine?

    @State private var selectedType: FactorType = .ssri
    @State private var value: Double = 1
    @State private var notes = ""
    @State private var isActive = true
    @State private var morningEnabled = false
    @State private var noonEnabled = false
    @State private var eveningEnabled = true
    @State private var morningTime = Date()
    @State private var noonTime = Date()
    @State private var eveningTime = Date()
    @State private var reminderTiming: DailyRoutineReminderTiming = .after
    @State private var reminderOffsetMinutes = 45

    private var medTypes: [FactorType] {
        FactorType.allCases.filter {
            $0.category == .supplement || $0.category == .medical || $0 == .otherSubstance
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Substance", selection: $selectedType) {
                    ForEach(medTypes, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                HStack {
                    Text("Dose")
                    TextField("Valeur", value: $value, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                Section {
                    slotEditor(
                        title: "Matin",
                        enabled: $morningEnabled,
                        time: $morningTime,
                        icon: "sunrise.fill"
                    )
                    slotEditor(
                        title: "Midi",
                        enabled: $noonEnabled,
                        time: $noonTime,
                        icon: "sun.max.fill"
                    )
                    slotEditor(
                        title: "Soir",
                        enabled: $eveningEnabled,
                        time: $eveningTime,
                        icon: "moon.stars.fill"
                    )
                } header: {
                    Text("Créneaux")
                } footer: {
                    Text("Une routine peut avoir plusieurs prises dans la journée.")
                }
                Picker("Rappel", selection: $reminderTiming) {
                    ForEach(DailyRoutineReminderTiming.allCases, id: \.rawValue) { timing in
                        Text(timing.displayName).tag(timing)
                    }
                }
                if reminderTiming != .atTime {
                    Stepper("X = \(reminderOffsetMinutes) min", value: $reminderOffsetMinutes, in: 5...180, step: 5)
                }
                Toggle("Active", isOn: $isActive)
                TextField("Note (optionnel)", text: $notes, axis: .vertical)
            }
            .navigationTitle(routine == nil ? "Nouvelle routine" : "Modifier routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear { loadFromRoutine() }
        }
    }

    @ViewBuilder
    private func slotEditor(title: String, enabled: Binding<Bool>, time: Binding<Date>, icon: String) -> some View {
        Toggle(isOn: enabled) {
            Label(title, systemImage: icon)
        }
        if enabled.wrappedValue {
            DatePicker("Heure", selection: time, displayedComponents: [.hourAndMinute])
        }
    }

    private func loadFromRoutine() {
        guard let routine else { return }
        selectedType = routine.type
        value = routine.defaultValue
        notes = routine.notes ?? ""
        isActive = routine.isActive
        reminderTiming = routine.reminderTiming
        reminderOffsetMinutes = routine.reminderOffsetMinutes
        routine.ensureDefaultSlots()
        for slot in routine.slots ?? [] {
            var c = DateComponents()
            c.hour = slot.hour
            c.minute = slot.minute
            let d = Calendar.current.date(from: c) ?? Date()
            switch slot.slot {
            case .morning:
                morningEnabled = slot.isEnabled
                morningTime = d
            case .noon:
                noonEnabled = slot.isEnabled
                noonTime = d
            case .evening:
                eveningEnabled = slot.isEnabled
                eveningTime = d
            }
        }
        if (routine.slots ?? []).isEmpty {
            var c = DateComponents()
            c.hour = routine.hour
            c.minute = routine.minute
            eveningTime = Calendar.current.date(from: c) ?? Date()
        }
    }

    private func save() {
        let target = routine ?? DailySubstanceRoutine(type: selectedType)
        target.type = selectedType
        target.defaultValue = max(0, value)
        target.notes = notes.isEmpty ? nil : notes
        target.isActive = isActive
        target.reminderTiming = reminderTiming
        target.reminderOffsetMinutes = reminderOffsetMinutes

        if target.slots == nil { target.slots = [] }
        target.slots?.removeAll()

        func addSlot(_ kind: RoutineSlotKind, enabled: Bool, time: Date) {
            let p = Calendar.current.dateComponents([.hour, .minute], from: time)
            let slot = DailyRoutineSlot(
                slot: kind,
                hour: p.hour ?? 8,
                minute: p.minute ?? 0,
                isEnabled: enabled,
                reminderTiming: reminderTiming,
                reminderOffsetMinutes: reminderOffsetMinutes
            )
            slot.routine = target
            target.slots?.append(slot)
            if enabled && kind == .evening {
                target.hour = p.hour ?? 22
                target.minute = p.minute ?? 0
            }
        }

        addSlot(.morning, enabled: morningEnabled, time: morningTime)
        addSlot(.noon, enabled: noonEnabled, time: noonTime)
        addSlot(.evening, enabled: eveningEnabled, time: eveningTime)

        if routine == nil { modelContext.insert(target) }
        try? modelContext.save()
    }
}
