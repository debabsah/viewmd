import SwiftUI
import AppKit

/// The Notion-style sidebar: header (workspace + live dot + collapse «),
/// filter row (⌘P), the collapsible file tree, and the bottom utility
/// cluster (Aa panel, Edit mode, Open Folder). Palette colors only.
struct SidebarV2View: View {
    @ObservedObject var controller: WorkspaceWindowController
    @ObservedObject var workspace: Workspace
    @ObservedObject var ui: WindowUIState
    let isPeek: Bool

    @State private var filterQuery = ""
    @State private var expanded: Set<URL> = []
    @FocusState private var filterFocused: Bool

    private var palette: ShellPalette { controller.palette }

    private var visibleTree: [FileNode] {
        TreeFilter.filter(workspace.tree, query: filterQuery)
    }

    private var fileCount: Int {
        func count(_ nodes: [FileNode]) -> Int {
            nodes.reduce(0) { $0 + ($1.isDirectory ? count($1.children) : 1) }
        }
        return count(workspace.tree)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterRow
            ScrollView {
                LazyVStack(spacing: 1) {
                    TreeLevel(nodes: visibleTree, depth: 0, palette: palette,
                              expanded: $expanded,
                              forceExpand: !filterQuery.isEmpty,
                              activeURL: workspace.activeTab?.url,
                              open: { workspace.openFile($0) })
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            bottomCluster
        }
        .background(palette.sideBackground.color)
        .onAppear { expandAll() }
        .onChange(of: workspace.folderURL) { _ in expandAll() }
        .onChange(of: ui.filterFocusToken) { _ in filterFocused = true }
    }

    private func expandAll() {
        func collect(_ nodes: [FileNode], into set: inout Set<URL>) {
            for n in nodes where n.isDirectory {
                set.insert(n.url)
                collect(n.children, into: &set)
            }
        }
        var all = Set<URL>()
        collect(workspace.tree, into: &all)
        expanded = all
    }

    private var header: some View {
        HStack(spacing: 7) {
            Text("▤ \(workspace.folderURL?.lastPathComponent ?? "files")")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(palette.text.color)
                .lineLimit(1)
            Text("· \(fileCount) files")
                .font(.system(size: 11.5))
                .foregroundStyle(palette.mutedText.color)
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
                .help(dotHelp)
            Spacer()
            if !isPeek {
                Button {
                    withAnimation(.easeOut(duration: 0.26)) { ui.sidebarVisible = false }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.mutedText.color)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Collapse Sidebar (⌘B)")
            }
        }
        .padding(.init(top: 9, leading: 14, bottom: 5, trailing: 10))
    }

    private var dotColor: Color {
        if ui.reloadFlash { return palette.accent.color }
        if workspace.activeTab?.isWatching == true { return Color(.sRGB, red: 0.13, green: 0.77, blue: 0.37) }
        return palette.mutedText.color
    }

    private var dotHelp: String {
        workspace.activeTab?.isWatching == true
            ? "Watching — live reload on" : "Not watching"
    }

    private var filterRow: some View {
        SidebarRow(palette: palette) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(palette.mutedText.color)
                .frame(width: 18)
            TextField("Filter files", text: $filterQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(palette.softText.color)
                .focused($filterFocused)
                .onExitCommand { filterQuery = ""; filterFocused = false }
            if !filterQuery.isEmpty {
                Button { filterQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(palette.mutedText.color)
                }
                .buttonStyle(.plain)
            } else {
                Text("⌘P")
                    .font(.system(size: 10.5))
                    .foregroundStyle(palette.mutedText.color)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 5).fill(palette.wash.color))
            }
        }
        .padding(.horizontal, 8)
    }

    private var bottomCluster: some View {
        VStack(spacing: 1) {
            SidebarRow(palette: palette, action: { ui.aaPanelShown.toggle() }) {
                Text("Aa").font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(palette.mutedText.color).frame(width: 18)
                Text("Theme & display").font(.system(size: 13))
                    .foregroundStyle(palette.softText.color)
                Spacer()
            }
            .popover(isPresented: $ui.aaPanelShown, arrowEdge: .trailing) {
                AaPanelPlaceholder()   // replaced by AaPanelView in Task 10
            }
            SidebarRow(palette: palette, action: { controller.toggleSourceAction(nil) }) {
                Image(systemName: "pencil").font(.system(size: 12))
                    .foregroundStyle(editActive ? palette.accentText.color : palette.mutedText.color)
                    .frame(width: 18)
                Text("Edit mode").font(.system(size: 13, weight: editActive ? .semibold : .regular))
                    .foregroundStyle(editActive ? palette.accentText.color : palette.softText.color)
                Spacer()
                Text("⌘E").font(.system(size: 10.5))
                    .foregroundStyle(palette.mutedText.color)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 5).fill(palette.wash.color))
            }
            SidebarRow(palette: palette, action: {
                (NSApp.delegate as? AppDelegate)?.openFolderAction(nil)
            }) {
                Image(systemName: "plus").font(.system(size: 12))
                    .foregroundStyle(palette.mutedText.color).frame(width: 18)
                Text("Open Folder…").font(.system(size: 13))
                    .foregroundStyle(palette.softText.color)
                Spacer()
            }
        }
        .padding(.init(top: 4, leading: 8, bottom: 10, trailing: 8))
    }

    private var editActive: Bool {
        workspace.activeTab?.mode == .source
    }
}

