import Foundation
import SwiftUI

@MainActor
final class SetupViewModel: ObservableObject {

    @Published var step: Int = 1
    @Published var sessionName: String = ""
    @Published var selectedPreset: SessionPreset = SessionPreset.all[0]
    @Published var intervalMinutes: Int = 60
    @Published var checkInMethod: CheckInMethod = .biometric
    @Published var contacts: [Contact] = []
    @Published var selectedActions: Set<AlertAction> = [.sms, .shareLocation]
    @Published var customMessage: String = ""
    @Published var pinEntry: String = ""
    @Published var pinConfirm: String = ""
    @Published var customQuestion: String = ""
    @Published var customAnswer: String = ""
    @Published var saveAsTemplate: Bool = false

    var canProceedStep1: Bool { !sessionName.trimmingCharacters(in: .whitespaces).isEmpty }
    var canProceedStep4: Bool { contacts.contains { !$0.phoneNumber.isEmpty } }

    func applyPreset(_ preset: SessionPreset) {
        selectedPreset = preset
        sessionName = preset.name
        intervalMinutes = preset.defaultIntervalMinutes
        checkInMethod = preset.recommendedMethod
        selectedActions = Set(preset.suggestedActions)
    }

    func buildConfig() -> AlertConfig {
        AlertConfig(
            name: sessionName,
            intervalMinutes: intervalMinutes,
            checkInMethod: checkInMethod,
            contacts: contacts,
            actions: selectedActions.map(\.rawValue),
            customAlertMessage: customMessage,
            presetId: selectedPreset.id
        )
    }

    func configureSecrets() async {
        if checkInMethod == .pin, pinEntry.count == AppConstants.pinLength {
            await PINService.shared.setPIN(pinEntry)
        }
        if checkInMethod == .customQuestion, !customQuestion.isEmpty, !customAnswer.isEmpty {
            await PINService.shared.setCustomQuestion(customQuestion, answer: customAnswer)
        }
    }

    func durationLabel(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        if minutes == 60 { return "1 h" }
        if minutes % 60 == 0 { return "\(minutes / 60) h" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}
