import SwiftUI

struct SettingsPanelView: View {
    let isOpen: Bool
    let configs: [HandpanConfig]
    let selectedIndex: Int
    let tuningRate: Double
    let reverbLevel: Int
    let padLabelMode: PadLabelMode
    let velocityEnabled: Bool
    let onClose: () -> Void
    let onSelected: (Int) -> Void
    let onTuningSelected: (Double) -> Void
    let onReverbSelected: (Int) -> Void
    let onPadLabelModeSelected: (PadLabelMode) -> Void
    let onVelocityEnabledChanged: (Bool) -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack {
            if isOpen {
                panelContent
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = min(max(value.translation.height, -140), 0)
                            }
                            .onEnded { value in
                                if dragOffset <= -56 || (value.predictedEndTranslation.height < -450) {
                                    onClose()
                                }
                                dragOffset = 0
                            }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .animation(.easeOut(duration: 0.3), value: isOpen)
        .allowsHitTesting(isOpen)
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(HandpanColors.border)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            sectionTitle("Scale")
            Picker("Scale", selection: Binding(
                get: { selectedIndex },
                set: onSelected
            )) {
                ForEach(Array(configs.enumerated()), id: \.offset) { index, config in
                    Text(config.name).tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            sectionTitle("Tuning")
            HStack(spacing: 8) {
                ForEach(Tunings.options) { option in
                    chipButton(title: option.label, selected: tuningRate == option.rate) {
                        onTuningSelected(option.rate)
                    }
                }
            }

            sectionTitle("Reverb")
            HStack(spacing: 8) {
                ForEach(ReverbLevels.options) { option in
                    chipButton(title: option.label, selected: reverbLevel == option.level) {
                        onReverbSelected(option.level)
                    }
                }
            }

            sectionTitle("Pad labels")
            HStack(spacing: 8) {
                ForEach(PadLabelMode.allCases) { mode in
                    chipButton(
                        title: mode.label,
                        selected: padLabelMode == mode
                    ) {
                        onPadLabelModeSelected(mode)
                    }
                }
            }

            Toggle(isOn: Binding(
                get: { velocityEnabled },
                set: onVelocityEnabledChanged
            )) {
                Text("Velocity (touch position)")
                    .font(HandpanTypography.settingsLabel)
                    .foregroundStyle(HandpanColors.text)
            }
            .tint(HandpanColors.accentBlue)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(HandpanColors.border.opacity(0.65), lineWidth: 0.8)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(HandpanTypography.settingsSection)
            .foregroundStyle(HandpanColors.textTertiary)
    }

    private func chipButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HandpanTypography.settingsLabel)
                .foregroundStyle(selected ? HandpanColors.text : HandpanColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected ? HandpanColors.accentBlueDim.opacity(0.55) : HandpanColors.surfaceElevated,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
