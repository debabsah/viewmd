import SwiftUI

struct WorkspaceRootView: View {
    @ObservedObject var workspace: Workspace
    let bridge: RenderBridge
    @AppStorage("showSidebar") private var showSidebar = true

    var body: some View {
        HSplitView {
            if showSidebar && workspace.folderURL != nil {
                SidebarView(workspace: workspace)
                    .frame(minWidth: 180, idealWidth: 230, maxWidth: 400)
            }
            VStack(spacing: 0) {
                if workspace.tabs.count > 1 {
                    TabBarView(workspace: workspace)
                    Divider()
                }
                if workspace.activeTab != nil {
                    RenderView(bridge: bridge)
                } else {
                    EmptyDropHint()
                }
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 480, minHeight: 320)
    }
}

struct EmptyDropHint: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 42))
                .foregroundStyle(.tertiary)
            Text("Open a Markdown file or folder")
                .foregroundStyle(.secondary)
            Text("⌘O file · ⌘⇧O folder · or drop one here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
