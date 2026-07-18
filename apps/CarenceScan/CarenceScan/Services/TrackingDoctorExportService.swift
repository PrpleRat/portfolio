import UIKit

@MainActor
enum TrackingDoctorExportService {

    static func generatePDF(
        baseline: SavedResultsPayload,
        evolutif: EvolutiveBilanResult?,
        tracker: SymptomTrackerViewModel
    ) -> Data? {
        let html = buildHTML(baseline: baseline, evolutif: evolutif, tracker: tracker)
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: pageRect.insetBy(dx: 40, dy: 40)), forKey: "printableRect")
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    private static func buildHTML(
        baseline: SavedResultsPayload,
        evolutif: EvolutiveBilanResult?,
        tracker: SymptomTrackerViewModel
    ) -> String {
        let date = Date().formatted(date: .long, time: .omitted)
        let streak = StreakEngine.streakActuel(tracker: tracker)
        let profil = baseline.profil

        var grossesseHTML = ""
        if profil?.situationHormonale == .enceinte {
            grossesseHTML = """
            <div class="box alert">🤱 <strong>Patiente enceinte</strong> — supplémentation uniquement sur prescription. Priorité : B9, fer, iode, vitamine D.</div>
            """
        } else if profil?.situationHormonale == .allaitante {
            grossesseHTML = """
            <div class="box alert">🤱 <strong>Patiente allaitante</strong> — besoins accrus en iode, B12, vitamine D, oméga-3.</div>
            """
        }

        let journalRows = tracker.trackedSymptomeIds.map { id -> String in
            let label = CarenceDatabase.symptomeLabel(for: id)
            let entries = SymptomJournalStorage.entries(for: id, lastDays: 14)
            let present = entries.filter(\.present).count
            let freq = SymptomFrequencyEngine.frequence(symptomeId: id)
            let freqLabel = freq?.label ?? "Données insuffisantes"
            let baselineFreq = baseline.symptomeSelections.first(where: { $0.symptomeId == id })?.frequence.label ?? "—"
            return "<tr><td>\(escape(label))</td><td>\(baselineFreq)</td><td>\(present)/\(entries.count)</td><td>\(escape(freqLabel))</td></tr>"
        }.joined()

        let carencesBaseline = baseline.scores.prefix(6).map { s in
            let nom = CarenceDatabase.carence(for: s.carenceId)?.nom ?? s.carenceId
            return "<li>\(escape(nom)) — \(escape(s.niveau.label)) (réf. \(s.score))</li>"
        }.joined()

        var carencesEvolutifHTML = ""
        if let evolutif, evolutif.estPret {
            let evo = evolutif.scoresEvolutifs.prefix(6).map { s in
                let nom = CarenceDatabase.carence(for: s.carenceId)?.nom ?? s.carenceId
                let base = baseline.scores.first(where: { $0.carenceId == s.carenceId })
                let delta = base.map { " (réf. \($0.niveau.label) → actuel \(s.niveau.label))" } ?? ""
                return "<li>\(escape(nom)) — \(escape(s.niveau.label)) (score \(s.score))\(escape(delta))</li>"
            }.joined()
            carencesEvolutifHTML = """
            <h2>Bilan évolutif (journal \(evolutif.joursSuivi) j)</h2>
            <p class="meta">Recalculé en fusionnant le bilan de référence et les fréquences observées sur 14 jours.</p>
            <ul>\(evo)</ul>
            """
            if !evolutif.symptomesResolus.isEmpty {
                let resolus = evolutif.symptomesResolus.map { escape(CarenceDatabase.symptomeLabel(for: $0)) }.joined(separator: ", ")
                carencesEvolutifHTML += "<p><strong>Symptômes résolus (14j sans apparition) :</strong> \(resolus)</p>"
            }
        }

        return """
        <!DOCTYPE html><html lang="fr"><head><meta charset="utf-8">
        <style>
        body { font-family: -apple-system, Helvetica, Arial; font-size: 10pt; color: #1c1c1e; line-height: 1.45; }
        h1 { color: #4A7C59; font-size: 15pt; }
        h2 { color: #4A7C59; font-size: 11pt; margin-top: 16px; }
        .meta { color: #666; font-size: 9pt; }
        .box { background: #f5f5f3; padding: 8px; border-radius: 6px; margin: 8px 0; }
        .alert { background: #fff3e0; border-left: 3px solid #d4a017; }
        table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 9pt; }
        th, td { border: 1px solid #ddd; padding: 5px; text-align: left; }
        th { background: #f0f0ee; }
        .footer { font-size: 8pt; color: #666; margin-top: 16px; border-top: 1px solid #ddd; padding-top: 8px; }
        </style></head><body>
        <h1>Suivi symptômes — CarenceScan</h1>
        <p class="meta">Export pour consultation — \(escape(date))</p>
        \(grossesseHTML)
        <div class="box"><strong>Engagement suivi :</strong> \(streak) jour\(streak > 1 ? "s" : "") consécutif\(streak > 1 ? "s" : "") · Record \(tracker.settings.longestStreak) j</div>
        <h2>Bilan de référence (\(baseline.date.formatted(date: .abbreviated, time: .omitted)))</h2>
        <ul>\(carencesBaseline)</ul>
        \(carencesEvolutifHTML)
        <h2>Journal symptômes (14 derniers jours)</h2>
        <table>
        <tr><th>Symptôme</th><th>Fréq. référence</th><th>Jours présents</th><th>Fréq. observée</th></tr>
        \(journalRows)
        </table>
        <h2>Demandes au praticien</h2>
        <ul>
        <li>Comparer bilan de référence et évolution journalière</li>
        <li>Valider les carences persistantes par analyses ciblées</li>
        <li>Adapter supplémentation selon contexte (grossesse/allaitement si applicable)</li>
        </ul>
        <p class="footer">\(escape(AppConstants.disclaimerPrincipal))</p>
        </body></html>
        """
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
