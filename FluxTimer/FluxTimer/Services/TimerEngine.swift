import Foundation
import Combine

class TimerEngine: ObservableObject {
    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedBeforePause: TimeInterval = 0
    private weak var model: TimerModel?
    private var lastDisplaySeconds: Int = -1
    private var currentTickInterval: TimeInterval = 1.0

    init(model: TimerModel) {
        self.model = model
    }

    var currentElapsed: TimeInterval {
        guard let start = startDate else { return accumulatedBeforePause }
        return accumulatedBeforePause + Date().timeIntervalSince(start)
    }

    func start() {
        guard let model else { return }
        if model.state == .idle || model.state == .setup {
            accumulatedBeforePause = 0
            model.elapsed = 0
            model.startedAt = Date()
            lastDisplaySeconds = -1
        }
        startDate = Date()
        model.state = .running

        // Immediately set correct displaySeconds so views don't see 0 briefly
        let initialSeconds = Int(model.displayTime)
        model.displaySeconds = initialSeconds
        lastDisplaySeconds = initialSeconds

        startTicking()
    }

    func pause() {
        guard let model else { return }
        accumulatedBeforePause = currentElapsed
        startDate = nil
        timer?.invalidate()
        timer = nil
        model.state = .paused
    }

    func reset() {
        guard let model else { return }
        timer?.invalidate()
        timer = nil
        startDate = nil
        accumulatedBeforePause = 0
        model.elapsed = 0
        model.displaySeconds = 0
        model.startedAt = nil
        lastDisplaySeconds = -1
        model.state = .setup
    }

    func stop() {
        guard let model else { return }
        let finalElapsed = currentElapsed
        timer?.invalidate()
        timer = nil
        startDate = nil

        if model.startedAt != nil {
            let record = SessionRecord(
                id: UUID(),
                timerId: model.id,
                label: model.label,
                mode: model.mode,
                configuredDuration: model.configuredDuration,
                actualElapsed: finalElapsed,
                startedAt: model.startedAt ?? Date(),
                completedAt: Date(),
                completionReason: .stopped
            )
            SessionHistoryManager.shared.append(record)
        }

        model.state = .idle
    }

    private func startTicking() {
        scheduleTimer(interval: tickInterval)
    }

    /// Adaptive tick interval: 1Hz normally, 0.1s for centiseconds or final 10 seconds
    private var tickInterval: TimeInterval {
        guard let model else { return 1.0 }
        return model.needsHighFrequency ? 0.1 : 1.0
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        currentTickInterval = interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard let model else { return }
        let elapsed = currentElapsed
        model.elapsed = elapsed

        // Check completion
        if model.mode == .countdown && elapsed >= model.configuredDuration {
            model.elapsed = model.configuredDuration
            complete()
            return
        }

        // Only publish displaySeconds when the visible second changes
        let currentSecond = Int(model.displayTime)
        if currentSecond != lastDisplaySeconds {
            model.displaySeconds = currentSecond
            lastDisplaySeconds = currentSecond
        }

        // Switch tick rate if needed (e.g., entering last 10 seconds)
        let desiredInterval = tickInterval
        if desiredInterval != currentTickInterval {
            scheduleTimer(interval: desiredInterval)
        }
    }

    private func complete() {
        guard let model else { return }
        timer?.invalidate()
        timer = nil
        startDate = nil
        model.displaySeconds = 0
        model.state = .completed

        let record = SessionRecord(
            id: UUID(),
            timerId: model.id,
            label: model.label,
            mode: model.mode,
            configuredDuration: model.configuredDuration,
            actualElapsed: model.elapsed,
            startedAt: model.startedAt ?? Date(),
            completedAt: Date(),
            completionReason: .expired
        )
        SessionHistoryManager.shared.append(record)

        if model.alerts.soundEnabled {
            SoundManager.shared.playCompletionSound()
        }
        if model.alerts.notificationEnabled {
            NotificationManager.shared.sendTimerComplete(label: model.label)
        }
    }
}
