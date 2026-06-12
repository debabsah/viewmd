import Foundation

struct SessionSnapshot: Codable, Equatable {
    var folderPath: String?
    var openFilePaths: [String]
    var activeFilePath: String?
}

enum SessionStore {
    static let defaultsKey = "session.snapshot"
    static let restoreEnabledKey = "session.restoreEnabled"

    @MainActor
    static func capture(_ workspace: Workspace) -> SessionSnapshot {
        SessionSnapshot(
            folderPath: workspace.folderURL?.path,
            openFilePaths: workspace.tabs.map { $0.url.path },
            activeFilePath: workspace.activeTab?.url.path)
    }

    static func save(_ snapshot: SessionSnapshot, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    static func load(from defaults: UserDefaults = .standard) -> SessionSnapshot? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(SessionSnapshot.self, from: data)
    }

    @MainActor
    static func apply(_ snapshot: SessionSnapshot, using controller: WorkspaceWindowController) {
        if let folder = snapshot.folderPath,
           FileManager.default.fileExists(atPath: folder) {
            controller.open(url: URL(fileURLWithPath: folder))
        }
        for path in snapshot.openFilePaths where FileManager.default.fileExists(atPath: path) {
            controller.open(url: URL(fileURLWithPath: path))
        }
        if let active = snapshot.activeFilePath,
           let tab = controller.workspace.tabs.first(where: { $0.url.path == active }) {
            controller.workspace.activeTabID = tab.id
        }
    }
}
