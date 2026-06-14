import SwiftUI
import AppKit

// UI-layer bridge: keeps SwiftUI out of Core while letting every shell view
// write `palette.background.color`.
extension RGBA {
    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    // Same sRGB values as `color`, for AppKit layers (the titlebar drag view).
    var nsColor: NSColor {
        NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
}
