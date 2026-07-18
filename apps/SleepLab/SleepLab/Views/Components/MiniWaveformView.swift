import SwiftUI

/// Mini waveform décorative (déterministe depuis un seed).
struct MiniWaveformView: View {
    let seed: UInt64
    var barCount: Int = 28
    var accent: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(SleepTheme.accent.opacity(accent ? 0.35 + barOpacity(index) * 0.55 : 0.25))
                    .frame(width: 3, height: barHeight(index))
            }
        }
        .frame(height: 32)
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let v = pseudoRandom(seed: seed, index: index)
        return 6 + CGFloat(v) * 22
    }

    private func barOpacity(_ index: Int) -> Double {
        pseudoRandom(seed: seed &+ 17, index: index)
    }

    private func pseudoRandom(seed: UInt64, index: Int) -> Double {
        var x = seed ^ UInt64(index &* 2654435761)
        x ^= x >> 33
        x &*= 0xff51afd7ed558ccd
        x ^= x >> 33
        return Double(x % 1000) / 1000.0
    }
}
