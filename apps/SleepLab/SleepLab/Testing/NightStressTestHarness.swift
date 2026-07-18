import Foundation
import SwiftData

/// Outils pour stress-tester l’app sans attendre 8 h (Profil → Laboratoire QA).
@MainActor
enum NightStressTestHarness {

    /// Ajoute 5 événements sonores espacés sur la dernière nuit terminée.
    static func injectSpreadSoundEvents(context: ModelContext) throws -> String {
        var descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let session = try context.fetch(descriptor).first else {
            return "Aucune nuit enregistrée."
        }
        guard let end = session.endTime else {
            return "La dernière session n’est pas terminée — termine-la d’abord."
        }

        let start = session.startTime
        let span = max(end.timeIntervalSince(start), 3600)
        let offsets: [TimeInterval] = [
            span * 0.12,
            span * 0.28,
            span * 0.45,
            span * 0.62,
            span * 0.78
        ]
        let types: [SoundType] = [.snoring, .breathing, .coughing, .unknown, .environmentalNoise]

        for (offset, type) in zip(offsets, types) {
            let at = start.addingTimeInterval(offset)
            let event = SoundEvent(
                timestamp: at,
                soundType: type,
                decibelLevel: Double.random(in: 48...72),
                duration: 12,
                clipFileName: nil
            )
            event.session = session
            session.soundEvents.append(event)
            context.insert(event)
        }
        try context.save()
        return "5 sons de test ajoutés entre \(SoundEventFormatting.clockLabel(for: start)) et \(SoundEventFormatting.clockLabel(for: end)). Ouvre Historique → Sons."
    }

    /// Nuit courte : tracking réel ~3 min, phases toutes les 20 s, sons injectés.
    static func runShortNight(
        tracker: SleepTracker,
        context: ModelContext,
        profile: UserProfile?,
        alarm: AlarmConfig?
    ) async -> String {
        guard !tracker.isTracking else {
            return "Un tracking est déjà actif."
        }

        let previousPhaseInterval = tracker.phaseRecordInterval
        tracker.phaseRecordInterval = 20
        defer { tracker.phaseRecordInterval = previousPhaseInterval }

        let ok = await tracker.startNight(factors: [], alarm: alarm)
        guard ok, tracker.isTracking else {
            return tracker.lastStartError ?? "Impossible de démarrer le tracking."
        }

        guard let start = tracker.currentSession?.startTime else {
            await tracker.stopNight()
            return "Session introuvable."
        }

        for (index, delay) in [35.0, 70.0, 105.0, 140.0].enumerated() {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard tracker.isTracking else { break }
            let types: [SoundType] = [.snoring, .coughing, .breathing, .unknown]
            let at = start.addingTimeInterval(delay)
            tracker.soundMonitor.injectTestEvent(type: types[index], decibels: 52 + Double(index) * 4, at: at)
        }

        try? await Task.sleep(nanoseconds: 45_000_000_000)
        await tracker.stopNight()

        let count = tracker.lastCompletedSession?.soundEvents.count ?? 0
        return "Nuit courte terminée. \(count) événement(s) sonore(s). Vérifie les heures (secondes + offset) dans Sons de la nuit."
    }
}
