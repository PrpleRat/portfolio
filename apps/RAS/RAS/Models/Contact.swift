import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String
    var relationship: String
    var isEmergencyService: Bool
    var priority: Int

    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    var formattedPhone: String {
        let digits = phoneNumber.filter(\.isNumber)
        if digits.hasPrefix("0"), digits.count == 10 {
            return "+33" + String(digits.dropFirst())
        }
        return phoneNumber
    }

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        phoneNumber: String = "",
        email: String = "",
        relationship: String = "Famille",
        isEmergencyService: Bool = false,
        priority: Int = 1
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.relationship = relationship
        self.isEmergencyService = isEmergencyService
        self.priority = priority
    }

    static var emergency112: Contact {
        Contact(
            firstName: "Urgences",
            lastName: "112",
            phoneNumber: "112",
            relationship: "Secours",
            isEmergencyService: true,
            priority: 99
        )
    }
}
