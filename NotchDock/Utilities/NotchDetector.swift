import AppKit

struct NotchInfo {
    let rect: CGRect       // Position and size in screen coordinates
    let screen: NSScreen
    let hasNotch: Bool
}

enum NotchDetector {

    /// Returns notch info for the built-in display (or main screen fallback).
    static func detect() -> NotchInfo {
        let screen = builtInScreen() ?? NSScreen.main ?? NSScreen.screens[0]
        return notchInfo(for: screen)
    }

    // MARK: - Private

    private static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            return CGDisplayIsBuiltin(id) != 0
        }
    }

    private static func notchInfo(for screen: NSScreen) -> NotchInfo {
        // On macOS 12+, screens with a notch expose auxiliaryTopLeftArea / auxiliaryTopRightArea.
        // The notch occupies the gap between these two areas.
        if #available(macOS 12.0, *) {
            let safeAreaInsets = screen.safeAreaInsets
            if safeAreaInsets.top > 0 {
                let frame = screen.frame
                let topLeftArea = screen.auxiliaryTopLeftArea
                let topRightArea = screen.auxiliaryTopRightArea

                if topLeftArea != nil || topRightArea != nil {
                    let leftMaxX = topLeftArea?.maxX ?? frame.minX
                    let rightMinX = topRightArea?.minX ?? frame.maxX
                    let notchWidth = rightMinX - leftMaxX
                    let notchHeight = safeAreaInsets.top
                    let notchX = leftMaxX
                    let notchY = frame.maxY - notchHeight

                    return NotchInfo(
                        rect: CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight),
                        screen: screen,
                        hasNotch: true
                    )
                }
            }
        }

        // Fallback: no notch detected — place a fake "notch" region at top-center
        let frame = screen.frame
        let fallbackWidth: CGFloat = 200
        let fallbackHeight: CGFloat = 32
        let notchRect = CGRect(
            x: frame.midX - fallbackWidth / 2,
            y: frame.maxY - fallbackHeight,
            width: fallbackWidth,
            height: fallbackHeight
        )
        return NotchInfo(rect: notchRect, screen: screen, hasNotch: false)
    }
}
