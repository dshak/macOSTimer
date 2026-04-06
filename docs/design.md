# Flux Timer — macOS Countdown & Stopwatch

## Design Philosophy

**Concept: "Time as Liquid Light"**

Flux treats time not as a rigid mechanical countdown but as a living, flowing substance. The timer is a small jewel on your desktop — a glowing droplet of color that breathes and shifts as seconds pass. When time runs out, it doesn't just beep — it *erupts*.

The name **Flux** captures the duality: time is always in flux, and the visual design flows like a flux of light and color across the compact window.

**What makes it unforgettable:** The gradient palette *evolves* as the timer progresses — a 60-minute countdown starts as cool ocean blue and slowly warms to urgent amber-red as it approaches zero. Time becomes color. You can *feel* how much time remains without reading the digits.

---

## Visual Identity

### Typography

**Primary Display Font: SF Pro Rounded (Bold/Heavy)**
- Ships with macOS — zero bundle cost
- The rounded terminals feel friendly and modern, not clinical
- Tabular (monospaced) figures prevent layout jitter as digits change
- Fallback: SF Pro Display for a sharper, more serious feel

**Secondary/Alternative Display Fonts (User Configurable):**
- **SF Mono Rounded** — for a developer/technical aesthetic
- **Avenir Next (Demi Bold)** — geometric, clean, European feel
- **Futura Medium** — Bauhaus-inspired, bold personality
- **Menlo** — monospaced, retro-terminal charm

**Label/Control Font: SF Pro Text (Medium)**
- Small labels, timer names, preset labels
- 10–12pt, tracking +0.5 for readability at small sizes

### Color System

#### Gradient Palettes (Colorful Mode)

Each palette defines a 3-stop gradient that animates through a journey as the timer progresses:

| Palette Name | Start (100%) | Midpoint (50%) | End (0% / Elapsed) | Mood |
|---|---|---|---|---|
| **Solar Flare** | `#FF6B35` → `#F72585` | `#B5179E` → `#7209B7` | `#560BAD` → `#480CA8` | Warm urgency → deep intensity |
| **Deep Ocean** | `#0077B6` → `#0096C7` | `#00B4D8` → `#48CAE4` | `#90E0EF` → `#CAF0F8` | Calm depth → bright surface |
| **Northern Lights** | `#06D6A0` → `#1B9AAA` | `#EF476F` → `#F78C6B` | `#FFD166` → `#FCEC52` | Ethereal → fiery |
| **Midnight Ember** | `#1A1A2E` → `#16213E` | `#0F3460` → `#533483` | `#E94560` → `#FF6B6B` | Darkness → glowing coals |
| **Lavender Dusk** | `#E0AAFF` → `#C77DFF` | `#9D4EDD` → `#7B2CBF` | `#5A189A` → `#3C096C` | Soft → concentrated |
| **Citrus Burst** | `#F9C74F` → `#F9844A` | `#F8961E` → `#F3722C` | `#F94144` → `#E71D36` | Warm → hot |

**Count-Up Mode:** Gradient starts neutral and intensifies over time.
**Count-Down Mode:** Gradient follows the palette's full journey from start → end as time depletes.

#### Glassy/Translucent Mode Colors

- **Background:** `NSVisualEffectView` with `.hudWindow` material + `.behindWindow` blending
- **Primary text:** `#FFFFFF` at 95% opacity
- **Secondary text:** `#FFFFFF` at 60% opacity
- **Accent glow:** Soft colored border derived from the selected gradient palette (first color at 30% opacity)
- **Hover state overlay:** `#FFFFFF` at 5% opacity
- **Dividers/separators:** `#FFFFFF` at 10% opacity

#### Semantic Colors

| Token | Light Context | Dark Context | Usage |
|---|---|---|---|
| `alertSuccess` | `#06D6A0` | `#06D6A0` | Timer complete (count-up milestone) |
| `alertUrgent` | `#E71D36` | `#FF6B6B` | Final 10% of countdown |
| `controlActive` | `#4CC9F0` | `#4CC9F0` | Toggle on state |
| `controlInactive` | `#6C757D` | `#ADB5BD` | Toggle off state |

---

## Component Architecture

### Window Anatomy (Compact Mode — Default)

```
┌─────────────────────────────────┐
│  ┌─ gradient/glass background ─┐ │
│  │                             │ │
│  │    ╔═══════════════════╗    │ │  ← Timer Display (hero)
│  │    ║    23 : 45 . 12   ║    │ │     SF Pro Rounded Heavy, 36pt
│  │    ╚═══════════════════╝    │ │
│  │                             │ │
│  │    ┌─┐ ┌─┐ ┌─┐      ··    │ │  ← Alert toggles (sound, notif, flash)
│  │    │🔊│ │🔔│ │⚡│     label │ │     + optional timer label
│  │    └─┘ └─┘ └─┘             │ │
│  └─────────────────────────────┘ │
│         [hover control bar]      │  ← Appears on mouse hover
│    ▶/⏸   ⏹   ⟲   ⊕   ⚙       │     Play/Pause, Stop, Reset, New Timer, Settings
└─────────────────────────────────┘
```

