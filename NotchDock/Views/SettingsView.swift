import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: DockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pinned Apps")
                .font(.headline)
                .padding(.horizontal)

            if store.apps.isEmpty {
                Text("No apps pinned yet.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(store.apps) { app in
                    HStack(alignment: .center, spacing: 8) {
                        Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: 20))
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(app.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Button(role: .destructive) {
                            store.removeApp(id: app.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: 24)
                    .padding(.horizontal)
                }
            }

            Divider()

            Button {
                addAppFromPicker()
            } label: {
                Label("Add Application…", systemImage: "plus")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .frame(width: 250)
    }

    private func addAppFromPicker() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Application"
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleID = bundle.bundleIdentifier {
                store.addApp(bundleID: bundleID)
            }
        }
    }
}
