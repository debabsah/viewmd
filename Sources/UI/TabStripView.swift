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
            Spacer().frame(width: 78)   // traffic-light zone (drag handle)
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
            Spacer().frame(width: 6)    // tiny gap before the tabs (drag handle)
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
            Spacer(minLength: 10)       // right drag zone, after the + (drag handle)
        }
        .frame(height: 38)
        // The empty gaps above (traffic-light zone, before-tabs, after-+) fall
        // through to this drag layer; tabs/buttons sit on top and keep their
        // clicks. So the strip gets native window drag + double-click-to-zoom,
        // Notion-style, while still wearing the theme's side tone.
        .background(WindowDragArea(color: palette.sideBackground.nsColor))
    }
}

/// The native equivalent of Electron's `-webkit-app-region: drag`: a view the
/// window treats as its title bar. Empty areas of the strip get drag-to-move
/// and double-click-to-zoom for free; interactive controls on top opt out by
/// consuming their own clicks. Paints the strip's theme tone so themes are
/// unaffected.
private struct WindowDragArea: NSViewRepresentable {
    let color: NSColor

    func makeNSView(context: Context) -> NSView {
        let view = TitlebarDragView()
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        view.layer?.backgroundColor = color.cgColor
    }
}

private final class TitlebarDragView: NSView {
    // Marks this region as titlebar: the OS handles drag and double-click-to-zoom.
    override var mouseDownCanMoveWindow: Bool { true }

    // Fallback for when the hosting view delivers the click here instead of
    // letting the window treat it as a titlebar drag: replicate the native
    // behavior, honoring the system "double-click a title bar to…" setting.
    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount >= 2 {
            switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
            case "Minimize": window.miniaturize(nil)
            case "None": break
            default: window.performZoom(nil)   // "Maximize" / "Fill" / unset
            }
        } else {
            window.performDrag(with: event)
        }
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
