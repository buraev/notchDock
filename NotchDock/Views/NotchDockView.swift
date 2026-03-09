import SwiftUI

struct NotchDockView: View {
    @ObservedObject var store: DockStore
    let isExpanded: Bool

    var body: some View {
        ZStack {
            // Background — rounded dark pill
            if isExpanded {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.85))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            }

            if isExpanded {
                HStack(spacing: 8) {
                    ForEach(store.apps) { app in
                        AppIconView(app: app)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}
