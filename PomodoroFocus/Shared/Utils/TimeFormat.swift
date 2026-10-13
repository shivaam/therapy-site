import Foundation

enum TimeFormat {
    /// "25:00", or "1:05:00" once past an hour.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    /// "25 min", "1 h", "1 h 5 min".
    static func minutes(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let r = m % 60
        return r == 0 ? "\(h) h" : "\(h) h \(r) min"
    }
}
