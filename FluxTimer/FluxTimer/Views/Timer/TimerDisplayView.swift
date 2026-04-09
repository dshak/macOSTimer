import SwiftUI

struct TimerDisplayView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        // Derive display from the published displaySeconds (triggers view updates only when second changes)
        let total = model.displaySeconds
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if hours > 0 {
                if hours >= 10 {
                    FlipDigit(digit: hours / 10)
                }
                FlipDigit(digit: hours % 10)
                AnimatedSeparator(isRunning: model.state == .running)
            }

            FlipDigit(digit: minutes / 10)
            FlipDigit(digit: minutes % 10)
            AnimatedSeparator(isRunning: model.state == .running)
            FlipDigit(digit: seconds / 10)
            FlipDigit(digit: seconds % 10)

            // Centiseconds (optional, uses displayTime for sub-second precision)
            if settings.showCentiseconds && model.state == .running {
                let centis = Int((model.displayTime - floor(model.displayTime)) * 100)
                Text(".")
                    .opacity(0.5)
                Text(String(format: "%02d", centis))
                    .font(settings.timerFont.font(size: settings.fontSize * 0.45))
            }
        }
        .font(settings.timerFont.font(size: settings.fontSize))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        // Pause blink — only animate opacity when paused
        .opacity(blinkOpacity)
        .onChange(of: model.state, initial: true) { _, newState in
            if newState == .paused {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    blinkOpacity = 0.3
                }
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    blinkOpacity = 1.0
                }
            }
        }
    }

    @State private var blinkOpacity: Double = 1.0
}

/// A single digit that animates (slides up) only when its value changes
private struct FlipDigit: View {
    let digit: Int

    @State private var displayDigit: Int = -1
    @State private var offset: CGFloat = 0
    @State private var digitOpacity: Double = 1.0

    var body: some View {
        Text("\(displayDigit < 0 ? digit : displayDigit)")
            .offset(y: offset)
            .opacity(digitOpacity)
            .onChange(of: digit) { oldVal, newVal in
                guard oldVal != newVal else { return }
                withAnimation(.easeIn(duration: 0.1)) {
                    offset = -6
                    digitOpacity = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    displayDigit = newVal
                    offset = 6
                    withAnimation(.easeOut(duration: 0.1)) {
                        offset = 0
                        digitOpacity = 1.0
                    }
                }
            }
            .onAppear {
                displayDigit = digit
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
