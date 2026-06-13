import Foundation
import Combine

/// Per-window shell state: sidebar geometry/visibility, peek overlay,
/// Aa panel presentation, and the filter-focus signal.
@MainActor
final class WindowUIState: ObservableObject {
    /// Which pane the sidebar shows: the file tree or the document outline.
    enum SidebarTab { case files, outline }

    @Published var sidebarTab: SidebarTab = .files
    @Published var sidebarVisible = true {
        didSet { if sidebarVisible { peekShown = false } }
    }
    @Published var sidebarWidth: Double = SidebarDefaults.loadWidth()
    @Published var peekShown = false
    @Published var aaPanelShown = false
    /// Incremented to ask the sidebar to focus its filter field (⌘P).
    @Published var filterFocusToken = 0
    /// Briefly true after a live disk reload — the sidebar dot flashes accent.
    @Published var reloadFlash = false

    func flashReload() {
        reloadFlash = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            self.reloadFlash = false
        }
    }

    func persistWidth() {
        SidebarDefaults.saveWidth(sidebarWidth)
    }
}
