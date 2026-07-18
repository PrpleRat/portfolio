import SwiftUI

struct HandpanScreen: View {
    @EnvironmentObject private var audio: HandpanAudioEngine
    @EnvironmentObject private var playback: NotePlaybackTracker

    @State private var settingsOpen = false
    @State private var selectedConfigIndex = 0
    @State private var tuningRate = Tunings.defaultRate
    @State private var padLabelMode: PadLabelMode = .off
    @State private var velocityEnabled = false
    @State private var reverbLevel = ReverbLevels.defaultLevel

    private let instrumentVerticalFactor = 0.74

    private var audioReady: Bool { audio.status == .ready }

    var body: some View {
        GeometryReader { geometry in
            let handpanSize = min(
                geometry.size.width * 1.0,
                geometry.size.height * 0.75
            ).clamped(to: 248...640)
            let config = HandpanConfigs.all[selectedConfigIndex]

            ZStack {
                HandpanColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        SettingsButton(isOpen: settingsOpen) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                settingsOpen.toggle()
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 18)

                    ScaleTitle(name: config.name)
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                    Spacer()

                    HandpanInstrumentView(
                        config: config,
                        size: handpanSize,
                        audioReady: audioReady,
                        audioStatus: audio.status,
                        playback: playback,
                        labelMode: padLabelMode,
                        velocityEnabled: velocityEnabled,
                        onPlay: playNote
                    )
                    .offset(y: geometry.size.height * (instrumentVerticalFactor - 0.5) * 0.35)
                    .padding(.bottom, geometry.size.height * 0.02)

                    Spacer()
                }

                SettingsPanelView(
                    isOpen: settingsOpen,
                    configs: HandpanConfigs.all,
                    selectedIndex: selectedConfigIndex,
                    tuningRate: tuningRate,
                    reverbLevel: reverbLevel,
                    padLabelMode: padLabelMode,
                    velocityEnabled: velocityEnabled,
                    onClose: { withAnimation { settingsOpen = false } },
                    onSelected: { selectedConfigIndex = $0 },
                    onTuningSelected: { tuningRate = $0 },
                    onReverbSelected: { reverbLevel = $0 },
                    onPadLabelModeSelected: { padLabelMode = $0 },
                    onVelocityEnabledChanged: { velocityEnabled = $0 }
                )
            }
        }
        .task {
            _ = await audio.waitUntilReady()
        }
    }

    private func playNote(padId: String, soundBase: String, velocity: Double) {
        guard audioReady else { return }

        let sound = ReverbLevels.soundWithReverb(soundBase, level: reverbLevel)
        audio.play(sound: sound, volume: velocity, rate: tuningRate)

        let baseDuration = audio.estimatedDurationMs(for: sound, rate: tuningRate)
        playback.registerPlayback(
            padId: padId,
            durationMs: Int(Double(baseDuration) * 1.32),
            peakIntensity: velocity
        )
    }
}

private struct HandpanInstrumentView: View {
    let config: HandpanConfig
    let size: CGFloat
    let audioReady: Bool
    let audioStatus: AudioStatus
    @ObservedObject var playback: NotePlaybackTracker
    let labelMode: PadLabelMode
    let velocityEnabled: Bool
    let onPlay: (String, String, Double) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(outerPads.enumerated()), id: \.offset) { index, pad in
                let metrics = HandpanLayout.layoutMetrics(outerCount: outerPads.count)
                let radius = size * metrics.radiusFactor
                let padSize = size * metrics.padFactor
                let offset: CGSize = {
                    if config.usesCompactRing {
                        HandpanLayout.offsetForCompactRing(index: index, count: outerPads.count, radius: radius)
                    } else {
                        HandpanLayout.offset(for: pad.position, radius: radius)
                    }
                }()

                HandpanPadView(
                    label: NoteSounds.padLabel(
                        mode: labelMode,
                        noteId: pad.noteId,
                        position: pad.position,
                        ringNumber: pad.displayNumber
                    ),
                    size: padSize,
                    hitSize: padSize * 1.42,
                    velocityEnabled: velocityEnabled,
                    enabled: audioReady,
                    glow: playback.glow(for: pad.padId),
                    onTap: { velocity in
                        onPlay(pad.padId, pad.sound, velocity)
                    }
                )
                .offset(x: offset.width, y: offset.height)
            }

            if let center = config.center {
                HandpanPadView(
                    label: NoteSounds.padLabel(
                        mode: labelMode,
                        noteId: center.noteId,
                        position: center.position,
                        ringNumber: 1
                    ),
                    size: size * 0.315,
                    hitSize: size * 0.38,
                    isCenter: true,
                    velocityEnabled: velocityEnabled,
                    enabled: audioReady,
                    glow: playback.glow(for: center.padId),
                    onTap: { velocity in
                        onPlay(center.padId, center.sound, velocity)
                    }
                )
            }

            StatusBadgeView(status: audioStatus)
        }
        .frame(width: size, height: size)
    }

    private var outerPads: [HandpanPadSlot] {
        config.displayOuterPads
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
