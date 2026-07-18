import IOKit.pwr_mgt

/// Thin wrapper over an IOKit power assertion. This is the entire sleep engine.
final class SleepGuard {
    // nonisolated(unsafe) lets deinit call end() from a non-isolated context
    // (safe: all callers are @MainActor; IOKit calls are synchronous C functions)
    nonisolated(unsafe) private var assertionID: IOPMAssertionID = 0
    nonisolated(unsafe) private(set) var isActive = false

    /// - Parameter keepDisplayAwake: true → also prevents display sleep,
    ///   false → only prevents system idle sleep but lets the screen dim.
    @discardableResult
    nonisolated func begin(keepDisplayAwake: Bool, reason: String = "Doppio is keeping this Mac awake") -> Bool {
        guard !isActive else { return true }
        let type: CFString = (keepDisplayAwake
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        isActive = (result == kIOReturnSuccess)
        return isActive
    }

    nonisolated func end() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }

    deinit { end() }
}
