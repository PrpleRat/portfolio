import MapKit
import SwiftUI

struct NearbyView: View {
    @StateObject private var viewModel = NearbyViewModel()
    @State private var region = MKCoordinateRegion(
        center: AppConstants.occitanieCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(coordinateRegion: $region, annotationItems: mapAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        annotationView(for: item)
                            .onTapGesture { viewModel.selectStop(item.place) }
                    }
                }
                .frame(height: 300)
                .onAppear {
                    LocationManager.shared.requestPermission()
                    LocationManager.shared.startUpdating()
                    viewModel.loadNearby()
                }
                .onReceive(LocationManager.shared.$coordinate) { coord in
                    if let coord {
                        region.center = coord
                    }
                }

                filterBar

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }

                stopList
            }
            .navigationTitle("À proximité")
            .refreshable { viewModel.loadNearby() }
            .sheet(item: $viewModel.selectedStop) { stop in
                DepartureBoardView(stop: stop, departures: viewModel.departures)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(NearbyFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) { viewModel.filter = filter }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.filter == filter ? TransportStyle.occitanieRed() : Color(.secondarySystemBackground))
                        .foregroundStyle(viewModel.filter == filter ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }

    private var stopList: some View {
        List {
            if viewModel.filter == .bikes || viewModel.filter == .all {
                ForEach(viewModel.bikeStations) { station in
                    HStack {
                        Image(systemName: "bicycle")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text(station.name)
                            Text("\(station.availableBikes) vélos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            ForEach(viewModel.filteredStops) { stop in
                NearbyStopCard(stop: stop, userCoordinate: viewModel.userCoordinate)
                    .onTapGesture { viewModel.selectStop(stop) }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.filteredStops.isEmpty && viewModel.bikeStations.isEmpty {
                ContentUnavailableView(
                    "Aucun arrêt",
                    systemImage: "tram.fill.tunnel",
                    description: Text("Autorise la localisation ou réessaie dans quelques secondes.")
                )
            }
        }
    }

    private var mapAnnotations: [NearbyMapItem] {
        var items = viewModel.filteredStops.map { NearbyMapItem(place: $0, kind: .stop) }
        if viewModel.filter == .bikes || viewModel.filter == .all {
            items += viewModel.bikeStations.map { station in
                NearbyMapItem(
                    place: Place(
                        id: "bike-\(station.id)",
                        name: station.name,
                        type: .poi,
                        coordinate: Place.Coordinate(lat: station.latitude, lon: station.longitude),
                        city: nil,
                        postalCode: nil,
                        administrativeRegion: nil
                    ),
                    kind: .bike(station.availableBikes)
                )
            }
        }
        return items
    }

    @ViewBuilder
    private func annotationView(for item: NearbyMapItem) -> some View {
        switch item.kind {
        case .stop:
            Image(systemName: "tram.fill.tunnel")
                .foregroundStyle(.white)
                .padding(6)
                .background(TransportStyle.occitanieRed())
                .clipShape(Circle())
        case .bike(let count):
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bicycle")
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.green)
                    .clipShape(Circle())
                Text("\(count)")
                    .font(.caption2)
                    .padding(2)
                    .background(.white)
                    .clipShape(Circle())
                    .offset(x: 6, y: -6)
            }
        }
    }
}

struct NearbyMapItem: Identifiable {
    let id: String
    let place: Place
    let kind: Kind
    var coordinate: CLLocationCoordinate2D { place.clCoordinate }

    enum Kind {
        case stop
        case bike(Int)
    }

    init(place: Place, kind: Kind) {
        self.id = place.id
        self.place = place
        self.kind = kind
    }
}