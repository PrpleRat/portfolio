import SwiftUI

struct SearchView: View {
  @StateObject private var viewModel = SearchViewModel()
  @State private var navigateToResults = false
  @State private var resultJourneys: [Journey] = []
  @FocusState private var focusedField: SearchViewModel.SearchFocusTarget?

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 20) {
            header
            searchCard(proxy: proxy)
            DateTimePicker(departAt: $viewModel.departAt, selectedDate: $viewModel.selectedDate)
            TransportFilterView(enabledModes: $viewModel.enabledModes)
            frequentStations
            calculateButton
            stateView
          }
          .padding()
        }
      }
      .background(Color(.systemGroupedBackground))
      .scrollDismissesKeyboard(.interactively)
      .navigationDestination(isPresented: $navigateToResults) {
        ResultsView(journeys: resultJourneys)
      }
      .onChange(of: viewModel.state) { _, newState in
        if case .results(let journeys) = newState {
          resultJourneys = journeys
          navigateToResults = true
        }
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(TransportStyle.occitanieRed())
          .frame(width: 44, height: 44)
        Image(systemName: "cross.fill")
          .foregroundStyle(TransportStyle.occitanieGold())
      }
      VStack(alignment: .leading) {
        Text("TrajOc")
          .font(.title.bold())
        Text("Transports Occitanie")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
  }

  private func searchCard(proxy: ScrollViewProxy) -> some View {
    VStack(spacing: 12) {
      originSection(proxy: proxy)

      Button(action: viewModel.swapEndpoints) {
        Image(systemName: "arrow.up.arrow.down.circle.fill")
          .font(.title2)
          .foregroundStyle(TransportStyle.occitanieRed())
      }

      destinationSection(proxy: proxy)

      MultiStopEditor(
        stops: $viewModel.intermediateStops,
        texts: $viewModel.intermediateTexts,
        onAdd: viewModel.addIntermediateStop,
        onRemove: viewModel.removeIntermediate(at:),
        onMove: viewModel.moveIntermediate(from:to:)
      )

      if viewModel.intermediateStops.count > 1 {
        Toggle("Optimiser l'ordre des étapes", isOn: $viewModel.shouldOptimizeStops)
          .font(.subheadline)
      }
    }
    .padding(16)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
  }

  private func originSection(proxy: ScrollViewProxy) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      PlaceSearchBar(
        label: "Départ",
        text: $viewModel.originText,
        isFocused: $focusedField,
        focusTarget: .origin,
        showLocationButton: true,
        onLocationTap: viewModel.useCurrentLocationForOrigin,
        onTextChange: { viewModel.searchSuggestions(for: $0) },
        onFocus: { viewModel.beginEditing(.origin) },
        onSubmit: { focusDestination(proxy: proxy) }
      )
      .id(SearchViewModel.SearchFocusTarget.origin)

      if viewModel.activeField == .origin {
        suggestionPanel(for: .origin, proxy: proxy)
      } else if viewModel.origin != nil {
        selectedPlaceChip(viewModel.origin!)
      }
    }
  }

  private func destinationSection(proxy: ScrollViewProxy) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      PlaceSearchBar(
        label: "Arrivée",
        text: $viewModel.destinationText,
        isFocused: $focusedField,
        focusTarget: .destination,
        showLocationButton: false,
        onLocationTap: {},
        onTextChange: { viewModel.searchSuggestions(for: $0) },
        onFocus: { viewModel.beginEditing(.destination) },
        onSubmit: { viewModel.dismissSuggestions(); focusedField = nil }
      )
      .id(SearchViewModel.SearchFocusTarget.destination)

      if viewModel.activeField == .destination {
        suggestionPanel(for: .destination, proxy: proxy)
      } else if viewModel.destination != nil {
        selectedPlaceChip(viewModel.destination!)
      }
    }
  }

  private func selectedPlaceChip(_ place: Place) -> some View {
    HStack(spacing: 8) {
      Image(systemName: place.isStation ? "checkmark.circle.fill" : "mappin.circle.fill")
        .foregroundStyle(.green)
      Text(place.name)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
      Spacer()
    }
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func suggestionPanel(
    for field: SearchViewModel.SearchField,
    proxy: ScrollViewProxy
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Choisir dans la liste")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        if viewModel.isSearchingSuggestions {
          ProgressView().controlSize(.small)
        }
        Button("Fermer") {
          viewModel.dismissSuggestions()
          focusedField = nil
        }
        .font(.caption)
      }
      .padding(.horizontal, 14)
      .padding(.top, 10)
      .padding(.bottom, 6)

      if viewModel.suggestions.isEmpty && !viewModel.isSearchingSuggestions {
        Text("Tape au moins 2 caractères (ex. « 32 lascrosses toulouse » ou « matabiau »).")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(14)
      } else {
        ForEach(Array(viewModel.suggestions.prefix(8).enumerated()), id: \.element.id) { index, place in
          PlaceSuggestionRow(place: place) {
            pickSuggestion(place, field: field, proxy: proxy)
          }
          if index < min(viewModel.suggestions.count, 8) - 1 {
            Divider().padding(.leading, 58)
          }
        }
      }
    }
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(TransportStyle.occitanieRed().opacity(0.35), lineWidth: 1)
    )
  }

  private func pickSuggestion(
    _ place: Place,
    field: SearchViewModel.SearchField,
    proxy: ScrollViewProxy
  ) {
    let nextFocus = viewModel.selectSuggestion(place, field: field)
    focusedField = nil

    guard let nextFocus else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.easeInOut(duration: 0.25)) {
        proxy.scrollTo(nextFocus, anchor: .center)
      }
      focusedField = nextFocus
      viewModel.beginEditing(.destination)
    }
  }

  private func focusDestination(proxy: ScrollViewProxy) {
    viewModel.dismissSuggestions()
    withAnimation {
        proxy.scrollTo(SearchViewModel.SearchFocusTarget.destination, anchor: .center)
    }
    focusedField = .destination
    viewModel.beginEditing(.destination)
  }

  private var frequentStations: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Gares fréquentes")
        .font(.headline)
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        ForEach(StationCatalog.all.prefix(8)) { station in
          Button(station.name) {
            let place = station.asPlace
            if viewModel.origin == nil {
              _ = viewModel.selectSuggestion(place, field: .origin)
              focusedField = .destination
              viewModel.beginEditing(.destination)
            } else {
              _ = viewModel.selectSuggestion(place, field: .destination)
              focusedField = nil
              viewModel.dismissSuggestions()
            }
          }
          .font(.caption.weight(.medium))
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .padding(8)
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(Color(.secondarySystemGroupedBackground))
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
      }
    }
  }

  private var calculateButton: some View {
    Button {
      viewModel.dismissSuggestions()
      focusedField = nil
      viewModel.calculateJourney()
    } label: {
      Text("Calculer l'itinéraire")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(TransportStyle.occitanieRed())
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
  }

  @ViewBuilder
  private var stateView: some View {
    switch viewModel.state {
    case .searching:
      ProgressView("Recherche des itinéraires…")
    case .error(let message):
      VStack(spacing: 8) {
        Text(message)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
        Button("Réessayer") { viewModel.resetError() }
      }
      .padding()
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    default:
      EmptyView()
    }
  }
}

#Preview {
  SearchView()
}
