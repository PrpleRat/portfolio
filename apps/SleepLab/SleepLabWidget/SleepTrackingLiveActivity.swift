import ActivityKit
import SwiftUI
import WidgetKit

struct SleepTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTrackingAttributes.self) { context in
            SleepTrackingLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isPaused ? "pause.circle.fill" : "moon.zzz.fill")
                        .foregroundStyle(.purple)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.phaseName)
                            .font(.headline)
                        Text(context.state.elapsedText)
                            .font(.caption.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Link(destination: URL(string: "sleeplab://wake")!) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                    }
                }
            } compactLeading: {
                Image(systemName: "moon.zzz.fill")
            } compactTrailing: {
                Text(context.state.elapsedText)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "moon.zzz.fill")
            }
        }
    }
}

private struct SleepTrackingLiveActivityView: View {
    let context: ActivityViewContext<SleepTrackingAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(AppBrand.displayName) · \(context.attributes.sessionKindTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.phaseName)
                    .font(.headline)
                Text(context.state.elapsedText)
                    .font(.title2.bold().monospacedDigit())
            }
            Spacer()
            Link(destination: URL(string: "sleeplab://wake")!) {
                Label("Réveil", systemImage: "sun.max.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .activityBackgroundTint(Color(red: 0.06, green: 0.07, blue: 0.12))
    }
}
