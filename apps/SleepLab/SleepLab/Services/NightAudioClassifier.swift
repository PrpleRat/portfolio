import AVFoundation
import Foundation

/// Classification heuristique nocturne (sans Mac / sans Core ML).
enum NightAudioClassifier {

    struct Classification {
        let type: SoundType
        let confidence: Double
    }

    static func classify(buffer: AVAudioPCMBuffer, sampleRate: Double) -> Classification? {
        guard let features = AudioSpectralFeatures.analyze(buffer: buffer, sampleRate: sampleRate) else {
            return nil
        }

        let db = features.decibels

        // Toux / toussotement : pic bref, médiums, forte crête — priorité haute
        if features.coughScore >= 0.52 {
            return Classification(type: .coughing, confidence: features.coughScore)
        }
        if features.coughScore >= 0.38, db >= 44, features.attackRatio > 1.1 {
            return Classification(type: .coughing, confidence: features.coughScore)
        }

        // Bruit fort large spectre
        if db > 72, features.midRatio + features.highRatio > 0.45 {
            return Classification(type: .environmentalNoise, confidence: 0.8)
        }

        // Ronflement (événements sonores legacy — le pipeline SnoreEvent est séparé)
        if features.snoreScore >= 0.55, features.coughScore < 0.35, db >= 40 {
            return Classification(type: .snoring, confidence: features.snoreScore)
        }

        // Respiration stable basse fréquence
        if db >= 40, db <= 58,
           features.lowRatio > 0.45,
           features.crestFactor < 4,
           features.coughScore < 0.3,
           features.zeroCrossingRate < 0.12 {
            return Classification(type: .breathing, confidence: 0.65)
        }

        if db >= 42, features.coughScore < 0.32 {
            return Classification(type: .unknown, confidence: 0.5)
        }

        return nil
    }
}
