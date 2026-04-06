import SwiftUI

@main
struct FluxTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We manage windows manually via WindowManager,
        // but SwiftUI requires at least one Scene.
        // Use a Settings scene as a placeholder — it won't show unless invoked.
        Settings {
            EmptyView()
        }
    }
}
