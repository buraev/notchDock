import Foundation
import Combine
import SwiftUI

final class DockStore: ObservableObject {

    private static let userDefaultsKey = "notchdock.pinned_apps"

    @Published var apps: [DockApp] {
        didSet { save() }
    }

    @Published var isDraggingIcon = false
    @Published var isExpanded = false

    init() {
        self.apps = Self.load()
        if apps.isEmpty {
            // Default apps for first launch
            self.apps = [
                DockApp(bundleIdentifier: "com.apple.finder"),
                DockApp(bundleIdentifier: "com.apple.Safari"),
                DockApp(bundleIdentifier: "com.apple.mail"),
                DockApp(bundleIdentifier: "com.apple.MobileSMS"),
            ]
        }
    }

    func addApp(bundleID: String) {
        guard !apps.contains(where: { $0.bundleIdentifier == bundleID }) else { return }
        apps.append(DockApp(bundleIdentifier: bundleID))
    }

    func removeApp(id: String) {
        apps.removeAll { $0.id == id }
    }

    func moveApp(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
    }

    func moveApp(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < apps.count,
              toIndex >= 0, toIndex < apps.count else { return }
        let app = apps.remove(at: fromIndex)
        apps.insert(app, at: toIndex)
    }

    // MARK: - Expand / Collapse (animated)

    func expand() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isExpanded = true
        }
    }

    func collapse() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
            isExpanded = false
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    private static func load() -> [DockApp] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let apps = try? JSONDecoder().decode([DockApp].self, from: data) else {
            return []
        }
        return apps
    }
}
