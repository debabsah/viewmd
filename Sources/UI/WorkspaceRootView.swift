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
                if ui.sidebarVisible && workspace.folderURL != nil {
                    SidebarV2View(controller: controller, workspace: workspace,
                                  ui: ui, isPeek: false)
                        .frame(width: ui.sidebarWidth)
                        .transition(.move(edge: .leading))
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
