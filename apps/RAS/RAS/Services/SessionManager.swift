import Foundation
import SwiftData

actor SessionManager {

    static let shared = SessionManager()

    private let notifScheduler = NotificationScheduler.shared
    private let location = LocationService.shared

    func startSession(_ config: AlertConfig, context: ModelContext) async throws -> SafeSession {
        let session = SafeSession(
            name: config.name,
            intervalMinutes: config.intervalMinutes,
            checkInMethod: config.checkInMethod,
            isActive: true,
            alertConfigId: config.id
        )

        if let loc = await location.currentLocation() {
            session.startLatitude = loc.coordinate.latitude
            session.startLongitude = loc.coordinate.longitude
        }

        context.insert(session)
        try context.save()
        await notifScheduler.scheduleSession(session)
        return session
    }

    func recordCheckIn(
        session: SafeSession,
        method: CheckInMethod,
        cycle: Int,
        context: ModelContext
    ) async throws {
        let loc = await location.currentLocation()

        let record = CheckInRecord(
            date: Date(),
            method: method.rawValue,
            latitude: loc?.coordinate.latitude,
            longitude: loc?.coordinate.longitude,
            responseTimeSeconds: 0
        )

        session.checkIns.append(record)
        try context.save()

        await notifScheduler.cancelAlerts(for: session, cycle: cycle)
        await notifScheduler.scheduleSession(session)
    }

    func endSession(_ session: SafeSession, context: ModelContext) async throws {
        session.isActive = false
        session.endTime = Date()
        try context.save()
        await notifScheduler.cancelSession(session)
    }
}
