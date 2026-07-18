import Foundation
import Observation

/// Owns all app state. Drives the countdown. Auto-releases at zero and on deinit.
@Observable @MainActor
final class AwakeSession {
    private(set) var isActive = false
    private(set) var remaining: TimeInterval?   // nil = indefinite; drives the label tick
    private(set) var endDate: Date?             // drives the menu-header "until X" text

    private let guardian = SleepGuard()
    private var countdownTask: Task<Void, Never>?

    /// - Parameter duration: nil = stay awake indefinitely; otherwise seconds.
    func start(duration: TimeInterval?, keepDisplayAwake: Bool = true) {
        stop()
        guard guardian.begin(keepDisplayAwake: keepDisplayAwake) else { return }
        isActive = true
        if let duration {
            let end = Date().addingTimeInterval(duration)
            endDate = end
            remaining = duration
            countdownTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard let self, !Task.isCancelled else { return }
                    let left = self.endDate?.timeIntervalSinceNow ?? 0
                    if left <= 0 { self.stop(); return }
                    self.remaining = left
                }
            }
        }
        StateFile.write(active: true, endDate: endDate)
    }

    func stop() {
        countdownTask?.cancel()
        countdownTask = nil
        guardian.end()
        isActive = false
        remaining = nil
        endDate = nil
        StateFile.write(active: false, endDate: nil)
    }

    func toggle() { isActive ? stop() : start(duration: nil) }
}
