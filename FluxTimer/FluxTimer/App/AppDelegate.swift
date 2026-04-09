import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var statusBarController: StatusBarController!
    var socketServer: SocketServer!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        NotificationManager.shared.requestPermission()

        // Set up window manager
        windowManager = WindowManager()

        // Set up status bar
        statusBarController = StatusBarController(windowManager: windowManager)

        // Set up socket server for MCP
        socketServer = SocketServer.shared
        socketServer.windowManager = windowManager
        socketServer.start()

        // Create initial timer
        windowManager.createTimerAndShow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        socketServer?.shutdown()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowManager?.showAllWindows()
        }
        return true
    }

    // MARK: - Settings Window

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Flux Timer Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
