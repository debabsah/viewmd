import SwiftUI

struct TabBarView: View {
    @ObservedObject var workspace: Workspace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach(workspace.tabs) { tab in
                    TabChip(
                        title: tab.displayName,
                        isActive: tab.id == workspace.activeTabID,
                        activate: { workspace.activeTabID = tab.id },
                        close: { workspace.closeTab(id: tab.id) })
                }
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 32)
        .background(.bar)
    }
}

private struct TabChip: View {
    let title: String
    let isActive: Bool
    let activate: () -> Void
    let close: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .lineLimit(1)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(hovering || isActive ? 0.6 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? AnyShapeStyle(.background) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: activate)
        .onHover { hovering = $0 }
    }
}
