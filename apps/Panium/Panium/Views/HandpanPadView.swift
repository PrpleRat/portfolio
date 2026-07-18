import SwiftUI

struct HandpanPadView: View {
    let label: String
    let size: CGFloat
    let hitSize: CGFloat
    var isCenter: Bool = false
    var velocityEnabled: Bool = false
    let enabled: Bool
    let glow: Double
    let onTap: (Double) -> Void

    @State private var pressed = false
    @State private var driftPhase: Double = 0
    @State private var holdTask: Task<Void, Never>?

    private let holdRepeatInitialDelay: Duration = .milliseconds(520)
    private let holdRepeatInterval: Duration = .milliseconds(400)

    var body: some View {
        let auraExtent = size * 0.55
        let playScale = 1.0 + glow * (isCenter ? 0.09 : 0.042)
        let pressScale = pressed ? 0.985 : 1.0
        let vibrateX = glow > 0.03 ? sin(driftPhase * 4.2) * (isCenter ? 0.7 : 1.1) * glow : 0
        let vibrateY = glow > 0.03 ? cos(driftPhase * 4.2) * (isCenter ? 0.5 : 0.75) * glow : 0

        ZStack {
            Circle()
                .fill(padFillColor)
                .overlay {
                    Circle()
                        .stroke(padBorderColor, lineWidth: isCenter ? 1.4 : 1.2)
                }
                .frame(width: size, height: size)
                .overlay {
                    if !label.isEmpty {
                        Text(label)
                            .font(HandpanTypography.padLabel)
                            .fontWeight(isCenter ? .semibold : .medium)
                            .foregroundStyle(labelColor)
                            .font(.system(size: isCenter ? 22 : 15, weight: .medium, design: .rounded))
                    }
                }

            if glow > 0.02 {
                Circle()
                    .fill(HandpanColors.accentBlue.opacity(glow * 0.25))
                    .blur(radius: size * 0.18)
                    .frame(width: size * 1.2, height: size * 1.2)
            }
        }
        .frame(width: hitSize, height: hitSize)
        .scaleEffect(playScale * pressScale)
        .offset(x: vibrateX, y: vibrateY)
        .animation(.easeOut(duration: glow > 0.02 ? 0.14 : 0.07), value: glow)
        .animation(.easeOut(duration: 0.07), value: pressed)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard enabled else { return }
                    if !pressed {
                        pressed = true
                        let velocity = velocityFrom(location: value.location)
                        onTap(velocity)
                        startHoldRepeat(initialVelocity: velocity)
                    }
                }
                .onEnded { _ in
                    pressed = false
                    cancelHoldRepeat()
                }
        )
        .onChange(of: glow) { _, newGlow in
            if newGlow > 0.02 {
                startDriftAnimation()
            }
        }
        .allowsHitTesting(enabled)
    }

    private var padFillColor: Color {
        if glow <= 0.02 { return HandpanColors.padIdle }
        return HandpanColors.accentBlueDim.opacity(0.2 + glow * 0.35)
    }

    private var padBorderColor: Color {
        glow > 0.02 ? HandpanColors.padBorder : HandpanColors.padBorderIdle
    }

    private var labelColor: Color {
        glow > 0.1 ? HandpanColors.text.opacity(0.6 + glow * 0.4) : HandpanColors.padLabel
    }

    private func velocityFrom(location: CGPoint) -> Double {
        guard velocityEnabled else { return 1.0 }
        let center = CGPoint(x: hitSize / 2, y: hitSize / 2)
        let distance = hypot(location.x - center.x, location.y - center.y)
        let normalized = min(max(distance / (size / 2), 0), 1)
        let centerStrength = 1.0 - normalized
        let curved = pow(centerStrength, 0.65)
        return min(max(0.22 + curved * 0.78, 0.22), 1.0)
    }

    private func startHoldRepeat(initialVelocity: Double) {
        cancelHoldRepeat()
        holdTask = Task {
            try? await Task.sleep(for: holdRepeatInitialDelay)
            while !Task.isCancelled && pressed {
                onTap(initialVelocity)
                try? await Task.sleep(for: holdRepeatInterval)
            }
        }
    }

    private func cancelHoldRepeat() {
        holdTask?.cancel()
        holdTask = nil
    }

    private func startDriftAnimation() {
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            driftPhase = .pi * 2
        }
    }
}
