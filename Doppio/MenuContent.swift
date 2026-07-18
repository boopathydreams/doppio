import SwiftUI
import AppKit

struct MenuContent: View {
    var session: AwakeSession
    @AppStorage("keepDisplayAwake")  private var keepDisplayAwake = true
    @AppStorage("doppio.customHr")   private var savedHr  = ""
    @AppStorage("doppio.customMin")  private var savedMin = ""

    var body: some View {
        // ── Status header ──────────────────────────────────────────────
        Label {
            Text(headerText).fontWeight(.semibold)
        } icon: {
            Image(systemName: "circle.fill")
                .foregroundStyle(session.isActive ? Color.green : Color.secondary)
                .font(.system(size: 8))
        }

        Divider()

        // ── Timed presets ──────────────────────────────────────────────
        Section("Presets") {
            presetButton("15 minutes", systemImage: "15.circle",  duration: 15 * 60,     shortcut: "1")
            presetButton("30 minutes", systemImage: "30.circle",  duration: 30 * 60,     shortcut: "2")
            presetButton("1 hour",     systemImage: "clock",      duration: 60 * 60,     shortcut: "3")
            presetButton("2 hours",    systemImage: "clock.fill", duration: 2 * 60 * 60, shortcut: "4")
            presetButton("5 hours",    systemImage: "clock.badge.checkmark", duration: 5 * 60 * 60, shortcut: "5")
        }

        // ── Custom preset (shown only when a value has been saved) ─────
        Section("Custom") {
            if let label = customPresetLabel, let seconds = customPresetSeconds {
                // Saved value — shown as a directly-tappable preset
                Button {
                    session.start(duration: seconds, keepDisplayAwake: keepDisplayAwake)
                } label: {
                    Label(label, systemImage: "arrow.counterclockwise.circle.fill")
                }
                .keyboardShortcut("6", modifiers: .command)
            }

            // Always-visible item to open the editor
            Button {
                showCustomDurationAlert()
            } label: {
                Label(customPresetLabel == nil ? "Set custom…" : "Edit custom…",
                      systemImage: "slider.horizontal.3")
            }
        }

        // ── No-limit + off ─────────────────────────────────────────────
        Button {
            session.start(duration: nil, keepDisplayAwake: keepDisplayAwake)
        } label: {
            Label("Keep awake (no limit)", systemImage: "infinity")
        }
        .keyboardShortcut("0", modifiers: .command)

        Button {
            session.stop()
        } label: {
            Label("Turn off", systemImage: "stop.circle")
        }
        .disabled(!session.isActive)
        .keyboardShortcut(".", modifiers: .command)

        Divider()

        // ── Options ────────────────────────────────────────────────────
        Section("Options") {
            Toggle(isOn: Binding(
                get: { !keepDisplayAwake },
                set: { keepDisplayAwake = !$0 }
            )) {
                Label("Allow display to sleep", systemImage: "moon.zzz")
            }

            Toggle(isOn: Binding(
                get: { LoginItem.isEnabled },
                set: { _ in LoginItem.toggle() }
            )) {
                Label("Launch at login", systemImage: "house")
            }
        }

        Divider()

        Button {
            installCLI()
        } label: {
            Label("Install CLI Tool…", systemImage: "terminal")
        }

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("Quit Doppio", systemImage: "power")
        }
        .keyboardShortcut("q")
    }

    // MARK: – Custom preset helpers

    /// Human-readable label for the saved custom value, e.g. "1h 30m" or "45m".
    private var customPresetLabel: String? {
        let hr  = Double(savedHr)  ?? 0
        let min = Double(savedMin) ?? 0
        guard hr > 0 || min > 0 else { return nil }
        var parts: [String] = []
        if hr  > 0 { parts.append(hr  == hr.rounded()  ? "\(Int(hr))h"  : "\(hr)h")  }
        if min > 0 { parts.append(min == min.rounded() ? "\(Int(min))m" : "\(min)m") }
        return parts.joined(separator: " ")
    }

    private var customPresetSeconds: TimeInterval? {
        let hr  = Double(savedHr)  ?? 0
        let min = Double(savedMin) ?? 0
        let s   = hr * 3600 + min * 60
        return s > 0 ? s : nil
    }

    // MARK: – Custom duration alert

    private func showCustomDurationAlert() {
        let alert = NSAlert()
        alert.messageText = "Custom duration"
        alert.informativeText = "Enter hours and/or minutes — both are optional."
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 210, height: 28))

        let hrField  = makeField(placeholder: "0", value: savedHr,
                                 frame: NSRect(x: 0,   y: 2, width: 64, height: 24))
        let hrLabel  = makeLabel("hr",  frame: NSRect(x: 70,  y: 6, width: 22, height: 16))
        let minField = makeField(placeholder: "0", value: savedMin,
                                 frame: NSRect(x: 102, y: 2, width: 64, height: 24))
        let minLabel = makeLabel("min", frame: NSRect(x: 172, y: 6, width: 30, height: 16))

        [hrField, hrLabel, minField, minLabel].forEach { container.addSubview($0) }
        alert.accessoryView = container
        alert.window.initialFirstResponder = hrField

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let hr  = Double(hrField.stringValue.trimmingCharacters(in: .whitespaces))  ?? 0
        let min = Double(minField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        guard hr * 3600 + min * 60 > 0 else { return }

        // Persist via @AppStorage — menu updates instantly
        savedHr  = hrField.stringValue.trimmingCharacters(in: .whitespaces)
        savedMin = minField.stringValue.trimmingCharacters(in: .whitespaces)

        session.start(duration: hr * 3600 + min * 60, keepDisplayAwake: keepDisplayAwake)
    }

    private func makeField(placeholder: String, value: String, frame: NSRect) -> NSTextField {
        let f = NSTextField(frame: frame)
        f.placeholderString = placeholder
        f.stringValue = value
        f.bezelStyle = .roundedBezel
        return f
    }

    private func makeLabel(_ text: String, frame: NSRect) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.frame = frame
        l.textColor = .secondaryLabelColor
        l.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        return l
    }

    // MARK: – Preset helper

    @ViewBuilder
    private func presetButton(
        _ title: String,
        systemImage: String,
        duration: TimeInterval,
        shortcut: Character
    ) -> some View {
        Button {
            session.start(duration: duration, keepDisplayAwake: keepDisplayAwake)
        } label: {
            Label(title, systemImage: systemImage)
        }
        .keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
    }

    // MARK: – CLI installer

    private func installCLI() {
        guard let resourceDir = Bundle.main.resourceURL else {
            showCLIAlert(title: "CLI not bundled",
                         message: "Could not locate the app bundle Resources folder.", detail: nil)
            return
        }
        let src = resourceDir.appendingPathComponent("doppio")
        guard FileManager.default.fileExists(atPath: src.path) else {
            showCLIAlert(title: "CLI not bundled",
                         message: "Could not locate the doppio script inside the app bundle.", detail: nil)
            return
        }

        // Already installed (e.g. via Homebrew symlink)?
        let usrLocalBin = URL(fileURLWithPath: "/usr/local/bin/doppio")
        if FileManager.default.fileExists(atPath: usrLocalBin.path) {
            showCLIAlert(title: "CLI already installed",
                         message: "doppio is already available at /usr/local/bin/doppio.",
                         detail: "Run `doppio --help` in Terminal to use it.")
            return
        }

        // Try /usr/local/bin first, fall back to ~/.local/bin (no sudo needed)
        let candidates: [URL] = [
            usrLocalBin,
            URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent(".local/bin/doppio"))
        ]

        for dest in candidates {
            do {
                try FileManager.default.createDirectory(
                    at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: src, to: dest)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)

                let isLocalBin = dest.path.contains(".local/bin")
                showCLIAlert(
                    title: "CLI installed",
                    message: "doppio installed to \(dest.path)",
                    detail: isLocalBin
                        ? "Add ~/.local/bin to your PATH if not already:\n  echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.zshrc"
                        : "Run `doppio --help` in Terminal to confirm."
                )
                return
            } catch {
                continue
            }
        }

        // Both failed — show manual command
        showCLIAlert(
            title: "Permission denied",
            message: "Could not install automatically. Run this in Terminal:",
            detail: "sudo cp \"\(src.path)\" /usr/local/bin/doppio && sudo chmod +x /usr/local/bin/doppio"
        )
    }

    private func showCLIAlert(title: String, message: String, detail: String?) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail.map { "\(message)\n\n\($0)" } ?? message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private var headerText: String {
        if let endDate = session.endDate {
            return "Awake · until \(endDate.formatted(date: .omitted, time: .shortened))"
        } else if session.isActive {
            return "Awake · no limit"
        } else {
            return "Asleep-friendly"
        }
    }
}
