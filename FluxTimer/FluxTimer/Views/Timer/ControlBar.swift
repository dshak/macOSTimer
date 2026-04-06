import SwiftUI

struct ControlBar: View {
    @ObservedObject var model: TimerModel
    let engine: TimerEngine
    let onNewTimer: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Play / Pause
            ControlButton(
                icon: model.state == .running ? "pause.fill" : "play.fill",
                action: {
                    if model.state == .running {
                        engine.pause()
                    } else {
                        engine.start()
                    }
                }
            )

            // Stop
            ControlButton(icon: "stop.fill") {
                engine.stop()
                onClose()
            }

            // Reset
            ControlButton(icon: "arrow.counterclockwise") {
                engine.reset()
            }

            Spacer()

            // New Timer
            ControlButton(icon: "plus") {
                onNewTimer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.6))
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.15 : 1.0)
        .animation(.spring(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