/// One 28px Notion row with hover wash. Content is arbitrary.
struct SidebarRow<Content: View>: View {
    let palette: ShellPalette
    var action: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6, content: content)
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? palette.wash.color : .clear))
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .onTapGesture { action?() }
    }
}

/// Recursive tree level: folders with rotating chevrons, files with glyphs.
struct TreeLevel: View {
    let nodes: [FileNode]
    let depth: Int
    let palette: ShellPalette
    @Binding var expanded: Set<URL>
    let forceExpand: Bool   // while filtering, all ancestors stay open
    let activeURL: URL?
    let open: (URL) -> Void

    var body: some View {
        ForEach(nodes) { node in
            if node.isDirectory {
                FolderRow(node: node, depth: depth, palette: palette,
                          isExpanded: forceExpand || expanded.contains(node.url),
                          toggle: {
                              if expanded.contains(node.url) { expanded.remove(node.url) }
                              else { expanded.insert(node.url) }
                          })
                if forceExpand || expanded.contains(node.url) {
                    TreeLevel(nodes: node.children, depth: depth + 1, palette: palette,
                              expanded: $expanded, forceExpand: forceExpand,
                              activeURL: activeURL, open: open)
                }
            } else {
                FileRow(node: node, depth: depth, palette: palette,
                        isActive: node.url == activeURL, open: { open(node.url) })
            }
        }
    }
}

private struct FolderRow: View {
    let node: FileNode
    let depth: Int
    let palette: ShellPalette
    let isExpanded: Bool
    let toggle: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(palette.mutedText.color)
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .animation(.easeOut(duration: 0.18), value: isExpanded)
                .frame(width: 18, height: 18)
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(hovering ? palette.wash2.color : .clear))
            Text(node.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.softText.color)
                .lineLimit(1)
            Spacer()
            if hovering {
                Text("\(node.children.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.mutedText.color)
            }
        }
        .padding(.leading, CGFloat(depth) * 12 + 8)
        .padding(.trailing, 8)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(hovering ? palette.wash.color : .clear))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: toggle)
    }
}

private struct FileRow: View {
    let node: FileNode
    let depth: Int
    let palette: ShellPalette
    let isActive: Bool
    let open: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 11.5))
                .foregroundStyle((isActive ? palette.accent : palette.mutedText).color)
                .frame(width: 18)
            Text(node.name)
                .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                .foregroundStyle((isActive ? palette.accentText : palette.softText).color)
                .lineLimit(1)
            Spacer()
        }
        .padding(.leading, CGFloat(depth) * 12 + 8)
        .padding(.trailing, 8)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(isActive ? AnyShapeStyle(palette.tint.color)
                           : AnyShapeStyle(hovering ? palette.wash.color : .clear)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: open)
    }
}

/// Temporary stand-in until Task 10 ships the real panel.
struct AaPanelPlaceholder: View {
    var body: some View {
        Text("Theme & display — Task 10")
            .font(.system(size: 12))
            .padding(20)
    }
}
