import Foundation

@MainActor
final class ContractStorage: ObservableObject {
    static let shared = ContractStorage()

    @Published private(set) var contracts: [Contract] = []

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.storageKeyContracts) else {
            contracts = []
            return
        }
        do {
            contracts = try JSONDecoder().decode([Contract].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            contracts = []
        }
    }

    func save(_ contract: Contract) {
        if let index = contracts.firstIndex(where: { $0.id == contract.id }) {
            contracts[index] = contract
        } else {
            contracts.insert(contract, at: 0)
        }
        persist()
        Task {
            await LicenseAlertService.shared.refreshAlerts(for: contracts)
        }
    }

    func delete(_ contract: Contract) {
        contracts.removeAll { $0.id == contract.id }
        persist()
        Task {
            await LicenseAlertService.shared.refreshAlerts(for: contracts)
        }
    }

    func recent(limit: Int = 5) -> [Contract] {
        Array(contracts.prefix(limit))
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(contracts)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeyContracts)
        } catch {
            // Silent — caller can surface via Alert if needed
        }
    }
}

@MainActor
final class ProfileStorage: ObservableObject {
    static let shared = ProfileStorage()

    @Published var profile = ProducerProfile()

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.storageKeyProfile) else { return }
        do {
            profile = try JSONDecoder().decode(ProducerProfile.self, from: data)
        } catch {
            profile = ProducerProfile()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeyProfile)
        } catch {
            // Silent
        }
    }
}

@MainActor
final class TemplateStorage: ObservableObject {
    static let shared = TemplateStorage()

    @Published private(set) var templates: [LicenseTemplate] = LicenseTemplate.defaultTemplates()

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.storageKeyTemplates) else { return }
        do {
            templates = try JSONDecoder().decode([LicenseTemplate].self, from: data)
        } catch {
            templates = LicenseTemplate.defaultTemplates()
        }
    }

    func template(for type: LicenseType) -> LicenseTemplate {
        templates.first { $0.licenseType == type }
            ?? LicenseTemplate.defaultTemplates().first { $0.licenseType == type }!
    }

    func update(_ template: LicenseTemplate) {
        if let index = templates.firstIndex(where: { $0.licenseType == template.licenseType }) {
            templates[index] = template
        }
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: AppConstants.storageKeyTemplates)
        } catch {
            // Silent
        }
    }
}
