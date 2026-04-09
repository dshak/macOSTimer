import SwiftUI

struct TimerSetupView: View {
    @ObservedObject var model: TimerModel
    let engine: TimerEngine
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var seconds: Int = 0

    var body: some View {
        VStack(spacing: 12) {
            // Mode toggle
            HStack(spacing: 8) {
                ModeButton(title: "Count Down", isSelected: model.mode == .countdown) {
                    model.mode = .countdown
                }
                ModeButton(title: "Count Up", isSelected: model.mode == .countup) {
                    model.mode = .countup
                }
            }

            if model.mode == .countdown {
                // Presets (built-in + custom, scrollable)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppSettings.shared.allPresets) { preset in
                            PresetPill(
                                label: preset.label,
                                isSelected: model.configuredDuration == preset.duration,
                                action: {
                                    model.configuredDuration = preset.duration
                                    updatePickerFromDuration(preset.duration)
                                }
                            )
                        }
                    }
                }

                // Time picker
                HStack(spacing: 4) {
                    DragDigit(label: "h", value: $hours, range: 0...23)
                    Text(":").foregroundStyle(.white.opacity(0.6)).font(.title2.weight(.bold))
                    DragDigit(label: "m", value: $minutes, range: 0...59)
                    Text(":").foregroundStyle(.white.opacity(0.6)).font(.title2.weight(.bold))
                    DragDigit(label: "s", value: $seconds, range: 0...59)
                }
                .onChange(of: hours) { updateDuration() }
                .onChange(of: minutes) { updateDuration() }
                .onChange(of: seconds) { updateDuration() }
            }

            // Start button
            Button(action: {
                engine.start()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.25)))
                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .onAppear {
            updatePickerFromDuration(model.configuredDuration)
        }
    }

    private func updateDuration() {
        model.configuredDuration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    private func updatePickerFromDuration(_ duration: TimeInterval) {
        let total = Int(duration)
        hours = total / 3600
        minutes = (total % 3600) / 60
        seconds = total % 60
    }
}

private struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(.white.opacity(isSelected ? 0.25 : 0.08))
                )
                .overlay(
                    Capsule().stroke(.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct PresetPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(isSelected ? 0.2 : (isHovered ? 0.12 : 0.06)))
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

/// Click-and-drag digit scrubber. Drag up to increase, down to decrease.
/// Uses NSView to capture mouse events before the window's move handler.
private struct DragDigit: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(isDragging ? 0.25 : 0.1))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(isDragging ? 0.4 : 0), lineWidth: 1)

                Text(String(format: "%02d", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .allowsHitTesting(false)

                // NSView overlay that captures all mouse events
                DragDigitControl(
                    value: $value,
                    isDragging: $isDragging,
                    range: range
                )
            }
            .frame(width: 44, height: 36)
            .animation(.easeOut(duration: 0.15), value: isDragging)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(isDragging ? 0.7 : 0.4))
        }
        .onHover { inside in
            if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
        }
    }
}

/// NSViewRepresentable that intercepts mouse events for digit scrubbing,
/// preventing them from reaching the window's isMovableByWindowBackground handler.
private struct DragDigitControl: NSViewRepresentable {
    @Binding var value: Int
    @Binding var isDragging: Bool
    let range: ClosedRange<Int>

    func makeNSView(context: Context) -> DragDigitNSView {
        let view = DragDigitNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: DragDigitNSView, context: Context) {
        context.coordinator.value = $value
        context.coordinator.isDragging = $isDragging
        context.coordinator.range = range
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, isDragging: $isDragging, range: range)
    }

    class Coordinator {
        var value: Binding<Int>
        var isDragging: Binding<Bool>
        var range: ClosedRange<Int>

        private var startY: CGFloat = 0
        private var startValue: Int = 0
        private var didDrag = false
        private let pointsPerUnit: CGFloat = 8

        init(value: Binding<Int>, isDragging: Binding<Bool>, range: ClosedRange<Int>) {
            self.value = value
            self.isDragging = isDragging
            self.range = range
        }

        func mouseDown(at point: NSPoint) {
            startY = point.y
            startValue = value.wrappedValue
            didDrag = false
        }

        func mouseDragged(at point: NSPoint) {
            if !isDragging.wrappedValue {
                isDragging.wrappedValue = true
            }
            didDrag = true

            // macOS Y: up is positive, so drag up = increase
            let delta = point.y - startY
            let steps = Int(delta / pointsPerUnit)
            let newValue = startValue + steps
            value.wrappedValue = clampWrapping(newValue)
        }

        func mouseUp() {
            isDragging.wrappedValue = false
            if !didDrag {
                // Click without drag: increment by 1
                value.wrappedValue = clampWrapping(value.wrappedValue + 1)
            }
        }

        func scrollWheel(deltaY: CGFloat) {
            let newValue = value.wrappedValue + Int(deltaY)
            value.wrappedValue = min(range.upperBound, max(range.lowerBound, newValue))
        }

        private func clampWrapping(_ v: Int) -> Int {
            let span = range.upperBound - range.lowerBound + 1
            var result = v
            while result > range.upperBound { result -= span }
            while result < range.lowerBound { result += span }
            return result
        }
    }
}

fileprivate class DragDigitNSView: NSView {
    weak var coordinator: DragDigitControl.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    // Prevent the window from starting a move when clicking this view
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        coordinator?.mouseDown(at: loc)
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        coordinator?.mouseDragged(at: loc)
    }

    override func mouseUp(with event: NSEvent) {
        coordinator?.mouseUp()
    }

    override func scrollWheel(with event: NSEvent) {
        coordinator?.scrollWheel(deltaY: event.deltaY)
    }
}
