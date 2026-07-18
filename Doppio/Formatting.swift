import Foundation

enum Formatting {
    /// 3725 → "1:02:05"; 305 → "5:05" (hour dropped when zero).
    static func hms(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval.rounded()))
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
