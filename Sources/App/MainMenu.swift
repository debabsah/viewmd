import AppKit

@MainActor
final class MainMenuBuilder: NSObject, NSMenuDelegate {
    static let shared = MainMenuBuilder()
    private let recentMenu = NSMenu(title: "Open Recent")
    private let themeMenu = NSMenu(title: "Theme")
    private let appearanceMenu = NSMenu(title: "Appearance")
    private let fontMenu = NSMenu(title: "Font")

    private var activeController: WorkspaceWindowController? {
        NSApp.mainWindow?.windowController as? WorkspaceWindowController
            ?? (NSApp.delegate as? AppDelegate)?.controllers.first
    }

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
        menu.addItem(withTitle: "Settings…",
                     action: #selector(AppDelegate.showSettingsAction(_:)), keyEquivalent: ",")
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
        menu.addItem(withTitle: "Filter Files",
                     action: #selector(WorkspaceWindowController.focusFilterAction(_:)),
                     keyEquivalent: "p")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Save",
                     action: #selector(WorkspaceWindowController.saveDocumentAction(_:)),
                     keyEquivalent: "s")
        let saveAs = NSMenuItem(title: "Save As…",
                                action: #selector(WorkspaceWindowController.saveAsAction(_:)),
                                keyEquivalent: "S")
        saveAs.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(saveAs)
        menu.addItem(withTitle: "Reveal in Finder",
                     action: #selector(WorkspaceWindowController.revealActiveInFinderAction(_:)),
                     keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
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
        menu.addItem(NSMenuItem.separator())
        let find = NSMenuItem(title: "Find…",
                              action: #selector(WorkspaceWindowController.findAction(_:)),
                              keyEquivalent: "f")
        find.tag = Int(NSTextFinder.Action.showFindInterface.rawValue)
        menu.addItem(find)
        item.submenu = menu
        return item
    }

    private func viewMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "View")
        menu.addItem(withTitle: "Toggle Sidebar",
                     action: #selector(WorkspaceWindowController.toggleSidebarAction(_:)),
                     keyEquivalent: "b")
        let outline = NSMenuItem(title: "Show Outline",
                                 action: #selector(WorkspaceWindowController.showOutlineAction(_:)),
                                 keyEquivalent: "o")
        outline.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(outline)
        menu.addItem(withTitle: "Edit Mode",
                     action: #selector(WorkspaceWindowController.toggleSourceAction(_:)),
                     keyEquivalent: "e")
        menu.addItem(NSMenuItem.separator())
        themeMenu.delegate = self
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)
        appearanceMenu.delegate = self
        let appearanceItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        appearanceItem.submenu = appearanceMenu
        menu.addItem(appearanceItem)
        fontMenu.delegate = self
        let fontItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        fontItem.submenu = fontMenu
        menu.addItem(fontItem)
        menu.addItem(withTitle: "Theme & Display…",
                     action: #selector(WorkspaceWindowController.showAaPanelAction(_:)),
                     keyEquivalent: "")
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

    // MARK: - Dynamic submenus

    func menuNeedsUpdate(_ menu: NSMenu) {
        switch menu {
        case recentMenu: rebuildRecents(menu)
        case themeMenu: rebuildThemes(menu)
        case appearanceMenu: rebuildAppearance(menu)
        case fontMenu: rebuildFonts(menu)
        default: break
        }
    }

    private func rebuildRecents(_ menu: NSMenu) {
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

    private func rebuildThemes(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let controller = activeController else { return }
        let current = controller.comfortModel.settings.themeID
        for theme in controller.comfortModel.themeStore.themes() {
            let item = NSMenuItem(title: theme.name,
                                  action: #selector(WorkspaceWindowController.setThemeAction(_:)),
                                  keyEquivalent: "")
            item.representedObject = theme.id
            item.state = theme.id == current ? .on : .off
            menu.addItem(item)
        }
    }

    private func rebuildAppearance(_ menu: NSMenu) {
        menu.removeAllItems()
        let current = activeController?.comfortModel.settings.appearanceOverride
        for (title, value) in [("Light", "light"), ("Follow System", nil), ("Dark", "dark")]
            as [(String, String?)] {
            let item = NSMenuItem(title: title,
                                  action: #selector(WorkspaceWindowController.setAppearanceAction(_:)),
                                  keyEquivalent: "")
            item.representedObject = value
            item.state = current == value ? .on : .off
            menu.addItem(item)
        }
    }

    private func rebuildFonts(_ menu: NSMenu) {
        menu.removeAllItems()
        let current = activeController?.comfortModel.settings.fontPack
        for (title, pack) in [("Theme Default", FontPack.themeDefault),
                              ("Serif", .serif), ("Mono", .mono)] {
            let item = NSMenuItem(title: title,
                                  action: #selector(WorkspaceWindowController.setFontPackAction(_:)),
                                  keyEquivalent: "")
            item.representedObject = pack.rawValue
            item.state = current == pack ? .on : .off
            menu.addItem(item)
        }
    }
}
