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
            tabSwitcher
            if ui.sidebarTab == .files {
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
            } else if let tab = workspace.activeTab {
                OutlinePane(document: tab, palette: palette,
                            onTap: { controller.scrollToHeading($0) })
            } else {
                OutlineEmpty(palette: palette, message: "Open a document to see its outline")
            }
            bottomCluster
        }
        .background(palette.sideBackground.color)
        .onAppear { expandAll() }
        .onChange(of: workspace.folderURL) { _ in expandAll() }
        .onChange(of: ui.filterFocusToken) { _ in
            ui.sidebarTab = .files
            DispatchQueue.main.async { filterFocused = true }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            segButton("Files", tab: .files)
            segButton("Outline", tab: .outline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 5)
    }

    @ViewBuilder
    private func segButton(_ title: String, tab: WindowUIState.SidebarTab) -> some View {
        let active = ui.sidebarTab == tab
        Text(title)
            .font(.system(size: 12, weight: active ? .semibold : .regular))
            .foregroundStyle((active ? palette.accentText : palette.mutedText).color)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(active ? palette.tint.color : Color.clear))
            .contentShape(Rectangle())
            .onTapGesture { ui.sidebarTab = tab }
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
            LiveDot(color: dotColor,
                    pulsing: workspace.activeTab?.isWatching == true)
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
                AaPanelView(controller: controller, model: controller.comfortModel)
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

/// The watch indicator: a solid dot with a soft halo that pulses outward
/// while the active document is being watched (the halo stays invisible when
/// not watching). The animation runs continuously; visibility is gated by
/// `pulsing`, so it reacts immediately when watch state changes.
private struct LiveDot: View {
    let color: Color
    let pulsing: Bool
    @State private var phase = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .background(
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .scaleEffect(phase ? 2.6 : 1)
                    .opacity(pulsing ? (phase ? 0 : 0.55) : 0)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = true
                }
            }
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

/// The outline pane: the active document's headings, indented by level, each
/// tappable to scroll the document to that heading. Observes the document so it
/// refreshes whenever a render posts a fresh heading list. Palette colors only.
private struct OutlinePane: View {
    @ObservedObject var document: OpenDocument
    let palette: ShellPalette
    let onTap: (String) -> Void

    var body: some View {
        if document.headings.isEmpty {
            OutlineEmpty(palette: palette, message: "No headings in this document")
        } else {
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(document.headings) { heading in
                        OutlineRow(heading: heading, palette: palette,
                                   tap: { onTap(heading.key) })
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
        }
    }
}

private struct OutlineRow: View {
    let heading: Heading
    let palette: ShellPalette
    let tap: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Text(heading.text)
                .font(.system(size: fontSize, weight: heading.level <= 1 ? .semibold : .regular))
                .foregroundStyle((heading.level <= 1 ? palette.softText : palette.mutedText).color)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.leading, CGFloat(max(0, heading.level - 1)) * 12 + 8)
        .padding(.trailing, 8)
        .frame(height: 26)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(hovering ? palette.wash.color : Color.clear))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: tap)
    }

    private var fontSize: CGFloat {
        switch heading.level {
        case 1: return 13.5
        case 2: return 13
        default: return 12.5
        }
    }
}

private struct OutlineEmpty: View {
    let palette: ShellPalette
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            Text(message)
                .font(.system(size: 12.5))
                .foregroundStyle(palette.mutedText.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
