import Foundation

/// Sidebar tree filter (the ⌘P row): case-insensitive fuzzy subsequence
/// match on FILE names; folders are retained only as ancestors of matches.
enum TreeFilter {
    static func matches(_ name: String, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerName = name.lowercased()
        let lowerQuery = query.lowercased()
        var cursor = lowerName.startIndex
        for ch in lowerQuery {
            guard let found = lowerName[cursor...].firstIndex(of: ch) else { return false }
            cursor = lowerName.index(after: found)
        }
        return true
    }

    static func filter(_ nodes: [FileNode], query: String) -> [FileNode] {
        guard !query.isEmpty else { return nodes }
        return nodes.compactMap { node in
            if node.isDirectory {
                let children = filter(node.children, query: query)
                guard !children.isEmpty else { return nil }
                var copy = node
                copy.children = children
                return copy
            }
            return matches(node.name, query: query) ? node : nil
        }
    }
}
