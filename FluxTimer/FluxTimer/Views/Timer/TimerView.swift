import SwiftUI

struct TimerView: View {
    @ObservedObject var model: TimerModel
    let engine: TimerEngine
    let onNewTimer: () -> Void
    let onClose: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @State private var isHovered = false
    @State private var flashOpacity: Double = 0
    @State private var urgencyScale: CGFloat = 1.0
    @State private var isEditingLabel = false
    @State private var editLabelText = ""

    // Urgency tier: 0 = normal, 1 = last 25%, 2 = last 10%, 3 = last 10 seconds
    private var urgencyTier: Int {
        guard model.mode == .countdown, model.configuredDuration > 0, model.state == .running else { return 0 }
        let pct = model.remaining / model.configuredDuration
        if model.remaining <= 10 { return 3 }
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
                    TimerDisplayView(model: model)
                        .scaleEffect(urgencyScale)
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

            // Close button (top-right, on hover)
            if isHovered && model.state != .setup {
                VStack {
                    HStack {
                        Spacer()
                        CloseButton(action: onClose)
                    }
                    Spacer()
                }
                .padding(6)
            }
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
        // Urgency pulse animation
        .onChange(of: urgencyTier) { _, tier in
            urgencyScale = 1.0
            switch tier {
            case 1:
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    urgencyScale = 1.02
                }
            case 2:
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    urgencyScale = 1.03
                }
            case 3:
                withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                    urgencyScale = 1.05
                }
            default:
                withAnimation(.easeOut(duration: 0.2)) {
                    urgencyScale = 1.0
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.state)
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
        Menu("Theme") {
            Button(model.themeMode == .gradient ? "* Gradient" : "Gradient") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    model.themeMode = .gradient
                }
            }
            Button(model.themeMode == .glass ? "* Glass" : "Glass") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    model.themeMode = .glass
                }
            }
        }

        // Palette picker
        Menu("Palette") {
            ForEach(GradientPalette.all) { palette in
                Button(palette.id == model.palette.id ? "* \(palette.name)" : palette.name) {
                    model.palette = palette
                }
            }
        }

        Divider()

        Button("Edit Label...") {
            editLabelText = model.label
            isEditingLabel = true
        }

        Button("Preferences...") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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

private struct CloseButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(isHovered ? 0.9 : 0.5))
                .frame(width: 18, height: 18)
                .background(Circle().fill(.black.opacity(isHovered ? 0.4 : 0.2)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
