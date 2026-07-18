import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("RAS — Fusée de détresse. Outil de bien-être personnel. Il ne remplace pas un équipement de secours homologué (SPOT, Garmin inReach, PLB) pour les activités à risque en zone blanche.")
            }

            Section("Limites techniques iOS") {
                Label {
                    Text("Les notifications locales planifiées fonctionnent même si l'app est fermée, mais nécessitent que les notifications soient activées et non bloquées.")
                } icon: {
                    Image(systemName: "bell.badge")
                }

                Label {
                    Text("iOS interdit l'envoi de SMS sans ton accord : RAS ouvre Messages avec le texte déjà écrit, tu appuies une fois sur Envoyer. Pour un envoi 100 % automatique, il faudra un serveur (prochaine version) ou un Raccourci Siri.")
                } icon: {
                    Image(systemName: "message.fill")
                }

                Label {
                    Text("Le SMS passe par le réseau GSM. Sans signal, aucun message ne peut partir.")
                } icon: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }

                Label {
                    Text("La position GPS est enregistrée au démarrage et à chaque check-in. En cas d'alerte sans signal, la dernière position connue est utilisée.")
                } icon: {
                    Image(systemName: "location")
                }

                Label {
                    Text("Consommation batterie faible (notifications locales uniquement). Emporte une batterie externe pour les longues sorties.")
                } icon: {
                    Image(systemName: "battery.100")
                }

                Label {
                    Text("iOS ne garantit pas l'exécution de timers en arrière-plan. RAS utilise des notifications planifiées à l'avance — pas un timer background permanent.")
                } icon: {
                    Image(systemName: "iphone")
                }
            }

            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("iOS minimum", value: "17.0")
            }
        }
        .navigationTitle("À propos")
    }
}
