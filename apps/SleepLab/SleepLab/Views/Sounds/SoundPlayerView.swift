import SwiftUI

struct SoundPlayerView: View {
    let event: SoundEvent
    var sessionStart: Date
    @StateObject private var audio = ClipAudioPlayer()

    private var clipAvailable: Bool {
        guard let name = event.clipFileName else { return false }
        return FileManager.default.fileExists(atPath: AudioHelpers.clipURL(fileName: name).path)
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(SleepTheme.accent)

            Text("Son nocturne")
                .font(.title2.bold())

            VStack(spacing: 4) {
                Text(SoundEventFormatting.clockLabel(for: event.timestamp))
                Text(SoundEventFormatting.offsetLabel(eventAt: event.timestamp, sessionStart: sessionStart))
            }
            .font(.subheadline)
            .foregroundStyle(SleepTheme.textSecondary)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<32, id: \.self) { i in
                    let h = barHeight(index: i)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(SleepTheme.accent.opacity(audio.isPlaying ? 0.9 : 0.4))
                        .frame(width: 4, height: h)
                }
            }
            .frame(height: 56)
            .animation(.easeInOut(duration: 0.2), value: audio.progress)

            VStack(spacing: 8) {
                ProgressView(value: audio.progress)
                    .tint(SleepTheme.accent)
                HStack {
                    Text(formatTime(audio.currentTime))
                    Spacer()
                    Text(formatTime(audio.duration > 0 ? audio.duration : event.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(SleepTheme.textSecondary)
            }
            .padding(.horizontal)

            HStack(spacing: 32) {
                Button {
                    audio.toggle()
                } label: {
                    Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                .disabled(!clipAvailable)
            }

            statusMessage

            Text(String(format: "Niveau détecté : %.0f dB", event.decibelLevel))
                .font(.caption)
        }
        .padding()
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Lecture")
        .onAppear {
            if let name = event.clipFileName {
                audio.load(fileName: name)
            }
        }
        .onDisappear { audio.stop() }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if event.clipFileName == nil {
            Text("Événement détecté sans clip (seuil ou intervalle entre enregistrements).")
                .font(.caption)
                .foregroundStyle(SleepTheme.textSecondary)
                .multilineTextAlignment(.center)
        } else if audio.loadFailed || !clipAvailable {
            Text("Fichier d'enregistrement introuvable sur l'appareil.")
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        } else {
            Text("Monte le volume média si la lecture est faible.")
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let phase = Double(index) / 32 * .pi * 4 + audio.progress * .pi * 2
        let base = sin(phase) * 0.5 + 0.5
        let active = audio.isPlaying ? base : 0.35
        return CGFloat(12 + active * 36)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
