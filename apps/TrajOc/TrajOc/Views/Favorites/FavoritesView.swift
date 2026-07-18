import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "Aucun favori",
                        systemImage: "star",
                        description: Text("Sauvegarde un itinéraire depuis l'écran de détail.")
                    )
                } else {
                    List {
                        ForEach(viewModel.favorites, id: \.id) { favorite in
                            FavoriteRow(favorite: favorite)
                        }
                        .onDelete { indexSet in
                            indexSet.map { viewModel.favorites[$0] }.forEach {
                                viewModel.delete($0, context: modelContext)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favoris")
            .onAppear { viewModel.reload(from: modelContext) }
        }
    }
}
