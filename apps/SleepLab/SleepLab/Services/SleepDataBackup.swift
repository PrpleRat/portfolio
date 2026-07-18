import Foundation
import SwiftData

// MARK: - Format JSON (export / import)

struct SleepLabBackupFile: Codable {
    static let currentVersion = 1

    var formatVersion: Int
    var exportedAt: Date
    var appVersion: String
    var calibration: CalibrationBackup?
    var profile: ProfileBackup?
    var alarm: AlarmBackup?
    var sessions: [SessionBackup]
    var orphanFactors: [FactorBackup]
    var dreams: [DreamBackup]
    var periodDays: [PeriodDayBackup]
    var dailySymptoms: [DailySymptomBackup]
    var dailyRoutines: [DailyRoutineBackup]?
}

struct CalibrationBackup: Codable {
    var phonePosition: String
    var awakeVarianceBaseline: Double
    var movementThresholdMultiplier: Double
    var calibrationNightCount: Int
    var isCalibrated: Bool
    var nightVarianceHistory: [Double]
}

struct ProfileBackup: Codable {
    var birthDate: Date?
    var biologicalSexRaw: String
    var weight: Double?
    var height: Double?
    var chronicConditionsData: String
    var medicationsData: String
    var hasApneaDiagnosed: Bool
    var storeNightAudioClips: Bool
    var tracksMenstrualCycle: Bool
    var averageCycleLength: Int
    var averagePeriodLength: Int?
    var lastPeriodStart: Date?
    var targetSleepDuration: Double
    var targetBedtimeHour: Int
    var targetBedtimeMinute: Int
    var minimumBedtimeHour: Int?
    var minimumBedtimeMinute: Int?
    var chronotypeRaw: String
    var caffeineMetabolism: Int
    var motionThresholdScale: Double
}

struct AlarmBackup: Codable {
    var isEnabled: Bool
    var targetWakeHour: Int
    var targetWakeMinute: Int
    var windowMinutes: Int
    var soundRaw: String
    var progressiveVolume: Bool
    var progressiveDurationSeconds: Int
}

struct SessionBackup: Codable {
    var id: UUID
    var kindRaw: String
    var startTime: Date
    var endTime: Date?
    var totalDuration: TimeInterval
    var awakenings: Int
    var overallScore: Int
    var efficiencyScore: Int
    var deepSleepMinutes: Int
    var remSleepMinutes: Int
    var lightSleepMinutes: Int
    var avgHeartRate: Double?
    var minHeartRate: Double?
    var avgHRV: Double?
    var avgSPO2: Double?
    var respiratoryRate: Double?
    var restingHeartRate: Double?
    var snoringMinutes: Int
    var loudestEvent: Double?
    var nightTemperature: Double?
    var humidity: Double?
    var pressure: Double?
    var alarmTime: Date?
    var actualWakeTime: Date?
    var wakePhaseRaw: String?
    var cycleDay: Int?
    var isManuallyEntered: Bool
    var pauseCount: Int
    var excludedPauseDuration: TimeInterval?
    var phases: [PhaseBackup]
    var soundEvents: [SoundEventBackup]
    var snoreEvents: [SnoreEventBackup]
    var factors: [FactorBackup]
}

struct PhaseBackup: Codable {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var phaseTypeRaw: String
    var movementScore: Double
    var heartRate: Double?
}

struct SoundEventBackup: Codable {
    var id: UUID
    var timestamp: Date
    var soundTypeRaw: String
    var decibelLevel: Double
    var duration: TimeInterval
    var clipFileName: String?
}

struct SnoreEventBackup: Codable {
    var id: UUID
    var timestamp: Date
    var duration: TimeInterval
    var confidence: Double
}

struct FactorBackup: Codable {
    var id: UUID
    var typeRaw: String
    var value: Double
    var unit: String
    var consumedAt: Date
    var hoursBeforeSleep: Double
    var subjectiveImpact: Int?
    var notes: String?
    var routineLinkRaw: String?
    var sessionId: UUID?
}

