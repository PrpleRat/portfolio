import Foundation
import SwiftData

/// Orchestrateur principal du tracking nocturne
@MainActor
final class SleepTracker: ObservableObject {
    let motionAnalyzer = MotionAnalyzer()
    let soundMonitor = SoundMonitor()
    let snoreDetection = SnoreDetectionService()
    let healthKit = HealthKitService()
    let weatherService = WeatherService()
    let locationHelper = LocationHelper()

    @Published var isTracking = false
    @Published var isPaused = false
    @Published var currentSession: SleepSession?
    @Published var lastCompletedSession: SleepSession?
    @Published var smartAlarm: SmartAlarm?
    @Published var elapsed: TimeInterval = 0
    @Published var lastStartError: String?
    @Published var audioMonitoringEnabled = false

    private var phaseTimer: Timer?
    private var elapsedTimer: Timer?
    private var lastPhaseRecord: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var pauseStartedAt: Date?
    private var modelContext: ModelContext?
    private var alarmConfig: AlarmConfig?
    private var userProfile: UserProfile?
    /// QA : intervalle entre enregistrements de phase (défaut 300 s).
    var phaseRecordInterval: TimeInterval = 300

    /// Évite des centaines de `save()` SQLite par nuit (événements audio + ronflement).
    private var persistTask: Task<Void, Never>?
    private var lastLiveActivityPhase: SleepPhaseType?
    private var lastLiveActivityPaused: Bool?
    private var lastLiveActivityElapsedMinute: Int = -1

    private static let persistDebounceSeconds: TimeInterval = 60
    private static let snoreMergeGapSeconds: TimeInterval = 20
    private static let maxSnoreEventDuration: TimeInterval = 12

    func configure(context: ModelContext, profile: UserProfile?, alarm: AlarmConfig?) {
        modelContext = context
        userProfile = profile
        alarmConfig = alarm
    }

    @discardableResult
    func startNight(
        factors: [SleepFactor],
        alarm: AlarmConfig?,
        wakeTime: Date? = nil
    ) async -> Bool {
        await startSession(kind: .night, factors: factors, alarm: alarm, wakeTime: wakeTime)
    }

    @discardableResult
    func startNap() async -> Bool {
        await startSession(kind: .nap, factors: [], alarm: nil)
    }

    @discardableResult
    func startSession(
        kind: SleepSessionKind,
        factors: [SleepFactor],
        alarm: AlarmConfig?,
        wakeTime: Date? = nil
    ) async -> Bool {
        guard let ctx = modelContext else {
            lastStartError = "Base de données non prête. Reviens à l’accueil puis réessaie."
            return false
        }

        lastStartError = nil
        audioMonitoringEnabled = false

        if isTracking {
            await stopNight()
        }

        if kind == .night {
            if let resumable = try? SleepNightGrouper.findResumableNight(in: ctx) {
                return await continueExistingNight(
                    session: resumable,
                    factors: factors,
                    alarm: alarm,
                    wakeTime: wakeTime
                )
            }
        }

        let session = SleepSession(kind: kind)
        let bedtime = projectedBedtime(for: session)

        for f in factors {
            ctx.insert(f)
            linkFactor(f, to: session, bedtime: bedtime)
        }
        let existingSessions = (try? ctx.fetch(FetchDescriptor<SleepSession>())) ?? []
        let existingFactors = (try? ctx.fetch(FetchDescriptor<SleepFactor>())) ?? []
        SleepFactorAttribution.attachOrphans(
            to: session,
            allSessions: existingSessions,
            allFactors: existingFactors,
            in: ctx
        )

        if kind == .night, let profile = userProfile, profile.tracksMenstrualCycle {
            let logged = CyclePeriodEngine.loggedDaySet(in: ctx)
            let healthStart = await MenstrualCycleService().latestPeriodStartFromHealthKit()
            if let insight = CyclePeriodEngine.buildInsight(
                profile: profile,
                loggedDays: logged,
                healthPeriodStart: healthStart
            ) {
                CyclePeriodEngine.syncProfile(profile, insight: insight, loggedDays: logged)
                session.cycleDay = insight.cycleDay
            } else {
                session.cycleDay = profile.currentCycleDay()
            }
        }

        if kind == .night, let alarm, alarm.isEnabled {
            let resolvedWake = wakeTime ?? alarm.nextWakeTime(relativeTo: session.startTime)
            session.alarmTime = resolvedWake
            smartAlarm = SmartAlarm(
                config: alarm,
                sessionStart: session.startTime,
                wakeTime: resolvedWake
            )
            smartAlarm?.startMonitoring()
        } else {
            smartAlarm = nil
        }

        ctx.insert(session)
        currentSession = session
        lastPhaseRecord = Date()

        motionAnalyzer.beginSession(at: session.startTime)
        motionAnalyzer.startTracking()

        soundMonitor.onSoundEvent = { [weak self] type, db, clip, clipDuration, detectedAt in
            Task { @MainActor in
                self?.recordSound(
                    type: type,
                    decibels: db,
                    clipName: clip,
                    clipDuration: clipDuration,
                    detectedAt: detectedAt
                )
            }
        }
        snoreDetection.onSnoreDetected = { [weak self] at, duration, confidence in
            Task { @MainActor in
                self?.recordSnoreEvent(detectedAt: at, duration: duration, confidence: confidence)
            }
        }
        snoreDetection.start()
        soundMonitor.onPCMSamples = { samples, sampleRate in
            SnoreIngestRouter.ingest(samples: samples, sourceSampleRate: sampleRate)
        }

        let recordClips = userProfile?.storeNightAudioClips ?? false
        audioMonitoringEnabled = await soundMonitor.startMonitoring(recordClips: recordClips)
        if !audioMonitoringEnabled, let audioError = soundMonitor.lastStartError {
            lastStartError = audioError
        }

        await healthKit.requestAuthorization()

        Task {
            await self.fetchWeatherIfPossible(for: session)
        }

        isTracking = true
        isPaused = false
        totalPausedDuration = 0
        pauseStartedAt = nil
        resetLiveActivityThrottle()
        SleepBackgroundTask.schedule()
        startTimers()
        _ = SleepLiveActivityManager.start(sessionKind: kind)
        refreshLiveActivity()
        persistNow()
        return true
    }

