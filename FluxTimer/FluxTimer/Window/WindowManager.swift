import AppKit
import SwiftUI
import Combine

struct TimerInstance {
    let model: TimerModel
    let engine: TimerEngine
    let window: TimerWindow
}

class WindowManager: ObservableObject {
    @Published var timers: [TimerInstance] = []
    let snapManager = SnapManager()
    private var cancellables = Set<AnyCancellable>()

    func createTimer(
        mode: TimerMode = .countdown,
        duration: TimeInterval = 1800,
        label: String = ""
    ) -> TimerModel {
        let model = TimerModel(mode: mode, duration: duration, label: label)
        let engine = TimerEngine(model: model)

        let windowSize = NSSize(width: 240, height: model.state == .setup ? 220 : 120)
        let origin = nextWindowOrigin(size: windowSize)
        let window = TimerWindow(contentRect: NSRect(origin: origin, size: windowSize))
        window.snapManager = snapManager

        let timerView = TimerView(
            model: model,
            engine: engine,
            onNewTimer: { [weak self] in
                self?.createTimerAndShow()
            },
            onClose: { [weak self] in
                self?.closeTimer(id: model.id.uuidString)
            }
        )

        window.contentView = NSHostingView(rootView: timerView)

        // Track state changes to resize window
        model.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak window] state in
                guard let window else { return }
                let height: CGFloat = state == .setup ? 220 : 120
                var frame = window.frame
                let dy = frame.size.height - height
                frame.origin.y += dy // Keep top edge pinned
                frame.size.height = height
                window.setFrame(frame, display: true, animate: true)
            }
            .store(in: &cancellables)

        let instance = TimerInstance(model: model, engine: engine, window: window)
        timers.append(instance)

        snapManager.register(window)
        window.orderFrontRegardless()

        return model
    }

    @discardableResult
    func createTimerAndShow(
        mode: TimerMode = .countdown,
        duration: TimeInterval = 1800,
        label: String = ""
    ) -> TimerModel {
        createTimer(mode: mode, duration: duration, label: label)
    }

    func closeTimer(id: String) {
        guard let index = timers.firstIndex(where: { $0.model.id.uuidString == id }) else { return }
        let instance = timers[index]
        instance.engine.stop()
        snapManager.unregister(instance.window)
        instance.window.close()
        timers.remove(at: index)
    }

    func engine(for timerId: String) -> TimerEngine? {
        timers.first { $0.model.id.uuidString == timerId }?.engine
    }

    func timerModel(for timerId: String) -> TimerModel? {
        timers.first { $0.model.id.uuidString == timerId }?.model
    }

    func allTimerModels() -> [TimerModel] {
        timers.map(\.model)
    }

    func showWindow(for timerId: String) {
        if let window = timers.first(where: { $0.model.id.uuidString == timerId })?.window {
            window.orderFrontRegardless()
            window.makeKey()
        }
    }

    func showAllWindows() {
        for instance in timers {
            instance.window.orderFrontRegardless()
        }
    }

    // MARK: - Window Positioning

    /// Place new windows in a cascading position near the top-right of the screen,
    /// offset downward for each additional timer. If existing timers are present,
    /// try to place the new one adjacent (to the right or below) the most recent one.
    private func nextWindowOrigin(size: NSSize) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let visibleFrame = screen.visibleFrame

        if let lastWindow = timers.last?.window {
            // Try placing to the right of the last timer
            let rightOrigin = NSPoint(
                x: lastWindow.frame.maxX + 4,
                y: lastWindow.frame.origin.y
            )
            if rightOrigin.x + size.width <= visibleFrame.maxX {
                return rightOrigin
            }

            // If no room to the right, place below
            let belowOrigin = NSPoint(
                x: lastWindow.frame.origin.x,
                y: lastWindow.frame.origin.y - size.height - 4
            )
            if belowOrigin.y >= visibleFrame.minY {
                return belowOrigin
            }
        }

        // Default: top-right corner
        return NSPoint(
            x: visibleFrame.maxX - size.width - 20,
            y: visibleFrame.maxY - size.height - 20
        )
    }
}
