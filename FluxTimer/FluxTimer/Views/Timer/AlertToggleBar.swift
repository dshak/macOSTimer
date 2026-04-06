import SwiftUI

struct AlertToggleBar: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        HStack(spacing: 6) {
            AlertToggle(
                icon: "speaker.wave.2.fill",
                isActive: model.alerts.soundEnabled,
                accentColor: .cyan
            ) {
                model.alerts.soundEnabled.toggle()
            }

            AlertToggle(
                icon: "bell.fill",
                isActive: model.alerts.notificationEnabled,
                accentColor: .cyan
            ) {
                model.alerts.notificationEnabled.toggle()
            }

            AlertToggle(
                icon: "bolt.fill",
                isActive: model.alerts.flashEnabled,
                accentColor: .cyan
            ) {
                model.alerts.flashEnabled.toggle()
            }
        }
    }
}

private struct AlertToggle: View {
    let icon: String
    let isActive: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(isActive ? 0.9 : 0.3))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(.white.opacity(isActive ? 0.15 : 0.05))
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(isActive ? 0.4 : 0), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
