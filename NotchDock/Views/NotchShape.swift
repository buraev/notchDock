import SwiftUI

/// Animatable notch shape that morphs between collapsed (notch only) and expanded (notch + dock bar).
/// Inspired by boring.notch's smooth shape morphing with AnimatablePair.
struct NotchShape: Shape {

    /// How far the dock has expanded (0 = collapsed, 1 = fully expanded)
    var progress: CGFloat

    /// Notch dimensions (from NotchDetector)
    let notchWidth: CGFloat
    let notchHeight: CGFloat

    /// Dock bar dimensions when fully expanded
    let dockWidth: CGFloat
    let dockHeight: CGFloat

    /// Gap between notch connector and dock bar
    let separatorGap: CGFloat

    private let topRadius: CGFloat = 6
    private let bottomRadius: CGFloat = 22
    private let notchConnectorRadius: CGFloat = 10

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let centerX = rect.midX

        // --- Notch connector (always present, anchored at top center) ---
        let notchLeft = centerX - notchWidth / 2
        let notchRight = centerX + notchWidth / 2
        let notchTop = rect.minY
        let notchBottom = notchTop + notchHeight

        // --- Dock bar (expands below notch) ---
        let currentDockWidth = notchWidth + (dockWidth - notchWidth) * progress
        let currentDockHeight = dockHeight * progress
        let currentGap = separatorGap * progress

        let dockLeft = centerX - currentDockWidth / 2
        let dockRight = centerX + currentDockWidth / 2
        let dockTop = notchBottom + currentGap
        let dockBottom = dockTop + currentDockHeight

        let currentBottomRadius = min(bottomRadius * progress, bottomRadius)
        let currentTopDockRadius = min(bottomRadius * progress, bottomRadius)

        // Draw notch connector
        let cr = min(notchConnectorRadius, notchHeight / 2)
        path.move(to: CGPoint(x: notchLeft, y: notchTop))
        path.addLine(to: CGPoint(x: notchRight, y: notchTop))
        path.addLine(to: CGPoint(x: notchRight, y: notchBottom - cr))
        path.addArc(
            tangent1End: CGPoint(x: notchRight, y: notchBottom),
            tangent2End: CGPoint(x: notchRight - cr, y: notchBottom),
            radius: cr
        )
        path.addLine(to: CGPoint(x: notchLeft + cr, y: notchBottom))
        path.addArc(
            tangent1End: CGPoint(x: notchLeft, y: notchBottom),
            tangent2End: CGPoint(x: notchLeft, y: notchBottom - cr),
            radius: cr
        )
        path.closeSubpath()

        // Draw dock bar only when expanding
        if progress > 0.01 {
            let br = min(currentBottomRadius, currentDockHeight / 2, currentDockWidth / 2)
            let tr = min(currentTopDockRadius, currentDockHeight / 2, currentDockWidth / 2)

            path.move(to: CGPoint(x: dockLeft + tr, y: dockTop))
            path.addLine(to: CGPoint(x: dockRight - tr, y: dockTop))

            path.addArc(
                tangent1End: CGPoint(x: dockRight, y: dockTop),
                tangent2End: CGPoint(x: dockRight, y: dockTop + tr),
                radius: tr
            )

            path.addLine(to: CGPoint(x: dockRight, y: dockBottom - br))

            path.addArc(
                tangent1End: CGPoint(x: dockRight, y: dockBottom),
                tangent2End: CGPoint(x: dockRight - br, y: dockBottom),
                radius: br
            )

            path.addLine(to: CGPoint(x: dockLeft + br, y: dockBottom))

            path.addArc(
                tangent1End: CGPoint(x: dockLeft, y: dockBottom),
                tangent2End: CGPoint(x: dockLeft, y: dockBottom - br),
                radius: br
            )

            path.addLine(to: CGPoint(x: dockLeft, y: dockTop + tr))

            path.addArc(
                tangent1End: CGPoint(x: dockLeft, y: dockTop),
                tangent2End: CGPoint(x: dockLeft + tr, y: dockTop),
                radius: tr
            )

            path.closeSubpath()
        }

        return path
    }
}