struct DreamBackup: Codable {
    var id: UUID
    var createdAt: Date
    var dreamDate: Date
    var title: String
    var narrative: String
    var clarity: Int
    var vividness: Int
    var isLucid: Bool
    var isRecurring: Bool
    var categoryRaw: String
    var emotionsData: String
    var tagsData: String
    var symbolsData: String
    var moodOnWake: Int
    var sessionId: UUID?
}

struct PeriodDayBackup: Codable {
    var id: UUID
    var dayStart: Date
    var flowIntensityRaw: String
    var updatedAt: Date
}

struct DailySymptomBackup: Codable {
    var id: UUID
    var dayStart: Date
    var hotFlash: Bool
    var cramps: Bool
    var moodRaw: String
    var updatedAt: Date
}

struct DailyRoutineSlotBackup: Codable {
    var id: UUID
    var slotRaw: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    var reminderTimingRaw: String?
    var reminderOffsetMinutes: Int?
}

struct DailyRoutineBackup: Codable {
    var id: UUID
    var typeRaw: String
    var defaultValue: Double
    var hour: Int
    var minute: Int
    var isActive: Bool
    var notes: String?
    var reminderTimingRaw: String?
    var reminderOffsetMinutes: Int?
    var slots: [DailyRoutineSlotBackup]?
}

enum SleepDataBackupError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidFile
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v): return "Version de sauvegarde non supportée (\(v))."
        case .invalidFile: return "Fichier JSON invalide."
        case .importFailed(let msg): return msg
        }
    }
}

// MARK: - Service

