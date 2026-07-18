import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CheckInViewModel: ObservableObject {

    @Published var isVerifying = false
    @Published var didSucceed = false
    @Published var errorMessage: String?
    @Published var graceRemaining: TimeInterval = TimeInterval(AppConstants.gracePeriodMinutes * 60)

    func verify(
        method: CheckInMethod,
        session: SafeSession,
        cycle: Int,
        context: ModelContext,
        pin: String = "",
        password: String = "",
        answer: String = ""
    ) async {
        isVerifying = true
        errorMessage = nil
        defer { isVerifying = false }

        let ok: Bool
        switch method {
        case .faceID, .touchID, .biometric:
            ok = await BiometricService.shared.authenticateWithFallback()
        case .pin:
            if await PINService.shared.isLockedOut {
                errorMessage = "Trop de tentatives. Réessaie dans quelques secondes."
                ok = false
            } else if await PINService.shared.verifyPIN(pin) {
                await PINService.shared.resetAttempts()
                ok = true
            } else {
                await PINService.shared.recordFailedAttempt()
                HapticManager.error()
                errorMessage = "Code incorrect"
                ok = false
            }
        case .password:
            ok = await PINService.shared.verifyPIN(password)
            if !ok { errorMessage = "Mot de passe incorrect" }
        case .customQuestion:
            ok = await PINService.shared.verifyAnswer(answer)
            if !ok { errorMessage = "Réponse incorrecte" }
        case .tapButton:
            ok = true
        }

        guard ok else { return }

        HapticManager.success()
        didSucceed = true
        try? await SessionManager.shared.recordCheckIn(
            session: session,
            method: method,
            cycle: cycle,
            context: context
        )
    }

    func triggerAlert(session: SafeSession, config: AlertConfig) async {
        let location = await LocationService.shared.currentLocation()
        await AlertDispatcher.shared.dispatch(session: session, config: config, location: location)
    }
}
