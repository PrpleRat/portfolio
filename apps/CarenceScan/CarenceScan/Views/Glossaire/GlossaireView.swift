import SwiftUI

struct GlossaireView: View {
    @State private var recherche = ""

    private var filtrees: [GlossaireEntry] {
        let q = recherche.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return GlossaireData.entries }
        return GlossaireData.entries.filter {
            $0.terme.lowercased().contains(q) || $0.definition.lowercased().contains(q)
        }
    }

    var body: some View {
        List(filtrees) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.terme)
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
                Text(entry.definition)
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Glossaire")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $recherche, prompt: "Rechercher un terme")
    }
}

struct GlossaireLink: View {
    let termeId: String
    @State private var showGlossaire = false

    private var entry: GlossaireEntry? {
        GlossaireData.entry(id: termeId)
    }

    var body: some View {
        if let entry {
            Button {
                showGlossaire = true
            } label: {
                HStack(spacing: 4) {
                    Text(entry.terme)
                        .font(.caption.weight(.semibold))
                        .underline()
                    Image(systemName: "info.circle")
                        .font(.caption2)
                }
                .foregroundStyle(CarenceColors.primary)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showGlossaire) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(entry.terme)
                                .font(.title2.bold())
                            Text(entry.definition)
                                .font(.body)
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                        .padding(24)
                    }
                    .background(CarenceColors.background.ignoresSafeArea())
                    .navigationTitle("Glossaire")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fermer") { showGlossaire = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .accessibilityLabel("Définition de \(entry.terme)")
        }
    }
}