**Dimensions:**
- Default: **240 x 120 pt** (compact)
- With controls visible: **240 x 156 pt** (controls slide in from bottom)
- Minimum: **180 x 90 pt** (user can resize smaller)
- Maximum: **400 x 200 pt**

**Window Properties:**
- `NSWindow.StyleMask`: `.borderless` — no title bar
- `NSWindow.Level`: `.floating` (configurable, can be set to `.normal`)
- Corner radius: **16pt**
- Shadow: `NSShadow` with `shadowBlurRadius: 20`, `shadowOffset: (0, -4)`, `shadowColor: black at 25%`
- Resizable via corner drag handle (subtle, appears on hover)

### Component Hierarchy

```
FluxApp (App)
├── AppDelegate
│   ├── StatusBarController          — Menu bar icon + dropdown
│   └── WindowManager                — Creates/tracks/snaps timer windows
│
├── TimerWindow (NSWindow subclass)  — One per timer instance
│   ├── TimerHostingView             — SwiftUI hosting wrapper
│   │   └── TimerView               — Main SwiftUI view
│   │       ├── TimerDisplayView     — The big digits
│   │       │   ├── DigitGroup       — Hours:Minutes:Seconds
│   │       │   └── Separator        — Animated colon/dot separators
│   │       ├── AlertToggleBar       — Sound/Notification/Flash toggles
│   │       ├── TimerLabelView       — Optional editable name
│   │       └── ControlBar           — Play/Pause/Stop/Reset (hover reveal)
│   │
│   ├── GradientBackgroundView       — Animated gradient layer
│   └── GlassBackgroundView          — Vibrancy/blur layer
│
├── Models
│   ├── TimerModel (ObservableObject) — Timer state, elapsed/remaining
│   ├── TimerPreset                   — Preset durations
│   ├── ThemeConfiguration            — Colors, fonts, opacity
│   └── AlertConfiguration            — Sound/notif/flash toggles
│
├── Services
│   ├── TimerEngine                   — High-precision timing (DispatchSource)
│   ├── SoundManager                  — Alert sound playback
│   ├── NotificationManager           — UNUserNotificationCenter
│   └── SnapManager                   — Window magnetic snapping logic
│
├── Settings
│   ├── SettingsWindow                — Preferences panel
│   │   ├── AppearanceTab            — Theme, palette, font, opacity
│   │   ├── PresetsTab               — Manage timer presets
│   │   ├── AlertsTab                — Default alert config
│   │   └── GeneralTab               — Launch at login, menu bar behavior
│   └── UserDefaults+Extensions      — Persisted settings
│
└── Resources
    ├── AlertSounds/                  — Bundled .caf audio files
    └── Assets.xcassets               — App icon, gradient textures
```

---

## Detailed Component Specifications

### 1. TimerDisplayView — The Hero Element

The timer digits are the single most important visual element. They must be:
- **Instantly readable** from 3+ feet away at default size
- **Stable** — no layout jitter when digits change (tabular figures)
- **Beautiful** — the typeface IS the design

**Layout:**

```
    HH : MM : SS . cc
    └──┘   └──┘   └──┘  └─┘
     36pt   36pt   36pt  18pt (centiseconds, optional)
```

- Hours hidden when < 1 hour (show `MM : SS` only for compactness)
- Centiseconds shown only in count-up/stopwatch mode
- Colon separators: 60% opacity, with a subtle pulse animation (opacity 60% → 40% → 60% over 1s) while running
- When paused: digits and colons blink (opacity 100% → 30% → 100%, 0.8s cycle)

**Digit Transition Animation:**
- When a digit changes, the old digit slides up and fades out while the new digit slides in from below and fades in
- Duration: 200ms, `easeOut` curve
- Only the changing digit animates — others remain static
- This creates a subtle "flip clock" feel without literal flip styling

**Urgency Escalation (Countdown Mode):**
- Last 25%: digits scale up slightly (1.0 → 1.02) with a gentle pulse
- Last 10%: pulse rate increases, gradient shifts to warm/urgent colors
- Last 10 seconds: each second triggers a brief scale bump (1.0 → 1.05 → 1.0, 150ms)
- At 0:00: full-window flash (white overlay at 80% → 0%, 3 cycles over 1.5s)

### 2. AlertToggleBar

Three small circular toggle buttons, always visible (not hidden behind hover):

```
  ┌───┐  ┌───┐  ┌───┐
  │ 🔊 │  │ 🔔 │  │ ⚡ │
  └───┘  └───┘  └───┘
  Sound   Notif  Flash
```

**Specs:**
- Size: **22 x 22 pt** each, with 6pt spacing
- Active state: icon at full opacity + subtle glow ring (accent color, 2pt, 40% opacity)
- Inactive state: icon at 40% opacity, no glow
- Tap to toggle — instant state change, no animation delay
- Icons: SF Symbols — `speaker.wave.2.fill`, `bell.fill`, `bolt.fill`
- Positioned: bottom-left of timer face, 8pt from edge

### 3. ControlBar (Hover Reveal)

Controls that appear when the mouse enters the timer window:

```
  ▶ / ⏸     ⏹      ⟲       ⊕       ⚙
  Play/     Stop   Reset   New     Settings
  Pause                    Timer
```

