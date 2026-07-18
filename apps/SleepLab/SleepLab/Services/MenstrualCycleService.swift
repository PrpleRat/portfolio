import Foundation
import HealthKit
import SwiftData
import SwiftData

/// Phase du cycle (terminologie produit).
enum CyclePhase: String, CaseIterable, Identifiable, Equatable {
    case menstrual, follicular, ovulatory, luteal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .menstrual: return "Menstruelle"
        case .follicular: return "Folliculaire"
        case .ovulatory: return "Ovulatoire"
        case .luteal: return "Lutéale"
        }
    }

    /// Jours typiques sur un cycle de 28 j (pour la timeline visuelle).
    var typicalDaySpan: Int {
        switch self {
        case .menstrual: return 5
        case .follicular: return 8
        case .ovulatory: return 3
        case .luteal: return 12
        }
    }

    var timelineColor: (r: Double, g: Double, b: Double) {
        switch self {
        case .menstrual: return (0.85, 0.35, 0.45)
        case .follicular: return (0.45, 0.65, 0.95)
        case .ovulatory: return (0.95, 0.75, 0.35)
        case .luteal: return (0.55, 0.45, 0.85)
        }
    }

    static func from(cycleDay: Int, cycleLength: Int = 28) -> CyclePhase {
        let menstrualEnd = min(5, cycleLength / 5)
        let follicularEnd = min(13, cycleLength / 2)
        let ovulatoryEnd = min(16, follicularEnd + 3)
        switch cycleDay {
        case 1...menstrualEnd: return .menstrual
        case (menstrualEnd + 1)...follicularEnd: return .follicular
        case (follicularEnd + 1)...ovulatoryEnd: return .ovulatory
        default: return .luteal
        }
    }
}

struct CycleSnapshot: Equatable {
    var periodStart: Date
    var cycleLength: Int
    var cycleDay: Int
    var phase: CyclePhase
    var source: String
}

struct MenstrualFlowDay: Identifiable {
    let id = UUID()
    let date: Date
    let hadFlow: Bool
}

/// Lecture HealthKit + dérivation jour / phase du cycle.
final class MenstrualCycleService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorizationIfNeeded() async {
        guard isAvailable,
              let flowType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return }
        try? await store.requestAuthorization(toShare: [], read: [flowType])
    }

    /// État actuel : calendrier in-app, puis Santé, puis profil.
    func currentSnapshot(
        profile: UserProfile?,
        modelContext: ModelContext? = nil
    ) async -> CycleSnapshot? {
        await requestAuthorizationIfNeeded()
        let healthStart = await latestPeriodStartFromHealthKit()
        if let ctx = modelContext {
            let logged = CyclePeriodEngine.loggedDaySet(in: ctx)
            if let insight = CyclePeriodEngine.buildInsight(
                profile: profile,
                loggedDays: logged,
                healthPeriodStart: healthStart
            ) {
                if let profile {
                    CyclePeriodEngine.syncProfile(profile, insight: insight, loggedDays: logged)
                }
                return CyclePeriodEngine.snapshot(from: insight)
            }
        }

        let cycleLength = profile?.averageCycleLength ?? 28
        if let start = healthStart {
            let day = Self.cycleDay(since: start, cycleLength: cycleLength)
            return CycleSnapshot(
                periodStart: start,
                cycleLength: cycleLength,
                cycleDay: day,
                phase: CyclePhase.from(cycleDay: day, cycleLength: cycleLength),
                source: "Santé"
            )
        }

        guard let profile,
              profile.tracksMenstrualCycle,
              let start = profile.lastPeriodStart else { return nil }

        let day = Self.cycleDay(since: start, cycleLength: cycleLength)
        return CycleSnapshot(
            periodStart: start,
            cycleLength: cycleLength,
            cycleDay: day,
            phase: CyclePhase.from(cycleDay: day, cycleLength: cycleLength),
            source: "Profil"
        )
    }

    func fetchFlowHistory(days: Int = 90) async -> [MenstrualFlowDay] {
        guard isAvailable,
              let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return [] }
        await requestAuthorizationIfNeeded()

        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: end) else { return [] }

        let samples = await fetchCategorySamples(type: type, from: start, to: end)
        var flowDays = Set<Date>()
        for sample in samples where isMenstrualFlow(sample) {
            flowDays.insert(Calendar.current.startOfDay(for: sample.startDate))
        }

        var result: [MenstrualFlowDay] = []
        var cursor = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        while cursor <= endDay {
            result.append(MenstrualFlowDay(date: cursor, hadFlow: flowDays.contains(cursor)))
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    func latestPeriodStartFromHealthKit() async -> Date? {
        guard isAvailable,
              let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return nil }

        let samples = await fetchCategorySamples(
            type: type,
            from: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
            to: Date()
        )
        let bleeding = samples
            .filter(isMenstrualFlow)
            .sorted { $0.startDate > $1.startDate }

        guard let latest = bleeding.first else { return nil }

        var clusterStart = Calendar.current.startOfDay(for: latest.startDate)
        let sortedAsc = bleeding.sorted { $0.startDate < $1.startDate }
        for sample in sortedAsc.reversed() {
            let day = Calendar.current.startOfDay(for: sample.startDate)
            if clusterStart.timeIntervalSince(day) <= 86400 * 2 {
                clusterStart = day
            } else {
                break
            }
        }
        return clusterStart
    }

    static func cycleDay(since periodStart: Date, cycleLength: Int, on date: Date = Date()) -> Int {
        let start = Calendar.current.startOfDay(for: periodStart)
        let target = Calendar.current.startOfDay(for: date)
        let days = Calendar.current.dateComponents([.day], from: start, to: target).day ?? 0
        let mod = ((days % cycleLength) + cycleLength) % cycleLength
        return mod + 1
    }

    static func phase(for date: Date, snapshot: CycleSnapshot) -> CyclePhase {
        let day = cycleDay(since: snapshot.periodStart, cycleLength: snapshot.cycleLength, on: date)
        return CyclePhase.from(cycleDay: day, cycleLength: snapshot.cycleLength)
    }

    private func isMenstrualFlow(_ sample: HKCategorySample) -> Bool {
        guard let value = HKCategoryValueMenstrualFlow(rawValue: sample.value) else { return false }
        switch value {
        case .light, .medium, .heavy, .unspecified:
            return true
        default:
            return false
        }
    }

    private func fetchCategorySamples(type: HKCategoryType, from start: Date, to end: Date) async -> [HKCategorySample] {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                cont.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }
}
