import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var statusBarController: StatusBarController!
    var socketServer: SocketServer!

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
}
