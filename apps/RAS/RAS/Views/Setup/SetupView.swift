import SwiftData
import SwiftUI

struct SetupView: View {

    var onComplete: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SetupViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(value: Double(vm.step), total: 6)
                    .padding(.horizontal)

                Group {
                    switch vm.step {
                    case 1: Step1_NamePreset(vm: vm)
                    case 2: Step2_Duration(vm: vm)
                    case 3: Step3_CheckInMethod(vm: vm)
                    case 4: Step4_Contacts(vm: vm)
                    case 5: Step5_Actions(vm: vm)
                    case 6: Step6_Review(vm: vm)
                    default: EmptyView()
                    }
                }
                .frame(maxHeight: .infinity)

                navigationButtons
            }
            .navigationTitle("Nouvelle session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private var navigationButtons: some View {
        HStack {
            if vm.step > 1 {
                Button("Retour") { vm.step -= 1 }
            }
            Spacer()
            if vm.step < 6 {
                Button("Suivant") { vm.step += 1 }
                    .disabled(!canProceed)
            } else {
                Button("Démarrer maintenant") {
                    Task { await startSession() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canProceedStep4)
            }
        }
        .padding()
    }

    private var canProceed: Bool {
        switch vm.step {
        case 1: return vm.canProceedStep1
        case 4: return vm.canProceedStep4
        default: return true
        }
    }

    private func startSession() async {
        await vm.configureSecrets()
        let config = vm.buildConfig()
        modelContext.insert(config)
        for contact in vm.contacts {
            modelContext.insert(contact)
        }
        do {
            _ = try await SessionManager.shared.startSession(config, context: modelContext)
            onComplete()
            dismiss()
        } catch {
            // Session start failed silently in UI — user can retry
        }
    }
}