enum SleepDataBackupService {
    @MainActor
    static func export(from context: ModelContext) throws -> Data {
        let backup = try buildBackup(from: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    @MainActor
    static func exportToTemporaryFile(from context: ModelContext) throws -> URL {
        let data = try export(from: context)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let name = "\(AppBrand.displayName)-backup-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importBackup(
        data: Data,
        into context: ModelContext,
        mode: ImportMode
    ) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(SleepLabBackupFile.self, from: data)
        guard backup.formatVersion <= SleepLabBackupFile.currentVersion else {
            throw SleepDataBackupError.unsupportedVersion(backup.formatVersion)
        }
        return try apply(backup, to: context, mode: mode)
    }

    enum ImportMode {
        case merge
        case replaceAll
    }

    struct ImportResult {
        let sessionsImported: Int
        let sessionsSkipped: Int
        let factorsImported: Int
        let dreamsImported: Int
    }

    // MARK: - Export build

    @MainActor
    private static func buildBackup(from context: ModelContext) throws -> SleepLabBackupFile {
        let sessions = try context.fetch(FetchDescriptor<SleepSession>())
        let factors = try context.fetch(FetchDescriptor<SleepFactor>())
        let dreams = try context.fetch(FetchDescriptor<DreamEntry>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let alarms = try context.fetch(FetchDescriptor<AlarmConfig>())
        let periodDays = try context.fetch(FetchDescriptor<PeriodDayLog>())
        let symptoms = try context.fetch(FetchDescriptor<DailySymptom>())
        let routines = try context.fetch(FetchDescriptor<DailySubstanceRoutine>())

        let sessionIDs = Set(sessions.map(\.id))
        let orphanFactors = factors.filter { f in
            guard let sid = f.session?.id else { return true }
            return !sessionIDs.contains(sid)
        }

        let cal = SleepCalibrationManager.shared
        let calibration = CalibrationBackup(
            phonePosition: cal.phonePosition.rawValue,
            awakeVarianceBaseline: cal.awakeVarianceBaseline,
            movementThresholdMultiplier: cal.movementThresholdMultiplier,
            calibrationNightCount: cal.calibrationNightCount,
            isCalibrated: cal.isCalibrated,
            nightVarianceHistory: cal.nightVarianceHistory
        )

        return SleepLabBackupFile(
            formatVersion: SleepLabBackupFile.currentVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            calibration: calibration,
            profile: profiles.first.map { profileBackup(from: $0) },
            alarm: alarms.first.map { alarmBackup(from: $0) },
            sessions: sessions.map { sessionBackup(from: $0) },
            orphanFactors: orphanFactors.map { factorBackup(from: $0, sessionId: nil) },
            dreams: dreams.map { dreamBackup(from: $0) },
            periodDays: periodDays.map { periodBackup(from: $0) },
            dailySymptoms: symptoms.map { symptomBackup(from: $0) },
            dailyRoutines: routines.map { routineBackup(from: $0) }
        )
    }

    private static func sessionBackup(from s: SleepSession) -> SessionBackup {
        SessionBackup(
            id: s.id,
            kindRaw: s.kindRaw,
            startTime: s.startTime,
            endTime: s.endTime,
            totalDuration: s.totalDuration,
            awakenings: s.awakenings,
            overallScore: s.overallScore,
            efficiencyScore: s.efficiencyScore,
            deepSleepMinutes: s.deepSleepMinutes,
            remSleepMinutes: s.remSleepMinutes,
            lightSleepMinutes: s.lightSleepMinutes,
            avgHeartRate: s.avgHeartRate,
            minHeartRate: s.minHeartRate,
            avgHRV: s.avgHRV,
            avgSPO2: s.avgSPO2,
            respiratoryRate: s.respiratoryRate,
            restingHeartRate: s.restingHeartRate,
            snoringMinutes: s.snoringMinutes,
            loudestEvent: s.loudestEvent,
            nightTemperature: s.nightTemperature,
            humidity: s.humidity,
            pressure: s.pressure,
            alarmTime: s.alarmTime,
            actualWakeTime: s.actualWakeTime,
            wakePhaseRaw: s.wakePhaseRaw,
            cycleDay: s.cycleDay,
            isManuallyEntered: s.isManuallyEntered,
            pauseCount: s.pauseCount,
            excludedPauseDuration: s.excludedPauseDuration,
            phases: s.phases.map { phaseBackup(from: $0) },
            soundEvents: s.soundEvents.map { soundBackup(from: $0) },
            snoreEvents: s.snoreEvents.map { snoreBackup(from: $0) },
            factors: s.factors.map { factorBackup(from: $0, sessionId: s.id) }
        )
    }

    private static func phaseBackup(from p: SleepPhase) -> PhaseBackup {
        PhaseBackup(
            id: p.id,
            startTime: p.startTime,
            endTime: p.endTime,
            phaseTypeRaw: p.phaseTypeRaw,
            movementScore: p.movementScore,
            heartRate: p.heartRate
        )
    }

    private static func soundBackup(from e: SoundEvent) -> SoundEventBackup {
        SoundEventBackup(
            id: e.id,
            timestamp: e.timestamp,
            soundTypeRaw: e.typeRaw,
            decibelLevel: e.decibelLevel,
            duration: e.duration,
            clipFileName: e.clipFileName
        )
    }

    private static func snoreBackup(from e: SnoreEvent) -> SnoreEventBackup {
        SnoreEventBackup(
            id: e.id,
            timestamp: e.timestamp,
            duration: e.duration,
            confidence: e.confidence
        )
    }

    private static func factorBackup(from f: SleepFactor, sessionId: UUID?) -> FactorBackup {
        FactorBackup(
            id: f.id,
            typeRaw: f.typeRaw,
            value: f.value,
            unit: f.unit,
            consumedAt: f.consumedAt,
            hoursBeforeSleep: f.hoursBeforeSleep,
            subjectiveImpact: f.subjectiveImpact,
            notes: f.notes,
            routineLinkRaw: f.routineLinkRaw,
            sessionId: sessionId ?? f.session?.id
        )
    }

    private static func dreamBackup(from d: DreamEntry) -> DreamBackup {
        DreamBackup(
            id: d.id,
            createdAt: d.createdAt,
            dreamDate: d.dreamDate,
            title: d.title,
            narrative: d.narrative,
            clarity: d.clarity,
            vividness: d.vividness,
            isLucid: d.isLucid,
            isRecurring: d.isRecurring,
            categoryRaw: d.categoryRaw,
            emotionsData: d.emotionsData,
            tagsData: d.tagsData,
            symbolsData: d.symbolsData,
            moodOnWake: d.moodOnWake,
            sessionId: d.session?.id
        )
    }

    private static func profileBackup(from p: UserProfile) -> ProfileBackup {
        ProfileBackup(
            birthDate: p.birthDate,
            biologicalSexRaw: p.biologicalSexRaw,
            weight: p.weight,
            height: p.height,
            chronicConditionsData: p.chronicConditionsData,
            medicationsData: p.medicationsData,
            hasApneaDiagnosed: p.hasApneaDiagnosed,
            storeNightAudioClips: p.storeNightAudioClips,
            tracksMenstrualCycle: p.tracksMenstrualCycle,
            averageCycleLength: p.averageCycleLength,
            averagePeriodLength: p.averagePeriodLength,
            lastPeriodStart: p.lastPeriodStart,
            targetSleepDuration: p.targetSleepDuration,
            targetBedtimeHour: p.targetBedtimeHour,
            targetBedtimeMinute: p.targetBedtimeMinute,
            minimumBedtimeHour: p.minimumBedtimeHour,
            minimumBedtimeMinute: p.minimumBedtimeMinute,
            chronotypeRaw: p.chronotypeRaw,
            caffeineMetabolism: p.caffeineMetabolism,
            motionThresholdScale: p.motionThresholdScale
        )
    }

    private static func alarmBackup(from a: AlarmConfig) -> AlarmBackup {
        AlarmBackup(
            isEnabled: a.isEnabled,
            targetWakeHour: a.targetWakeHour,
            targetWakeMinute: a.targetWakeMinute,
            windowMinutes: a.windowMinutes,
            soundRaw: a.soundRaw,
            progressiveVolume: a.progressiveVolume,
            progressiveDurationSeconds: a.progressiveDurationSeconds
        )
    }

    private static func periodBackup(from p: PeriodDayLog) -> PeriodDayBackup {
        PeriodDayBackup(
            id: p.id,
            dayStart: p.dayStart,
            flowIntensityRaw: p.flowIntensityRaw,
            updatedAt: p.updatedAt
        )
    }

    private static func symptomBackup(from s: DailySymptom) -> DailySymptomBackup {
        DailySymptomBackup(
            id: s.id,
            dayStart: s.dayStart,
            hotFlash: s.hotFlash,
            cramps: s.cramps,
            moodRaw: s.moodRaw,
            updatedAt: s.updatedAt
        )
    }

    private static func routineBackup(from routine: DailySubstanceRoutine) -> DailyRoutineBackup {
        routine.ensureDefaultSlots()
        let slotBackups = (routine.slots ?? []).map { slot in
            DailyRoutineSlotBackup(
                id: slot.id,
                slotRaw: slot.slotRaw,
                hour: slot.hour,
                minute: slot.minute,
                isEnabled: slot.isEnabled,
                reminderTimingRaw: slot.reminderTimingRaw,
                reminderOffsetMinutes: slot.reminderOffsetMinutes
            )
        }
        return DailyRoutineBackup(
            id: routine.id,
            typeRaw: routine.typeRaw,
            defaultValue: routine.defaultValue,
            hour: routine.hour,
            minute: routine.minute,
            isActive: routine.isActive,
            notes: routine.notes,
            reminderTimingRaw: routine.reminderTimingRaw,
            reminderOffsetMinutes: routine.reminderOffsetMinutes,
            slots: slotBackups.isEmpty ? nil : slotBackups
        )
    }

    // MARK: - Import apply

    @MainActor
    private static func apply(
        _ backup: SleepLabBackupFile,
        to context: ModelContext,
        mode: ImportMode
    ) throws -> ImportResult {
        if mode == .replaceAll {
            try deleteAllData(in: context)
        }

        var existingSessionIDs = Set(try context.fetch(FetchDescriptor<SleepSession>()).map(\.id))
        var existingFactorIDs = Set(try context.fetch(FetchDescriptor<SleepFactor>()).map(\.id))
        var existingDreamIDs = Set(try context.fetch(FetchDescriptor<DreamEntry>()).map(\.id))

        if let cal = backup.calibration {
            applyCalibration(cal)
        }

        if let profileBackup = backup.profile {
            try applyProfile(profileBackup, context: context)
        }
        if let alarmBackup = backup.alarm {
            try applyAlarm(alarmBackup, context: context)
        }

        var sessionsImported = 0
        var sessionsSkipped = 0
        var sessionMap: [UUID: SleepSession] = [:]

        for dto in backup.sessions {
            if existingSessionIDs.contains(dto.id) {
                sessionsSkipped += 1
                continue
            }
            let session = insertSession(dto, context: context)
            sessionMap[dto.id] = session
            existingSessionIDs.insert(dto.id)
            sessionsImported += 1
        }

        var factorsImported = 0
        for dto in backup.orphanFactors {
            guard !existingFactorIDs.contains(dto.id) else { continue }
            insertFactor(dto, session: nil, context: context)
            existingFactorIDs.insert(dto.id)
            factorsImported += 1
        }

        var dreamsImported = 0
        for dto in backup.dreams {
            guard !existingDreamIDs.contains(dto.id) else { continue }
            let dream = DreamEntry(
                dreamDate: dto.dreamDate,
                title: dto.title,
                narrative: dto.narrative,
                category: DreamCategory(rawValue: dto.categoryRaw) ?? .ordinary,
                emotions: [],
                session: dto.sessionId.flatMap { sessionMap[$0] }
            )
            dream.id = dto.id
            dream.createdAt = dto.createdAt
            dream.clarity = dto.clarity
            dream.vividness = dto.vividness
            dream.isLucid = dto.isLucid
            dream.isRecurring = dto.isRecurring
            dream.emotionsData = dto.emotionsData
            dream.tagsData = dto.tagsData
            dream.symbolsData = dto.symbolsData
            dream.moodOnWake = dto.moodOnWake
            context.insert(dream)
            existingDreamIDs.insert(dto.id)
            dreamsImported += 1
        }

        for dto in backup.periodDays {
            guard !(try context.fetch(FetchDescriptor<PeriodDayLog>())).contains(where: { $0.id == dto.id }) else { continue }
            let log = PeriodDayLog(dayStart: dto.dayStart, flow: MenstrualFlowIntensity(rawValue: dto.flowIntensityRaw) ?? .medium)
            log.id = dto.id
            log.updatedAt = dto.updatedAt
            context.insert(log)
        }

        for dto in backup.dailySymptoms {
            guard !(try context.fetch(FetchDescriptor<DailySymptom>())).contains(where: { $0.id == dto.id }) else { continue }
            let s = DailySymptom(dayStart: dto.dayStart, mood: DailyMood(rawValue: dto.moodRaw) ?? .neutral)
            s.id = dto.id
            s.hotFlash = dto.hotFlash
            s.cramps = dto.cramps
            s.updatedAt = dto.updatedAt
            context.insert(s)
        }

        if let routines = backup.dailyRoutines {
            for dto in routines {
                guard !(try context.fetch(FetchDescriptor<DailySubstanceRoutine>())).contains(where: { $0.id == dto.id }) else { continue }
                let routine = DailySubstanceRoutine(
                    id: dto.id,
                    type: FactorType(rawValue: dto.typeRaw) ?? .ssri,
                    defaultValue: dto.defaultValue,
                    hour: dto.hour,
                    minute: dto.minute,
                    isActive: dto.isActive,
                    notes: dto.notes,
                    reminderTiming: DailyRoutineReminderTiming(rawValue: dto.reminderTimingRaw ?? "") ?? .after,
                    reminderOffsetMinutes: dto.reminderOffsetMinutes ?? 45
                )
                if let slots = dto.slots {
                    routine.slots = slots.map { sb in
                        let slot = DailyRoutineSlot(
                            id: sb.id,
                            slot: RoutineSlotKind(rawValue: sb.slotRaw) ?? .evening,
                            hour: sb.hour,
                            minute: sb.minute,
                            isEnabled: sb.isEnabled,
                            reminderTiming: DailyRoutineReminderTiming(rawValue: sb.reminderTimingRaw ?? "") ?? .after,
                            reminderOffsetMinutes: sb.reminderOffsetMinutes ?? 45
                        )
                        slot.routine = routine
                        return slot
                    }
                } else {
                    routine.ensureDefaultSlots()
                }
                context.insert(routine)
            }
        }

        try context.save()
        return ImportResult(
            sessionsImported: sessionsImported,
            sessionsSkipped: sessionsSkipped,
            factorsImported: factorsImported,
            dreamsImported: dreamsImported
        )
    }

    @MainActor
    private static func deleteAllData(in context: ModelContext) throws {
        for session in try context.fetch(FetchDescriptor<SleepSession>()) {
            context.delete(session)
        }
        for factor in try context.fetch(FetchDescriptor<SleepFactor>()) {
            context.delete(factor)
        }
        for dream in try context.fetch(FetchDescriptor<DreamEntry>()) {
            context.delete(dream)
        }
        for log in try context.fetch(FetchDescriptor<PeriodDayLog>()) {
            context.delete(log)
        }
        for s in try context.fetch(FetchDescriptor<DailySymptom>()) {
            context.delete(s)
        }
        for routine in try context.fetch(FetchDescriptor<DailySubstanceRoutine>()) {
            context.delete(routine)
        }
        try context.save()
    }

    @MainActor
    private static func applyCalibration(_ dto: CalibrationBackup) {
        SleepCalibrationManager.shared.restoreFromBackup(
            phonePosition: PhonePosition(rawValue: dto.phonePosition) ?? .mattress,
            awakeVarianceBaseline: dto.awakeVarianceBaseline,
            movementThresholdMultiplier: dto.movementThresholdMultiplier,
            calibrationNightCount: dto.calibrationNightCount,
            isCalibrated: dto.isCalibrated,
            nightVarianceHistory: dto.nightVarianceHistory
        )
    }

    @MainActor
    private static func applyProfile(_ dto: ProfileBackup, context: ModelContext) throws {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty { context.insert(profile) }
        profile.birthDate = dto.birthDate
        profile.biologicalSexRaw = dto.biologicalSexRaw
        profile.weight = dto.weight
        profile.height = dto.height
        profile.chronicConditionsData = dto.chronicConditionsData
        profile.medicationsData = dto.medicationsData
        profile.hasApneaDiagnosed = dto.hasApneaDiagnosed
        profile.storeNightAudioClips = dto.storeNightAudioClips
        profile.tracksMenstrualCycle = dto.tracksMenstrualCycle
        profile.averageCycleLength = dto.averageCycleLength
        profile.averagePeriodLength = dto.averagePeriodLength
        profile.lastPeriodStart = dto.lastPeriodStart
        profile.targetSleepDuration = dto.targetSleepDuration
        profile.targetBedtimeHour = dto.targetBedtimeHour
        profile.targetBedtimeMinute = dto.targetBedtimeMinute
        if let h = dto.minimumBedtimeHour { profile.minimumBedtimeHour = h }
        if let m = dto.minimumBedtimeMinute { profile.minimumBedtimeMinute = m }
        profile.chronotypeRaw = dto.chronotypeRaw
        profile.caffeineMetabolism = dto.caffeineMetabolism
        profile.motionThresholdScale = dto.motionThresholdScale
    }

    @MainActor
    private static func applyAlarm(_ dto: AlarmBackup, context: ModelContext) throws {
        let alarms = try context.fetch(FetchDescriptor<AlarmConfig>())
        let alarm = alarms.first ?? AlarmConfig()
        if alarms.isEmpty { context.insert(alarm) }
        alarm.isEnabled = dto.isEnabled
        alarm.targetWakeHour = dto.targetWakeHour
        alarm.targetWakeMinute = dto.targetWakeMinute
        alarm.windowMinutes = dto.windowMinutes
        alarm.soundRaw = dto.soundRaw
        alarm.progressiveVolume = dto.progressiveVolume
        alarm.progressiveDurationSeconds = dto.progressiveDurationSeconds
    }

    @MainActor
    private static func insertSession(_ dto: SessionBackup, context: ModelContext) -> SleepSession {
        let session = SleepSession(startTime: dto.startTime, kind: SleepSessionKind(rawValue: dto.kindRaw) ?? .night)
        session.id = dto.id
        session.endTime = dto.endTime
        session.totalDuration = dto.totalDuration
        session.awakenings = dto.awakenings
        session.overallScore = dto.overallScore
        session.efficiencyScore = dto.efficiencyScore
        session.deepSleepMinutes = dto.deepSleepMinutes
        session.remSleepMinutes = dto.remSleepMinutes
        session.lightSleepMinutes = dto.lightSleepMinutes
        session.avgHeartRate = dto.avgHeartRate
        session.minHeartRate = dto.minHeartRate
        session.avgHRV = dto.avgHRV
        session.avgSPO2 = dto.avgSPO2
        session.respiratoryRate = dto.respiratoryRate
        session.restingHeartRate = dto.restingHeartRate
        session.snoringMinutes = dto.snoringMinutes
        session.loudestEvent = dto.loudestEvent
        session.nightTemperature = dto.nightTemperature
        session.humidity = dto.humidity
        session.pressure = dto.pressure
        session.alarmTime = dto.alarmTime
        session.actualWakeTime = dto.actualWakeTime
        session.wakePhaseRaw = dto.wakePhaseRaw
        session.cycleDay = dto.cycleDay
        session.isManuallyEntered = dto.isManuallyEntered
        session.pauseCount = dto.pauseCount
        session.excludedPauseDuration = dto.excludedPauseDuration ?? 0

        context.insert(session)

        for p in dto.phases {
            let phase = SleepPhase(
                id: p.id,
                startTime: p.startTime,
                endTime: p.endTime,
                phaseType: SleepPhaseType(rawValue: p.phaseTypeRaw) ?? .light,
                movementScore: p.movementScore,
                heartRate: p.heartRate
            )
            phase.session = session
            session.phases.append(phase)
            context.insert(phase)
        }

        for e in dto.soundEvents {
            let event = SoundEvent(
                timestamp: e.timestamp,
                soundType: SoundType(rawValue: e.soundTypeRaw) ?? .unknown,
                decibelLevel: e.decibelLevel,
                duration: e.duration,
                clipFileName: e.clipFileName
            )
            event.id = e.id
            event.session = session
            session.soundEvents.append(event)
            context.insert(event)
        }

        for e in dto.snoreEvents {
            let event = SnoreEvent(timestamp: e.timestamp, duration: e.duration, confidence: e.confidence)
            event.id = e.id
            event.session = session
            session.snoreEvents.append(event)
            context.insert(event)
        }

        for f in dto.factors {
            insertFactor(f, session: session, context: context)
        }

        SleepPhaseBackfill.backfillIfNeeded(session: session, modelContext: context)

        return session
    }

    @MainActor
    private static func insertFactor(_ dto: FactorBackup, session: SleepSession?, context: ModelContext) {
        let factor = SleepFactor(
            id: dto.id,
            type: FactorType(rawValue: dto.typeRaw) ?? .caffeine,
            value: dto.value,
            unit: dto.unit,
            consumedAt: dto.consumedAt,
            hoursBeforeSleep: dto.hoursBeforeSleep,
            subjectiveImpact: dto.subjectiveImpact,
            notes: dto.notes,
            routineLinkRaw: dto.routineLinkRaw
        )
        factor.session = session
        if let session, !session.factors.contains(where: { $0.id == factor.id }) {
            session.factors.append(factor)
        }
        context.insert(factor)
    }
}
