import SwiftUI

struct DepartureBoardView: View {
    let stop: Place
    let departures: [Departure]

    var body: some View {
        NavigationStack {
            Group {
                if departures.isEmpty {
                    ContentUnavailableView(
                        stop.id.hasPrefix("osm-") ? "Horaires bus indisponibles" : "Aucun départ",
                        systemImage: "clock",
                        description: Text(
                            stop.id.hasPrefix("osm-")
                                ? "Arrêt recensé OpenStreetMap (liO / réseau local). Horaires temps réel à venir — consulte liO ou la gare TER la plus proche."
                                : "Pas de départ prévu prochainement sur cet arrêt."
                        )
                    )
                } else {
                    List(departures) { departure in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    TransportBadge(mode: departure.line.mode, label: departure.line.code)
                                    Text(departure.direction)
                                        .lineLimit(1)
                                }
                                Text(departure.line.network)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(DurationFormatter.format(date: departure.realTime))
                                    .font(.headline)
                                    .foregroundStyle(departure.isDelayed ? .red : .primary)
                                Text(DurationFormatter.relativeMinutes(until: departure.realTime))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if departure.hasDisruption {
                                Text("⚠️")
                            }
                        }
                    }
                }
            }
            .navigationTitle(stop.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
