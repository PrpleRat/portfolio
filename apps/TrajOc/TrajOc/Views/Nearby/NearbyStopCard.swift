import CoreLocation
import SwiftUI

struct NearbyStopCard: View {
    let stop: Place
    let userCoordinate: CLLocationCoordinate2D?

    var body: some View {
        HStack {
            Image(systemName: stop.type == .stopPoint ? "bus.fill" : "train.side.front.car")
                .foregroundStyle(stop.type == .stopPoint ? .blue : TransportStyle.occitanieRed())
            VStack(alignment: .leading) {
                Text(stop.name)
                    .font(.subheadline.weight(.medium))
                if let distance = formattedDistance {
                    Text(distance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDistance: String? {
        guard let userCoordinate else { return nil }
        let user = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let stopLoc = CLLocation(latitude: stop.coordinate.lat, longitude: stop.coordinate.lon)
        return DistanceFormatter.format(meters: user.distance(from: stopLoc))
    }
}
