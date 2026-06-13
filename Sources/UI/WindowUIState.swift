import Foundation
import Combine

/// Per-window shell state: sidebar geometry/visibility, peek overlay,
/// Aa panel presentation, and the filter-focus signal.
@MainActor
final class WindowUIState: ObservableObject {
    @Published var sidebarVisible = true
    @Published var sidebarWidth: Double = SidebarDefaults.loadWidth()
    @Published var peekShown = false
    @Published var aaPanelShown = false
    /// Incremented to ask the sidebar to focus its filter field (⌘P).
    @Published var filterFocusToken = 0

    func persistWidth() {
        SidebarDefaults.saveWidth(sidebarWidth)
    }
}
