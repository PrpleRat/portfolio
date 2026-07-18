import SwiftUI

struct TimerRingView: View {

    let timeRemaining: TimeInterval
    let totalInterval: TimeInterval

    private var progress: Double {
        guard totalInterval > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalInterval))
    }

    private var ringColor: Color {
        if progress > 0.5 { return .safeGreen }
        if progress > 0.2 { return .safeOrange }
        return .safeRed
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            VStack(spacing: 4) {
                Text(timeRemaining.formattedCountdown)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("avant vérif.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .scaleEffect(timeRemaining < 300 ? 1.03 : 1)
        .animation(
            timeRemaining < 300 ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
            value: timeRemaining < 300
        )
        .onChange(of: timeRemaining) { _, newValue in
            if newValue < 60, newValue > 59 {
                SoundManager.playAlertSound()
            }
        }
    }
}

#Preview {
    TimerRingView(timeRemaining: 2700, totalInterval: 3600)
}
