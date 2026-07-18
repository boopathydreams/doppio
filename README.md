<div align="center">

# ☕ Doppio

### A double shot for your Mac.

**Keep your Mac awake — with a countdown you can actually see, and a one-liner that keeps it awake for exactly as long as your AI coding agent is working.**

[![Release](https://img.shields.io/github/v/release/boopathy-nr/doppio?style=flat-square)](https://github.com/boopathy-nr/doppio/releases)
[![Downloads](https://img.shields.io/github/downloads/boopathy-nr/doppio/total?style=flat-square)](https://github.com/boopathy-nr/doppio/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/macOS-26%2B-black?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Built with Swift](https://img.shields.io/badge/Swift-6-orange?style=flat-square&logo=swift)](https://swift.org)

<!-- 👇 THE MONEY SHOT. Record a short GIF (~10s): menu bar showing the live countdown ticking down,
     alongside a terminal running `doppio while claude`. This one image sells the whole app. -->
<img src="docs/demo.gif" alt="Doppio menu bar countdown + doppio while claude" width="640">

</div>

---

## Why Doppio?

Every Mac has `caffeinate`. There are a dozen menu-bar apps that wrap it. Doppio does two things none of them do:

**1. It shows you the timer.** Set "stay awake for 2 hours" and you can see, at a glance, that 1:12 remains. No mystery about whether it's still on.

**2. It babysits your AI coding agent.**

```bash
doppio while claude
```

That keeps your Mac awake for *exactly* as long as your agent runs, then lets it sleep the moment the job finishes. No guessing a duration. No forgetting to turn it off and draining your battery overnight. No dead two-hour run because the screen went dark and the machine dozed off halfway through.

If you kick off long, unattended agent sessions and walk away — this is for you.

---

## Install

**Homebrew (recommended):**

```bash
brew install --cask doppio
```

> Until the cask lands in `homebrew-cask` core, install from the tap:
> `brew install --cask boopathy-nr/tap/doppio`

**Direct download:** grab the latest `Doppio.dmg` from [Releases](https://github.com/boopathy-nr/doppio/releases), drag it to Applications, and launch. The build is signed with a Developer ID and notarized by Apple, so Gatekeeper won't complain.

**CLI only:** copy `CLI/doppio` to `/usr/local/bin/` and `chmod +x` it. The `doppio while` command works independently of the GUI app.

Doppio lives in your menu bar — no Dock icon, no window.

---

## Usage

### From the menu bar

Click the ☕ cup. A **filled cup** means your Mac is staying awake; an **empty cup** means it'll sleep normally. When a timed session is running, the remaining time shows right next to the icon in the menu bar (e.g. `☕ 1:24:07`).

Open the menu for:

- **Timed presets** — 15m / 30m / 1h / 2h / 5h
- **Keep awake (no limit)** — stays on until you turn it off
- **Turn off** — cancels the active session
- **Allow display to sleep** — system stays awake, screen can dim (saves battery)
- **Launch at login**

### From the command line

Install the CLI (`CLI/doppio` → `/usr/local/bin/doppio`) and you're good to go:

```bash
doppio while <command>   # stay awake for the whole command, then sleep — kill-proof
doppio on [minutes]      # turn on (no minutes = indefinite)
doppio off               # turn off
doppio toggle            # toggle
doppio status            # print current state
```

```bash
# Real examples
doppio while npm run build:all
doppio while pytest -x --timeout=3600
doppio while claude          # ← the one you'll actually use
```

`doppio while` scopes the awake state to the lifetime of the process. If the command finishes, crashes, or is `kill -9`'d, your Mac goes right back to sleeping normally — the OS guarantees it. You physically cannot leave it stuck awake.

---

## 🤖 Keeping your AI agent alive

Long agent runs are the reason Doppio exists. Two ways to wire it up:

**Wrap the whole session (simplest, most reliable):**

```bash
doppio while claude
```

Awake for the entire session, asleep the instant it ends. Recommended for walk-away runs.

**Or hook the session lifecycle** (awake only while the agent is actively working):

```bash
doppio install-claude-hook
```

This prints ready-to-paste [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) that activate Doppio on `SessionStart` and release it on `SessionEnd`. Works with any tool that can run a shell command on start/stop — Cursor, aider, custom agent loops, CI-on-your-laptop, whatever.

Either way, a glance at the menu bar confirms the run is protected.

---

## URL scheme

Doppio registers the `doppio://` URL scheme, so any script or tool can control it without the CLI:

```bash
open "doppio://activate"             # turn on, no limit
open "doppio://activate?minutes=90"  # turn on for 90 minutes
open "doppio://deactivate"           # turn off
open "doppio://toggle"               # toggle
```

Useful for custom agents, CI scripts, or integrating with apps like Shortcuts or Raycast.

---

## Doppio vs. the alternatives

| | `caffeinate` | Caffeine / KYA | Amphetamine | **Doppio** |
|---|:---:|:---:|:---:|:---:|
| Menu bar toggle | ❌ | ✅ | ✅ | ✅ |
| **Visible countdown timer** | ❌ | ❌ | partial | ✅ |
| **First-class CLI** | ✅ | ❌ | ❌ | ✅ |
| **Wrap a command (`while`)** | ✅ | ❌ | ❌ | ✅ |
| **URL scheme** | ❌ | ❌ | ❌ | ✅ |
| **AI-agent integration** | ❌ | ❌ | ❌ | ✅ |
| IOKit (no child process) | n/a | mixed | ✅ | ✅ |
| Open source | ✅ | mixed | ❌ | ✅ |

---

## How it works

Doppio talks to macOS power management directly through **IOKit power assertions** (`IOPMAssertionCreateWithName`) — the same mechanism `caffeinate` uses internally, but with no subprocess, instant release, and explicit control over whether the display or just the system is kept awake.

Every session auto-releases at zero and on quit. Because IOKit assertions are owned by the process, the OS reclaims them if Doppio ever dies unexpectedly — so there's no failure mode where your Mac is stuck awake.

The one place Doppio *does* use `caffeinate` is the `doppio while <command>` wrapper, where scoping the assertion to a command's lifetime is exactly the guarantee you want: it dies with the process, even on `kill -9`.

The app is built with Swift 6 and SwiftUI (`MenuBarExtra`), targeting **macOS 26 (Tahoe)+**.

---

## Features

- 🕐 **Live countdown** in the menu bar — seconds-accurate, always visible
- ⌨️ **`doppio while <cmd>`** — keep awake for the exact life of any command
- 🌐 **URL scheme** — scriptable from anywhere (`doppio://activate?minutes=60`)
- 🤖 **AI-agent ready** — one-liner + Claude Code / Cursor hook integration
- ☕ Timed presets (15m → 5h) and an indefinite mode
- 🌙 **Allow display to sleep** — system stays awake, screen can dim
- 🚀 **Launch at login**
- 📡 **`doppio status`** — readable state from any shell script
- 🪶 Tiny and native — pure Swift, no Electron, no telemetry, no account
- 🔓 MIT licensed, runs entirely on your machine

---

## Known limitations

- **Closed lid on battery:** macOS won't let any app keep the Mac awake with the lid shut on battery power — that's a hardware/thermal rule, not something Doppio can override. For big overnight jobs, keep the lid open or connect an external display and power.
- **Not on the Mac App Store:** the `while <command>` feature spawns arbitrary processes, which the App Store sandbox forbids. Doppio is distributed directly and via Homebrew instead.

---

## Building from source

```bash
git clone https://github.com/boopathy-nr/doppio.git
cd doppio
open Doppio.xcodeproj    # Xcode 16+ required; ⌘R to build and run
```

Requires **Xcode 16+** and **macOS 26 (Tahoe)**. The CLI lives in `CLI/doppio` and works independently of the app.

```bash
# Install the CLI
cp CLI/doppio /usr/local/bin/doppio
```

---

## Contributing

Issues and PRs welcome. Good first contributions: additional shell integrations (Cursor hooks, aider hooks), localizations, and a progress-ring menu bar icon. Please open an issue before starting anything substantial.

---

## Why "Doppio"?

A *doppio* is a double shot of espresso — the thing you order when you need to stay up and get through the work. Seemed fitting for an app whose entire job is keeping your Mac awake through the long haul. ☕

---

## License

[MIT](LICENSE) © Boopathy N Ramachandran

<div align="center">
<sub>Built for everyone who's watched a two-hour job die because their Mac fell asleep.</sub>
</div>
