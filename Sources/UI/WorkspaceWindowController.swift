import AppKit
import SwiftUI
import Combine

@MainActor
final class WorkspaceWindowController: NSWindowController {
    let workspace = Workspace()
    let bridge = RenderBridge()
    private var cancellables = Set<AnyCancellable>()
    private var lastTabID: UUID?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = false
        window.center()
        window.setFrameAutosaveName("viewmd.workspace")
        self.init(window: window)
        window.contentView = NSHostingView(rootView: WorkspaceRootView(
            workspace: workspace, bridge: bridge,
            openURL: { [weak self] in self?.open(url: $0) }))

        bridge.onOpenExternal = { NSWorkspace.shared.open($0) }
        bridge.onOpenRelative = { [weak self] href in
            guard let self,
                  let base = self.workspace.activeTab?.url.deletingLastPathComponent() else { return }
            let target = URL(fileURLWithPath: href, relativeTo: base).standardizedFileURL
            if FileManager.default.fileExists(atPath: target.path) {
                self.open(url: target)
            }
        }
        workspace.$activeTabID
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in self?.activeTabChanged(to: id) }
            .store(in: &cancellables)
    }

    func open(url: URL) {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue {
            workspace.openFolder(url)
        } else {
            workspace.openFile(url)
        }
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func activeTabChanged(to newID: UUID?) {
        if let last = lastTabID, last != newID,
           let outgoing = workspace.tabs.first(where: { $0.id == last }) {
            bridge.currentScrollTop { outgoing.savedScrollTop = $0 }
        }
        lastTabID = newID
        guard let doc = workspace.tabs.first(where: { $0.id == newID }) else {
            window?.title = "viewmd"
            return
        }
        doc.onDiskReload = { [weak self, weak doc] in
            guard let self, let doc else { return }
            // background tabs reload their model silently; only the active tab renders
            guard doc.id == self.workspace.activeTabID else { return }
            self.render(doc, scroll: RenderBridge.Scroll(mode: "anchor", top: nil))
        }
        render(doc, scroll: RenderBridge.Scroll(mode: "absolute", top: doc.savedScrollTop))
        window?.title = doc.displayName
    }

    @objc func toggleSourceAction(_ sender: Any?) {
        guard let doc = workspace.activeTab else { return }
        if doc.mode == .rendered {
            doc.mode = .source
        } else {
            doc.mode = .rendered
            render(doc, scroll: RenderBridge.Scroll(mode: "anchor", top: nil))
        }
    }

    @objc func toggleSidebarAction(_ sender: Any?) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "showSidebar"), forKey: "showSidebar")
    }

    @objc func saveDocumentAction(_ sender: Any?) {
        guard let doc = workspace.activeTab else { return }
        do {
            try doc.save()
            if doc.mode == .rendered {
                render(doc, scroll: RenderBridge.Scroll(mode: "anchor", top: nil))
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()   // spec: alert, never drop the buffer
        }
    }

    @objc func closeTabAction(_ sender: Any?) {
        if let id = workspace.activeTabID {
            workspace.closeTab(id: id)
        } else {
            window?.performClose(sender)
        }
    }

    func render(_ doc: OpenDocument, scroll: RenderBridge.Scroll?) {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        bridge.render(RenderBridge.Payload(
            text: doc.text,
            appearance: dark ? "dark" : "light",
            codeBlocks: "auto",
            themeCSS: RenderBridge.bundledThemeCSS("refined"),  // ThemeStore arrives in Task 17
            comfort: nil,
            scroll: scroll))
    }
}
