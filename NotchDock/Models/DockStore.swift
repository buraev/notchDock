import Foundation
import Combine

final class DockStore: ObservableObject {

    private static let userDefaultsKey = "notchdock.pinned_apps"

    @Published var apps: [DockApp] {
        didSet { save() }
    }

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
