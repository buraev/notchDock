import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    private let store: DockStore
    private let notchInfo: NotchInfo
    private var trackingArea: NSTrackingArea?
    private var isExpanded = false
    private var globalMonitor: Any?
    private var iconsVisible = false

    // Layout constants
    private let iconSize: CGFloat = 40
    private let iconSpacing: CGFloat = 8
    private let dockPadding: CGFloat = 10     // equal padding on all sides
    private let indicatorSpace: CGFloat = 8   // space for running dot below icon

    // Background view (pure black like notch)
    private var backgroundView: NSView?

    init(store: DockStore) {
        self.store = store
        self.notchInfo = NotchDetector.detect()

        let panel = NotchWindow(contentRect: .zero)
        super.init(window: panel)

        let collapsed = collapsedRect()
        panel.setFrame(collapsed, display: false)

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

        // Height: notch + padding top + icon + indicator space + padding bottom
        let dockAreaHeight = dockPadding + iconSize + indicatorSpace + dockPadding
        let totalHeight = notchRect.height + dockAreaHeight

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
        guard isExpanded else { return }
        collapse()
    }

    // MARK: - Global Mouse Monitor (fallback)

    private func installGlobalMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, self.isExpanded, let window = self.window else { return }
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

    // MARK: - Animation

    private func expand() {
        isExpanded = true
        let targetRect = expandedRect()

        // 1. Resize window immediately
        window?.setFrame(targetRect, display: true)
        setupTrackingArea()

        // 2. Setup black background (hidden)
        setupBackgroundView(for: targetRect)
        backgroundView?.alphaValue = 0

        // 3. Fade in background
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.backgroundView?.animator().alphaValue = 1.0
        }, completionHandler: {
            // 4. After background visible, show icons
            self.iconsVisible = true
            self.updateContent(expanded: true)
        })

        installGlobalMonitor()
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        removeGlobalMonitor()

        // 1. Hide icons first
        iconsVisible = false
        updateContent(expanded: false)

        // 2. Small delay, then fade out background
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.backgroundView?.animator().alphaValue = 0
            }, completionHandler: {
                self.backgroundView?.removeFromSuperview()
                self.backgroundView = nil

                // Remove hosting views
                self.window?.contentView?.subviews
                    .filter { $0 !== self.backgroundView }
                    .forEach { $0.removeFromSuperview() }

                let collapsed = self.collapsedRect()
                self.window?.setFrame(collapsed, display: true)
                self.setupTrackingArea()
            })
        }
    }

    // MARK: - Background View (pure black like notch)

    private func setupBackgroundView(for windowRect: NSRect) {
        backgroundView?.removeFromSuperview()

        guard let contentView = window?.contentView else { return }
        let bounds = contentView.bounds
        let notchRect = notchInfo.rect

        // Calculate notch position relative to the window
        let notchLocalX = notchRect.origin.x - windowRect.origin.x
        let notchLocalWidth = notchRect.width
        let notchLocalHeight = notchRect.height
        let dockTop = bounds.height - notchLocalHeight

        let bgView = NSView(frame: bounds)
        bgView.wantsLayer = true
        bgView.layer?.backgroundColor = NSColor.black.cgColor
        bgView.autoresizingMask = [.width, .height]

        // Create custom T-shape: dock bar + notch connector
        let path = CGMutablePath()
        let cornerRadius: CGFloat = 16
        let notchCornerRadius: CGFloat = 10

        let dockLeft: CGFloat = 0
        let dockRight = bounds.width
        let dockBottom: CGFloat = 0

        // Bottom-left corner
        path.move(to: CGPoint(x: dockLeft + cornerRadius, y: dockBottom))
        path.addLine(to: CGPoint(x: dockRight - cornerRadius, y: dockBottom))

        // Bottom-right corner
        path.addArc(tangent1End: CGPoint(x: dockRight, y: dockBottom),
                     tangent2End: CGPoint(x: dockRight, y: dockBottom + cornerRadius),
                     radius: cornerRadius)

        // Right edge up to notch level
        path.addLine(to: CGPoint(x: dockRight, y: dockTop - cornerRadius))

        // Top-right corner of dock
        path.addArc(tangent1End: CGPoint(x: dockRight, y: dockTop),
                     tangent2End: CGPoint(x: dockRight - cornerRadius, y: dockTop),
                     radius: cornerRadius)

        // Top edge to right side of notch
        let notchRight = notchLocalX + notchLocalWidth
        path.addLine(to: CGPoint(x: notchRight + notchCornerRadius, y: dockTop))

        // Curve into notch right side
        path.addArc(tangent1End: CGPoint(x: notchRight, y: dockTop),
                     tangent2End: CGPoint(x: notchRight, y: dockTop + notchCornerRadius),
                     radius: notchCornerRadius)

        // Right edge of notch going up
        path.addLine(to: CGPoint(x: notchRight, y: bounds.height))

        // Top of notch
        path.addLine(to: CGPoint(x: notchLocalX, y: bounds.height))

        // Left edge of notch going down
        path.addLine(to: CGPoint(x: notchLocalX, y: dockTop + notchCornerRadius))

        // Curve out of notch left side
        path.addArc(tangent1End: CGPoint(x: notchLocalX, y: dockTop),
                     tangent2End: CGPoint(x: notchLocalX - notchCornerRadius, y: dockTop),
                     radius: notchCornerRadius)

        // Top edge to left side
        path.addLine(to: CGPoint(x: dockLeft + cornerRadius, y: dockTop))

        // Top-left corner of dock
        path.addArc(tangent1End: CGPoint(x: dockLeft, y: dockTop),
                     tangent2End: CGPoint(x: dockLeft, y: dockTop - cornerRadius),
                     radius: cornerRadius)

        // Left edge down
        path.addLine(to: CGPoint(x: dockLeft, y: dockBottom + cornerRadius))

        // Bottom-left corner
        path.addArc(tangent1End: CGPoint(x: dockLeft, y: dockBottom),
                     tangent2End: CGPoint(x: dockLeft + cornerRadius, y: dockBottom),
                     radius: cornerRadius)

        path.closeSubpath()

        // Apply shape mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        bgView.layer?.mask = maskLayer

        // Subtle border
        let borderLayer = CAShapeLayer()
        borderLayer.path = path
        borderLayer.fillColor = nil
        borderLayer.strokeColor = NSColor.white.withAlphaComponent(0.15).cgColor
        borderLayer.lineWidth = 0.5
        borderLayer.frame = bounds
        bgView.layer?.addSublayer(borderLayer)

        contentView.addSubview(bgView, positioned: .below, relativeTo: nil)
        backgroundView = bgView
    }

    // MARK: - Content

    private func updateContent(expanded: Bool) {
        guard let contentView = window?.contentView else { return }

        // Remove existing hosting views (keep background)
        contentView.subviews
            .filter { $0 !== backgroundView }
            .forEach { $0.removeFromSuperview() }

        if expanded && iconsVisible {
            let notchRect = notchInfo.rect
            let hostingView = NSHostingView(
                rootView: NotchDockView(
                    store: store,
                    isExpanded: true,
                    notchHeight: notchRect.height
                )
            )
            hostingView.frame = contentView.bounds
            hostingView.autoresizingMask = [.width, .height]
            hostingView.layer?.backgroundColor = .clear
            contentView.addSubview(hostingView)
        }
    }
}
