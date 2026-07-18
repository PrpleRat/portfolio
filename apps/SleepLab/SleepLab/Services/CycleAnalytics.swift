import Foundation
import SwiftData

struct PhaseSleepStats: Identifiable {
    var id: String { phase.rawValue }
    let phase: CyclePhase
    let sessionCount: Int
    let averageScore: Double?
    let dominantDreamEmotion: DreamEmotion?
    let dominantEmotionLabel: String
}

/// Point pour le sparkline (jour du cycle → score).
struct CycleDayScorePoint: Identifiable {
    let id = UUID()
    let cycleDay: Int
    let score: Int
    let date: Date
}

enum CycleAnalytics {
    static func phaseStats(
        sessions: [SleepSession],
        dreams: [DreamEntry],
        snapshot: CycleSnapshot
    ) -> [PhaseSleepStats] {
        CyclePhase.allCases.map { phase in
            let phaseSessions = sessions.filter { session in
                guard session.endTime != nil, session.overallScore > 0 else { return false }
                let day = MenstrualCycleService.cycleDay(
                    since: snapshot.periodStart,
                    cycleLength: snapshot.cycleLength,
                    on: session.startTime
                )
                return CyclePhase.from(cycleDay: day, cycleLength: snapshot.cycleLength) == phase
            }

            let scores = phaseSessions.map(\.overallScore)
            let avg: Double? = scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count)

            let phaseDreams = dreams.filter { dream in
                let day = MenstrualCycleService.cycleDay(
                    since: snapshot.periodStart,
                    cycleLength: snapshot.cycleLength,
                    on: dream.dreamDate
                )
                return CyclePhase.from(cycleDay: day, cycleLength: snapshot.cycleLength) == phase
            }

            let emotionCounts = emotionFrequency(in: phaseDreams)
            let dominant = emotionCounts.max(by: { $0.value < $1.value })?.key
            let label = dominant?.displayName ?? (phaseDreams.isEmpty ? "—" : "Mixte")

            return PhaseSleepStats(
                phase: phase,
                sessionCount: phaseSessions.count,
                averageScore: avg,
                dominantDreamEmotion: dominant,
                dominantEmotionLabel: label
            )
        }
    }

    static func sparklinePoints(
        sessions: [SleepSession],
        snapshot: CycleSnapshot
    ) -> [CycleDayScorePoint] {
        sessions
            .filter { $0.endTime != nil && $0.overallScore > 0 }
            .map { session in
                CycleDayScorePoint(
                    cycleDay: MenstrualCycleService.cycleDay(
                        since: snapshot.periodStart,
                        cycleLength: snapshot.cycleLength,
                        on: session.startTime
                    ),
                    score: session.overallScore,
                    date: session.startTime
                )
            }
            .sorted { $0.cycleDay < $1.cycleDay }
    }

    private static func emotionFrequency(in dreams: [DreamEntry]) -> [DreamEmotion: Int] {
        var counts: [DreamEmotion: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                counts[emotion, default: 0] += 1
            }
            if dream.emotions.isEmpty, let primary = dream.primaryEmotion {
                counts[primary, default: 0] += 1
            }
        }
        return counts
    }

    /// Symptôme du jour ou création.
    static func symptom(
        for date: Date = Date(),
        in context: ModelContext
    ) -> DailySymptom {
        let day = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailySymptom>()
        if let existing = (try? context.fetch(descriptor))?.first(where: {
            Calendar.current.isDate($0.dayStart, inSameDayAs: day)
        }) {
            return existing
        }
        let created = DailySymptom(dayStart: day)
        context.insert(created)
        return created
    }

    /// Nuit(s) commencée(s) la veille ou ce jour — lien indicatif par date.
    static func sessions(on day: Date, from sessions: [SleepSession]) -> [SleepSession] {
        sessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: day)
                || Calendar.current.isDate(
                    session.endTime ?? session.startTime,
                    inSameDayAs: day
                )
        }
    }
}