**Reveal Animation:**
- Mouse enters window → controls slide up from bottom over 200ms (`easeOut`)
- Slight blur/darken overlay on the bottom 36pt of the window
- Mouse exits window → controls slide down and disappear over 300ms (`easeInOut`)
- Controls remain visible while any button is being hovered/pressed

**Button Specs:**
- SF Symbols: `play.fill`/`pause.fill`, `stop.fill`, `arrow.counterclockwise`, `plus`, `gearshape.fill`
- Size: **28 x 28 pt** touch/click targets
- Hover: scale 1.0 → 1.15, with 100ms spring animation
- Press: scale down to 0.95, 50ms
- Color: white at 80% opacity (glassy mode) or contrasting light/dark against gradient

### 4. GradientBackgroundView

**Implementation: `TimelineView` + `Canvas` or `MeshGradient` (macOS 14+)**

The gradient is not static — it breathes and evolves:

**Ambient Animation (Always Running):**
- Two overlapping radial gradients rotate slowly in opposite directions
- Rotation speed: 360 degrees per 30 seconds (very slow, almost imperceptible)
- Creates a shimmering, lava-lamp-like effect without being distracting
- Implemented via `Canvas` with `drawLayer` for performance

**Progress-Linked Animation (Countdown Mode):**
- The gradient palette interpolates based on timer progress
- At 100% remaining: palette start colors dominate
- At 50%: midpoint colors
- At 0%: end colors
- Interpolation is smooth and continuous — `Color.interpolate()` via HSB space for perceptually smooth transitions

**Performance:**
- Gradient rendering targets 30fps (not 60) — sufficient for slow ambient motion, halves GPU load
- Use `drawingGroup()` modifier to rasterize the gradient layer
- Timer precision engine runs independently from UI updates

### 5. GlassBackgroundView

**Implementation: `NSVisualEffectView` wrapped in `NSViewRepresentable`**

```swift
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow        // dark translucent
        view.blendingMode = .behindWindow  // blurs desktop behind
        view.state = .active
        view.isEmphasized = true
        return view
    }
}
```

**Enhancements over raw vibrancy:**
- Subtle 1pt inner border: white at 15% opacity (catches light, defines edge)
- Outer glow: 4pt blur of the selected accent color at 20% opacity
- Corner radius matches window: 16pt, clipped with `RoundedRectangle`

### 6. Timer Setup / Preset Selector

When creating a new timer or resetting, a setup overlay appears:

```
┌─────────────────────────────────┐
│                                 │
│     ┌──────┐ ┌──────┐ ┌──────┐ │  ← Preset pills
│     │ 30m  │ │  1h  │ │  2h  │ │
│     └──────┘ └──────┘ └──────┘ │
│                                 │
│     ┌──────────────────────┐    │  ← Custom time input
│     │   00 : 30 : 00       │    │     Scroll wheels or direct type
│     └──────────────────────┘    │
│                                 │
│     ┌──────┐         ┌──────┐  │
│     │Count↑│         │Count↓│  │  ← Mode selector
│     └──────┘         └──────┘  │
│                                 │
│           [ Start ▶ ]           │
│                                 │
└─────────────────────────────────┘
```

**Preset Pills:**
- Rounded rectangle, 60 x 32 pt
- Unselected: semi-transparent fill, light text
- Selected: filled with accent color, bold text
- Custom presets added via Settings, appear in same row (scrollable if > 5)

**Time Input:**
- Three scroll-wheel selectors (hours, minutes, seconds)
- Mousewheel/trackpad scroll to change values
- Or click a digit group to type directly
- Large, clear digits in the same display font

**Mode Toggle:**
- Two pill buttons: "Count Up" / "Count Down"
- Segmented control style
- Count Up starts from 00:00 and goes up
- Count Down starts from the set time and goes to 00:00

### 7. StatusBarController (Menu Bar Integration)

**Menu Bar Item:**
- When at least one timer is running, show: `⏱ 23:45` (most recent/primary timer)
- When multiple timers running: `⏱ 23:45 | 01:15:30` (up to 2 shown, then `⏱ 2 timers`)
- When all paused: `⏸ 23:45` (paused icon)
- When no timers: just the app icon (small `⏱` monochrome)

**Menu Bar Dropdown:**

```
┌──────────────────────────────────┐
│  Flux Timers                     │
│  ─────────────────────────────── │
│  ⏱ Focus Block       23:45  ▶⏸ │  ← Each timer row
│  ⏱ Break Timer     01:15:30  ▶⏸ │     with inline play/pause
│  ─────────────────────────────── │
│  ⊕ New Timer                     │
│  ─────────────────────────────── │
│  ⚙ Preferences...               │
│  ⏻ Quit Flux                    │
└──────────────────────────────────┘
```

- Click a timer row → brings its window to front / unminimizes
- Inline play/pause button on each row
- Styled with standard `NSMenu` for native feel (not custom-drawn)

---

## Window Management & Snapping

### Magnetic Snapping System

**Detection:**
- On window drag (`NSWindow.move` notifications), calculate distances between all timer window edges
- Compare: left↔right, top↔bottom, left↔left, top↔top (alignment snapping)
- Snap threshold: **20pt**

