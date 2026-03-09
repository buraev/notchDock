import Foundation

struct DockApp: Identifiable, Codable, Equatable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String

    init(bundleIdentifier: String, name: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name ?? AppLauncher.appName(for: bundleIdentifier)
    }

    // Custom Codable to handle the computed `name` fallback
    enum CodingKeys: String, CodingKey {
        case bundleIdentifier, name
    }
}
