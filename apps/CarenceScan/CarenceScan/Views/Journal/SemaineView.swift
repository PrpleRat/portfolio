import SwiftUI

struct SemaineView: View {
    @EnvironmentObject private var journal: JournalEngine

    let aliments: [AlimentTrackable]
    let carencesUtilisateur: [String]

    @State private var jourSelectionne: JourAnalyse?

    private var jours: [JourAnalyse] {
        journal.analyserSemaine(aliments: aliments, carencesUtilisateur: carencesUtilisateur)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("7 derniers jours")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                HStack(spacing: 8) {
                    ForEach(jours) { jour in
                        jourBubble(jour)
                    }
                }

                if let jour = jourSelectionne ?? jours.last {
                    detailJour(jour)
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Vue semaine")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            jourSelectionne = jours.last
        }
    }

    private func jourBubble(_ jour: JourAnalyse) -> some View {
        let color = scoreColor(jour.scoreJournee)
        let isSelected = jourSelectionne?.date == jour.date

        return Button {
            jourSelectionne = jour
        } label: {
            VStack(spacing: 6) {
                Text(jour.date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                Text("\(jour.scoreJournee)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? CarenceColors.textPrimary : .clear, lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func detailJour(_ jour: JourAnalyse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(jour.date, format: .dateTime.day().month().year())
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            Text("Score : \(jour.scoreJournee)% — \(jour.carencesCouvertes.count)/\(carencesUtilisateur.count) carences couvertes")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)

            if jour.alimentsConsommes.isEmpty {
                Text("Aucun aliment coché ce jour-là.")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
            } else {
                ForEach(jour.alimentsConsommes.sorted(), id: \.self) { alimentId in
                    if let aliment = aliments.first(where: { $0.id == alimentId }) {
                        HStack {
                            Text(aliment.emoji)
                            Text(aliment.nom)
                                .font(.subheadline)
                                .foregroundStyle(CarenceColors.textPrimary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CarenceColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scoreColor(_ score: Int) -> Color {
        if score > 70 { return CarenceColors.primary }
        if score >= 40 { return .orange }
        return CarenceColors.alert
    }
}
