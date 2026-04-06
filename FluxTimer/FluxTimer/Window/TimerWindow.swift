import AppKit
import SwiftUI

class TimerWindow: NSWindow {
    weak var snapManager: SnapManager?
    private var isDragging = false

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isReleasedWhenClosed = false

        // Monitor for window move events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveNotification),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // Detect mouse-down to start drag tracking
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        snapManager?.windowWillStartDrag(self)
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        super.mouseUp(with: event)
    }

    @objc private func windowDidMoveNotification() {
        guard isDragging else { return }
        snapManager?.windowDidMove(self)
    }
}
