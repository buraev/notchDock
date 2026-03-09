import SwiftUI

@main
struct NotchDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("NotchDock", systemImage: "dock.rectangle") {
            SettingsView(store: appDelegate.dockStore)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let dockStore = DockStore()
    private var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NotchWindowController(store: dockStore)
        windowController?.showWindow(nil)
    }
}
