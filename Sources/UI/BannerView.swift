import SwiftUI
import AppKit

struct BannerView: View {
    @ObservedObject var document: OpenDocument

    var body: some View {
        switch document.banner {
        case .none:
            EmptyView()
        case .conflict:
            banner(icon: "exclamationmark.triangle.fill",
                   text: "Changed on disk") {
                Button("Reload") { document.reloadFromDisk() }
                Button("Keep Mine") { try? document.keepMine() }
            }
        case .missing:
            banner(icon: "questionmark.folder.fill",
                   text: "File was deleted or moved") {
                Button("Save As…") { saveAs() }
                Button("Dismiss") { document.banner = .none }
            }
        case .notice(let message):
            banner(icon: "info.circle.fill", text: message) {
                Button("OK") { document.banner = .none }
            }
        }
    }

    @ViewBuilder
    private func banner(icon: String, text: String,
                        @ViewBuilder buttons: () -> some View) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
            Text(text).lineLimit(1)
            Spacer()
            HStack(spacing: 8, content: buttons)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(Divider(), alignment: .bottom)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func saveAs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = document.displayName
        if panel.runModal() == .OK, let url = panel.url {
            try? document.saveAs(url)
        }
    }
}
