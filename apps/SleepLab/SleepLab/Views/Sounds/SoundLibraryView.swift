import SwiftUI

/// Liste des sons nocturnes (bêta) — sans catégories, avec mini waveform.
struct SoundLibraryView: View {
    let session: SleepSession

    private var events: [SoundEvent] {
        session.soundEvents.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        List {
            Section {
                Label("Détection audio en bêta — seuil relevé pour limiter les faux positifs.", systemImage: "waveform.badge.mic")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }

            if events.isEmpty {
                ContentUnavailableView(
                    "Aucun son détecté",
                    systemImage: "speaker.slash",
                    description: Text("Les sons marquants apparaîtront ici avec un extrait audio si l’enregistrement est activé.")
                )
            } else {
                ForEach(events, id: \.id) { event in
                    NavigationLink {
                        SoundPlayerView(event: event, sessionStart: session.startTime)
                    } label: {
                        soundRow(event)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SleepTheme.background.ignoresSafeArea())
        .navigationTitle("Sons de la nuit")
    }

    private func soundRow(_ event: SoundEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(SoundEventFormatting.clockLabel(for: event.timestamp))
                    .font(.subheadline.bold())
                Spacer()
                Text(String(format: "%.0f dB", event.decibelLevel))
                    .font(.caption)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            Text(SoundEventFormatting.offsetLabel(eventAt: event.timestamp, sessionStart: session.startTime))
                .font(.caption2)
                .foregroundStyle(SleepTheme.textSecondary)
            MiniWaveformView(seed: waveformSeed(for: event))
            if !clipExists(for: event) {
                Text("Pas d’extrait enregistré")
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func waveformSeed(for event: SoundEvent) -> UInt64 {
        UInt64(bitPattern: Int64(event.timestamp.timeIntervalSince1970 * 1000))
            ^ UInt64(event.decibelLevel.bitPattern)
    }

    private func clipExists(for event: SoundEvent) -> Bool {
        guard let name = event.clipFileName else { return false }
        return FileManager.default.fileExists(atPath: AudioHelpers.clipURL(fileName: name).path)
    }
}