**Snap Behavior:**
- When within threshold, window jumps to exact alignment (0pt gap or configurable 2pt gap)
- Brief haptic-like visual feedback: subtle scale pulse (1.0 → 1.01 → 1.0) on both windows
- A faint colored line appears briefly at the snap edge (accent color, 2pt, fades over 300ms)

**Group Dragging:**
- Snapped windows form a group tracked by `SnapManager`
- When dragging any window in a group, all grouped windows move together
- Dragging away with enough velocity (> threshold) detaches from group
- Data structure: a simple graph — nodes are windows, edges are snap connections with edge metadata (which sides are snapped)

**Implementation:**

```swift
class SnapManager {
    struct SnapEdge {
        let windowA: NSWindow
        let windowB: NSWindow
        let sideA: Edge  // .left, .right, .top, .bottom
        let sideB: Edge
    }
    
    private var snapGroups: [[NSWindow]] = []
    private var activeSnaps: [SnapEdge] = []
    
    func windowDidMove(_ window: NSWindow) {
        let candidates = allTimerWindows.filter { $0 != window }
        for candidate in candidates {
            if let snap = detectSnap(moving: window, target: candidate) {
                applySnap(snap)
            }
        }
    }
    
    func detectSnap(moving: NSWindow, target: NSWindow) -> SnapEdge? {
        let threshold: CGFloat = 20
        let mf = moving.frame
        let tf = target.frame
        
        // Right edge of moving → Left edge of target
        if abs(mf.maxX - tf.minX) < threshold && rangesOverlap(mf.minY...mf.maxY, tf.minY...tf.maxY) {
            return SnapEdge(windowA: moving, windowB: target, sideA: .right, sideB: .left)
        }
        // ... (check all 4 edge combinations)
        return nil
    }
}
```

---

## Animation Specifications

| Animation | Trigger | Duration | Curve | Details |
|---|---|---|---|---|
| Gradient ambient rotation | Always (when gradient theme) | 30s full cycle | Linear | Two counter-rotating radial gradients |
| Gradient progress shift | Timer progress change | Continuous | Linear interpolation | HSB color space interpolation |
| Digit flip | Digit value change | 200ms | `.easeOut` | Old slides up + fades, new slides in from below |
| Colon pulse | Timer running | 1000ms cycle | `.easeInOut` | Opacity 60% → 40% → 60% |
| Pause blink | Timer paused | 800ms cycle | `.easeInOut` | Full display opacity 100% → 30% → 100% |
| Urgency pulse | Last 25% of countdown | 2000ms cycle | `.easeInOut` | Scale 1.0 → 1.02 → 1.0 |
| Final countdown bump | Last 10 seconds | 150ms per second | `.spring(dampingFraction: 0.5)` | Scale 1.0 → 1.05 → 1.0 |
| Completion flash | Timer hits 0:00 | 500ms × 3 cycles | `.easeOut` | White overlay 80% → 0% opacity |
| Control bar reveal | Mouse enter window | 200ms | `.easeOut` | Slide up from bottom, Y offset 36 → 0 |
| Control bar dismiss | Mouse exit window | 300ms | `.easeInOut` | Slide down, Y offset 0 → 36 |
| Button hover | Mouse enter button | 100ms | `.spring` | Scale 1.0 → 1.15 |
| Button press | Mouse down on button | 50ms | `.easeIn` | Scale 1.15 → 0.95 |
| Snap feedback | Windows snap together | 300ms | `.easeOut` | Scale pulse 1.0 → 1.01 → 1.0 + edge line fade |
| Window appear | New timer created | 350ms | `.spring(dampingFraction: 0.7)` | Scale from 0.8 → 1.0, opacity 0 → 1 |
| Window dismiss | Timer closed | 250ms | `.easeIn` | Scale 1.0 → 0.9, opacity 1 → 0 |
| Theme switch | User toggles theme | 400ms | `.easeInOut` | Cross-fade between gradient and glass backgrounds |

---

## Interaction Patterns

### Creating a Timer
1. Click `⊕` in menu bar dropdown, or `⊕` button on an existing timer's control bar
2. Setup overlay appears (see Section 6)
3. Select preset or set custom time
4. Choose Count Up or Count Down
5. Optionally set a label name
6. Press Start → new window appears with spring animation, timer begins

### Pausing / Resuming
- Hover over timer window → control bar appears → click `⏸` / `▶`
- Or click the timer digits directly (large tap target) as a shortcut

### Resetting
- Hover → control bar → click `⟲`
- Timer returns to initial value (countdown) or 00:00 (stopwatch)
- Brief rewind animation: digits blur and snap to reset value (150ms)

### Closing a Timer
- Hover → a small `✕` appears in top-right corner (8pt circle, appears at 50% opacity)
- Click `✕` → confirmation only if timer is actively running
- Closed timer removes from menu bar list

### Changing Theme Mid-Timer
- Right-click on timer window → context menu with theme options
- Or access via Settings (`⚙`) on control bar
- Cross-fade transition between gradient and glass (400ms)

### Editing Timer Label
- Double-click on the label area (or the empty space below digits if no label)
- Inline text field appears, pre-selected
- Enter to confirm, Escape to cancel
- Max 20 characters, truncated with ellipsis in compact view

---

## Settings / Preferences Window

Standard macOS preferences window with tabs:

