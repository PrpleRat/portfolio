import Foundation

/// Modèle de cycles ~90 min pour éviter un hypnogramme « 100 % profond » avec téléphone fixe.
enum SleepArchitectureEstimator {

    /// Phase typique selon le temps écoulé depuis le coucher (minutes).
    static func typicalPhase(elapsedMinutes: Double) -> SleepPhaseType {
        guard elapsedMinutes >= 8 else { return .light }
        let pos = elapsedMinutes.truncatingRemainder(dividingBy: 90)
        switch pos {
        case 8..<22: return .light
        case 22..<42: return .deep
        case 42..<58: return .light
        case 58..<78: return .rem
        default: return .light
        }
    }

    /// Fusion mouvement (accéléromètre) + architecture physiologique.
    static func blend(
        motion: SleepPhaseType,
        architectural: SleepPhaseType,
        elapsedMinutes: Double,
        movementScore: Double,
        baseline: Double
    ) -> SleepPhaseType {
        if motion == .awake { return .awake }

        let ratio = movementScore / max(baseline, 0.02)

        // Début de nuit : peu de profond même si immobile
        if elapsedMinutes < 25, architectural != .deep, motion == .deep {
            return .light
        }

        // Immobilité seule ne suffit pas → suivre le cycle attendu
        if motion == .deep, architectural != .deep {
            return architectural
        }

        if motion == .rem { return .rem }

        if architectural == .rem, motion == .light, ratio < 1.2 {
            return .rem
        }

        if motion == .light, ratio < 0.9 {
            return architectural
        }

        return motion
    }
}
