import SwiftUI

struct Step3_CheckInMethod: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        List {
            Section {
                ForEach(CheckInMethod.allCases) { method in
                    Button {
                        vm.checkInMethod = method
                    } label: {
                        HStack {
                            Image(systemName: method.sfSymbol)
                                .foregroundStyle(Color(securityLevel: method.securityLevel))
                            VStack(alignment: .leading) {
                                Text(method.displayName)
                                Text(method.securityLevel.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vm.checkInMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.safeGreen)
                            }
                        }
                    }
                }
            } footer: {
                Text("Choisis une méthode utilisable même avec des gants si besoin.")
            }

            if vm.checkInMethod == .pin {
                Section("Créer un PIN à 6 chiffres") {
                    SecureField("PIN", text: $vm.pinEntry)
                        .keyboardType(.numberPad)
                    SecureField("Confirmer", text: $vm.pinConfirm)
                        .keyboardType(.numberPad)
                }
            }

            if vm.checkInMethod == .customQuestion {
                Section("Question secrète") {
                    TextField("Question", text: $vm.customQuestion)
                    SecureField("Réponse", text: $vm.customAnswer)
                }
            }
        }
    }
}
