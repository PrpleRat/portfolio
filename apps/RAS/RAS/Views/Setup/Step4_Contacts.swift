import SwiftUI

struct Step4_Contacts: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        List {
            Section {
                Button("Ajouter manuellement") {
                    vm.contacts.append(Contact(priority: vm.contacts.count + 1))
                }
                Button("Ajouter les urgences 112") {
                    if !vm.contacts.contains(where: \.isEmergencyService) {
                        vm.contacts.append(Contact.emergency112)
                    }
                }
            }

            Section("Contacts d'urgence") {
                ForEach(vm.contacts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Prénom", text: $vm.contacts[index].firstName)
                        TextField("Nom", text: $vm.contacts[index].lastName)
                        TextField("Téléphone", text: $vm.contacts[index].phoneNumber)
                            .keyboardType(.phonePad)
                        TextField("Email (optionnel)", text: $vm.contacts[index].email)
                            .keyboardType(.emailAddress)
                    }
                }
                .onDelete { offsets in
                    vm.contacts.remove(atOffsets: offsets)
                }
            }
        }
    }
}
