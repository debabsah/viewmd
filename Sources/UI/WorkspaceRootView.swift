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
                    SidebarResizeHandle(ui: ui)
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

/// 5pt invisible divider; drag resizes the sidebar within spec bounds.
struct SidebarResizeHandle: View {
    @ObservedObject var ui: WindowUIState
    @State private var startWidth: Double?

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 5)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if startWidth == nil { startWidth = ui.sidebarWidth }
                        let proposed = (startWidth ?? SidebarDefaults.defaultWidth)
                            + value.translation.width
                        ui.sidebarWidth = min(max(proposed,
                                                  SidebarDefaults.widthRange.lowerBound),
                                              SidebarDefaults.widthRange.upperBound)
                    }
                    .onEnded { _ in
                        startWidth = nil
                        ui.persistWidth()
                    })
    }
}
