import AppKit

/// A borderless, always-on-top panel that sits over the notch area.
final class NotchWindow: NSPanel {

    /// The visible content rect (notch + dock area), set by the controller.
    /// Mouse events outside this rect pass through to apps below.
    var visibleContentRect: NSRect = .zero

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // Behavior — always on top, across all spaces
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Don't steal focus
        isMovable = false
        isMovableByWindowBackground = false

        // Accept mouse events
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true

        // Allow drag overlays to render outside window bounds
        contentView?.wantsLayer = true
        contentView?.layer?.masksToBounds = false
    }

    // Allow the panel to become key so we can receive clicks
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
