import SwiftUI

struct NotchDockView: View {
    @ObservedObject var store: DockStore
    var notchWidth: CGFloat = 200
    var notchHeight: CGFloat = 32
    var dockHeight: CGFloat = 68
    var tooltipOverflow: CGFloat = 0

    private let iconSize: CGFloat = 40
    private let iconSpacing: CGFloat = 8
    private let dockPadding: CGFloat = 10
    private var step: CGFloat { iconSize + iconSpacing }

    private var visibleApps: [DockApp] {
        if isDraggingOutside, let draggedID = draggedAppID {
            return store.apps.filter { $0.id != draggedID }
        }
        return store.apps
    }

    private var dockWidth: CGFloat {
        let iconCount = CGFloat(max(visibleApps.count, 1))
        let contentWidth = iconCount * iconSize + (iconCount - 1) * iconSpacing + dockPadding * 2
        return max(notchWidth, contentWidth)
    }

    // Delayed icon visibility (background first, then icons)
    @State private var showIcons = false

    // MARK: - Drag State

    @State private var draggedAppID: String?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDraggingOutside = false
    @State private var dockFrame: CGRect = .zero

    // Gesture state machine (tap vs drag)
    @State private var pressedAppID: String?
    @State private var isInDragMode = false
    @State private var longPressTimer: DispatchWorkItem?

    // Poof animation
    @State private var poofScale: CGFloat = 1.0
    @State private var poofOpacity: Double = 1.0
    @State private var isPoofing = false
    @State private var poofPosition: CGPoint = .zero

