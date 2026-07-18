import Foundation
import HealthKit
import SwiftData

struct HealthProfileImportResult {
    let updatedFields: [String]
    let message: String
}

struct HealthSleepImportResult {
    let imported: Int
    let skipped: Int
}

/// Lecture / écriture HealthKit pour enrichir les sessions et le profil
final class HealthKitService: ObservableObject {
    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationDenied = false

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let spo2 = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) { types.insert(spo2) }
        if let rr = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { types.insert(rr) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(rhr) }
        if let flow = HKObjectType.categoryType(forIdentifier: .menstrualFlow) { types.insert(flow) }
        if let mass = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(mass) }
        if let height = HKObjectType.quantityType(forIdentifier: .height) { types.insert(height) }
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(dob) }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { types.insert(sex) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
        } catch {
            authorizationDenied = true
        }
    }

    /// Remplit le profil depuis Santé (date de naissance, sexe, taille, poids, dernières règles).
    func importProfile(into profile: UserProfile) async -> HealthProfileImportResult {
        guard isAvailable else {
            return HealthProfileImportResult(updatedFields: [], message: "Santé n’est pas disponible sur cet appareil.")
        }
        await requestAuthorization()

        var updated: [String] = []

        if let components = try? store.dateOfBirthComponents(),
           let birth = Calendar.current.date(from: components) {
            profile.birthDate = birth
            updated.append("Date de naissance")
        }

        if let sexObject = try? store.biologicalSex() {
            profile.biologicalSex = Self.mapBiologicalSex(sexObject.biologicalSex)
            updated.append("Sexe biologique")
        }

        if let kg = await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo)) {
            profile.weight = kg
            updated.append("Poids")
        }

        if let meters = await latestQuantity(.height, unit: .meter()) {
            profile.height = meters * 100
            updated.append("Taille")
        }

        if let lastPeriod = await latestMenstrualFlowStart() {
            profile.tracksMenstrualCycle = true
            profile.lastPeriodStart = lastPeriod
            updated.append("Dernières règles")
        }

        if updated.isEmpty {
            return HealthProfileImportResult(
                updatedFields: [],
                message: "Aucune donnée profil trouvée dans Santé. Vérifie que taille, poids et identité y sont renseignés, et que \(AppBrand.displayName) a l’accès en lecture."
            )
        }
        return HealthProfileImportResult(
            updatedFields: updated,
            message: "Importé : \(updated.joined(separator: ", "))."
        )
    }

    /// Importe les nuits déjà enregistrées dans Santé (Apple Watch, autre app…) pour remplir Historique / Insights.
    func importSleepHistory(
        into context: ModelContext,
        days: Int = 30,
        profile: UserProfile?
    ) async -> HealthSleepImportResult {
        guard isAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return HealthSleepImportResult(imported: 0, skipped: 0)
        }
        await requestAuthorization()

        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: end) else {
            return HealthSleepImportResult(imported: 0, skipped: 0)
        }

        let samples = await fetchSleepSamples(type: sleepType, from: start, to: end)
        let nights = groupSleepSamples(samples)
        var imported = 0
        var skipped = 0

        for night in nights {
            let duration = night.end.timeIntervalSince(night.start)
            guard duration >= 2 * 3600 else {
                skipped += 1
                continue
            }
            if sessionExists(in: context, start: night.start, end: night.end) {
                skipped += 1
                continue
            }

            let session = SleepSession(startTime: night.start)
            session.endTime = night.end
            session.finalize(at: night.end)
            for segment in night.segments {
                let phase = SleepPhase(
                    startTime: segment.start,
                    endTime: segment.end,
                    phaseType: segment.phase,
                    movementScore: 0
                )
                phase.session = session
                session.phases.append(phase)
                context.insert(phase)
            }
            session.recalculatePhaseMinutes()
            await enrichSession(session)
            SleepScoreCalculator.apply(to: session, profile: profile)
            context.insert(session)
            imported += 1
        }

        try? context.save()
        return HealthSleepImportResult(imported: imported, skipped: skipped)
    }

    private struct ImportedNight {
        var start: Date
        var end: Date
        var segments: [(start: Date, end: Date, phase: SleepPhaseType)]
    }

    private func fetchSleepSamples(type: HKCategoryType, from start: Date, to end: Date) async -> [HKCategorySample] {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let cats = (samples as? [HKCategorySample]) ?? []
                cont.resume(returning: cats)
            }
            store.execute(query)
        }
    }

    private func groupSleepSamples(_ samples: [HKCategorySample]) -> [ImportedNight] {
        let asleep = samples.filter { sample in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
            switch value {
            case .inBed: return false
            default: return true
            }
        }.sorted { $0.startDate < $1.startDate }

        guard !asleep.isEmpty else { return [] }

        var nights: [ImportedNight] = []
        var currentSegments: [(start: Date, end: Date, phase: SleepPhaseType)] = []
        var blockStart = asleep[0].startDate
        var blockEnd = asleep[0].endDate

        func flushBlock() {
            guard !currentSegments.isEmpty else { return }
            nights.append(ImportedNight(start: blockStart, end: blockEnd, segments: currentSegments))
            currentSegments = []
        }

        for sample in asleep {
            let phase = phaseType(from: sample)
            if let lastEnd = currentSegments.last?.end,
               sample.startDate.timeIntervalSince(lastEnd) > 3 * 3600 {
                flushBlock()
                blockStart = sample.startDate
            }
            currentSegments.append((start: sample.startDate, end: sample.endDate, phase: phase))
            blockEnd = max(blockEnd, sample.endDate)
        }
        flushBlock()
        return nights
    }

    private func phaseType(from sample: HKCategorySample) -> SleepPhaseType {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return .light }
        switch value {
        case .awake: return .awake
        case .asleepDeep: return .deep
        case .asleepREM: return .rem
        case .asleepCore, .asleepUnspecified: return .light
        default: return .light
        }
    }

    private func latestMenstrualFlowStart() async -> Date? {
        guard let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 20, sortDescriptors: [sort]) { _, samples, _ in
                let cats = (samples as? [HKCategorySample]) ?? []
                let menstrual = cats.first { sample in
                    guard let v = HKCategoryValueMenstrualFlow(rawValue: sample.value) else { return false }
                    switch v {
                    case .light, .medium, .heavy, .unspecified:
                        return true
                    default:
                        return false
                    }
                }
                cont.resume(returning: menstrual?.startDate)
            }
            store.execute(query)
        }
    }

    private func sessionExists(in context: ModelContext, start: Date, end: Date) -> Bool {
        let tolerance: TimeInterval = 30 * 60
        let descriptor = FetchDescriptor<SleepSession>()
        guard let sessions = try? context.fetch(descriptor) else { return false }
        return sessions.contains { existing in
            abs(existing.startTime.timeIntervalSince(start)) < tolerance
                && abs((existing.endTime ?? existing.startTime).timeIntervalSince(end)) < tolerance
        }
    }

    private static func mapBiologicalSex(_ hk: HKBiologicalSex) -> BiologicalSex {
        switch hk {
        case HKBiologicalSex.female:
            return .female
        case HKBiologicalSex.male:
            return .male
        case HKBiologicalSex.other, HKBiologicalSex.notSet:
            return .other
        @unknown default:
            return .other
        }
    }

    func enrichSession(_ session: SleepSession) async {
        guard isAvailable else { return }
        let start = session.startTime
        let end = session.endTime ?? Date()

        session.avgHeartRate = await averageQuantity(.heartRate, from: start, to: end, unit: .count().unitDivided(by: .minute()))
        session.minHeartRate = await minQuantity(.heartRate, from: start, to: end, unit: .count().unitDivided(by: .minute()))
        session.avgHRV = await averageQuantity(.heartRateVariabilitySDNN, from: start, to: end, unit: .secondUnit(with: .milli))
        session.avgSPO2 = await averageQuantity(.oxygenSaturation, from: start, to: end, unit: .percent())
        session.respiratoryRate = await averageQuantity(.respiratoryRate, from: start, to: end, unit: .count().unitDivided(by: .minute()))
        session.restingHeartRate = await latestQuantity(.restingHeartRate, unit: .count().unitDivided(by: .minute()))
    }

    /// Exporte une session vers l’app Santé (phases + lit + sommeil global si besoin).
    func exportSessionToHealth(_ session: SleepSession) async {
        guard isAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let end = session.endTime else { return }
        await requestAuthorization()

        var samples: [HKCategorySample] = []
        let metadata = [HKMetadataKeyExternalUUID: session.id.uuidString]

        for phase in session.phases {
            let value: HKCategoryValueSleepAnalysis
            switch phase.phaseType {
            case .awake: value = .awake
            case .light: value = .asleepCore
            case .deep: value = .asleepDeep
            case .rem: value = .asleepREM
            }
            let sample = HKCategorySample(
                type: sleepType,
                value: value.rawValue,
                start: phase.startTime,
                end: phase.endTime,
                metadata: metadata
            )
            samples.append(sample)
        }

        if samples.isEmpty {
            let asleep = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                start: session.startTime,
                end: end,
                metadata: metadata
            )
            samples.append(asleep)
        }

        let inBed = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: session.startTime,
            end: end,
            metadata: metadata
        )
        samples.append(inBed)

        do {
            try await store.save(samples)
        } catch {
            // Santé peut refuser l’écriture si l’utilisateur n’a pas autorisé le partage.
        }
    }

    /// Ré-exporte les nuits récentes déjà dans SleepLab vers Santé.
    func exportRecentSessions(_ sessions: [SleepSession], limit: Int = 14) async -> Int {
        let completed = sessions
            .filter { $0.endTime != nil }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
            .prefix(limit)
        for session in completed {
            await exportSessionToHealth(session)
        }
        return completed.count
    }

    @available(*, deprecated, renamed: "exportSessionToHealth")
    func writeSleepPhases(for session: SleepSession) async {
        await exportSessionToHealth(session)
    }

    private func averageQuantity(
        _ id: HKQuantityTypeIdentifier,
        from start: Date,
        to end: Date,
        unit: HKUnit
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                cont.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func minQuantity(
        _ id: HKQuantityTypeIdentifier,
        from start: Date,
        to end: Date,
        unit: HKUnit
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMin) { _, stats, _ in
                cont.resume(returning: stats?.minimumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let q = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                cont.resume(returning: q)
            }
            store.execute(query)
        }
    }
}