### Appearance Tab
- **Theme:** Segmented control — `Gradient` | `Glass`
- **Palette:** Grid of gradient swatches (6 built-in + custom)
- **Font:** Dropdown with live preview of each font showing "12:34:56"
- **Font Size:** Slider with live preview (range: 24pt — 48pt for timer display)
- **Window Opacity:** Slider 40% — 100% (primarily affects glass mode)
- **Always on Top:** Toggle
- **Show Centiseconds:** Toggle

### Presets Tab
- List of presets with duration and label
- Built-in presets are not deletable (but can be hidden)
- `+` button to add custom preset
- Drag to reorder
- Swipe/delete to remove custom presets

### Alerts Tab
- **Default Sound:** Dropdown (system sounds + 3-4 bundled custom sounds)
- **Default Notification:** Toggle
- **Default Flash:** Toggle
- **Sound Volume:** Slider
- These are defaults — each timer can override individually

### General Tab
- **Launch at Login:** Toggle
- **Show in Menu Bar:** Toggle (always on by default)
- **Menu Bar Display:** `Most Recent Timer` | `All Timers` | `Icon Only`
- **Snap Threshold:** Slider 10pt — 40pt
- **Snap Gap:** 0pt or 2pt toggle

---

## Technical Architecture

### Timer Engine

The timer must be **precise and power-efficient**. No `Timer.scheduledTimer` with 10ms intervals.

```swift
class TimerEngine: ObservableObject {
    @Published var elapsed: TimeInterval = 0
    @Published var state: TimerState = .idle  // .idle, .running, .paused, .completed
    
    private var startDate: Date?
    private var accumulatedBeforePause: TimeInterval = 0
    private var displayLink: CVDisplayLink?
    
    // Use CVDisplayLink for smooth UI updates (synced to display refresh)
    // But calculate elapsed time from wall clock (Date), not frame counting
    // This ensures accuracy even if frames are dropped
    
    var currentElapsed: TimeInterval {
        guard let start = startDate else { return accumulatedBeforePause }
        return accumulatedBeforePause + Date().timeIntervalSince(start)
    }
    
    func start() {
        startDate = Date()
        state = .running
        startDisplayLink()
    }
    
    func pause() {
        accumulatedBeforePause = currentElapsed
        startDate = nil
        state = .paused
        stopDisplayLink()
    }
}
```

