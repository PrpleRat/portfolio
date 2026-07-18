import SwiftUI

struct SymptomeFicheView: View {
    let symptomeId: String

    private var fiche: SymptomeFicheDetail? {
        SymptomeFicheProvider.fiche(for: symptomeId)
    }

    var body: some View {
        Group {
            if let fiche {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(fiche.label)
                                .font(.title2.bold())
                                .foregroundStyle(CarenceColors.textPrimary)
                            Text(fiche.categorie)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CarenceColors.primary)
                        }

                        sectionBlock(title: "En bref", content: fiche.description)

                        sectionBlock(title: "Quand s'inquiéter ?", content: fiche.quandSinquieter, style: .warning)

                        if !fiche.carencesLiees.isEmpty {
                            Text("Carences associées")
                                .font(.headline)
                                .foregroundStyle(CarenceColors.textPrimary)

                            ForEach(fiche.carencesLiees) { link in
                                NavigationLink {
                                    CarenceDetailView(carenceId: link.carenceId)
                                } label: {
                                    HStack {
                                        Text("\(link.tier.emoji) \(link.carenceNom)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(CarenceColors.textPrimary)
                                        Spacer()
                                        Text(link.tier.label)
                                            .font(.caption2)
                                            .foregroundStyle(CarenceColors.textSecondary)
                                    }
                                    .padding(12)
                                    .background(CarenceColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        Text(AppConstants.disclaimerPrincipal)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView("Symptôme introuvable", systemImage: "questionmark.circle")
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Fiche symptôme")
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum BlockStyle { case normal, warning }

    private func sectionBlock(title: String, content: String, style: BlockStyle = .normal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            Text(content)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(style == .warning ? CarenceColors.warningBackground : CarenceColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct SymptomesEncyclopedieView: View {
    private let symptomes = CarenceDatabase.shared.symptomes

    var body: some View {
        List(symptomes) { symptome in
            NavigationLink {
                SymptomeFicheView(symptomeId: symptome.id)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symptome.label)
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textPrimary)
                    if let cat = SymptomCategory(rawValue: symptome.categorie) {
                        Text(cat.title)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Symptômes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
