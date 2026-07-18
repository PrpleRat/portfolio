import SwiftUI

struct CircadianEnergyCard: View {
    let forecast: CircadianEnergyEngine.Forecast

    @State private var explainedWindow: CircadianEnergyEngine.TimeWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(SleepTheme.accent)
                Text("Énergie & fatigue")
                    .font(.headline)
                Spacer()
            }

            Text(forecast.headline)
                .font(.subheadline)
                .foregroundStyle(SleepTheme.textPrimary)

            Text(forecast.detailLine)
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)

            VStack(spacing: 8) {
                ForEach(upcomingWindows) { window in
                    Button {
                        explainedWindow = window
                    } label: {
                        HStack {
                            Image(systemName: icon(for: window.kind))
                                .foregroundStyle(color(for: window.kind))
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(window.label)
                                        .font(.caption.weight(.semibold))
                                    Image(systemName: "info.circle")
                                        .font(.caption2)
                                        .foregroundStyle(SleepTheme.textSecondary)
                                }
                                Text(timeRange(window))
                                    .font(.caption2)
                                    .foregroundStyle(SleepTheme.textSecondary)
                                if let ref = window.referenceTime {
                                    Text("Prise : \(ref.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(SleepTheme.textSecondary.opacity(0.85))
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tape sur un repère pour comprendre ce que ça signifie.")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
        .padding()
        .background(SleepTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $explainedWindow) { window in
            energyExplanationSheet(window)
        }
    }

    private func energyExplanationSheet(_ window: CircadianEnergyEngine.TimeWindow) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(window.label)
                        .font(.title2.bold())
                    Text(timeRange(window))
                        .font(.subheadline)
                        .foregroundStyle(SleepTheme.textSecondary)
                    if let ref = window.referenceTime {
                        Text("Référence : \(ref.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    Text(EnergyWindowGlossary.explanation(for: window.kind))
                        .font(.body)
                }
                .padding()
            }
            .background(SleepTheme.background.ignoresSafeArea())
            .navigationTitle("Explication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { explainedWindow = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var upcomingWindows: [CircadianEnergyEngine.TimeWindow] {
        let now = Date()
        return forecast.windows
            .filter { $0.end > now.addingTimeInterval(-20 * 60) }
            .prefix(5)
            .map { $0 }
    }

    private func timeRange(_ window: CircadianEnergyEngine.TimeWindow) -> String {
        let start = window.start.formatted(date: .omitted, time: .shortened)
        let end = window.end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    private func icon(for kind: CircadianEnergyEngine.TimeWindow.Kind) -> String {
        switch kind {
        case .inertia: return "moon.zzz.fill"
        case .energyPeak: return "sun.max.fill"
        case .fatigueDip: return "cloud.drizzle.fill"
        case .fatiguePeak: return "battery.25"
        case .caffeineBoost: return "cup.and.saucer.fill"
        case .substanceDip: return "drop.triangle.fill"
        case .secondWind: return "sparkles"
        }
    }

    private func color(for kind: CircadianEnergyEngine.TimeWindow.Kind) -> Color {
        switch kind {
        case .inertia: return SleepTheme.textSecondary
        case .energyPeak: return .yellow
        case .fatigueDip: return .orange
        case .fatiguePeak: return SleepTheme.phaseAwake
        case .caffeineBoost: return SleepTheme.accent
        case .substanceDip: return .purple.opacity(0.8)
        case .secondWind: return .purple
        }
    }
}
