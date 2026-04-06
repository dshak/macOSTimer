import Foundation
import SwiftUI
import Combine

enum TimerMode: String, Codable {
    case countdown
    case countup
}

enum TimerState: String, Codable {
    case idle
    case setup
    case running
    case paused
    case completed
}

class TimerModel: ObservableObject, Identifiable {
    let id: UUID
    @Published var mode: TimerMode
    @Published var state: TimerState = .setup
    @Published var configuredDuration: TimeInterval
    @Published var elapsed: TimeInterval = 0
    @Published var label: String
    @Published var alerts: AlertConfiguration
    @Published var palette: GradientPalette
    @Published var themeMode: ThemeMode = .gradient

    var startedAt: Date?

    var remaining: TimeInterval {
        max(0, configuredDuration - elapsed)
    }

    var displayTime: TimeInterval {
        switch mode {
        case .countdown: return remaining
        case .countup: return elapsed
        }
    }

    var progress: Double {
        guard mode == .countdown, configuredDuration > 0 else { return 0 }
        return elapsed / configuredDuration
    }

    var isComplete: Bool {
        mode == .countdown && elapsed >= configuredDuration && state == .completed
    }

    var formattedTime: String {
        let t = displayTime
        let hours = Int(t) / 3600
        let minutes = (Int(t) % 3600) / 60
        let seconds = Int(t) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var shortFormattedTime: String {
        let t = displayTime
        let hours = Int(t) / 3600
        let minutes = (Int(t) % 3600) / 60
        let seconds = Int(t) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        mode: TimerMode = .countdown,
        duration: TimeInterval = 1800,
        label: String = "",
        alerts: AlertConfiguration = AlertConfiguration(),
        palette: GradientPalette = .solarFlare
    ) {
        self.id = id
        self.mode = mode
        self.configuredDuration = duration
        self.label = label
        self.alerts = alerts
        self.palette = palette
    }

    func toJSON() -> [String: Any] {
        var dict: [String: Any] = [
            "timer_id": id.uuidString,
            "state": state.rawValue,
            "mode": mode.rawValue,
            "elapsed": elapsed,
            "label": label,
            "alerts": [
                "sound": alerts.soundEnabled,
                "notification": alerts.notificationEnabled,
                "flash": alerts.flashEnabled
            ]
        ]
        if mode == .countdown {
            dict["remaining"] = remaining
            dict["configured_duration"] = configuredDuration
        }
        return dict
    }
}
