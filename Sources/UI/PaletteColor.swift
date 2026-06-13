import SwiftUI

// UI-layer bridge: keeps SwiftUI out of Core while letting every shell view
// write `palette.background.color`.
extension RGBA {
    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
