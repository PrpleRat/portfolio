import Foundation
import SwiftData

@Model
final class AlertConfig {

    var id: UUID
    var name: String
    var intervalMinutes: Int
    var checkInMethod: String
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var contacts: [Contact]
    var actions: [String]
    var customAlertMessage: String
    var presetId: String?

    init(
        name: String,
        intervalMinutes: Int,
        checkInMethod: CheckInMethod,
        isDefault: Bool = false,
        contacts: [Contact] = [],
        actions: [String] = [AlertAction.iMessage.rawValue, AlertAction.sms.rawValue],
        customAlertMessage: String = "",
        presetId: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.intervalMinutes = intervalMinutes
        self.checkInMethod = checkInMethod.rawValue
        self.isDefault = isDefault
        self.createdAt = Date()
        self.contacts = contacts
        self.actions = actions
        self.customAlertMessage = customAlertMessage
        self.presetId = presetId
    }

    var checkInMethodEnum: CheckInMethod {
        CheckInMethod(rawValue: checkInMethod) ?? .biometric
    }

    var alertActions: [AlertAction] {
        actions.compactMap { AlertAction(rawValue: $0) }
    }
}
