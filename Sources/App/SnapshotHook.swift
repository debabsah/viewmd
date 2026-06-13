import AppKit

/// Dev/verification only: permission-free self-capture of viewmd's own window.
///
/// An app may snapshot its OWN window's native layer tree via `cacheDisplay`
/// without the Screen Recording TCC permission that `screencapture` needs.
/// All v0.2.0 shell UI is native SwiftUI hosted in an NSView, so this captures
/// exactly the chrome under test (the WKWebView document area composites in a
/// separate process and may render blank here — that is fine; the document
/// rendering is unchanged from v0.1.0 and verified elsewhere).
///
/// Triggered by env vars (inert in normal use):
///   VMD_SHOT        — output PNG path (required to activate)
///   VMD_SHOT_DELAY  — seconds to wait for first render (default 3.5)
///   VMD_SHOT_OPEN   — a file/folder path to open before capture (argv is
///                     ignored on direct-binary launch, so open it explicitly)
///   VMD_SHOT_AA     — if "1", open the Theme & display popover before capture
enum SnapshotHook {
    @MainActor
    static func runIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let path = env["VMD_SHOT"] else { return }
        let delay = Double(env["VMD_SHOT_DELAY"] ?? "") ?? 3.5

        if let openPath = env["VMD_SHOT_OPEN"],
           let controller = (NSApp.delegate as? AppDelegate)?.mainController() {
            controller.open(url: URL(fileURLWithPath: openPath))
            // opening a file after the folder keeps the sidebar visible, so a
            // themed capture shows sidebar + document together
            if let filePath = env["VMD_SHOT_OPENFILE"] {
                controller.open(url: URL(fileURLWithPath: filePath))
            }
        }
        if env["VMD_SHOT_AA"] == "1",
           let controller = (NSApp.delegate as? AppDelegate)?.controllers.first {
            // route through the action so the sidebar is revealed first (the
            // panel's popover anchors to a sidebar row)
            controller.showAaPanelAction(nil)
        }
        if env["VMD_SHOT_OUTLINE"] == "1",
           let controller = (NSApp.delegate as? AppDelegate)?.controllers.first {
            // reveal the sidebar and switch it to the document outline pane
            controller.showOutlineAction(nil)
        }
        if env["VMD_SHOT_SETTINGS"] == "1" {
            (NSApp.delegate as? AppDelegate)?.showSettingsAction(nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            capture(to: path)
            NSApp.terminate(nil)
        }
    }

    @MainActor
    private static func capture(to path: String) {
        // Prefer a popover/panel window if one is open (e.g. the Aa panel),
        // else the main workspace window.
        let window = NSApp.windows.first(where: { $0.isVisible && $0.className.contains("Popover") })
            ?? NSApp.keyWindow
            ?? NSApp.windows.first(where: { $0.isVisible })
        guard let view = window?.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
