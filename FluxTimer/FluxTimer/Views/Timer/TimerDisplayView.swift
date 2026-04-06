import SwiftUI

struct TimerDisplayView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        let t = model.displayTime
        let hours = Int(t) / 3600
        let minutes = (Int(t) % 3600) / 60
        let seconds = Int(t) % 60

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if hours > 0 {
                FlipDigitPair(value: hours, padded: false)
                AnimatedSeparator(isRunning: model.state == .running)
            }

            FlipDigitPair(value: minutes, padded: true)
            AnimatedSeparator(isRunning: model.state == .running)
            FlipDigitPair(value: seconds, padded: true)
        }
        .font(.system(size: 42, weight: .heavy, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        // Pause blink
        .opacity(model.state == .paused ? (blinkOpacity) : 1.0)
        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: model.state == .paused)
    }

    @State private var blinkOpacity: Double = 0.3
}

/// A digit pair that animates (slides up) when the value changes
private struct FlipDigitPair: View {
    let value: Int
    let padded: Bool

    @State private var displayValue: Int = -1
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var text: String {
        padded ? String(format: "%02d", displayValue < 0 ? value : displayValue) : "\(displayValue < 0 ? value : displayValue)"
    }

    var body: some View {
        Text(text)
            .offset(y: offset)
            .opacity(opacity)
            .onChange(of: value) { oldVal, newVal in
                guard oldVal != newVal else { return }
                // Slide old value up and fade out
                withAnimation(.easeIn(duration: 0.1)) {
                    offset = -6
                    opacity = 0.3
                }
                // After a brief moment, snap to new value and slide in from below
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    displayValue = newVal
                    offset = 6
                    withAnimation(.easeOut(duration: 0.1)) {
                        offset = 0
                        opacity = 1.0
                    }
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

/// Colon separator with subtle pulse while running
private struct AnimatedSeparator: View {
    let isRunning: Bool
    @State private var pulseOpacity: Double = 0.7

    var body: some View {
        Text(":")
            .opacity(pulseOpacity)
            .padding(.horizontal, 1)
            .onChange(of: isRunning, initial: true) { _, running in
                if running {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.35
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pulseOpacity = 0.7
                    }
                }
            }
    }
}