    /// Reprend une nuit finalisée (ex. app tuée le matin) au lieu d’en créer une deuxième.
    private func continueExistingNight(
        session: SleepSession,
        factors: [SleepFactor],
        alarm: AlarmConfig?,
        wakeTime: Date?
    ) async -> Bool {
        guard let ctx = modelContext else { return false }

        lastStartError = nil
        audioMonitoringEnabled = false
        session.reopenForContinuation(now: Date())

        let bedtime = session.startTime
        for f in factors {
            ctx.insert(f)
            linkFactor(f, to: session, bedtime: bedtime)
        }
        let existingSessions = (try? ctx.fetch(FetchDescriptor<SleepSession>())) ?? []
        let existingFactors = (try? ctx.fetch(FetchDescriptor<SleepFactor>())) ?? []
        SleepFactorAttribution.attachOrphans(
            to: session,
            allSessions: existingSessions,
            allFactors: existingFactors,
            in: ctx
        )

        if let alarm, alarm.isEnabled {
            let resolvedWake = wakeTime ?? alarm.nextWakeTime(relativeTo: Date())
            session.alarmTime = resolvedWake
            smartAlarm = SmartAlarm(
                config: alarm,
                sessionStart: session.startTime,
                wakeTime: resolvedWake
            )
            smartAlarm?.startMonitoring()
        } else {
            smartAlarm = nil
        }

        currentSession = session
        lastPhaseRecord = Date()
        totalPausedDuration = 0
        pauseStartedAt = nil

        motionAnalyzer.beginSession(at: session.startTime)
        motionAnalyzer.startTracking()

        soundMonitor.onSoundEvent = { [weak self] type, db, clip, clipDuration, detectedAt in
            Task { @MainActor in
                self?.recordSound(
                    type: type,
                    decibels: db,
                    clipName: clip,
                    clipDuration: clipDuration,
                    detectedAt: detectedAt
                )
            }
        }
        snoreDetection.onSnoreDetected = { [weak self] at, duration, confidence in
            Task { @MainActor in
                self?.recordSnoreEvent(detectedAt: at, duration: duration, confidence: confidence)
            }
        }
        snoreDetection.start()
        soundMonitor.onPCMSamples = { samples, sampleRate in
            SnoreIngestRouter.ingest(samples: samples, sourceSampleRate: sampleRate)
        }

        let recordClips = userProfile?.storeNightAudioClips ?? false
        audioMonitoringEnabled = await soundMonitor.startMonitoring(recordClips: recordClips)
        if !audioMonitoringEnabled, let audioError = soundMonitor.lastStartError {
            lastStartError = audioError
        }

        isTracking = true
        isPaused = false
        resetLiveActivityThrottle()
        SleepBackgroundTask.schedule()
        startTimers()
        _ = SleepLiveActivityManager.start(sessionKind: session.kind)
        refreshLiveActivity()
        persistNow()
        return true
    }

