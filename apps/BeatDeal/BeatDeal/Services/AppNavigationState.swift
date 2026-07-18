import Foundation

@MainActor
final class AppNavigationState: ObservableObject {
    static let shared = AppNavigationState()

    @Published var contractIdToOpen: String?

    private init() {}

    func openContract(id: String) {
        contractIdToOpen = id
    }

    func consumeContractToOpen() -> String? {
        let value = contractIdToOpen
        contractIdToOpen = nil
        return value
    }
}
