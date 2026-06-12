import SwiftUI

extension FileNode {
    var childrenOrNil: [FileNode]? { isDirectory ? children : nil }
}

struct SidebarView: View {
    @ObservedObject var workspace: Workspace

    var body: some View {
        List {
            OutlineGroup(workspace.tree, children: \.childrenOrNil) { node in
                if node.isDirectory {
                    Label(node.name, systemImage: "folder")
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        workspace.openFile(node.url)
                    } label: {
                        Label(node.name, systemImage: "doc.text")
                            .fontWeight(workspace.activeTab?.url == node.url ? .medium : .regular)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
