import Foundation

struct GlossaireEntry: Identifiable, Hashable {
    let id: String
    let terme: String
    let definition: String
}

enum GlossaireData {
    static let entries: [GlossaireEntry] = [
        GlossaireEntry(id: "ferritine", terme: "Ferritine", definition: "Protéine qui stocke le fer. Un taux bas (< 30 µg/L) confirme une carence en fer, même si l'hémoglobine est normale."),
        GlossaireEntry(id: "nfs", terme: "NFS", definition: "Numération formule sanguine — analyse qui mesure globules rouges, hémoglobine et signes d'anémie."),
        GlossaireEntry(id: "b12", terme: "Vitamine B12", definition: "Vitamine essentielle pour les nerfs et l'énergie. Carence fréquente chez les personnes âgées et les régimes végétaliens."),
        GlossaireEntry(id: "methylcobalamine", terme: "Méthylcobalamine", definition: "Forme active de la B12, mieux utilisée par l'organisme que la cyanocobalamine classique."),
        GlossaireEntry(id: "vitamine_d", terme: "Vitamine D (25-OH)", definition: "Hormone fabriquée sous l'action du soleil. Un bilan sanguin (25-OH vitamine D) guide la supplémentation."),
        GlossaireEntry(id: "omega3", terme: "Oméga-3 (EPA/DHA)", definition: "Acides gras anti-inflammatoires présents dans les poissons gras. Le DHA est important pour le cerveau."),
        GlossaireEntry(id: "magnesium", terme: "Magnésium", definition: "Minéral clé pour le sommeil, les muscles et le stress. Le bisglycinate est une forme bien tolérée."),
        GlossaireEntry(id: "folates", terme: "Acide folique (B9)", definition: "Vitamine essentielle pour la division cellulaire. Critique en début de grossesse."),
        GlossaireEntry(id: "tsh", terme: "TSH", definition: "Hormone qui régule la thyroïde. Un taux élevé peut indiquer une hypothyroïdie."),
        GlossaireEntry(id: "probable", terme: "Probable", definition: "Plusieurs de vos symptômes correspondent à cette carence, mais ce n'est pas un diagnostic — un bilan confirme."),
        GlossaireEntry(id: "tres_probable", terme: "Très probable", definition: "Forte cohérence entre vos symptômes et cette carence. Consultation et bilan sanguin recommandés."),
        GlossaireEntry(id: "quasi_certaine", terme: "Quasi certaine", definition: "Tableau symptomatique très évocateur. Priorité à un bilan médical avant toute supplémentation.")
    ]

    static func entry(for terme: String) -> GlossaireEntry? {
        let lower = terme.lowercased()
        return entries.first {
            lower.contains($0.terme.lowercased()) || $0.terme.lowercased().contains(lower)
        }
    }

    static func entry(id: String) -> GlossaireEntry? {
        entries.first { $0.id == id }
    }
}
