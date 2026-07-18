import Charts
import SwiftUI

struct HypnogramView: View {
    let session: SleepSession

    private var isTheoretical: Bool {
        SleepPhaseTheoreticalEstimate.shouldShow(for: session)
    }

    private var chartData: [PhaseSegment] {
        if isTheoretical, let segments = SleepPhaseTheoreticalEstimate.segments(for: session) {
            return segments.map { PhaseSegment(start: $0.start, end: $0.end, type: $0.type) }
        }
        return session.phases.map { phase in
            PhaseSegment(
                start: phase.startTime,
                end: phase.endTime,
                type: phase.phaseType
            )
        }
    }

    private var showPhaseDisclaimer: Bool {
        isTheoretical || MotionAnalyzer.isLikelyOverestimatedDeep(session: session)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isTheoretical ? "Hypothèse de phases" : "Hypnogramme")
                .font(.headline)

            if isTheoretical, let architecture = SleepPhaseTheoreticalEstimate.estimate(for: session) {
                TheoreticalPhaseEstimateCard(architecture: architecture, compact: true)
            } else if showPhaseDisclaimer && !isTheoretical {
                Label {
                    Text("Estimation (téléphone + cycles ~90 min) — pas un EEG. Si le profond semblait surestimé avant, cette version combine mouvements, architecture du sommeil et lissage temporel.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(SleepTheme.accent)
                }
                .padding(10)
                .background(SleepTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if chartData.isEmpty {
                Text("Pas assez de données pour afficher un graphique.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            Chart(chartData) { segment in
                RectangleMark(
                    xStart: .value("Début", segment.start),
                    xEnd: .value("Fin", segment.end),
                    y: .value("Phase", segment.type.chartOrder)
                )
                .foregroundStyle(SleepTheme.phaseColor(segment.type))
            }
            .chartYScale(domain: 0...3)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(phaseLabel(v))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(format: .dateTime.hour())
            }
            .frame(height: 220)

            soundMarkers
            wakeMarker

            legend
        }
        .padding()
        .background(SleepTheme.background)
        .navigationTitle(isTheoretical ? "Hypothèse" : "Phases")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var soundMarkers: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(session.soundEvents.prefix(20), id: \.id) { event in
                    VStack {
                        Image(systemName: event.soundType.sfSymbol)
                        Text(event.soundType.displayName)
                            .font(.caption2)
                    }
                    .padding(6)
                    .background(SleepTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var wakeMarker: some View {
        Group {
            if let wake = session.actualWakeTime ?? session.alarmTime {
                Label("Réveil : \(wake.formatted(date: .omitted, time: .shortened))", systemImage: "alarm.fill")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.accent)
            }
        }
    }

    private var legend: some View {
        HStack {
            ForEach(SleepPhaseType.allCases, id: \.self) { phase in
                HStack(spacing: 4) {
                    Circle().fill(SleepTheme.phaseColor(phase)).frame(width: 8, height: 8)
                    Text(phase.displayName).font(.caption2)
                }
            }
        }
    }

    private func phaseLabel(_ order: Int) -> String {
        SleepPhaseType.allCases.first { $0.chartOrder == order }?.displayName ?? ""
    }
}

private struct PhaseSegment: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let type: SleepPhaseType
}
