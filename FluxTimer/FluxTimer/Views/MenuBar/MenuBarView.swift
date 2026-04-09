import AppKit
import Combine

class StatusBarController {
    private var statusItem: NSStatusItem
    private var updateTimer: Timer?
    private weak var windowManager: WindowManager?

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Flux Timer")
            button.imagePosition = .imageLeading
        }

        updateMenu()
        startUpdating()
    }

    func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    private func updateDisplay() {
        guard let wm = windowManager else { return }
        let settings = AppSettings.shared
        let running = wm.timers.filter { $0.model.state == .running }

        if let button = statusItem.button {
            switch settings.menuBarDisplay {
            case .iconOnly:
                button.title = ""
            case .mostRecent:
                if let last = running.last {
                    button.title = " \(last.model.shortFormattedTime)"
                } else {
                    button.title = ""
                }
            case .allTimers:
                if running.isEmpty {
                    button.title = ""
                } else if running.count == 1 {
                    button.title = " \(running[0].model.shortFormattedTime)"
                } else if running.count == 2 {
                    button.title = " \(running[0].model.shortFormattedTime) | \(running[1].model.shortFormattedTime)"
                } else {
                    button.title = " \(running.count) timers"
                }
            }
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        menu.addItem(withTitle: "Flux Timer", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(.separator())

        if let wm = windowManager {
            for instance in wm.timers {
                let model = instance.model
                let stateIcon: String
                switch model.state {
                case .running: stateIcon = "▶"
                case .paused: stateIcon = "⏸"
                case .completed: stateIcon = "✓"
                default: stateIcon = "○"
                }

                let label = model.label.isEmpty ? "Timer" : model.label
                let title = "\(stateIcon)  \(label)    \(model.shortFormattedTime)"
                let item = NSMenuItem(title: title, action: #selector(timerItemClicked(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = model.id.uuidString
                menu.addItem(item)
            }

            if !wm.timers.isEmpty {
                menu.addItem(.separator())
            }
        }

        let newItem = NSMenuItem(title: "New Timer", action: #selector(newTimerClicked), keyEquivalent: "n")
        newItem.target = self
        menu.addItem(newItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(preferencesClicked), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Flux", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func timerItemClicked(_ sender: NSMenuItem) {
        guard let timerId = sender.representedObject as? String else { return }
        windowManager?.showWindow(for: timerId)
    }

    @objc private func newTimerClicked() {
        windowManager?.createTimerAndShow()
    }

    @objc private func preferencesClicked() {
        (NSApp.delegate as? AppDelegate)?.showSettings()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
