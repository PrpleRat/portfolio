import SwiftUI

struct ResultsView: View {
    @StateObject private var viewModel: ResultsViewModel

    init(journeys: [Journey]) {
        _viewModel = StateObject(wrappedValue: ResultsViewModel(journeys: journeys))
    }

    var body: some View {
        JourneyListView(
            journeys: viewModel.journeys,
            disruptions: viewModel.disruptions
        )
        .navigationTitle("Itinéraires")
        .onAppear { viewModel.loadDisruptions() }
    }
}

struct JourneyListView: View {
    let journeys: [Journey]
    let disruptions: [Disruption]

    var body: some View {
        List(journeys) { journey in
            NavigationLink {
                JourneyDetailView(journey: journey)
            } label: {
                JourneyCard(journey: journey)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
