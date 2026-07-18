import SwiftUI

struct PlaceSearchBar: View {
    let label: String
    @Binding var text: String
    var isFocused: FocusState<SearchViewModel.SearchFocusTarget?>.Binding
    let focusTarget: SearchViewModel.SearchFocusTarget
    let showLocationButton: Bool
    let onLocationTap: () -> Void
    let onTextChange: (String) -> Void
    let onFocus: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showLocationButton {
                Button(action: onLocationTap) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(TransportStyle.occitanieRed())
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                TextField("N° et rue, gare, ville…", text: $text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isFocused.wrappedValue == focusTarget
                                    ? TransportStyle.occitanieRed().opacity(0.8)
                                    : Color(.separator).opacity(0.35),
                                lineWidth: isFocused.wrappedValue == focusTarget ? 2 : 1
                            )
                    )
                    .textContentType(.fullStreetAddress)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused(isFocused, equals: focusTarget)
                    .onChange(of: text) { _, newValue in
                        onTextChange(newValue)
                    }
                    .onSubmit(onSubmit)
            }
        }
    }
}
