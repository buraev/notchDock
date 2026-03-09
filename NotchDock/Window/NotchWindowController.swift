import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    private let store: DockStore
    private let notchInfo: NotchInfo
    private var trackingArea: NSTrackingArea?
    private var isExpanded = false
    private var globalMonitor: Any?

    // Layout constants
    private let iconSize: CGFloat = 40
    private let iconSpacing: CGFloat = 8
    private let dockPadding: CGFloat = 10     // equal padding on all sides
    private let indicatorSpace: CGFloat = 8   // space for running dot below icon
    private let tooltipOverflow: CGFloat = 30  // extra space below dock for tooltip
    private let separatorGap: CGFloat = 4      // gap between notch and dock bar

    init(store: DockStore) {
        self.store = store
        self.notchInfo = NotchDetector.detect()

        let panel = NotchWindow(contentRect: .zero)
        super.init(window: panel)

        let collapsed = collapsedRect()
        panel.setFrame(collapsed, display: false)

        setupContent()
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

    // MARK: - Rect Calculations

    private func collapsedRect() -> NSRect {
        let notchRect = notchInfo.rect
        // Hover zone matches the notch exactly
        return NSRect(
            x: notchRect.origin.x,
            y: notchRect.origin.y,
            width: notchRect.width,
            height: notchRect.height
        )
    }

    private func expandedRect() -> NSRect {
        let notchRect = notchInfo.rect
        let iconCount = CGFloat(max(store.apps.count, 1))

        // Width: icons + spacing + padding on both sides
        let contentWidth = iconCount * iconSize + (iconCount - 1) * iconSpacing + dockPadding * 2
        // At minimum, match notch width
        let dockWidth = max(notchRect.width, contentWidth)

        // Height: notch + padding top + icon + indicator space + padding bottom + tooltip overflow
        let dockAreaHeight = 14 + iconSize + indicatorSpace + 2
        let totalHeight = notchRect.height + separatorGap + dockAreaHeight + tooltipOverflow

        return NSRect(
            x: notchRect.midX - dockWidth / 2,
            y: notchRect.maxY - totalHeight,
            width: dockWidth,
            height: totalHeight
        )
    }

    // MARK: - Tracking Area

    private func setupTrackingArea() {
        guard let contentView = window?.contentView else { return }

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
        guard isExpanded, !store.isDraggingIcon else { return }
        collapse()
    }

    // MARK: - Global Mouse Monitor (fallback)

    private func installGlobalMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, self.isExpanded, !self.store.isDraggingIcon, let window = self.window else { return }
            let mouseLocation = NSEvent.mouseLocation
            let expandedFrame = window.frame
            let tolerance: CGFloat = 15
            let checkRect = expandedFrame.insetBy(dx: -tolerance, dy: -tolerance)
            if !checkRect.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.collapse()
                }
            }
        }
    }

    private func removeGlobalMonitor() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    // MARK: - Content (mounted once)

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        let notchRect = notchInfo.rect
        let dockAreaHeight = 14 + iconSize + indicatorSpace + 2

        let hostingView = NSHostingView(
            rootView: NotchDockView(
                store: store,
                notchWidth: notchRect.width,
                notchHeight: notchRect.height,
                dockHeight: dockAreaHeight,
                tooltipOverflow: tooltipOverflow
            )
        )
        hostingView.frame = contentView.bounds
        hostingView.autoresizingMask = [.width, .height]
        hostingView.layer?.backgroundColor = .clear
        contentView.addSubview(hostingView)
    }

    // MARK: - Animation

    private func expand() {
        isExpanded = true
        window?.setFrame(expandedRect(), display: true)
        setupTrackingArea()
        store.expand()
        installGlobalMonitor()
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        removeGlobalMonitor()
        store.collapse()

        // Wait for spring animation to settle before shrinking window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, !self.isExpanded else { return }
            self.window?.setFrame(self.collapsedRect(), display: true)
            self.setupTrackingArea()
        }
    }
}
