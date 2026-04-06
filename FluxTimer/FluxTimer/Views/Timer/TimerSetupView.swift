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
                // Presets
                HStack(spacing: 8) {
                    ForEach(TimerPreset.builtIn) { preset in
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

                // Time picker
                HStack(spacing: 4) {
                    TimeWheel(label: "h", value: $hours, range: 0...23)
                    Text(":").foregroundStyle(.white.opacity(0.6)).font(.title2.weight(.bold))
                    TimeWheel(label: "m", value: $minutes, range: 0...59)
                    Text(":").foregroundStyle(.white.opacity(0.6)).font(.title2.weight(.bold))
                    TimeWheel(label: "s", value: $seconds, range: 0...59)
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

private struct TimeWheel: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1)))
                .onScrollWheel { delta in
                    let newValue = value - Int(delta)
                    value = min(range.upperBound, max(range.lowerBound, newValue))
                }

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// Scroll wheel detection for time picker
struct ScrollWheelModifier: ViewModifier {
    let handler: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content.background(
            ScrollWheelReceiver(handler: handler)
        )
    }
}

struct ScrollWheelReceiver: NSViewRepresentable {
    let handler: (CGFloat) -> Void

    func makeNSView(context: Context) -> ScrollWheelNSView {
        let view = ScrollWheelNSView()
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.handler = handler
    }
}

class ScrollWheelNSView: NSView {
    var handler: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        handler?(event.deltaY)
    }
}

extension View {
    func onScrollWheel(_ handler: @escaping (CGFloat) -> Void) -> some View {
        modifier(ScrollWheelModifier(handler: handler))
    }
}
