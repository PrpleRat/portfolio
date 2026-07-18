import PDFKit
import UIKit

enum PDFExportService {

    static func generatePDF(
        payload: SavedResultsPayload,
        database: CarenceDatabaseFile = CarenceDatabase.shared
    ) -> Data? {
        let html = buildHTML(payload: payload, database: database)
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let printableRect = pageRect.insetBy(dx: 36, dy: 36)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for pageIndex in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: pageIndex, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    static func buildHTML(
        payload: SavedResultsPayload,
        database: CarenceDatabaseFile
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: payload.date)

        var rows = ""
        for (index, score) in payload.scores.enumerated() {
            guard let carence = database.carences.first(where: { $0.id == score.carenceId }) else { continue }
            let symptomes = score.symptomesDetectes
                .prefix(4)
                .map { CarenceDatabase.symptomeLabel(for: $0) }
                .joined(separator: ", ")
            let aliments = carence.alimentsCles.prefix(3).joined(separator: ", ")
            rows += """
            <tr>
              <td>\(index + 1)</td>
              <td><strong>\(escape(carence.nom))</strong></td>
              <td>\(escape(score.niveau.label)) (\(score.score))</td>
              <td>\(escape(symptomes))</td>
              <td>\(escape(aliments))</td>
            </tr>
            """
        }

        var complements = ""
        for score in payload.scores.prefix(8) {
            guard let carence = database.carences.first(where: { $0.id == score.carenceId }) else { continue }
            let c = carence.complement
            complements += """
            <tr>
              <td>\(escape(carence.nom))</td>
              <td>\(escape(c.nom))</td>
              <td>\(escape(c.posologie))</td>
              <td>\(escape(c.formeRecommandee))</td>
              <td>\(escape(c.prixMois))</td>
            </tr>
            """
        }

        var alertes = ""
        for regleId in payload.reglesDetectees {
            if let regle = database.reglesCombinatoiresSpeciales.first(where: { $0.id == regleId }) {
                alertes += "<p class=\"alert\">\(escape(regle.messageAlerte))</p>"
            }
        }
        if !payload.medicamentsSelectionnes.isEmpty {
            alertes += "<p class=\"alert\">\(escape(AppConstants.alerteMedicaments))</p>"
        }
        if payload.scores.contains(where: { $0.carenceId == "fer" }) {
            alertes += "<p class=\"alert\">\(escape(AppConstants.alerteFer))</p>"
        }
        if payload.medicamentsSelectionnes.contains("sertraline")
            || payload.scores.contains(where: { $0.carenceId == "tryptophane" }) {
            alertes += "<p class=\"alert\">\(escape(AppConstants.alerte5HTP))</p>"
        }

        let soins = CarenceDatabase.soinsLocaux(for: Set(payload.symptomesSelectionnes))
        var soinsHTML = ""
        if !soins.isEmpty {
            soinsHTML = "<h2>Soins locaux recommandés</h2><ul>"
            for soin in soins {
                soinsHTML += "<li><strong>\(escape(soin.nom))</strong> — \(escape(soin.utilisation)) (\(escape(soin.prix)))</li>"
            }
            soinsHTML += "</ul>"
        }

        let recettes = RecettesEngine.suggererRecettes(depuis: payload.scores, carencesBase: database.carences)
        var recettesHTML = """
        <h2 style="color: #4A7C59; margin-top: 32px;">Recettes suggérées</h2>
        <p style="color: #666; font-size: 12px; margin-bottom: 16px;">
            Sélectionnées pour couvrir plusieurs de vos carences simultanément.
        </p>
        """
        for item in recettes.prefix(3) {
            let carences = item.carencesMatchees.map { RecettesEngine.carenceNom(for: $0) }.joined(separator: ", ")
            recettesHTML += """
            <div style="margin-bottom: 16px; padding: 12px; border: 1px solid #e0e0e0; border-radius: 8px;">
              <p style="font-weight: bold; margin: 0 0 4px;">
                \(escape(item.recette.emoji)) \(escape(item.recette.titre)) — \(escape(item.recette.temps))
              </p>
              <p style="color: #4A7C59; font-size: 11px; margin: 0;">Couvre : \(escape(carences))</p>
            </div>
            """
        }

        let liste = ListeCoursesEngine.genererListe(
            depuis: payload.scores,
            symptomesDetectes: payload.symptomeSelections.map(\.symptomeId),
            database: database
        )
        var listeHTML = """
        <h2 style="color: #4A7C59; margin-top: 32px;">Liste de courses</h2>
        <h3>💊 Pharmacie</h3>
        """
        for item in liste.pharmacie {
            listeHTML += "<p>☐ \(escape(item.nom))"
            if let prix = item.prix { listeHTML += " — \(escape(prix))" }
            listeHTML += "</p>"
        }
        listeHTML += "<h3>🛒 Supermarché</h3>"
        for item in liste.supermarche.prefix(20) {
            listeHTML += "<p>☐ \(escape(item.nom))</p>"
        }

        return """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #1c1c1e; font-size: 11pt; line-height: 1.45; }
            h1 { color: #4A7C59; font-size: 18pt; margin-bottom: 4px; }
            h2 { color: #4A7C59; font-size: 13pt; margin-top: 20px; }
            .meta { color: #636366; font-size: 10pt; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 9pt; }
            th, td { border: 1px solid #e6e6e4; padding: 6px 8px; text-align: left; vertical-align: top; }
            th { background: #f5f5f3; color: #4A7C59; }
            .alert { background: #fef2f2; color: #b91c1c; padding: 8px 10px; border-radius: 6px; border-left: 4px solid #E05A4E; }
            .footer { margin-top: 24px; font-size: 9pt; color: #636366; border-top: 1px solid #e6e6e4; padding-top: 12px; }
          </style>
        </head>
        <body>
          <h1>Mon Bilan Carences &amp; Solutions</h1>
          <p class="meta">Guide personnalisé à présenter à votre médecin — généré le \(escape(dateStr))</p>
          \(alertes)
          <h2>Carences par priorité</h2>
          <table>
            <thead>
              <tr>
                <th>Priorité</th><th>Carence</th><th>Probabilité</th><th>Symptômes déclencheurs</th><th>Aliments clés</th>
              </tr>
            </thead>
            <tbody>\(rows)</tbody>
          </table>
          <h2>Compléments recommandés</h2>
          <table>
            <thead>
              <tr><th>Carence</th><th>Complément</th><th>Posologie</th><th>Forme</th><th>Prix/mois</th></tr>
            </thead>
            <tbody>\(complements)</tbody>
          </table>
          \(soinsHTML)
          \(recettesHTML)
          \(listeHTML)
          <p class="footer">\(escape(AppConstants.disclaimerPrincipal))</p>
        </body>
        </html>
        """
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
