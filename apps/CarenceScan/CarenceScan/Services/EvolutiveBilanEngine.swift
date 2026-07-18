import Foundation

struct EvolutiveBilanResult {
    let baseline: SavedResultsPayload
    let selectionsEffectives: [SymptomeSelection]
    let scoresEvolutifs: [ScoreResult]
    let symptomesResolus: [String]
    let symptomesAjoutes: [String]
    let dateCalcul: Date
    let joursSuivi: Int
    let estPret: Bool

    var deltaCarences: [(carenceId: String, baselineNiveau: ProbabilityLevel?, evolueNiveau: ProbabilityLevel?)] {
        let baseMap = Dictionary(uniqueKeysWithValues: baseline.scores.map { ($0.carenceId, $0.niveau) })
        let evoMap = Dictionary(uniqueKeysWithValues: scoresEvolutifs.map { ($0.carenceId, $0.niveau) })
        let ids = Set(baseMap.keys).union(evoMap.keys)
        return ids.compactMap { id in
            let b = baseMap[id]
            let e = evoMap[id]
            guard b != e else { return nil }
            return (id, b, e)
        }.sorted { ($0.evolueNiveau?.sortOrder ?? 0) > ($1.evolueNiveau?.sortOrder ?? 0) }
    }
}

@MainActor
enum EvolutiveBilanEngine {

    /// Fusionne le bilan de référence (questionnaire) avec les fréquences du journal quotidien.
    static func calculer(
        baseline: SavedResultsPayload,
        trackedIds: [String],
        addedIds: [String],
        trackingStartDate: Date?
    ) -> EvolutiveBilanResult {
        var byId: [String: SymptomeSelection] = [:]
        var resolus: [String] = []

        // 1. Bilan de référence — toujours la base
        for sel in baseline.symptomeSelections {
            byId[sel.symptomeId] = sel
        }

        // 2. Symptômes ajoutés pendant le suivi
        for id in addedIds where !byId.keys.contains(id) {
            byId[id] = SymptomeSelection(symptomeId: id, frequence: .frequent)
        }

        // 3. Mise à jour des fréquences via journal (sans effacer la référence)
        for id in trackedIds {
            var sel = byId[id] ?? SymptomeSelection(symptomeId: id)
            if let journal = SymptomFrequencyEngine.frequence(symptomeId: id) {
                if journal == .jamais {
                    resolus.append(id)
                    byId.removeValue(forKey: id)
                } else if let freq = journal.scoringFrequence {
                    sel.frequence = freq
                    byId[id] = sel
                }
            }
        }

        let selections = Array(byId.values)
        let contextes = CarenceDatabase.shared.contextesMedicaux.filter {
            baseline.contextesSelectionnes.contains($0.id)
        }

        let scores = ScoringEngine.calculerScores(
            selections: selections,
            medicamentsSelectionnes: Set(baseline.medicamentsSelectionnes),
            profil: baseline.profil,
            contextesActifs: contextes
        )

        let jours = joursDepuis(trackingStartDate)
        let entriesCount = SymptomJournalStorage.loadEntries().count
        let estPret = jours >= SymptomFrequencyEngine.minDaysForEstimate
            || entriesCount >= SymptomFrequencyEngine.minDaysForEstimate

        return EvolutiveBilanResult(
            baseline: baseline,
            selectionsEffectives: selections,
            scoresEvolutifs: scores,
            symptomesResolus: resolus,
            symptomesAjoutes: addedIds.filter { !baseline.symptomeSelections.map(\.symptomeId).contains($0) },
            dateCalcul: Date(),
            joursSuivi: jours,
            estPret: estPret
        )
    }

    static func calculerDepuisStockage(tracker: SymptomTrackerViewModel) -> EvolutiveBilanResult? {
        guard let baseline = ResultsStorage.load() else { return nil }
        return calculer(
            baseline: baseline,
            trackedIds: tracker.trackedSymptomeIds,
            addedIds: tracker.settings.addedSymptomeIds,
            trackingStartDate: tracker.settings.trackingStartDate
        )
    }

    private static func joursDepuis(_ date: Date?) -> Int {
        guard let date else { return 0 }
        let start = Calendar.current.startOfDay(for: date)
        let today = Calendar.current.startOfDay(for: Date())
        return max(0, Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0)
    }
}
