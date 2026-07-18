import Foundation

/// Détecte des combinaisons substances à risque (message simple, non alarmiste).
enum MedicationInteractionEngine {
    struct InteractionWarning: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let severity: Severity

        enum Severity {
            case caution
            case attention
        }
    }

    static func warnings(
        factors: [SleepFactor],
        routines: [DailySubstanceRoutine],
        day: Date = Date()
    ) -> [InteractionWarning] {
        var result: [InteractionWarning] = []
        let cal = Calendar.current
        let today = factors.filter { cal.isDate($0.consumedAt, inSameDayAs: day) }
        let types = Set(today.map(\.type))

        if types.contains(.alcohol) && (types.contains(.benzodiazepine) || types.contains(.medicationSleep)) {
            result.append(InteractionWarning(
                title: "Attention",
                message: "Alcool + sédatif le même jour : effet amplifié sur le sommeil et la vigilance. À éviter si possible.",
                severity: .attention
            ))
        }

        if types.contains(.caffeine) && types.contains(.ssri) {
            let lateCaffeine = today.first { $0.type == .caffeine && cal.component(.hour, from: $0.consumedAt) >= 16 }
            let ssriTaken = today.contains { $0.type == .ssri }
                || routines.contains { $0.type == .ssri && routineTakenToday($0, day: day, factors: factors) }
            if lateCaffeine != nil && ssriTaken {
                result.append(InteractionWarning(
                    title: "Attention",
                    message: "Caféine tardive + ISRS : peut accentuer l’agitation ou retarder l’endormissement.",
                    severity: .caution
                ))
            }
        }

        if types.contains(.melatonin) && types.contains(.caffeine) {
            let caffeine = today.filter { $0.type == .caffeine }
            let melatonin = today.filter { $0.type == .melatonin }
            if let lastCaf = caffeine.max(by: { $0.consumedAt < $1.consumedAt }),
               let firstMel = melatonin.min(by: { $0.consumedAt < $1.consumedAt }),
               lastCaf.consumedAt > firstMel.consumedAt.addingTimeInterval(-2 * 3600) {
                result.append(InteractionWarning(
                    title: "Attention",
                    message: "Caféine et mélatonine proches dans la journée : effets opposés sur l’endormissement.",
                    severity: .caution
                ))
            }
        }

        return result
    }

    private static func routineTakenToday(
        _ routine: DailySubstanceRoutine,
        day: Date,
        factors: [SleepFactor]
    ) -> Bool {
        factors.contains { factor in
            Calendar.current.isDate(factor.consumedAt, inSameDayAs: day)
                && DailyRoutineMarkers.matchesRoutine(factor, routineId: routine.id)
                && !DailyRoutineMarkers.isSkipped(factor)
        }
    }
}
