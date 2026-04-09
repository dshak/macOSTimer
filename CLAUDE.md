# Flux Timer — Project Guide

## Overview
Native macOS SwiftUI countdown/stopwatch app with MCP server for Claude Code integration.
Repo: https://github.com/dshak/macOSTimer

## Build & Run
```bash
cd FluxTimer
xcodegen generate              # Regenerate after adding/removing Swift files
xcodebuild -project FluxTimer.xcodeproj -scheme FluxTimer -configuration Debug build
xcodebuild -project FluxTimer.xcodeproj -scheme FluxMCPServer -configuration Debug build
```

### Deploy to /Applications (IMPORTANT: must rm -rf first, cp -R merges instead of replacing)
```bash
rm -rf "/Applications/Flux Timer.app"
cp -R ~/Library/Developer/Xcode/DerivedData/FluxTimer-*/Build/Products/Debug/Flux\ Timer.app "/Applications/Flux Timer.app"
```

### MCP server binary
```bash
cp ~/Library/Developer/Xcode/DerivedData/FluxTimer-*/Build/Products/Debug/flux-mcp-server ~/bin/flux-mcp-server
```
Configured in Claude Code as `flux-timer` MCP server pointing to `~/bin/flux-mcp-server`.

## Architecture
- **FluxTimer/** — macOS app (SwiftUI + AppKit). LSUIElement (no dock icon, lives in menu bar).
- **FluxMCPServer/** — Separate CLI binary, speaks MCP over stdio, bridges to app via Unix socket at `/tmp/flux-timer.sock`.
- **project.yml** — XcodeGen config. Run `xcodegen generate` after adding/removing files.

## Key Technical Decisions

### Window management
- Borderless `NSWindow` with `isMovableByWindowBackground = true`
- This means **SwiftUI buttons inside the window don't receive clicks** — the window drag intercepts them
- Workaround: any clickable NSView must use `NSViewRepresentable` with `mouseDownCanMoveWindow = false` (see `DragDigitNSView`, `CloseButtonNSView`, `NativeCloseButton`)
- Close button uses `NativeCloseButton` (NSViewRepresentable) — draws its own X with Core Graphics
- Window close triggers `exit(0)` when last timer closes (NSApp.terminate didn't work with SwiftUI lifecycle)

### Menu bar (StatusBarController)
- **Must inherit from NSObject** — without it, @objc selector targets silently fail at runtime
- `statusItem` declared as `NSStatusItem!` (implicitly unwrapped) so `super.init()` can be called first
- Menu is rebuilt every 1 second via updateDisplay timer
- Preferences opens `AppDelegate.showSettings()` which creates an NSWindow directly (SwiftUI Settings scene doesn't work for LSUIElement apps)

### Timer performance
- Timer engine ticks at **1Hz normally**, switches to **10Hz** for centiseconds display or final 10 seconds
- `elapsed` on TimerModel is **NOT @Published** — only `displaySeconds: Int` is published, triggering SwiftUI diffs once per second
- Gradient background uses **GPU-accelerated rotation transforms** (LinearGradient + .rotationEffect), NOT Canvas/TimelineView
- Urgency pulse uses a **TimelineView** that only renders when urgencyTier > 0 — no `.repeatForever` animations (those leak and can't be reliably cancelled in SwiftUI)

### Animation gotchas
- **Never use `.animation(.repeatForever, value:)` modifier** — SwiftUI doesn't cancel these reliably when the value changes back. Use TimelineView + sin() for repeating visual effects instead.
- **Never use `.animation(value: model.state)` broadly** — it applies implicit animation to ALL view changes when state changes, interfering with other animations.
- Pause blink uses `onChange(of: model.state)` with explicit `withAnimation` to start/stop.
- Per-digit flip animation: each digit is a separate `FlipDigit` view so only changing digits animate.

### MCP server
- 8 tools: create, start, pause, reset, stop, get, list, update
- 3 resources: flux://timers, flux://history, flux://settings
- Socket protocol: newline-delimited JSON over Unix domain socket
- `FluxProtocol.swift` in the app defines shared types (FluxRequest, FluxResponse, FluxAction)
- `MCPProtocol.swift` in FluxMCPServer defines MCP JSON-RPC types with AnyCodableValue for flexible JSON

## Known Issues
- Context menu items that call AppDelegate methods (like Preferences) don't work from SwiftUI right-click menus — the `NSApp.delegate as? AppDelegate` cast fails in that context. Use menu bar instead.
- Stale `flux-mcp-server` processes accumulate across Claude Code sessions. Kill with `pkill -f flux-mcp-server`.

## File Structure Quick Reference
- `App/AppDelegate.swift` — launches WindowManager, StatusBar, SocketServer, Settings window
- `Models/TimerModel.swift` — @Published displaySeconds drives UI, non-published elapsed for precision
- `Models/AppSettings.swift` — singleton, all settings persisted via UserDefaults
- `Services/TimerEngine.swift` — adaptive tick rate, wall-clock timing
- `Services/SocketServer.swift` — handles all MCP bridge actions
- `Services/SnapManager.swift` — magnetic window snapping with group dragging
- `Views/Timer/TimerView.swift` — main composite view, urgency via UrgencyPulseWrapper
- `Views/Timer/TimerSetupView.swift` — DragDigit uses NSViewRepresentable for click-drag time input
- `Views/MenuBar/MenuBarView.swift` — StatusBarController (NSObject subclass!)
- `Window/TimerWindow.swift` — borderless NSWindow + NativeCloseButton + DraggableBackgroundView
- `Window/WindowManager.swift` — creates/tracks/closes timers, quit on last close
