import AppKit
import SwiftUI

class TimerWindow: NSWindow {
    weak var snapManager: SnapManager?
    var onCloseAction: (() -> Void)?
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveNotification),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    func cleanup() {}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        // Cmd+W or Escape closes the timer
        if (event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w")
            || event.keyCode == 53 /* Escape */ {
            onCloseAction?()
            return
        }
        super.keyDown(with: event)
    }

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

/// An NSView-backed close button that works in borderless windows with isMovableByWindowBackground.
/// The key: overriding mouseDownCanMoveWindow = false prevents the window drag from stealing clicks.
struct NativeCloseButton: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> CloseButtonNSView {
        let view = CloseButtonNSView()
        view.onClose = action
        return view
    }

    func updateNSView(_ nsView: CloseButtonNSView, context: Context) {
        nsView.onClose = action
    }
}

class CloseButtonNSView: NSView {
    var onClose: (() -> Void)?
    private var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let r = bounds.insetBy(dx: 1, dy: 1)

        // Circle
        let alpha: CGFloat = isPressed ? 0.7 : (isHovered ? 0.5 : 0.3)
        ctx.setFillColor(NSColor.black.withAlphaComponent(alpha).cgColor)
        ctx.fillEllipse(in: r)

        // X
        let inset = r.insetBy(dx: 4.5, dy: 4.5)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(isHovered ? 1.0 : 0.6).cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: inset.minX, y: inset.minY))
        ctx.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        ctx.move(to: CGPoint(x: inset.maxX, y: inset.minY))
        ctx.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        ctx.strokePath()
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
        // Do NOT call super — prevents window drag
    }

    override func mouseUp(with event: NSEvent) {
        isPressed = false
        needsDisplay = true
        let loc = convert(event.locationInWindow, from: nil)
        if bounds.contains(loc) {
            onClose?()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
        NSCursor.arrow.push()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
        NSCursor.pop()
    }
}
