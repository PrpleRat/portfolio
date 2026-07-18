import Foundation
import SwiftData

struct CheckInRecord: Codable, Hashable {
    let date: Date
    let method: String
    let latitude: Double?
    let longitude: Double?
    let responseTimeSeconds: Int
}

@Model
final class SafeSession {

    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date?
    var intervalMinutes: Int
    var checkInMethod: String
    var isActive: Bool
    var checkIns: [CheckInRecord]
    var wasAlertTriggered: Bool
    var alertTriggeredAt: Date?
    var startLatitude: Double?
    var startLongitude: Double?
    var alertConfigId: UUID?

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var totalCheckIns: Int { checkIns.count }

    var nextDeadline: Date? {
        guard isActive else { return nil }
        if let lastCheckIn = checkIns.sorted(by: { $0.date < $1.date }).last {
            return lastCheckIn.date.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }
        return startTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
    }

    init(
        id: UUID = UUID(),
        name: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        intervalMinutes: Int,
        checkInMethod: String,
        isActive: Bool = true,
        checkIns: [CheckInRecord] = [],
        wasAlertTriggered: Bool = false,
        alertTriggeredAt: Date? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        alertConfigId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.intervalMinutes = intervalMinutes
        self.checkInMethod = checkInMethod
        self.isActive = isActive
        self.checkIns = checkIns
        self.wasAlertTriggered = wasAlertTriggered
        self.alertTriggeredAt = alertTriggeredAt
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.alertConfigId = alertConfigId
    }
}
