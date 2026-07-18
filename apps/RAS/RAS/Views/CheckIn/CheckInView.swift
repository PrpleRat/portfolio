import SwiftData
import SwiftUI

struct CheckInView: View {

    let session: SafeSession
    let cycle: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CheckInViewModel()
    @Query private var configs: [AlertConfig]

    @State private var pin = ""
    @State private var password = ""
    @State private var answer = ""
    @State private var pinLocked = false
    @State private var lockoutRemaining: TimeInterval = 0

    private var method: CheckInMethod {
        CheckInMethod(rawValue: session.checkInMethod) ?? .biometric
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("⏰ Vérification requise")
                        .font(.title2.bold())
                    Text(session.name)
                        .foregroundStyle(.secondary)
                    Text("Prouve que tu vas bien pour poursuivre la session")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                Text("Délai de grâce : \(Int(vm.graceRemaining)) s")
                    .font(.caption)
                    .foregroundStyle(.safeRed)

                checkInContent

                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.safeRed)
                }

                if vm.didSucceed {
                    Label("Check-in enregistré", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.safeGreen)
                        .font(.headline)
                }

                Spacer()

                Link("Je ne vais pas bien → Appeler le 112", destination: URL(string: "tel://112")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onChange(of: vm.didSucceed) { _, ok in
                if ok {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var checkInContent: some View {
        switch method {
        case .faceID, .touchID, .biometric:
            BiometricCheckView {
                await performVerify()
            }
        case .pin:
            PINCheckView(
                pin: $pin,
                isLockedOut: pinLocked,
                lockoutRemaining: lockoutRemaining,
                onDigit: { digit in
                    guard pin.count < AppConstants.pinLength else { return }
                    pin += digit
                    HapticManager.light()
                    if pin.count == AppConstants.pinLength {
                        Task { await performVerify(pin: pin) }
                    }
                },
                onDelete: {
                    if !pin.isEmpty { pin.removeLast() }
                }
            )
        case .password:
            PasswordCheckView(password: $password) {
                Task { await performVerify(password: password) }
            }
        case .customQuestion:
            QuestionCheckView(
                question: UserDefaults.standard.string(forKey: AppConstants.questionKey) ?? "Question secrète",
                answer: $answer
            ) {
                Task { await performVerify(answer: answer) }
            }
        case .tapButton:
            Button("✅ RAS — Rien à signaler") {
                Task { await performVerify() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func performVerify(
        pin: String = "",
        password: String = "",
        answer: String = ""
    ) async {
        pinLocked = await PINService.shared.isLockedOut
        lockoutRemaining = await PINService.shared.lockoutTimeRemaining
        await vm.verify(
            method: method,
            session: session,
            cycle: cycle,
            context: modelContext,
            pin: pin,
            password: password,
            answer: answer
        )
    }
}
