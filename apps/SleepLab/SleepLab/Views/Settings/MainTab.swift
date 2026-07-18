import Foundation

/// Onglets principaux — évite les indices numériques quand l’onglet Cycle est ajouté ou retiré.
enum MainTab: Hashable {
    case home
    case history
    case dreams
    case insights
    case cycle
    case settings
}
