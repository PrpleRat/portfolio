import SwiftUI

struct ProfilView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel

    @State private var sexe: SexeBiologique = .femme
    @State private var age: TrancheAge = .vingt6_35
    @State private var situation: SituationHormonale = .reglesRegulieres
    @State private var showQuestionnaire = false

    var body: some View {
        VStack(spacing: 0) {
            QuestionnaireProgressBar(currentStep: .profil)

            ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Votre profil")
                        .font(.title2.bold())
                    Text("Ces informations permettent d'ajuster les calculs à votre situation.")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)
                }

                sectionTitle("Sexe biologique")
                HStack(spacing: 12) {
                    ForEach(SexeBiologique.allCases, id: \.self) { option in
                        Button {
                            sexe = option
                            if option == .homme {
                                situation = .nonApplicable
                            } else if situation == .nonApplicable {
                                situation = .reglesRegulieres
                            }
                        } label: {
                            Text(option.label)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(sexe == option ? CarenceColors.primary.opacity(0.15) : CarenceColors.surface)
                                .foregroundStyle(sexe == option ? CarenceColors.primary : CarenceColors.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(sexe == option ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sexe biologique \(option.label)")
                        .accessibilityAddTraits(sexe == option ? .isSelected : [])
                    }
                }
                Text("Utilisé uniquement pour ajuster les besoins nutritionnels de référence.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)

                sectionTitle("Tranche d'âge")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TrancheAge.allCases) { tranche in
                            Button {
                                age = tranche
                            } label: {
                                Text(tranche.label)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(age == tranche ? CarenceColors.primary : CarenceColors.surface)
                                    .foregroundStyle(age == tranche ? .white : CarenceColors.textPrimary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Âge \(tranche.label)")
                        }
                    }
                }

                if sexe == .femme {
                    sectionTitle("Situation hormonale")
                    FlowLayout(spacing: 8) {
                        ForEach(SituationHormonale.optionsFemme) { option in
                            Button {
                                situation = option
                            } label: {
                                Text(option.label)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(situation == option ? CarenceColors.primary.opacity(0.15) : CarenceColors.surface)
                                    .foregroundStyle(situation == option ? CarenceColors.primary : CarenceColors.textPrimary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(situation == option ? CarenceColors.primary : CarenceColors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                vm.setProfil(ProfilUtilisateur(sexe: sexe, age: age, situationHormonale: situation))
                showQuestionnaire = true
            } label: {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CarenceColors.primary)
            .padding()
            .background(CarenceColors.surface)
            .accessibilityLabel("Continuer vers le questionnaire")
        }
        .navigationDestination(isPresented: $showQuestionnaire) {
            QuestionnaireView()
        }
        .onAppear {
            if let p = vm.profil {
                sexe = p.sexe
                age = p.age
                situation = p.situationHormonale
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(CarenceColors.textPrimary)
    }
}

#Preview {
    NavigationStack {
        ProfilView()
            .environmentObject(QuestionnaireViewModel())
    }
}
