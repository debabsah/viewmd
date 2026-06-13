import SwiftUI
import AppKit

/// The titlebar: traffic lights (system-drawn, we pad past them), the
/// sidebar-restore » when collapsed, document tabs, and the + button.
/// Wears the theme's side tone; the active tab merges into the page.
struct TabStripView: View {
    @ObservedObject var workspace: Workspace
    @ObservedObject var ui: WindowUIState
    let palette: ShellPalette
    let openFileAction: () -> Void
    let revealInFinder: (URL) -> Void

    var body: some View {
        HStack(spacing: 2) {
            Spacer().frame(width: 78)   // traffic-light zone
            if !ui.sidebarVisible {
                Button {
                    withAnimation(.easeOut(duration: 0.26)) { ui.sidebarVisible = true }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.softText.color)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Show Sidebar (⌘B)")
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            ForEach(workspace.tabs) { tab in
                TabItem(
                    title: tab.displayName,
                    isActive: tab.id == workspace.activeTabID,
                    palette: palette,
                    activate: { workspace.activeTabID = tab.id },
                    close: { workspace.closeTab(id: tab.id) },
                    closeOthers: { workspace.closeTabs(except: tab.id) },
                    reveal: { revealInFinder(tab.url) })
            }
            Button(action: openFileAction) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.mutedText.color)
                    .frame(width: 25, height: 25)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open File (⌘O)")
            Spacer(minLength: 0)
        }
        .frame(height: 38)
        .background(palette.sideBackground.color)
    }
}

private struct TabItem: View {
    let title: String
    let isActive: Bool
    let palette: ShellPalette
    let activate: () -> Void
    let close: () -> Void
    let closeOthers: () -> Void
    let reveal: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.system(size: 12.5, weight: isActive ? .semibold : .regular))
                .foregroundStyle((isActive ? palette.text : palette.softText).color)
                .lineLimit(1)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(palette.mutedText.color)
            }
            .buttonStyle(.plain)
            .opacity(hovering || isActive ? 0.8 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .frame(height: 32, alignment: .center)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                .fill(isActive ? palette.background.color
                               : (hovering ? palette.wash2.color : .clear)))
        .contentShape(Rectangle())
        .onTapGesture(perform: activate)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Close Tab", action: close)
            Button("Close Others", action: closeOthers)
            Button("Reveal in Finder", action: reveal)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
