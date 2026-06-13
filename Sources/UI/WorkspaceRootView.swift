import SwiftUI

struct WorkspaceRootView: View {
    @ObservedObject var controller: WorkspaceWindowController
    @ObservedObject var workspace: Workspace
    @ObservedObject var ui: WindowUIState
    let bridge: RenderBridge
    let openURL: (URL) -> Void
    let openFilePanel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabStripView(
                workspace: workspace,
                ui: ui,
                palette: controller.palette,
                openFileAction: openFilePanel,
                revealInFinder: controller.revealInFinder)
            HStack(spacing: 0) {
                // Sidebar v2 mounts here in Task 7; placeholder keeps layout stable
                if ui.sidebarVisible && workspace.folderURL != nil {
                    Rectangle()
                        .fill(controller.palette.sideBackground.color)
                        .frame(width: ui.sidebarWidth)
                }
                Group {
                    if let tab = workspace.activeTab {
                        ActiveDocumentView(document: tab, bridge: bridge)
                            .id(tab.id)
                    } else {
                        EmptyDropHint()
                    }
                }
                .frame(minWidth: 400, maxWidth: .infinity)
                .background(controller.palette.background.color)
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .dropDestination(for: URL.self) { urls, _ in
            guard !urls.isEmpty else { return false }
            urls.forEach(openURL)
            return true
        }
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
