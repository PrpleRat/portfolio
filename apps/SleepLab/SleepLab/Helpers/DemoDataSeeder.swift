import Foundation
import SwiftData

/// Nuits fictives pour tester Historique / Insights sans attendre 7 vraies nuits.
enum DemoDataSeeder {
    static let defaultNightCount = 10

    @MainActor
    static func seedDemoNights(
        context: ModelContext,
        count: Int = defaultNightCount,
        profile: UserProfile?
    ) throws -> Int {
        let calendar = Calendar.current
        var created = 0

        for dayOffset in 1...count {
            guard let nightEnd = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date())) else {
                continue
            }
            let bedtime = calendar.date(byAdding: .hour, value: -8, to: nightEnd) ?? nightEnd
            let session = SleepSession(startTime: bedtime, kind: dayOffset == 1 ? .nap : .night)
            session.endTime = nightEnd
            session.totalDuration = nightEnd.timeIntervalSince(bedtime)
            session.awakenings = Int.random(in: 0...2)

            let phaseCount = 8
            var phaseStart = bedtime
            let phaseDuration = session.totalDuration / Double(phaseCount)
            let types: [SleepPhaseType] = [.light, .deep, .rem, .light, .deep, .light, .rem, .light]

            for (index, type) in types.enumerated() {
                let end = phaseStart.addingTimeInterval(phaseDuration)
                let phase = SleepPhase(
                    startTime: phaseStart,
                    endTime: index == types.count - 1 ? nightEnd : end,
                    phaseType: type,
                    movementScore: Double.random(in: 0.01...0.12)
                )
                phase.session = session
                session.phases.append(phase)
                context.insert(phase)
                phaseStart = end
            }
            session.recalculatePhaseMinutes()

            let factors = demoFactors(for: dayOffset)
            for factor in factors {
                factor.session = session
                session.factors.append(factor)
                context.insert(factor)
            }

            seedSoundEvents(for: session, nightStart: bedtime, nightEnd: nightEnd)
            seedSnoreEvents(for: session, nightStart: bedtime, nightEnd: nightEnd)
            SleepScoreCalculator.apply(to: session, profile: profile)
            context.insert(session)
            created += 1
        }

        try context.save()
        return created
    }

    private static func seedSoundEvents(for session: SleepSession, nightStart: Date, nightEnd: Date) {
        let span = nightEnd.timeIntervalSince(nightStart)
        let offsets: [TimeInterval] = [span * 0.2, span * 0.35, span * 0.5, span * 0.7]
        let types: [SoundType] = [.snoring, .breathing, .coughing, .unknown]
        for (offset, type) in zip(offsets, types) {
            let event = SoundEvent(
                timestamp: nightStart.addingTimeInterval(offset),
                soundType: type,
                decibelLevel: Double.random(in: 50...65),
                duration: 10
            )
            event.session = session
            session.soundEvents.append(event)
        }
    }

    private static func seedSnoreEvents(for session: SleepSession, nightStart: Date, nightEnd: Date) {
        let span = nightEnd.timeIntervalSince(nightStart)
        guard span > 3600 else { return }
        let offsets: [TimeInterval] = [span * 0.25, span * 0.26, span * 0.27, span * 0.55, span * 0.56]
        for offset in offsets {
            let event = SnoreEvent(
                timestamp: nightStart.addingTimeInterval(offset),
                duration: 1,
                confidence: 0.88 + Double.random(in: 0...0.1)
            )
            event.session = session
            session.snoreEvents.append(event)
        }
        session.recalculateSnoreMinutes()
    }

    private static func demoFactors(for day: Int) -> [SleepFactor] {
        var list: [SleepFactor] = [
            SleepFactor(type: .stressLevel, value: Double(3 + (day % 5)), consumedAt: Date()),
            SleepFactor(type: .mood, value: Double(5 + (day % 4)), consumedAt: Date())
        ]
        if day % 2 == 0 {
            list.append(SleepFactor(type: .caffeine, value: 80, consumedAt: Date()))
        }
        if day % 3 == 0 {
            list.append(SleepFactor(type: .exercise, value: 30, consumedAt: Date()))
        }
        if day % 4 == 0 {
            list.append(SleepFactor(type: .alcohol, value: 15, consumedAt: Date()))
        }
        if day % 5 == 0 {
            list.append(SleepFactor(type: .screenTime, value: 90, consumedAt: Date()))
        }
        if day % 6 == 0 {
            list.append(SleepFactor(type: .melatonin, value: 1, consumedAt: Date()))
        }
        return list
    }
}
