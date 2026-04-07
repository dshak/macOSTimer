# Flux Timer

A beautiful, native macOS countdown & stopwatch app that lives on your desktop. Built with SwiftUI. Ships with an MCP server so Claude Code can create, control, and query your timers programmatically.

That last part is the interesting bit. More on that below.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Why This Exists

I was about to start a 1-hour task and thought: "Is there a beautiful countdown timer for macOS?" Something small, stays on my screen, doesn't need a browser tab or an Electron wrapper eating 300MB of RAM.

Couldn't find one I liked. So I built one.

Then I thought — what if Claude Code could start timers for me? What if it could check how much time I have left and adjust its approach? What if it could pace a refactoring session to a deadline?

That's how the MCP server happened. The timer isn't just something you glance at — it's a time-awareness layer for your AI workflow.

## What You Get

**The Timer**
- Count up (stopwatch) or count down
- Compact floating window (240 x 120px) — tuck it anywhere
- Animated gradient backgrounds with 6 palettes that shift color as time progresses
- Frosted glass/translucent theme (macOS vibrancy)
- Per-digit flip animations, pulsing colons, urgency escalation in the final stretch
- Preset durations (30m, 1h, 2h) + custom presets
- Sound alert, macOS notification, and visual flash on completion — all toggleable per-timer, mid-run
- Editable labels, right-click context menu for theme/palette switching
- Lives in the menu bar when you don't need the window

**Multiple Timers**
- Spawn as many as you want
- Each gets its own floating window
- Drag them near each other and they snap together magnetically
- Snapped timers move as a group

**Configurable Everything**
- 5 font choices (SF Pro Rounded, SF Mono, Avenir Next, Futura, Menlo)
- Font size slider (24–48pt)
- Window opacity control
- Custom presets
- Alert sound selection with preview
- Snap threshold and gap settings
- Launch at login

**The MCP Server**
- 8 tools for full timer control from Claude Code
- 3 resources for querying state and history
- Session history logging
- Unix socket bridge to the running app

## Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build & Run

```bash
git clone https://github.com/dshak/macOSTimer.git
cd macOSTimer/FluxTimer
xcodegen generate
xcodebuild -project FluxTimer.xcodeproj -scheme FluxTimer -configuration Debug build
```

Then open the built app:

```bash
open ~/Library/Developer/Xcode/DerivedData/FluxTimer-*/Build/Products/Debug/Flux\ Timer.app
```

Or just open `FluxTimer.xcodeproj` in Xcode and hit Run.

### Resource Usage

Here's the thing about native apps — they're light:

| Resource | Target |
|---|---|
| Memory | < 30 MB |
| CPU (idle, timer running) | < 1% |
| Disk | < 5 MB |
| Battery impact | Negligible |

No Electron. No web runtime. No 400MB of Chromium.

## MCP Server — Claude Code Integration

This is where it gets fun. Flux Timer includes an MCP server that lets Claude Code talk directly to your timers.

### Setup

```bash
# Copy the MCP server binary somewhere stable
cp ~/Library/Developer/Xcode/DerivedData/FluxTimer-*/Build/Products/Debug/flux-mcp-server ~/bin/

# Add to Claude Code
claude mcp add flux-timer -- ~/bin/flux-mcp-server
```

Make sure Flux Timer is running — the MCP server communicates with the app via a Unix socket at `/tmp/flux-timer.sock`.

### Tools

| Tool | What It Does |
|---|---|
| `flux_create_timer` | Create a new timer window (countdown/countup, duration, label) |
| `flux_start_timer` | Start or resume a timer |
| `flux_pause_timer` | Pause a running timer |
| `flux_reset_timer` | Reset to initial state |
| `flux_stop_timer` | Stop and close (logs to history) |
| `flux_get_timer` | Get state, elapsed, remaining, label |
| `flux_list_timers` | List all active timers |
| `flux_update_timer` | Update label or alerts mid-run |

### Resources

| URI | Description |
|---|---|
| `flux://timers` | All active timers with full state |
| `flux://history` | Completed session log |
| `flux://settings` | Current app settings |

### What This Actually Looks Like

You say to Claude Code:

> "Let's spend 45 minutes on this refactor"

Claude creates a countdown, starts it, and you see it appear on your desktop. Midway through, Claude checks the timer:

> "15 minutes left. Let's commit what we have and defer the edge cases."

Timer completes — you get a chime, a notification, and a flash. The session is logged. Later you can ask:

> "How long did the refactor actually take?"

Claude reads the history and tells you.

You can also run pomodoro cycles, track multiple concurrent tasks, or just let Claude be aware of time without you having to think about it.

## Architecture

```
┌─────────────┐    stdio (JSON-RPC)    ┌──────────────────┐    Unix socket    ┌─────────────┐
│ Claude Code  │ ◄──────────────────► │ flux-mcp-server  │ ◄──────────────► │ Flux Timer   │
│ (MCP client) │                       │ (MCP bridge)     │                   │ (macOS app)  │
└─────────────┘                        └──────────────────┘                   └─────────────┘
```

- **Flux Timer** — SwiftUI app, manages windows, renders timers, listens on Unix socket
- **flux-mcp-server** — Separate binary, speaks MCP protocol over stdio, bridges to the app via socket
- **Communication** — Newline-delimited JSON over `/tmp/flux-timer.sock`

### Project Structure

```
FluxTimer/
├── project.yml                    # XcodeGen project definition
├── FluxTimer/
│   ├── App/                       # App entry, delegate
│   ├── Models/                    # TimerModel, AppSettings, presets, themes
│   ├── Views/
│   │   ├── Timer/                 # TimerView, digits, controls, setup
│   │   ├── Backgrounds/           # Animated gradient, glass/vibrancy
│   │   ├── MenuBar/               # Status bar controller
│   │   └── Settings/              # Preferences window (4 tabs)
│   ├── Window/                    # Custom NSWindow, WindowManager, SnapManager
│   ├── Services/                  # TimerEngine, SocketServer, sound, notifications
│   └── Resources/                 # App icon, asset catalog
└── FluxMCPServer/                 # Standalone MCP server executable
    ├── main.swift                 # stdio transport loop
    ├── MCPProtocol.swift          # JSON-RPC types
    ├── ToolHandlers.swift         # Tool implementations
    ├── ResourceHandlers.swift     # Resource reads
    └── SocketClient.swift         # Unix socket client
```

## Performance Notes

A few decisions that keep this light:

- **Timer ticks at 1Hz** — only bumps to 10Hz for centiseconds display or the final 10-second countdown
- **`displaySeconds` is the only published property** that drives UI — `elapsed` updates internally without triggering SwiftUI diffs
- **Gradient uses GPU-accelerated rotation transforms** — no Canvas redraws, no CPU-side rendering
- **Urgency pulse uses `TimelineView`** — runs only during the final countdown, zero cost otherwise

## Contributing

PRs welcome. A few things on the roadmap:

- [ ] More gradient palettes / custom palette editor
- [ ] Keyboard shortcuts (global hotkeys)
- [ ] Export session history (CSV/JSON)
- [ ] Compact "mini" mode (even smaller window)
- [ ] Widget for macOS desktop/notification center

## License

MIT — do whatever you want with it.

## Credits

Built by [Dave Shak](https://daveshak.com) with Claude Code.

The entire app — design doc, 34 Swift files, MCP server, app icon — was built in a single pairing session. That's not magic. That's what happens when you give an AI the right tools and get out of the way.
