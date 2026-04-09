import SwiftUI

struct TimerView: View {
    @ObservedObject var model: TimerModel
    let engine: TimerEngine
    let onNewTimer: () -> Void
    let onClose: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @State private var isHovered = false
    @State private var flashOpacity: Double = 0
    @State private var isEditingLabel = false
    @State private var editLabelText = ""

    // Urgency tier: 0 = normal, 1 = last 25%, 2 = last 10%, 3 = last 10 seconds
    private var urgencyTier: Int {
        guard model.mode == .countdown, model.configuredDuration > 0,
              model.state == .running, model.displaySeconds > 0 else { return 0 }
        let remainingSec = Double(model.displaySeconds)
        let pct = remainingSec / model.configuredDuration
        if remainingSec <= 10 { return 3 }
        if pct <= 0.10 { return 2 }
        if pct <= 0.25 { return 1 }
        return 0
    }

    var body: some View {
        ZStack {
            // Background — gradient or glass
            backgroundView
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Flash overlay for completion
            if flashOpacity > 0 {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(flashOpacity))
            }

            // Content
            VStack(spacing: 0) {
                if model.state == .setup {
                    TimerSetupView(model: model, engine: engine)
                } else {
                    Spacer(minLength: 6)

                    // Timer digits — tap to pause/resume
                    UrgencyPulseWrapper(tier: urgencyTier) {
                        TimerDisplayView(model: model)
                    }
                    .contentShape(Rectangle())
                        .onTapGesture {
                            if model.state == .running {
                                engine.pause()
                            } else if model.state == .paused || model.state == .completed {
                                engine.reset()
                                engine.start()
                            }
                        }

                    // Label + alert toggles row
                    HStack(spacing: 6) {
                        AlertToggleBar(model: model)

                        Spacer()

                        // Editable label
                        if isEditingLabel {
                            TextField("Label", text: $editLabelText, onCommit: {
                                model.label = String(editLabelText.prefix(20))
                                isEditingLabel = false
                            })
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 90)
                            .onExitCommand { isEditingLabel = false }
                        } else {
                            Text(model.label.isEmpty ? "Timer" : model.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                                .onTapGesture(count: 2) {
                                    editLabelText = model.label
                                    isEditingLabel = true
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)

                    Spacer(minLength: 2)

                    // Controls on hover
                    if isHovered || model.state == .paused || model.state == .completed {
                        ControlBar(model: model, engine: engine, onNewTimer: onNewTimer, onClose: onClose)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Close button — positioned absolutely in top-right
            NativeCloseButton(action: onClose)
                .frame(width: 20, height: 20)
                .position(x: 240 - 16, y: 16)

        }
        .frame(width: 240, height: model.state == .setup ? 220 : 120)
        .opacity(settings.windowOpacity)
        .shadow(color: .black.opacity(model.themeMode == .glass ? 0.2 : 0.35), radius: 16, y: 6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onChange(of: model.state) { _, newState in
            if newState == .completed && model.alerts.flashEnabled {
                triggerFlash()
            }
        }
        .contextMenu { contextMenuContent }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch model.themeMode {
        case .gradient:
            GradientBackground(palette: model.palette, progress: model.progress)
        case .glass:
            GlassBackground(accentColor: model.palette.colors[0])
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        // Theme toggle
        Picker("Theme", selection: Binding(
            get: { model.themeMode },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.4)) {
                    model.themeMode = newValue
                }
            }
        )) {
            Text("Gradient").tag(ThemeMode.gradient)
            Text("Glass").tag(ThemeMode.glass)
        }

        // Palette picker
        Picker("Palette", selection: Binding(
            get: { model.palette.id },
            set: { newId in
                if let p = GradientPalette.all.first(where: { $0.id == newId }) {
                    model.palette = p
                }
            }
        )) {
            ForEach(GradientPalette.all) { palette in
                Text(palette.name).tag(palette.id)
            }
        }

        Divider()

        Button("Edit Label...") {
            editLabelText = model.label
            isEditingLabel = true
        }
    }

    private func triggerFlash() {
        for i in 0..<3 {
            let delay = Double(i) * 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.15)) {
                    flashOpacity = 0.8
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.15) {
                withAnimation(.easeOut(duration: 0.35)) {
                    flashOpacity = 0
                }
            }
        }
    }
}

/// Wraps content with a scale pulse driven by TimelineView — only active when urgency tier > 0.
/// No `.repeatForever` animations — the pulse is computed from wall-clock time, so it
/// starts and stops cleanly with zero cancellation issues.
private struct UrgencyPulseWrapper<Content: View>: View {
    let tier: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        if tier > 0 {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                content()
                    .scaleEffect(scale(for: timeline.date))
            }
        } else {
            content()
        }
    }

    private func scale(for date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
        let amplitude: CGFloat
        let frequency: Double
        switch tier {
        case 1: amplitude = 0.02; frequency = 0.5
        case 2: amplitude = 0.03; frequency = 0.83
        case 3: amplitude = 0.05; frequency = 3.3
        default: return 1.0
        }
        return 1.0 + amplitude * CGFloat(sin(t * .pi * 2 * frequency))
    }
}

/// Close button backed by NSView so clicks aren't swallowed by isMovableByWindowBackground
private struct CloseButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        ZStack {
            Circle().fill(.black.opacity(isHovered ? 0.5 : 0.3))
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(isHovered ? 1.0 : 0.6))
                .allowsHitTesting(false)
            ClickReceiver(action: action)
        }
        .frame(width: 18, height: 18)
        .onHover { isHovered = $0 }
    }
}

/// NSView that captures clicks and prevents window drag
private struct ClickReceiver: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> ClickReceiverNSView {
        let view = ClickReceiverNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: ClickReceiverNSView, context: Context) {
        nsView.action = action
    }
}

fileprivate class ClickReceiverNSView: NSView {
    var action: (() -> Void)?

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        // Don't forward to super — prevents window drag
    }

    override func mouseUp(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if bounds.contains(loc) {
            action?()
        }
    }
}
