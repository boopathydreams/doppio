import SwiftUI

@main
struct DoppioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // delegate.session is a `let` on a non-@Observable AppDelegate.
        // DoppioApp.body accesses no @Observable properties directly, so it is
        // never re-evaluated when session state changes. The MenuBarExtra scene
        // stays stable — no status-item teardown when a session starts or stops.
        MenuBarExtra {
            MenuContent(session: delegate.session)
        } label: {
            StatusLabel(session: delegate.session)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// All @Observable access lives here, in a child view, not in DoppioApp.body.
/// Only this view re-renders on per-second ticks — the scene itself doesn't rebuild.
private struct StatusLabel: View {
    var session: AwakeSession

    var body: some View {
        Image(session.isActive ? "DoppioMenuBarFull" : "DoppioMenuBarEmpty")
            .renderingMode(.template)
        if let remaining = session.remaining {
            Text(Formatting.hms(remaining))
                .monospacedDigit()
        }
    }
}