    /// Pause pour réveil nocturne — même nuit, pas de finalisation.
    func pauseTracking() {
        guard isTracking, !isPaused, currentSession != nil else { return }
        recordCurrentPhase()
        phaseTimer?.invalidate()
        phaseTimer = nil
        motionAnalyzer.stopTracking()
        soundMonitor.stopMonitoring()
        snoreDetection.stop()
        isPaused = true
        pauseStartedAt = Date()
        currentSession?.pauseCount += 1
        refreshLiveActivity()
        persistNow()
    }

    /// Reprend le tracking sur la session en cours (nuit fractionnée).
    func resumeTracking() async {
        guard isTracking, isPaused, let session = currentSession else { return }
        if let pauseStart = pauseStartedAt {
            totalPausedDuration += Date().timeIntervalSince(pauseStart)
            pauseStartedAt = nil
        }
        lastPhaseRecord = Date()
        motionAnalyzer.beginSession(at: session.startTime)
        motionAnalyzer.startTracking()
        snoreDetection.start()
        let recordClips = userProfile?.storeNightAudioClips ?? false
        audioMonitoringEnabled = await soundMonitor.startMonitoring(recordClips: recordClips)
        isPaused = false
        startTimers()
        refreshLiveActivity()
        persistNow()
    }

    func requestWakeFromLiveActivity() async {
        guard isTracking else { return }
        await stopNight()
    }

    private func fetchWeatherIfPossible(for session: SleepSession) async {
        // Localisation déjà expliquée à l’onboarding — pas de nouvelle demande surprise ici.
        guard AppPermissions.locationStatus() == .authorizedWhenInUse
            || AppPermissions.locationStatus() == .authorizedAlways else { return }
        locationHelper.requestLocation()
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard let lat = locationHelper.latitude, let lon = locationHelper.longitude else { return }
        if let weather = await weatherService.fetchNightWeather(for: Date(), latitude: lat, longitude: lon) {
            session.nightTemperature = weather.temperature
            session.humidity = weather.humidity
            session.pressure = weather.pressure
            schedulePersist()
        }
    }

    func stopNight() async {
        if isPaused {
            if let pauseStart = pauseStartedAt {
                totalPausedDuration += Date().timeIntervalSince(pauseStart)
                pauseStartedAt = nil
            }
            isPaused = false
        }
        phaseTimer?.invalidate()
        elapsedTimer?.invalidate()
        motionAnalyzer.stopTracking()
        soundMonitor.stopMonitoring()
        snoreDetection.stop()
        smartAlarm?.stopMonitoring()

        guard let session = currentSession else {
            isTracking = false
            return
        }

        recordCurrentPhase()
        session.excludedPauseDuration += totalPausedDuration
        session.finalize(at: Date())
        SleepPhaseRebalancer.rebalance(session: session)
        SleepPhaseBackfill.backfillIfNeeded(session: session, modelContext: modelContext)
        session.recalculatePhaseMinutes()
        session.recalculateSnoreMinutes()
        session.actualWakeTime = Date()
        session.wakePhase = motionAnalyzer.currentPhase

        await healthKit.enrichSession(session)
        SleepScoreCalculator.apply(to: session, profile: userProfile)

        if session.kind == .night {
            let movementSamples = session.phases.map(\.movementScore).filter { $0 > 0 }
            SleepCalibrationManager.shared.updateBaselineFromNight(movementSamples)
        }

        await healthKit.exportSessionToHealth(session)

        persistNow()
        let latestDream = fetchLatestDream(for: session)
        WidgetBridge.syncSession(session, latestDream: latestDream)
        lastCompletedSession = session
        isTracking = false
        isPaused = false
        totalPausedDuration = 0
        currentSession = nil
        smartAlarm = nil
        resetLiveActivityThrottle()
        SleepLiveActivityManager.end()
    }

