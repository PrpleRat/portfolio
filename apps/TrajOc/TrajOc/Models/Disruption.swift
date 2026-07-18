import Foundation

/// Perturbation sur le réseau
struct Disruption: Identifiable, Codable, Equatable {
    let id: String
    let severity: Severity
    let status: Status
    let title: String
    let message: String
    let startDate: Date?
    let endDate: Date?
    let affectedLines: [String]
    let updatedAt: Date

    enum Severity: String, Codable {
        case blocking = "blocking"
        case significant = "significant_delays"
        case minor = "reduced_service"
        case information = "information"
        case noService = "no_service"
    }

    enum Status: String, Codable {
        case active = "active"
        case future = "future"
        case past = "past"
    }

    var severityColor: String {
        switch severity {
        case .blocking, .noService: return "#E74C3C"
        case .significant: return "#E67E22"
        case .minor: return "#F1C40F"
        case .information: return "#3498DB"
        }
    }
}
