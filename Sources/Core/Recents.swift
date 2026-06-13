import AppKit

struct RecentEntry: Equatable, Identifiable {
    let url: URL
    let isFolder: Bool
    let exists: Bool
    var id: URL { url }
    var name: String { url.lastPathComponent }
    /// Abbreviated parent path for the welcome list's right column.
    var shortPath: String {
        let parent = url.deletingLastPathComponent().path
        let home = NSHomeDirectory()
        return parent.hasPrefix(home)
            ? "~" + parent.dropFirst(home.count)
            : parent
    }
}

enum Recents {
    /// Pure, testable core.
    static func entries(from urls: [URL], limit: Int = 6) -> [RecentEntry] {
        urls.prefix(limit).map { url in
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return RecentEntry(url: url, isFolder: isDir.boolValue, exists: exists)
        }
    }

    /// Live source: the same recents list the File menu shows.
    @MainActor
    static func current(limit: Int = 6) -> [RecentEntry] {
        entries(from: NSDocumentController.shared.recentDocumentURLs, limit: limit)
    }
}