    var body: some View {
        ZStack(alignment: .top) {
            // Animated background shape
            NotchShape(
                progress: store.isExpanded ? 1 : 0,
                notchWidth: notchWidth,
                notchHeight: notchHeight,
                dockWidth: dockWidth,
                dockHeight: dockHeight,
                separatorGap: 4
            )
            .fill(Color.black)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.isExpanded)
            .animation(.easeInOut(duration: 0.15), value: isDraggingOutside)

            // Icon content (delayed on expand, early hide on collapse)
            if showIcons {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: notchHeight)

                    HStack(spacing: iconSpacing) {
                        ForEach(visibleApps, id: \.id) { app in
                            AppIconView(
                                app: app,
                                isPressed: pressedAppID == app.id && !isInDragMode
                            )
                            .opacity(draggedAppID == app.id && !isDraggingOutside ? 0.0 : 1.0)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("dock"))
                                    .onChanged { value in
                                        handleDragChanged(app: app, value: value)
                                    }
                                    .onEnded { value in
                                        handleDragEnded(app: app, value: value)
                                    }
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 2)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: DockFrameKey.self,
                                value: geo.frame(in: .named("dock"))
                            )
                        }
                    )
                    .onPreferenceChange(DockFrameKey.self) { frame in
                        dockFrame = frame
                    }

                    Spacer()
                        .frame(height: tooltipOverflow)
                }
                .coordinateSpace(name: "dock")
                .overlay {
                    // Floating dragged icon
                    if let appID = draggedAppID, isInDragMode, !isPoofing,
                       let app = store.apps.first(where: { $0.id == appID }) {
                        dragOverlay(for: app)
                            .allowsHitTesting(false)
                    }

                    // Poof animation
                    if isPoofing, let appID = draggedAppID,
                       let app = store.apps.first(where: { $0.id == appID }) {
                        poofOverlay(for: app)
                            .allowsHitTesting(false)
                    }
                }
                .transition(.opacity.animation(.easeOut(duration: 0.12)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: store.isExpanded) { expanded in
            if expanded {
                // Background expands first, icons appear after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        showIcons = true
                    }
                }
            } else {
                // Icons disappear first, background collapses after
                withAnimation(.easeOut(duration: 0.1)) {
                    showIcons = false
                }
            }
        }
    }

    // MARK: - Drag Overlay (always shown during drag)

    private func dragOverlay(for app: DockApp) -> some View {
        VStack(spacing: 4) {
            if isDraggingOutside {
                Text("Удалить")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.8))
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: iconSize))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(isDraggingOutside ? 1.15 : 1.05)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        }
        .position(dragLocation)
        .animation(.easeOut(duration: 0.12), value: isDraggingOutside)
    }

    // MARK: - Poof Overlay

    private func poofOverlay(for app: DockApp) -> some View {
        Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: iconSize))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .scaleEffect(poofScale)
            .opacity(poofOpacity)
            .position(poofPosition)
    }

    // MARK: - Gesture Handling

    private func handleDragChanged(app: DockApp, value: DragGesture.Value) {
        // First touch — start timer
        if pressedAppID == nil {
            pressedAppID = app.id
            let timer = DispatchWorkItem {
                enterDragMode(app: app, location: value.startLocation)
            }
            longPressTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.17, execute: timer)
            return
        }

        // Movement threshold — enter drag early
        let distance = hypot(value.location.x - value.startLocation.x,
                             value.location.y - value.startLocation.y)
        if !isInDragMode && distance > 5 {
            longPressTimer?.cancel()
            longPressTimer = nil
            enterDragMode(app: app, location: value.startLocation)
        }

        guard isInDragMode else { return }

        dragLocation = value.location

        // Check if outside dock bounds
        if dockFrame.height > 1 {
            let margin: CGFloat = 20
            let outside = value.location.x < dockFrame.minX - margin
                || value.location.x > dockFrame.maxX + margin
                || value.location.y < dockFrame.minY - margin
                || value.location.y > dockFrame.maxY + margin

            if outside != isDraggingOutside {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isDraggingOutside = outside
                }
            }
        }

        // Live reorder while dragging inside
        if !isDraggingOutside {
            let relativeX = value.location.x - dockFrame.minX
            let targetIndex = min(max(Int(floor(relativeX / step)), 0), store.apps.count - 1)

            if let currentIndex = store.apps.firstIndex(where: { $0.id == draggedAppID }),
               targetIndex != currentIndex {
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                    store.moveApp(fromIndex: currentIndex, toIndex: targetIndex)
                }
            }
        }
    }

    private func enterDragMode(app: DockApp, location: CGPoint) {
        guard !isInDragMode else { return }
        isInDragMode = true
        draggedAppID = app.id
        dragLocation = location
        store.isDraggingIcon = true
    }

    private func handleDragEnded(app: DockApp, value: DragGesture.Value) {
        longPressTimer?.cancel()
        longPressTimer = nil

        if !isInDragMode {
            // Quick tap — launch the app
            pressedAppID = nil
            AppLauncher.launch(bundleID: app.bundleIdentifier)
            return
        }

        // Final outside check
        if !isDraggingOutside, dockFrame.height > 1 {
            let margin: CGFloat = 20
            let pos = value.location
            if pos.x < dockFrame.minX - margin
                || pos.x > dockFrame.maxX + margin
                || pos.y < dockFrame.minY - margin
                || pos.y > dockFrame.maxY + margin {
                isDraggingOutside = true
            }
        }

        if isDraggingOutside {
            // Poof-remove animation
            poofPosition = dragLocation
            isPoofing = true
            isDraggingOutside = false

            poofScale = 1.0
            poofOpacity = 1.0

            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                poofScale = 1.5
                poofOpacity = 0.7
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    poofScale = 0.0
                    poofOpacity = 0.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                store.removeApp(id: app.id)
                resetDragState()
            }
        } else {
            resetDragState()
        }
    }

    private func resetDragState() {
        draggedAppID = nil
        pressedAppID = nil
        isInDragMode = false
        longPressTimer?.cancel()
        longPressTimer = nil
        dragLocation = .zero
        isDraggingOutside = false
        isPoofing = false
        poofScale = 1.0
        poofOpacity = 1.0
        poofPosition = .zero
        store.isDraggingIcon = false
    }
}

// MARK: - Preference Key for dock frame

private struct DockFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
