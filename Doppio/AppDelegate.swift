import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let session = AwakeSession()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar-only, no Dock icon
    }

    // Handles doppio://activate?minutes=120 , doppio://deactivate , doppio://toggle
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            switch url.host {
            case "activate":
                let minutes = comps?.queryItems?.first(where: { $0.name == "minutes" })?.value
                    .flatMap(Double.init)
                session.start(duration: minutes.map { $0 * 60 })
            case "deactivate":
                session.stop()
            case "toggle":
                session.toggle()
            default:
                break
            }
        }
    }
}
