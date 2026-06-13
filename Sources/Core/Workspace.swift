import Foundation

@MainActor
final class Workspace: ObservableObject {
    @Published private(set) var folderURL: URL?
    @Published private(set) var tree: [FileNode] = []
    @Published private(set) var tabs: [OpenDocument] = []
    @Published var activeTabID: UUID?

    private var folderWatcher: FolderWatcher?

    var activeTab: OpenDocument? { tabs.first { $0.id == activeTabID } }

    @discardableResult
    func openFile(_ url: URL) -> OpenDocument? {
        let std = url.standardizedFileURL
        if let existing = tabs.first(where: { $0.url == std }) {
            activeTabID = existing.id
            return existing
        }
        let doc = OpenDocument(url: std)
        do { try doc.open() } catch { return nil }
        tabs.append(doc)
        activeTabID = doc.id
        return doc
    }

    func openFolder(_ url: URL) {
        // Do not call standardizedFileURL on directories: on macOS it appends a
        // trailing slash when the directory exists, breaking equality checks.
        let std = url.absoluteURL
        folderURL = std
        rescan()
        folderWatcher?.stop()
        let watcher = FolderWatcher(url: std) { [weak self] in self?.rescan() }
        watcher.start()
        folderWatcher = watcher
    }

    func closeTab(id: UUID) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].teardown()
        tabs.remove(at: idx)
        if activeTabID == id {
            activeTabID = tabs.indices.contains(idx) ? tabs[idx].id : tabs.last?.id
        }
    }

    /// Close every tab except the given one, which becomes active.
    func closeTabs(except id: UUID) {
        for tab in tabs where tab.id != id { tab.teardown() }
        tabs.removeAll { $0.id != id }
        activeTabID = id
    }

    func teardown() {
        tabs.forEach { $0.teardown() }
        folderWatcher?.stop()
    }

    private func rescan() {
        guard let folderURL else { return }
        tree = FileTree.scan(root: folderURL)
    }
}
