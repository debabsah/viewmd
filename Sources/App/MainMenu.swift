import AppKit

@MainActor
final class MainMenuBuilder: NSObject, NSMenuDelegate {
    static let shared = MainMenuBuilder()
    private let recentMenu = NSMenu(title: "Open Recent")

    func build() -> NSMenu {
        let main = NSMenu()
        main.addItem(appMenuItem())
        main.addItem(fileMenuItem())
        main.addItem(editMenuItem())
        main.addItem(viewMenuItem())
        main.addItem(windowMenuItem())
        return main
    }

    private func appMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(withTitle: "About viewmd",
                     action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                     keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        let settings = NSMenuItem(title: "Settings…",
                                  action: #selector(AppDelegate.showSettingsAction(_:)),
                                  keyEquivalent: ",")
        menu.addItem(settings)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit viewmd",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    private func fileMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "Open…",
                     action: #selector(AppDelegate.openDocumentAction(_:)), keyEquivalent: "o")
        let openFolder = NSMenuItem(title: "Open Folder…",
                                    action: #selector(AppDelegate.openFolderAction(_:)),
                                    keyEquivalent: "O")
        openFolder.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(openFolder)

        recentMenu.delegate = self
        let recentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        recentItem.submenu = recentMenu
        menu.addItem(recentItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Save",
                     action: #selector(WorkspaceWindowController.saveDocumentAction(_:)),
                     keyEquivalent: "s")
        menu.addItem(withTitle: "Close Tab",
                     action: #selector(WorkspaceWindowController.closeTabAction(_:)),
                     keyEquivalent: "w")
        let closeWindow = NSMenuItem(title: "Close Window",
                                     action: #selector(NSWindow.performClose(_:)),
                                     keyEquivalent: "W")
        closeWindow.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(closeWindow)
        item.submenu = menu
        return item
    }

    private func editMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(redo)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All",
                     action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        item.submenu = menu
        return item
    }

    private func viewMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "View")
        menu.addItem(withTitle: "Toggle Source",
                     action: #selector(WorkspaceWindowController.toggleSourceAction(_:)),
                     keyEquivalent: "e")
        menu.addItem(withTitle: "Toggle Sidebar",
                     action: #selector(WorkspaceWindowController.toggleSidebarAction(_:)),
                     keyEquivalent: "b")
        menu.addItem(NSMenuItem.separator())
        let zoomIn = NSMenuItem(title: "Zoom In",
                                action: #selector(WorkspaceWindowController.zoomInAction(_:)),
                                keyEquivalent: "+")
        menu.addItem(zoomIn)
        menu.addItem(withTitle: "Zoom Out",
                     action: #selector(WorkspaceWindowController.zoomOutAction(_:)),
                     keyEquivalent: "-")
        menu.addItem(withTitle: "Actual Size",
                     action: #selector(WorkspaceWindowController.zoomResetAction(_:)),
                     keyEquivalent: "0")
        item.submenu = menu
        return item
    }

    private func windowMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize",
                     action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        NSApp.windowsMenu = menu
        item.submenu = menu
        return item
    }

    // MARK: - Open Recent (manual, non-NSDocument app)

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === recentMenu else { return }
        menu.removeAllItems()
        for url in NSDocumentController.shared.recentDocumentURLs {
            let item = NSMenuItem(title: url.lastPathComponent,
                                  action: #selector(AppDelegate.openRecentAction(_:)),
                                  keyEquivalent: "")
            item.representedObject = url
            item.toolTip = url.path
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Clear Menu",
                     action: #selector(AppDelegate.clearRecentsAction(_:)), keyEquivalent: "")
    }
}
