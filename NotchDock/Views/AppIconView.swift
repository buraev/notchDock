import SwiftUI

struct AppIconView: View {
    let app: DockApp

    @State private var isHovering = false

    private let iconSize: CGFloat = 36

    var body: some View {
        Button {
            AppLauncher.launch(bundleID: app.bundleIdentifier)
        } label: {
            VStack(spacing: 2) {
                Image(nsImage: AppLauncher.icon(for: app.bundleIdentifier, size: iconSize))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovering)

                if isHovering {
                    Text(app.name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
