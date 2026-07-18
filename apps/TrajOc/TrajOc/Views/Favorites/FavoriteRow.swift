import SwiftUI

struct FavoriteRow: View {
    let favorite: FavoriteJourney

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(favorite.name)
                .font(.headline)
            HStack {
                Text(favorite.originName)
                Image(systemName: "arrow.right")
                Text(favorite.destinationName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text("Ajouté le \(favorite.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
