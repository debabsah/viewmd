import SwiftUI

struct WorkspaceRootView: View {
    @ObservedObject var controller: WorkspaceWindowController
    @ObservedObject var workspace: Workspace
    @ObservedObject var ui: WindowUIState
    let bridge: RenderBridge
    let openURL: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabStripView(
                workspace: workspace,
                ui: ui,
                palette: controller.palette,
                revealInFinder: controller.revealInFinder)
            ZStack(alignment: .topLeading) {
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
                            WelcomeView(controller: controller, openURL: openURL)
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity)
                    .background(controller.palette.background.color)
                }

                if !ui.sidebarVisible && workspace.folderURL != nil {
                    // 16px hover hot zone on the window's left edge
                    Color.clear
                        .frame(width: 16)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onHover { inside in
                            if inside {
                                withAnimation(.easeOut(duration: 0.24)) { ui.peekShown = true }
                            }
                        }
                    if ui.peekShown {
                        SidebarV2View(controller: controller, workspace: workspace,
                                      ui: ui, isPeek: true)
                            .frame(width: 236)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.25), radius: 22, y: 8)
                            .padding(.leading, 8)
                            .padding(.vertical, 10)
                            .onHover { inside in
                                if !inside {
                                    withAnimation(.easeOut(duration: 0.2)) { ui.peekShown = false }
                                }
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
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
