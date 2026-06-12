import AppKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var controllers: [WorkspaceWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = makeMinimalMenu()
        mainController().showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @MainActor
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { mainController().open(url: $0) }
    }

    @MainActor
    func mainController() -> WorkspaceWindowController {
        if let existing = controllers.first { return existing }
        let controller = WorkspaceWindowController()
        controllers.append(controller)
        return controller
    }

    // MARK: - Menu actions

    @MainActor @objc func openDocumentAction(_ sender: Any?) {
        let panel = NSOpenPanel()
        if let md = UTType("net.daringfireball.markdown") {
            panel.allowedContentTypes = [md, .plainText]
        }
        if panel.runModal() == .OK, let url = panel.url {
            mainController().open(url: url)
        }
    }

    @MainActor @objc func openFolderAction(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            mainController().open(url: url)
        }
    }

    // Minimal menu; the full menu (with View/source toggle etc.) lands in Task 16.
    private func makeMinimalMenu() -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit viewmd",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…",
                         action: #selector(openDocumentAction(_:)), keyEquivalent: "o")
        let openFolder = NSMenuItem(title: "Open Folder…",
                                    action: #selector(openFolderAction(_:)), keyEquivalent: "O")
        openFolder.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(openFolder)
        fileItem.submenu = fileMenu
        main.addItem(fileItem)

        return main
    }
}
