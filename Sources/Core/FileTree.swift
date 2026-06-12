import Foundation

struct FileNode: Identifiable, Equatable {
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]
    var id: URL { url }
}

enum FileTree {
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

    /// Recursive scan: markdown files + directories that (transitively) contain them.
    /// Hidden entries are skipped. Directories sort before files, alphabetically.
    static func scan(root: URL) -> [FileNode] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else { return [] }

        var nodes: [FileNode] = []
        for entry in entries {
            let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                let children = scan(root: entry)
                if !children.isEmpty {
                    nodes.append(FileNode(url: entry, name: entry.lastPathComponent,
                                          isDirectory: true, children: children))
                }
            } else if markdownExtensions.contains(entry.pathExtension.lowercased()) {
                nodes.append(FileNode(url: entry, name: entry.lastPathComponent,
                                      isDirectory: false, children: []))
            }
        }
        return nodes.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
