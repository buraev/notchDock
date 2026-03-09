import SwiftUI

struct AppIconView: View {
    let app: DockApp
    @ObservedObject var store: DockStore

    @State private var isHovering = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingOut = false

    private let iconSize: CGFloat = 40

    private var isRunning: Bool {
        AppLauncher.isRunning(bundleID: app.bundleIdentifier)
    }

    var body: some View {
        Button {
            AppLauncher.launch(bundleID: app.bundleIdentifier)
        } label: {
            VStack(spacing: 0) {
                // Icon
                Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: iconSize))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(isHovering ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovering)

                // Running indicator dot
                Circle()
                    .fill(.white)
                    .frame(width: 4, height: 4)
                    .padding(.top, 3)
                    .opacity(isRunning ? 1 : 0)

                // Tooltip below icon with triangle
                if isHovering {
                    tooltipView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only track vertical drag for removal
                    let distance = abs(value.translation.height)
                    if distance > 40 {
                        isDraggingOut = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    let distance = abs(value.translation.height)
                    if distance > 60 {
                        // Remove from dock with poof
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = CGSize(width: value.translation.width, height: value.translation.height * 2)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            store.removeApp(id: app.id)
                            dragOffset = .zero
                            isDraggingOut = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = .zero
                            isDraggingOut = false
                        }
                    }
                }
        )
        .opacity(isDraggingOut ? 0.5 : 1.0)
    }

    // MARK: - Tooltip with triangle (liquid glass style)

    private var tooltipView: some View {
        VStack(spacing: 0) {
            // Triangle pointing up
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 10, height: 5)
                .padding(.top, 4)

            // Label
            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
