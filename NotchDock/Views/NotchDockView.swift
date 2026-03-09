import SwiftUI
import UniformTypeIdentifiers

struct NotchDockView: View {
    @ObservedObject var store: DockStore
    let isExpanded: Bool
    var notchHeight: CGFloat = 32

    @State private var draggingApp: DockApp?

    var body: some View {
        ZStack {
            if isExpanded {
                VStack(spacing: 0) {
                    // Top spacer matching notch height
                    Spacer()
                        .frame(height: notchHeight)

                    // Single row of icons below notch
                    HStack(spacing: 8) {
                        ForEach(store.apps) { app in
                            AppIconView(app: app, store: store)
                                .opacity(draggingApp?.id == app.id ? 0.3 : 1.0)
                                .onDrag {
                                    draggingApp = app
                                    return NSItemProvider(object: app.bundleIdentifier as NSString)
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: DockDropDelegate(
                                        app: app,
                                        store: store,
                                        draggingApp: $draggingApp
                                    )
                                )
                        }
                    }
                    .padding(10) // equal padding on all sides
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Drop Delegate for reordering

struct DockDropDelegate: DropDelegate {
    let app: DockApp
    let store: DockStore
    @Binding var draggingApp: DockApp?

    func performDrop(info: DropInfo) -> Bool {
        draggingApp = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingApp,
              dragging.id != app.id,
              let fromIndex = store.apps.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = store.apps.firstIndex(where: { $0.id == app.id }) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            store.apps.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }
}
