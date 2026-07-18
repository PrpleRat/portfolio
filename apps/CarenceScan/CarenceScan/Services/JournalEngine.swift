import Foundation

@MainActor
final class JournalEngine: ObservableObject {

    @Published private(set) var entrees: [EntreeJournal] = []

    private let storageKey = AppConstants.journalAlimentaireKey
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static let shared = JournalEngine()

    init() { charger() }

    func toggleAliment(_ alimentId: String, date: Date = Date()) {
        let dateNorm = normaliserDate(date)
        if let idx = entrees.firstIndex(where: {
            $0.alimentId == alimentId && normaliserDate($0.date) == dateNorm
        }) {
            entrees.remove(at: idx)
        } else {
            entrees.append(EntreeJournal(
                id: UUID(),
                date: dateNorm,
                alimentId: alimentId,
                portions: 1.0
            ))
        }
        sauvegarder()
    }

    func estConsomme(_ alimentId: String, date: Date = Date()) -> Bool {
        let dateNorm = normaliserDate(date)
        return entrees.contains {
            $0.alimentId == alimentId && normaliserDate($0.date) == dateNorm
        }
    }

    func calculerCarencesCouvertes(
        date: Date,
        aliments: [AlimentTrackable],
        carencesUtilisateur: [String]
    ) -> JourAnalyse {
        let dateNorm = normaliserDate(date)
        let entreesJour = entrees.filter { normaliserDate($0.date) == dateNorm }
        let alimentsConsom = Set(entreesJour.map(\.alimentId))

        var carencesCouvertes = Set<String>()
        for aliment in aliments where alimentsConsom.contains(aliment.id) {
            for carenceId in aliment.carencesCouvertes where carencesUtilisateur.contains(carenceId) {
                carencesCouvertes.insert(carenceId)
            }
        }

        let carencesNonCouvertes = Set(carencesUtilisateur).subtracting(carencesCouvertes)
        let score = carencesUtilisateur.isEmpty ? 0 :
            Int((Double(carencesCouvertes.count) / Double(carencesUtilisateur.count)) * 100)

        let suggestion = suggererAliment(
            carencesManquantes: carencesNonCouvertes,
            aliments: aliments,
            dejaMange: alimentsConsom
        )

        return JourAnalyse(
            date: dateNorm,
            alimentsConsommes: Array(alimentsConsom),
            carencesCouvertes: carencesCouvertes,
            carencesNonCouvertes: carencesNonCouvertes,
            scoreJournee: score,
            suggestionDuJour: suggestion
        )
    }

    func analyserSemaine(
        aliments: [AlimentTrackable],
        carencesUtilisateur: [String]
    ) -> [JourAnalyse] {
        let today = Date()
        return (0..<7).reversed().map { decalage in
            let date = Calendar.current.date(byAdding: .day, value: -decalage, to: today)!
            return calculerCarencesCouvertes(
                date: date,
                aliments: aliments,
                carencesUtilisateur: carencesUtilisateur
            )
        }
    }

    private func suggererAliment(
        carencesManquantes: Set<String>,
        aliments: [AlimentTrackable],
        dejaMange: Set<String>
    ) -> AlimentTrackable? {
        aliments
            .filter { !dejaMange.contains($0.id) }
            .map { aliment -> (AlimentTrackable, Int) in
                let couverture = aliment.carencesCouvertes.filter { carencesManquantes.contains($0) }.count
                return (aliment, couverture)
            }
            .filter { $0.1 > 0 }
            .max(by: { $0.1 < $1.1 })?
            .0
    }

    private func normaliserDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func sauvegarder() {
        guard let data = try? encoder.encode(entrees) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func charger() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? decoder.decode([EntreeJournal].self, from: data)
        else { return }
        entrees = saved
    }
}
