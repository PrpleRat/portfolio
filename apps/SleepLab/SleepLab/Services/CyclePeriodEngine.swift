import Foundation
import SwiftData

/// Calcul du cycle à partir des jours de règles saisis (+ Santé optionnel).
enum CyclePeriodEngine {

    struct CycleInsight: Equatable {
        var periodStart: Date
        var cycleLength: Int
        var periodLength: Int
        var cycleDay: Int
        var phase: CyclePhase
        var source: String
        var loggedPeriodDays: Int
        var predictedNextPeriodStart: Date?
        var daysUntilNextPeriod: Int?
        var isOnPeriodToday: Bool
        var fertileWindowStart: Date?
        var fertileWindowEnd: Date?
    }

    // MARK: - Lecture logs

    static func fetchLoggedDays(in context: ModelContext) -> [PeriodDayLog] {
        let descriptor = FetchDescriptor<PeriodDayLog>(
            sortBy: [SortDescriptor(\.dayStart, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func loggedDaySet(in context: ModelContext) -> Set<Date> {
        Set(fetchLoggedDays(in: context).map(\.dayStart))
    }

    static func log(for day: Date, in context: ModelContext) -> PeriodDayLog? {
        let start = Calendar.current.startOfDay(for: day)
        return fetchLoggedDays(in: context).first {
            Calendar.current.isDate($0.dayStart, inSameDayAs: start)
        }
    }

    @discardableResult
    static func togglePeriodDay(
        _ day: Date,
        flow: MenstrualFlowIntensity = .medium,
        in context: ModelContext
    ) -> Bool {
        let start = Calendar.current.startOfDay(for: day)
        if let existing = log(for: start, in: context) {
            context.delete(existing)
            try? context.save()
            return false
        }
        let entry = PeriodDayLog(dayStart: start, flow: flow)
        context.insert(entry)
        try? context.save()
        return true
    }

    static func setPeriodDay(
        _ day: Date,
        flow: MenstrualFlowIntensity,
        in context: ModelContext
    ) {
        let start = Calendar.current.startOfDay(for: day)
        if let existing = log(for: start, in: context) {
            existing.flowIntensity = flow
            existing.touch()
        } else {
            context.insert(PeriodDayLog(dayStart: start, flow: flow))
        }
        try? context.save()
    }

    // MARK: - Dérivation cycle

    /// Repères de début de règles (premier jour de chaque « cluster » consécutif).
    static func periodStarts(from loggedDays: Set<Date>, gapDays: Int = 2) -> [Date] {
        let sorted = loggedDays.sorted()
        guard !sorted.isEmpty else { return [] }

        var starts: [Date] = []
        var clusterStart = sorted[0]
        var previous = sorted[0]

        for day in sorted.dropFirst() {
            let delta = Calendar.current.dateComponents([.day], from: previous, to: day).day ?? 0
            if delta > gapDays {
                starts.append(clusterStart)
                clusterStart = day
            }
            previous = day
        }
        starts.append(clusterStart)
        return starts
    }

    static func inferredCycleLength(from starts: [Date], fallback: Int) -> Int {
        guard starts.count >= 2 else { return fallback }
        let sorted = starts.sorted()
        var gaps: [Int] = []
        for i in 1..<sorted.count {
            let d = Calendar.current.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? fallback
            if d >= 18, d <= 45 { gaps.append(d) }
        }
        guard !gaps.isEmpty else { return fallback }
        return max(21, min(45, gaps.reduce(0, +) / gaps.count))
    }

    static func inferredPeriodLength(from loggedDays: Set<Date>, latestStart: Date) -> Int {
        let end = Calendar.current.startOfDay(for: Date())
        let daysInCluster = loggedDays.filter { day in
            day >= latestStart && day <= end
        }.count
        if daysInCluster > 0 { return max(2, min(10, daysInCluster)) }
        return 5
    }

    static func buildInsight(
        profile: UserProfile?,
        loggedDays: Set<Date>,
        healthPeriodStart: Date?,
        on date: Date = Date()
    ) -> CycleInsight? {
        let fallbackCycle = profile?.averageCycleLength ?? 28
        let fallbackPeriod = profile?.effectivePeriodLength ?? 5

        var source = "Calendrier"
        var periodStart: Date?

        let logStarts = periodStarts(from: loggedDays)
        if let latest = logStarts.last {
            periodStart = latest
        }

        if let health = healthPeriodStart {
            if periodStart == nil || health > periodStart! {
                periodStart = Calendar.current.startOfDay(for: health)
                source = loggedDays.isEmpty ? "Santé" : "Calendrier + Santé"
            }
        }

        if periodStart == nil,
           let profile,
           profile.tracksMenstrualCycle,
           let manual = profile.lastPeriodStart {
            periodStart = Calendar.current.startOfDay(for: manual)
            source = loggedDays.isEmpty ? "Profil" : "Calendrier + Profil"
        }

        guard let start = periodStart else { return nil }

        let cycleLength = inferredCycleLength(from: logStarts, fallback: fallbackCycle)
        let periodLength = max(
            fallbackPeriod,
            inferredPeriodLength(from: loggedDays, latestStart: start)
        )

        let cycleDay = MenstrualCycleService.cycleDay(
            since: start,
            cycleLength: cycleLength,
            on: date
        )
        let phase = CyclePhase.from(cycleDay: cycleDay, cycleLength: cycleLength)

        let today = Calendar.current.startOfDay(for: date)
        let onPeriodToday = loggedDays.contains(today)

        let predictedNext = Calendar.current.date(byAdding: .day, value: cycleLength, to: start)
        let daysUntil: Int? = predictedNext.map {
            max(0, Calendar.current.dateComponents([.day], from: today, to: $0).day ?? 0)
        }

        let ovulationDay = max(periodLength + 1, cycleLength - 14)
        let fertileStart = Calendar.current.date(byAdding: .day, value: ovulationDay - 2, to: start)
        let fertileEnd = Calendar.current.date(byAdding: .day, value: ovulationDay + 2, to: start)

        return CycleInsight(
            periodStart: start,
            cycleLength: cycleLength,
            periodLength: periodLength,
            cycleDay: cycleDay,
            phase: phase,
            source: source,
            loggedPeriodDays: loggedDays.count,
            predictedNextPeriodStart: predictedNext,
            daysUntilNextPeriod: daysUntil,
            isOnPeriodToday: onPeriodToday,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd
        )
    }

    /// Met à jour le profil après modification du calendrier.
    static func syncProfile(_ profile: UserProfile, insight: CycleInsight, loggedDays: Set<Date>) {
        profile.tracksMenstrualCycle = true
        profile.lastPeriodStart = insight.periodStart
        profile.averageCycleLength = insight.cycleLength
        profile.effectivePeriodLength = insight.periodLength
        if !loggedDays.isEmpty {
            let starts = periodStarts(from: loggedDays)
            if starts.count >= 2 {
                profile.averageCycleLength = inferredCycleLength(from: starts, fallback: profile.averageCycleLength)
            }
        }
    }

    static func snapshot(from insight: CycleInsight) -> CycleSnapshot {
        CycleSnapshot(
            periodStart: insight.periodStart,
            cycleLength: insight.cycleLength,
            cycleDay: insight.cycleDay,
            phase: insight.phase,
            source: insight.source
        )
    }
}
