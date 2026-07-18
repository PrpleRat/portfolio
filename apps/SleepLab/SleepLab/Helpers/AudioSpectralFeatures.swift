import AVFoundation
import Accelerate
import Foundation

/// Descripteurs spectraux pour classifier toux, ronflement, respiration, bruit.
struct AudioSpectralFeatures {
    let rms: Float
    let decibels: Double
    let lowRatio: Double
    let midRatio: Double
    let highRatio: Double
    let spectralCentroidHz: Double
    let crestFactor: Double
    let zeroCrossingRate: Double
    let attackRatio: Double
    let snoreScore: Double
    let coughScore: Double

    static func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) -> AudioSpectralFeatures? {
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let n = Int(buffer.frameLength)
        guard n > 128, sampleRate > 0 else { return nil }

        var rms: Float = 0
        vDSP_rmsqv(data, 1, &rms, vDSP_Length(n))
        let db = AudioHelpers.rmsToDecibels(rms) + 90

        var zcr = 0
        for i in 1..<n where (data[i] >= 0) != (data[i - 1] >= 0) {
            zcr += 1
        }
        let zcrRate = Double(zcr) / Double(n)

        var peak: Float = 0
        vDSP_maxv(data, 1, &peak, vDSP_Length(n))
        let crest = Double(peak) / max(Double(rms), 1e-7)

        let attackSamples = max(8, n / 10)
        var attackRms: Float = 0
        vDSP_rmsqv(data, 1, &attackRms, vDSP_Length(attackSamples))
        let attackRatio = Double(attackRms) / max(Double(rms), 1e-7)

        guard let mags = magnitudeSpectrum(data: data, count: n, sampleRate: sampleRate) else {
            return AudioSpectralFeatures(
                rms: rms, decibels: db, lowRatio: 0, midRatio: 0, highRatio: 0,
                spectralCentroidHz: 0, crestFactor: crest, zeroCrossingRate: zcrRate,
                attackRatio: attackRatio, snoreScore: 0, coughScore: 0
            )
        }

        let fftSize = mags.count * 2
        let binWidth = sampleRate / Double(fftSize)
        let lowEnd = Int(40 / binWidth)
        let lowStop = Int(320 / binWidth)
        let midStop = Int(2_500 / binWidth)
        let highStop = min(mags.count, Int(8_000 / binWidth))

        let lowEnergy = bandEnergy(mags, start: lowEnd, end: lowStop)
        let midEnergy = bandEnergy(mags, start: lowStop, end: midStop)
        let highEnergy = bandEnergy(mags, start: midStop, end: highStop)
        let total = lowEnergy + midEnergy + highEnergy + 1e-9

        let lowRatio = lowEnergy / total
        let midRatio = midEnergy / total
        let highRatio = highEnergy / total

        var centroidNumer = 0.0
        var centroidDenom = 0.0
        for i in 0..<mags.count {
            let freq = Double(i) * binWidth
            let e = Double(mags[i])
            centroidNumer += freq * e
            centroidDenom += e
        }
        let centroid = centroidDenom > 0 ? centroidNumer / centroidDenom : 0

        let snoreScore = lowRatio * (1 - min(1, highRatio * 2))
        let coughScore = coughScoreFrom(
            midRatio: midRatio,
            highRatio: highRatio,
            crest: crest,
            attack: attackRatio,
            zcr: zcrRate,
            centroid: centroid,
            snoreScore: snoreScore,
            db: db
        )

        return AudioSpectralFeatures(
            rms: rms,
            decibels: db,
            lowRatio: lowRatio,
            midRatio: midRatio,
            highRatio: highRatio,
            spectralCentroidHz: centroid,
            crestFactor: crest,
            zeroCrossingRate: zcrRate,
            attackRatio: attackRatio,
            snoreScore: snoreScore,
            coughScore: coughScore
        )
    }

    private static func coughScoreFrom(
        midRatio: Double,
        highRatio: Double,
        crest: Double,
        attack: Double,
        zcr: Double,
        centroid: Double,
        snoreScore: Double,
        db: Double
    ) -> Double {
        guard db > 38 else { return 0 }
        var score = 0.0
        if midRatio > 0.28 { score += 0.35 }
        if midRatio > 0.38 { score += 0.15 }
        if crest > 3.5 { score += 0.2 }
        if crest > 6 { score += 0.1 }
        if attack > 1.15 { score += 0.15 }
        if attack > 1.4 { score += 0.1 }
        if zcr > 0.06 { score += 0.1 }
        if centroid > 400, centroid < 3_500 { score += 0.15 }
        if highRatio > 0.12, highRatio < 0.45 { score += 0.08 }
        if snoreScore < 0.42 { score += 0.12 }
        if snoreScore > 0.62 { score -= 0.35 }
        return min(1, max(0, score))
    }

    private static func bandEnergy(_ mags: [Float], start: Int, end: Int) -> Double {
        guard start < end, start < mags.count else { return 0 }
        let stop = min(end, mags.count)
        return Double(mags[start..<stop].reduce(0, +))
    }

    private static func magnitudeSpectrum(data: UnsafePointer<Float>, count: Int, sampleRate: Double) -> [Float]? {
        guard count > 0 else { return nil }
        let fftSize = 1 << Int(ceil(log2(Double(max(count, 2)))))
        guard fftSize >= 2 else { return nil }

        var padded = [Float](repeating: 0, count: fftSize)
        for i in 0..<min(count, fftSize) {
            padded[i] = data[i]
        }

        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var real = [Float](repeating: 0, count: fftSize / 2)
        var imag = [Float](repeating: 0, count: fftSize / 2)

        return real.withUnsafeMutableBufferPointer { realBuf in
            imag.withUnsafeMutableBufferPointer { imagBuf in
                guard let realBase = realBuf.baseAddress, let imagBase = imagBuf.baseAddress else {
                    return nil
                }
                var split = DSPSplitComplex(realp: realBase, imagp: imagBase)
                padded.withUnsafeBufferPointer { ptr in
                    ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(fftSize / 2))
                    }
                }
                vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                var mags = [Float](repeating: 0, count: fftSize / 2)
                vDSP_zvmags(&split, 1, &mags, 1, vDSP_Length(fftSize / 2))
                return mags
            }
        }
    }
}