**Key decisions:**
- Wall-clock based timing (not frame-counting) for accuracy
- `CVDisplayLink` for UI refresh (vsync'd, power efficient, pauses when window occluded)
- Display updates at screen refresh rate when visible, drops to 1Hz when in menu bar only
- `DispatchSourceTimer` as fallback for when CVDisplayLink is unavailable

### Data Persistence

**UserDefaults for:**
- Theme selection, font, palette, opacity
- Alert defaults
- Window positions (restored on relaunch)
- Preset list

**No Core Data / SQLite needed** — the data is tiny and simple.

```swift
struct TimerPreset: Codable, Identifiable {
    let id: UUID
    var label: String
    var duration: TimeInterval
    var isBuiltIn: Bool
}

struct AppSettings: Codable {
    var theme: Theme           // .gradient, .glass
    var gradientPalette: String // palette identifier
    var fontName: String
    var fontSize: CGFloat
    var windowOpacity: Double
    var alwaysOnTop: Bool
    var showCentiseconds: Bool
    var snapThreshold: CGFloat
    var snapGap: CGFloat
    var launchAtLogin: Bool
    var menuBarDisplay: MenuBarDisplayMode
    var defaultAlerts: AlertConfiguration
}
```

### App Lifecycle

```
Launch
  ├── Initialize StatusBarController (menu bar always present)
  ├── Restore previous session (if any saved timers were running)
  │   ├── Recalculate elapsed time from saved timestamps
  │   └── Recreate windows at saved positions
  └── If no previous session → show single new timer setup
  
Running
  ├── Multiple TimerWindow instances managed by WindowManager
  ├── Each window owns its own TimerEngine
  ├── SnapManager observes all window positions
  └── StatusBarController polls active timers at 1Hz for menu bar text
  
Minimize (⌘H or window close with running timer)
  ├── Windows hide, timers continue
  ├── Menu bar shows active timers
  └── Click menu bar → restore windows

Quit
  ├── Save running timer states (elapsed, mode, position)
  ├── Save all settings
  └── Clean exit
```

### Resource Budget

Target resource usage (essential for the user's requirement):

| Resource | Target | Strategy |
|---|---|---|
| **Memory** | < 25 MB idle, < 40 MB with 4 timers | Native SwiftUI, no web runtime |
| **CPU (idle)** | < 0.5% | CVDisplayLink pauses when occluded; gradient at 30fps |
| **CPU (active, 1 timer visible)** | < 2% | Minimal view redraws via `@Published` diffing |
| **GPU** | Minimal | `drawingGroup()` rasterization, no heavy Metal shaders |
| **Disk** | < 5 MB app bundle | System fonts, SF Symbols, small sound files |
| **Battery impact** | "No notable impact" | Respect `NSProcessInfo` power assertions, reduce work on battery |

### MCP Server — Claude Code Integration

Flux Timer embeds a lightweight MCP (Model Context Protocol) server, allowing Claude Code (and any MCP-compatible client) to create, control, and query timers programmatically. This turns Flux from a passive visual tool into a **time-awareness layer** for AI-assisted workflows.

#### Why MCP?

- **Auto-start timers from conversation** — "I want to spend 1 hour on this refactor" → Claude creates and starts a countdown labeled "Refactor" without you touching the mouse
- **Pace work to the clock** — Claude reads remaining time and adjusts strategy: ambitious early, wrap-up mode when time is low
- **Track actual time spent** — Claude starts a count-up timer at task start, reads the elapsed time when done, logs it
- **Pomodoro automation** — Claude orchestrates work/break cycles end-to-end
- **Multi-timer task orchestration** — "I have 2 hours: fix auth bug, write tests, update docs" → Claude creates 3 timers with estimated splits
- **Session history** — Completed timers are logged; Claude can answer "how long did the refactor take?"
- **Interrupt awareness** — If a timer has been paused a long time, Claude knows you got pulled away and can recap

#### Transport: stdio (Standard I/O)

The MCP server runs as a **standalone executable** (`flux-mcp-server`) that communicates via stdin/stdout using the MCP JSON-RPC protocol. This is the standard MCP transport for Claude Code integration.

- The server binary is bundled alongside the main Flux Timer app
- Claude Code launches it as a subprocess when configured
- The server communicates with the running Flux Timer app via a lightweight local Unix domain socket (`/tmp/flux-timer.sock`)
- If Flux Timer isn't running, the MCP server returns clear errors ("Flux Timer is not running")

```
┌─────────────┐    stdio (JSON-RPC)    ┌──────────────────┐    Unix socket    ┌─────────────┐
│ Claude Code  │ ◄──────────────────► │ flux-mcp-server  │ ◄──────────────► │ Flux Timer   │
│ (MCP client) │                       │ (MCP bridge)     │                   │ (macOS app)  │
└─────────────┘                        └──────────────────┘                   └─────────────┘
```

#### Claude Code Configuration

Users add to their Claude Code MCP settings (`~/.claude/settings.json` or project-level):

```json
{
  "mcpServers": {
    "flux-timer": {
      "command": "/Applications/Flux Timer.app/Contents/MacOS/flux-mcp-server",
      "args": []
    }
  }
}
```

#### MCP Tools

| Tool | Parameters | Returns | Description |
|---|---|---|---|
| `flux_create_timer` | `mode`: "countdown" \| "countup", `duration?`: seconds (required for countdown), `label?`: string | `{ timer_id, state, mode, duration, label }` | Creates a new timer window. Does NOT auto-start — call `flux_start_timer` to begin. |
| `flux_start_timer` | `timer_id`: string | `{ timer_id, state, started_at }` | Starts or resumes a paused/idle timer. |
| `flux_pause_timer` | `timer_id`: string | `{ timer_id, state, elapsed }` | Pauses a running timer. |
| `flux_reset_timer` | `timer_id`: string | `{ timer_id, state, elapsed: 0 }` | Resets timer to initial state (countdown: back to duration, countup: back to 0). |
| `flux_stop_timer` | `timer_id`: string | `{ timer_id, final_elapsed }` | Stops and closes the timer window. Logs to session history. |
| `flux_get_timer` | `timer_id`: string | `{ timer_id, state, mode, elapsed, remaining, label, alerts }` | Reads current state of a specific timer. |
| `flux_list_timers` | *(none)* | `{ timers: [{ timer_id, state, mode, elapsed, remaining, label }] }` | Lists all active timers. |
| `flux_update_timer` | `timer_id`: string, `label?`: string, `alerts?`: `{ sound, notification, flash }` | `{ timer_id, updated_fields }` | Updates label or alert toggles on a running timer. |

#### MCP Resources

| URI | Description |
|---|---|
| `flux://timers` | Live list of all active timers with full state (subscribable for real-time updates) |
| `flux://history` | Completed session log — timer_id, label, mode, duration, actual_elapsed, started_at, completed_at |
| `flux://settings` | Current app settings (theme, palette, font — read-only via MCP) |

#### Internal Communication Protocol

The MCP bridge (`flux-mcp-server`) talks to the running Flux Timer app over a Unix domain socket at `/tmp/flux-timer.sock`. The app starts listening on this socket at launch.

**Protocol:** Simple JSON messages over the socket, one per line (newline-delimited JSON):

```swift
// Request (MCP server → Flux app)
struct FluxRequest: Codable {
    let id: String           // correlation ID
    let action: String       // "create", "start", "pause", "reset", "stop", "get", "list", "update"
    let timerId: String?     // target timer (nil for "create" and "list")
    let params: [String: AnyCodable]?  // action-specific parameters
}

// Response (Flux app → MCP server)
struct FluxResponse: Codable {
    let id: String           // matching correlation ID
    let success: Bool
    let data: [String: AnyCodable]?    // result payload
    let error: String?       // error message if success == false
}
```

**Socket Lifecycle:**
- Flux Timer app creates and listens on `/tmp/flux-timer.sock` at launch
- Cleans up (deletes) the socket file on quit
- The MCP server connects when Claude Code invokes a tool, disconnects after response
- Multiple MCP server instances can connect simultaneously (each tool call is independent)

#### Session History Storage

Completed timer sessions are persisted to a simple JSON file for the `flux://history` resource:

```
~/Library/Application Support/FluxTimer/session_history.json
```

```json
[
  {
    "timer_id": "abc-123",
    "label": "Refactor auth module",
    "mode": "countdown",
    "configured_duration": 3600,
    "actual_elapsed": 3247,
    "started_at": "2026-04-06T10:00:00Z",
    "completed_at": "2026-04-06T10:54:07Z",
    "completion_reason": "finished"  // "finished", "stopped", "expired"
  }
]
```

History is capped at 500 entries (oldest pruned). Claude can query this to answer questions like "how long did I actually spend on X?"

#### Example Claude Code Workflows

**Simple timer start:**
```
User: "Let's spend 45 minutes on this bug fix"
Claude: [calls flux_create_timer(mode: "countdown", duration: 2700, label: "Bug fix #342")]
Claude: [calls flux_start_timer(timer_id: "...")]
Claude: "Started a 45-minute timer. Let's look at the bug..."
```

**Mid-session time check:**
```
Claude: [calls flux_get_timer(timer_id: "...")]
// Response: { remaining: 612, elapsed: 2088 }
Claude: "10 minutes left. Let's commit what we have and defer the edge cases."
```

**Pomodoro cycle:**
```
User: "Run a pomodoro session"
Claude: [calls flux_create_timer(mode: "countdown", duration: 1500, label: "Pomodoro - Work")]
Claude: [calls flux_start_timer(...)]
// ... 25 min later, timer completes ...
Claude: [calls flux_create_timer(mode: "countdown", duration: 300, label: "Pomodoro - Break")]
Claude: [calls flux_start_timer(...)]
Claude: "Work session done! 5-minute break started. Step away from the screen."
```

#### Resource Budget (MCP additions)

| Resource | Target | Strategy |
|---|---|---|
| **Memory (MCP server process)** | < 5 MB | Minimal Swift executable, no UI |
| **CPU (MCP server)** | 0% when idle | Only active during tool calls, no polling |
| **Socket overhead** | Negligible | Unix domain sockets are kernel-level, no network stack |
| **Disk (session history)** | < 1 MB | 500 entries cap, simple JSON |

### Build Configuration

- **Minimum macOS:** 14.0 (Sonoma) — for `MeshGradient` and modern SwiftUI features
- **Xcode:** 15+
- **Swift:** 5.9+
- **Signing:** Developer ID for distribution outside App Store (or App Store if desired)
- **Sandbox:** Enabled (with notifications entitlement + network.client for local socket)
- **Hardened Runtime:** Enabled

---

## Project Structure

```
FluxTimer/
├── FluxTimer.xcodeproj
├── FluxTimer/
│   ├── App/
│   │   ├── FluxTimerApp.swift          — @main, app lifecycle
│   │   ├── AppDelegate.swift           — NSApplicationDelegate
│   │   └── Info.plist
│   ├── Models/
│   │   ├── TimerModel.swift            — Observable timer state
│   │   ├── TimerPreset.swift           — Preset data model
│   │   ├── ThemeConfiguration.swift    — Visual theme settings
│   │   ├── AlertConfiguration.swift    — Alert toggle states
│   │   └── SessionRecord.swift         — Completed session history entry
│   ├── Views/
│   │   ├── Timer/
│   │   │   ├── TimerView.swift         — Main timer composite view
│   │   │   ├── TimerDisplayView.swift  — Digit display
│   │   │   ├── AlertToggleBar.swift    — Sound/notif/flash toggles
│   │   │   ├── ControlBar.swift        — Hover-reveal controls
│   │   │   └── TimerSetupView.swift    — Preset & custom time picker
│   │   ├── Backgrounds/
│   │   │   ├── GradientBackground.swift — Animated gradient canvas
│   │   │   └── GlassBackground.swift    — NSVisualEffectView wrapper
│   │   ├── MenuBar/
│   │   │   └── MenuBarView.swift        — Status item + dropdown
│   │   └── Settings/
│   │       ├── SettingsView.swift       — Tab container
│   │       ├── AppearanceTab.swift
│   │       ├── PresetsTab.swift
│   │       ├── AlertsTab.swift
│   │       └── GeneralTab.swift
│   ├── Window/
│   │   ├── TimerWindow.swift           — Custom NSWindow subclass
│   │   ├── TimerWindowController.swift — Window lifecycle
│   │   └── WindowManager.swift         — Multi-window orchestrator
│   ├── Services/
│   │   ├── TimerEngine.swift           — Precision timing core
│   │   ├── SnapManager.swift           — Magnetic window snapping
│   │   ├── SoundManager.swift          — Alert sound playback
│   │   ├── NotificationManager.swift   — macOS notifications
│   │   └── SocketServer.swift          — Unix domain socket listener for MCP bridge
│   ├── Utilities/
│   │   ├── Color+Interpolation.swift   — HSB color lerp
│   │   ├── UserDefaults+Settings.swift — Settings persistence
│   │   └── NSWindow+Helpers.swift      — Window position utilities
│   └── Resources/
│       ├── Assets.xcassets             — App icon, colors
│       └── Sounds/
│           ├── chime_soft.caf
│           ├── chime_bright.caf
│           └── chime_urgent.caf
├── FluxMCPServer/
│   ├── main.swift                      — Entry point, stdio transport loop
│   ├── MCPProtocol.swift               — JSON-RPC message types (initialize, tools/list, tools/call)
│   ├── ToolHandlers.swift              — Maps MCP tool calls → socket requests to Flux app
│   ├── ResourceHandlers.swift          — Maps MCP resource reads → socket requests
│   └── SocketClient.swift              — Connects to /tmp/flux-timer.sock
└── FluxTimerTests/
    ├── TimerEngineTests.swift
    ├── SnapManagerTests.swift
    ├── TimerModelTests.swift
    └── MCPIntegrationTests.swift       — End-to-end MCP tool call tests
```

---

## Visual Mockup Descriptions

### Mockup 1: Single Timer — Gradient Mode (Solar Flare Palette)

A small, floating rounded rectangle on the desktop. Background is a warm gradient flowing from deep orange-red at the top-left to magenta-purple at the bottom-right, with two subtle radial highlight spots that slowly orbit. The digits `23:45` are rendered in SF Pro Rounded Heavy at 36pt, pure white, centered vertically with generous padding. Below the digits, three small circular icons (speaker, bell, lightning bolt) sit in a row — the speaker and bell glow softly with a cyan ring indicating they're active, while the bolt is dimmed. A faint label "Focus Block" in SF Pro Text at 11pt sits to the right of the toggles. No window chrome visible — just the pure gradient rectangle with 16pt corners and a soft drop shadow.

### Mockup 2: Single Timer — Glass Mode

Same layout, but the background is a frosted glass panel. The desktop wallpaper (a mountain landscape) is visible through the blur, tinted slightly. A 1pt white inner border at 15% opacity traces the rounded rectangle. The digits are the same white SF Pro Rounded Heavy, but now they feel like they're floating over the glass. A subtle purple outer glow (from the selected Northern Lights palette) haloes the window edges. The overall effect is like a HUD element from a sci-fi interface.

### Mockup 3: Two Timers Snapped Together — Gradient Mode

Two timer windows sit side by side, their edges touching perfectly (0pt gap). The left shows `23:45` with Solar Flare gradient and label "Focus Block". The right shows `00:05:23` (counting up) with Deep Ocean gradient and label "Break". A faint colored line (accent blue) is visible at the snap seam, fading out. Together they look like a single unified widget with two panels, but each has its own gradient identity.

### Mockup 4: Menu Bar Dropdown

The macOS menu bar shows `⏱ 23:45 | 05:23` at the top of the screen. Below it, a standard macOS dropdown menu lists both timers with their labels, current times, and small play/pause buttons on the right side of each row. A separator line, then "New Timer" with a plus icon, another separator, "Preferences..." and "Quit Flux".

### Mockup 5: Timer Completion State

A timer has just hit `00:00`. The entire window is mid-flash — a bright white overlay is fading out over the gradient background, creating a blinding pulse effect. The digits `00:00` are scaled up slightly (1.05x) and will settle back to 1.0x. The gradient has shifted fully to its "end" colors (deep purple for Solar Flare). A macOS notification banner is visible in the top-right of the screen: "Flux — Focus Block timer complete!"

### Mockup 6: Timer Setup Overlay

The timer window has expanded slightly to show the setup view. Three preset pills ("30m", "1h", "2h") sit in a row, with "1h" highlighted in the accent color. Below, three scroll-wheel columns show `01 : 00 : 00`. Two pill buttons "Count Up" and "Count Down" are below that, with "Count Down" selected. A "Start ▶" button at the bottom glows with the accent color, ready to launch the timer.

---

## Implementation Priority

### Phase 1 — Core (MVP)
1. Single timer window with countdown and count-up
2. Gradient background (static palette, no animation initially)
3. Basic digit display with SF Pro Rounded
4. Start/Pause/Reset controls
5. Menu bar icon with time display
6. Timer completion notification + sound
7. Unix domain socket server in Flux app (SocketServer.swift)
8. MCP server executable (FluxMCPServer) with stdio transport
9. Core MCP tools: `flux_create_timer`, `flux_start_timer`, `flux_pause_timer`, `flux_reset_timer`, `flux_stop_timer`, `flux_get_timer`, `flux_list_timers`
10. Session history logging + `flux://history` resource

### Phase 2 — Polish
11. Animated gradient (ambient rotation + progress-linked color shift)
12. Glass/translucent theme
13. Digit flip animation
14. Urgency escalation animations
15. Alert toggle buttons on timer face
16. Timer labels
17. Preset selector
18. `flux_update_timer` MCP tool (labels, alerts)
19. `flux://timers` live resource with subscription support

### Phase 3 — Multi-Timer
20. Multiple timer windows
21. Magnetic snapping (SnapManager)
22. Group dragging
23. Menu bar dropdown with all timers

### Phase 4 — Configurability
24. Settings window (all tabs)
25. Font selection
26. Custom gradient palettes
27. Opacity control
28. Custom presets
29. Launch at login
30. `flux://settings` MCP resource

---

*Flux Timer — because every second should look beautiful.*
