import CoreLocation
import Foundation
import MessageUI
import SwiftUI

@MainActor
final class AlertDispatcher: ObservableObject {

    static let shared = AlertDispatcher()

    @Published var isDispatching = false
    @Published var dispatchLog: [String] = []
    /// Composer SMS in-app (1 appui « Envoyer » — limite iOS).
    @Published var pendingSMSCompose: SMSComposeRequest?

    func dispatch(session: SafeSession, config: AlertConfig, location: CLLocation?) async {
        guard !session.wasAlertTriggered else {
            dispatchLog.append("ℹ️ Alerte déjà déclenchée pour cette session")
            return
        }

        isDispatching = true
        dispatchLog = []

        let includeGPS = config.actions.contains(AlertAction.shareLocation.rawValue)
        let message = buildAlertMessage(
            session: session,
            config: config,
            location: includeGPS ? location : nil
        )
        let actions = config.actions.compactMap { AlertAction(rawValue: $0) }

        for action in actions {
            switch action {
            case .sms, .iMessage:
                await dispatchSMS(to: config.contacts, message: message)
            case .email:
                await dispatchEmail(
                    to: config.contacts,
                    subject: "🚨 Alerte RAS — \(session.name)",
                    body: message
                )
            case .shareLocation:
                break
            case .shortcut:
                await dispatchShortcut(named: "RAS Alerte")
            case .callEmergency:
                await dispatchEmergencyCall()
            }
        }

        session.wasAlertTriggered = true
        session.alertTriggeredAt = Date()
        isDispatching = false
    }

    private func buildAlertMessage(
        session: SafeSession,
        config: AlertConfig,
        location: CLLocation?
    ) -> String {
        var parts: [String] = []

        let base = config.customAlertMessage.isEmpty
            ? "⚠️ RAS : \(session.name) — La personne n'a pas répondu au check-in de sécurité."
            : config.customAlertMessage
        parts.append(base)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        parts.append("Démarré le : \(formatter.string(from: session.startTime))")

        if let last = session.checkIns.sorted(by: { $0.date < $1.date }).last {
            parts.append("Dernier contact : \(formatter.string(from: last.date))")
        }

        if let loc = location {
            let lat = String(format: "%.5f", loc.coordinate.latitude)
            let lon = String(format: "%.5f", loc.coordinate.longitude)
            parts.append("Position : \(lat), \(lon)")
            parts.append("Voir sur Maps : https://maps.apple.com/?ll=\(lat),\(lon)&z=15")
        } else if let lat = session.startLatitude, let lon = session.startLongitude {
            parts.append("Dernière position connue : \(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))")
        }

        parts.append("— Envoyé via RAS (fusée de détresse)")
        return parts.joined(separator: "\n")
    }

    private func dispatchSMS(to contacts: [Contact], message: String) async {
        let phones = contacts
            .filter { !$0.isEmergencyService && !$0.phoneNumber.isEmpty }
            .map(\.formattedPhone)

        guard !phones.isEmpty else {
            dispatchLog.append("⚠️ Aucun numéro de contact")
            return
        }

        if MFMessageComposeViewController.canSendText() {
            pendingSMSCompose = SMSComposeRequest(recipients: phones, body: message)
            dispatchLog.append("📱 Messages prêt — appuie sur Envoyer (\(phones.count) contact(s))")
            return
        }

        await openSMSFallback(phone: phones[0], message: message, label: phones[0])
    }

    private func openSMSFallback(phone: String, message: String, label: String) async {
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "sms:\(phone)&body=\(encoded)"
        if let url = URL(string: urlString) {
            await UIApplication.shared.open(url)
            dispatchLog.append("📱 Messages ouvert vers \(label) — appuie sur Envoyer")
        }
    }

    private func dispatchEmail(to contacts: [Contact], subject: String, body: String) async {
        let emails = contacts.compactMap { $0.email.isEmpty ? nil : $0.email }.joined(separator: ",")
        guard !emails.isEmpty else { return }
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(emails)?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: urlString) {
            await UIApplication.shared.open(url)
            dispatchLog.append("✉️ Mail ouvert — appuie sur Envoyer")
        }
    }

    private func dispatchShortcut(named name: String) async {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") {
            await UIApplication.shared.open(url)
            dispatchLog.append("✅ Raccourci Siri lancé : \(name)")
        }
    }

    private func dispatchEmergencyCall() async {
        if let url = URL(string: "tel://112") {
            await UIApplication.shared.open(url)
            dispatchLog.append("📞 Appel 112 initié")
        }
    }
}
