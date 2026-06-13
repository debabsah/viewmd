import SwiftUI
import AppKit

/// Empty-window state per the aa-panel-welcome mockup: icon, two open
/// buttons with visible shortcuts, recents (files + folders), drop hint.
struct WelcomeView: View {
    @ObservedObject var controller: WorkspaceWindowController
    let openURL: (URL) -> Void

    @State private var recents: [RecentEntry] = []

    private var palette: ShellPalette { controller.palette }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(.sRGB, red: 0.388, green: 0.4, blue: 0.945),
                             Color(.sRGB, red: 0.545, green: 0.361, blue: 0.965)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: "doc.plaintext")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white))
                .shadow(color: Color(.sRGB, red: 0.388, green: 0.4, blue: 0.945)
                    .opacity(0.35), radius: 12, y: 4)
                .padding(.bottom, 14)
            Text("viewmd")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(palette.text.color)
            Text("Markdown, beautifully — and instantly.")
                .font(.system(size: 12.5))
                .foregroundStyle(palette.mutedText.color)
                .padding(.bottom, 18)

            HStack(spacing: 8) {
                welcomeButton("Open File", kbd: "⌘O", prominent: true) {
                    (NSApp.delegate as? AppDelegate)?.openDocumentAction(nil)
                }
                welcomeButton("Open Folder", kbd: "⌘⇧O", prominent: false) {
                    (NSApp.delegate as? AppDelegate)?.openFolderAction(nil)
                }
            }
            .padding(.bottom, 22)

            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RECENT")
                        .font(.system(size: 10.5, weight: .semibold)).kerning(0.5)
                        .foregroundStyle(palette.mutedText.color)
                        .padding(.bottom, 2)
                    ForEach(recents) { entry in
                        recentRow(entry)
                    }
                }
                .frame(width: 380)
            }

            Text("or drop a Markdown file or folder anywhere in this window")
                .font(.system(size: 12))
                .foregroundStyle(palette.mutedText.color)
                .padding(.horizontal, 22).padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(palette.wash2.color,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                .padding(.top, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background.color)
        .onAppear { recents = Recents.current() }
    }

    private func welcomeButton(_ title: String, kbd: String, prominent: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title).font(.system(size: 13, weight: prominent ? .semibold : .regular))
                Text(kbd).font(.system(size: 10))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill(prominent ? Color.white.opacity(0.22) : palette.wash2.color))
            }
            .foregroundStyle(prominent ? Color.white : palette.softText.color)
            .padding(.horizontal, 16).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 9)
                .fill(prominent ? palette.accent.color : palette.sideBackground.color))
        }
        .buttonStyle(.plain)
    }

    private func recentRow(_ entry: RecentEntry) -> some View {
        HStack(spacing: 8) {
            Image(systemName: entry.isFolder ? "folder" : "doc.text")
                .font(.system(size: 11.5))
                .foregroundStyle(palette.mutedText.color)
            Text(entry.name)
                .font(.system(size: 13))
                .foregroundStyle(palette.softText.color)
                .lineLimit(1)
            Spacer()
            Text(entry.exists ? entry.shortPath : "missing")
                .font(.system(size: 11))
                .foregroundStyle(palette.mutedText.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(RecentRowHover(palette: palette))
        .contentShape(Rectangle())
        .opacity(entry.exists ? 1 : 0.5)
        .onTapGesture { if entry.exists { openURL(entry.url) } }
    }
}

/// Hover wash helper (separate so each row tracks its own hover).
private struct RecentRowHover: View {
    let palette: ShellPalette
    @State private var hovering = false
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(hovering ? palette.wash.color : .clear)
            .onHover { hovering = $0 }
    }
}
