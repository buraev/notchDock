import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    private let store: DockStore
    private let notchInfo: NotchInfo
    private var trackingArea: NSTrackingArea?
    private var isExpanded = false

    // Dock extends below the notch when hovered
    private let expandedHeight: CGFloat = 70
    private let collapsedHeight: CGFloat = 6  // thin hover-trigger strip

    init(store: DockStore) {
        self.store = store
        self.notchInfo = NotchDetector.detect()

        // Start with a thin strip at the notch position to catch hover
        let notchRect = notchInfo.rect
        let initialRect = NSRect(
            x: notchRect.origin.x,
            y: notchRect.origin.y + notchRect.height - collapsedHeight,
            width: notchRect.width,
            height: collapsedHeight
        )

        let panel = NotchWindow(contentRect: initialRect)
        super.init(window: panel)

        let hostingView = NSHostingView(
            rootView: NotchDockView(store: store, isExpanded: false)
        )
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)

        setupTrackingArea()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.orderFrontRegardless()
    }

    // MARK: - Tracking Area

    private func setupTrackingArea() {
        guard let contentView = window?.contentView else { return }

        // Remove old tracking area
        if let existing = trackingArea {
            contentView.removeTrackingArea(existing)
        }

        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
        trackingArea = area
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        guard !isExpanded else { return }
        expand()
    }

    override func mouseExited(with event: NSEvent) {
        guard isExpanded else { return }
        collapse()
    }

    // MARK: - Animation

    private func expand() {
        isExpanded = true
        let notchRect = notchInfo.rect

        let expandedRect = NSRect(
            x: notchRect.origin.x,
            y: notchRect.origin.y + notchRect.height - expandedHeight,
            width: notchRect.width,
            height: expandedHeight
        )

        updateContent(expanded: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.window?.animator().setFrame(expandedRect, display: true)
        }
    }

    private func collapse() {
        isExpanded = false
        let notchRect = notchInfo.rect

        let collapsedRect = NSRect(
            x: notchRect.origin.x,
            y: notchRect.origin.y + notchRect.height - collapsedHeight,
            width: notchRect.width,
            height: collapsedHeight
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.window?.animator().setFrame(collapsedRect, display: true)
        }, completionHandler: {
            self.updateContent(expanded: false)
        })
    }

    private func updateContent(expanded: Bool) {
        guard let contentView = window?.contentView else { return }
        // Replace hosting view content
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let hostingView = NSHostingView(
            rootView: NotchDockView(store: store, isExpanded: expanded)
        )
        hostingView.frame = contentView.bounds
        hostingView.autoresizingMask = [.width, .height]
        contentView.addSubview(hostingView)
    }
}
