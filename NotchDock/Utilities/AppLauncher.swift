import AppKit

enum AppLauncher {

    /// Launch an application by its bundle identifier.
    static func launch(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            NSLog("NotchDock: Could not find app with bundle ID: \(bundleID)")
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            if let error {
                NSLog("NotchDock: Failed to launch \(bundleID): \(error.localizedDescription)")
            }
        }
    }

    /// Get the icon for an app by bundle identifier.
    static func icon(for bundleID: String, size: CGFloat = 32) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: size, height: size)
            return icon
        }
        let fallback = NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App") ?? NSImage()
        fallback.size = NSSize(width: size, height: size)
        return fallback
    }

    /// Get the display name for an app by bundle identifier.
    static func appName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let bundle = Bundle(url: url)
            return bundle?.infoDictionary?["CFBundleName"] as? String
                ?? bundle?.infoDictionary?["CFBundleDisplayName"] as? String
                ?? url.deletingPathExtension().lastPathComponent
        }
        return bundleID
    }

    /// Check if an application is currently running.
    static func isRunning(bundleID: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }
}