    private func startTimers() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: phaseRecordInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.recordCurrentPhase()
            }
        }
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let start = self.currentSession?.startTime else { return }
                var total = Date().timeIntervalSince(start)
                if self.isPaused, let pauseStart = self.pauseStartedAt {
                    total -= Date().timeIntervalSince(pauseStart)
                }
                self.elapsed = max(0, total - self.totalPausedDuration)
                self.refreshLiveActivity()
                if let alarm = self.smartAlarm, !self.isPaused {
                    _ = alarm.checkAndTriggerIfNeeded(currentPhase: self.motionAnalyzer.currentPhase)
                }
            }
        }
    }

    private func recordCurrentPhase() {
        guard let session = currentSession else { return }
        let now = Date()
        let start = lastPhaseRecord ?? session.startTime
        let phaseType = motionAnalyzer.enrichedPhase(
            motionPhase: motionAnalyzer.currentPhase,
            heartRate: session.avgHeartRate,
            hrv: session.avgHRV
        )

        if phaseType == .awake {
            let duration = now.timeIntervalSince(start)
            if duration > 300 { session.awakenings += 1 }
        }

        let phase = SleepPhase(
            startTime: start,
            endTime: now,
            phaseType: phaseType,
            movementScore: motionAnalyzer.lastMovementScore
        )
        phase.session = session
        session.phases.append(phase)
        lastPhaseRecord = now
        session.recalculatePhaseMinutes()
        refreshLiveActivity()
        persistNow()
    }

    private func resetLiveActivityThrottle() {
        lastLiveActivityPhase = nil
        lastLiveActivityPaused = nil
        lastLiveActivityElapsedMinute = -1
    }

    /// Live Activity : pas plus d’une mise à jour / minute sauf changement de phase ou pause.
    private func refreshLiveActivity() {
        guard let session = currentSession, isTracking else { return }
        let phase = isPaused ? SleepPhaseType.awake : motionAnalyzer.currentPhase
        let paused = isPaused
        let elapsedMinute = Int(elapsed) / 60
        if lastLiveActivityPhase == phase,
           lastLiveActivityPaused == paused,
           lastLiveActivityElapsedMinute == elapsedMinute {
            return
        }
        lastLiveActivityPhase = phase
        lastLiveActivityPaused = paused
        lastLiveActivityElapsedMinute = elapsedMinute
        SleepLiveActivityManager.update(
            phase: phase,
            elapsed: elapsed,
            isPaused: paused,
            kind: session.kind
        )
    }

    /// Sauvegarde différée — regroupe les événements audio / ronflement.
    private func schedulePersist(debounceSeconds: TimeInterval = persistDebounceSeconds) {
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(debounceSeconds))
            guard !Task.isCancelled else { return }
            try? modelContext?.save()
        }
    }

    private func persistNow() {
        persistTask?.cancel()
        persistTask = nil
        try? modelContext?.save()
    }

    /// Appelé quand l’app passe en arrière-plan pendant une nuit — limite la perte si iOS tue le processus.
    func persistBeforeBackgroundIfTracking() {
        guard isTracking, !isPaused else { return }
        recordCurrentPhase()
        persistNow()
    }

    private func recordSound(
        type: SoundType,
        decibels: Double,
        clipName: String?,
        clipDuration: TimeInterval,
        detectedAt: Date
    ) {
        guard let session = currentSession else { return }
        let event = SoundEvent(
            timestamp: detectedAt,
            soundType: type,
            decibelLevel: decibels,
            duration: max(clipDuration, 1),
            clipFileName: clipName
        )
        event.session = session
        session.soundEvents.append(event)
        if decibels > (session.loudestEvent ?? 0) { session.loudestEvent = decibels }
        schedulePersist()
    }

    private func recordSnoreEvent(detectedAt: Date, duration: TimeInterval, confidence: Double) {
        guard let session = currentSession else { return }
        if let last = session.snoreEvents.last,
           detectedAt.timeIntervalSince(last.timestamp) < Self.snoreMergeGapSeconds {
            let span = min(
                detectedAt.timeIntervalSince(last.timestamp) + duration,
                Self.maxSnoreEventDuration
            )
            last.duration = min(Self.maxSnoreEventDuration, max(last.duration, span))
            last.confidence = max(last.confidence, confidence)
        } else {
            let event = SnoreEvent(
                timestamp: detectedAt,
                duration: duration,
                confidence: confidence
            )
            event.session = session
            session.snoreEvents.append(event)
        }
        session.recalculateSnoreMinutes()
        schedulePersist()
    }

    private func projectedBedtime(for session: SleepSession) -> Date {
        session.startTime
    }

    private func linkFactor(_ factor: SleepFactor, to session: SleepSession, bedtime: Date) {
        SleepFactorAttribution.link(factor, to: session, bedtime: bedtime)
    }

    private func fetchLatestDream(for session: SleepSession) -> DreamEntry? {
        guard let ctx = modelContext else { return nil }
        let descriptor = FetchDescriptor<DreamEntry>(
            sortBy: [SortDescriptor(\DreamEntry.dreamDate, order: .reverse)]
        )
        guard let dreams = try? ctx.fetch(descriptor) else { return nil }
        return dreams.first { dream in
            dream.session?.id == session.id
                || abs(dream.dreamDate.timeIntervalSince(session.endTime ?? session.startTime)) < 18 * 3600
        }
    }
}

import SwiftData
