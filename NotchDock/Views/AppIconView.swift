import SwiftUI

struct AppIconView: View {
    let app: DockApp
    var isPressed: Bool = false

    @State private var isHovering = false

    private let iconSize: CGFloat = 40

    private var isRunning: Bool {
        AppLauncher.isRunning(bundleID: app.bundleIdentifier)
    }

    private var iconScale: CGFloat {
        if isPressed { return 0.9 }
        if isHovering { return 1.05 }
        return 1.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: iconSize))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(iconScale)
                .animation(.spring(response: 0.25, dampingFraction: 0.3), value: isPressed)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovering)

            // Running indicator dot
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
                .padding(.top, 3)
                .opacity(isRunning ? 1 : 0)
        }
        // Fixed frame prevents tooltip from affecting layout/hit-testing of neighbors
        .frame(width: iconSize, height: iconSize + 8)
        .overlay(alignment: .bottom) {
            if isHovering {
                tooltipView
                    .offset(y: iconSize / 2 + 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Tooltip with triangle

    private var tooltipView: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(Color.black)
                .frame(width: 10, height: 5)

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black)
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
