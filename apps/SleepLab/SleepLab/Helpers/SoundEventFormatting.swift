import Foundation

enum SoundEventFormatting {
    /// Heure réelle avec secondes (évite que tout semble identique à la minute près).
    static func clockLabel(for date: Date) -> String {
        date.formatted(.dateTime.hour().minute().second())
    }

    /// Position dans la nuit par rapport au coucher, ex. « +2h 14m ».
    static func offsetLabel(eventAt: Date, sessionStart: Date) -> String {
        let delta = eventAt.timeIntervalSince(sessionStart)
        guard delta >= 0 else { return "avant coucher" }
        let h = Int(delta) / 3600
        let m = (Int(delta) % 3600) / 60
        let s = Int(delta) % 60
        if h > 0 { return String(format: "+%dh %02dm", h, m) }
        if m > 0 { return String(format: "+%dm %02ds", m, s) }
        return String(format: "+%ds", s)
    }

    static func listSubtitle(eventAt: Date, sessionStart: Date) -> String {
        "\(clockLabel(for: eventAt)) · \(offsetLabel(eventAt: eventAt, sessionStart: sessionStart))"
    }
}
