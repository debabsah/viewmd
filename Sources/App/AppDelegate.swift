import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var controllers: [WorkspaceWindowController] = []
    private var settingsWindow: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [SessionStore.restoreEnabledKey: true])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = MainMenuBuilder.shared.build()
        mainController().showWindow(nil)
        if UserDefaults.standard.bool(forKey: SessionStore.restoreEnabledKey),
           let snapshot = SessionStore.load() {
            SessionStore.apply(snapshot, using: mainController())
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: SessionStore.restoreEnabledKey),
              let controller = controllers.first else { return }
        SessionStore.save(SessionStore.capture(controller.workspace))
        controller.workspace.teardown()
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

    @MainActor @objc func openRecentAction(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        mainController().open(url: url)
    }

    @objc func clearRecentsAction(_ sender: Any?) {
        NSDocumentController.shared.clearRecentDocuments(nil)
    }

    @objc func showSettingsAction(_ sender: Any?) {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
