import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct SettingsView: View {
    @AppStorage(SessionStore.restoreEnabledKey) private var restoreSession = true
    @State private var systemStatus = ""

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Restore previous session on launch", isOn: $restoreSession)
            }
            Section("System") {
                LabeledContent("Command line") {
                    Button("Install viewmd CLI") {
                        do {
                            let url = try CLIInstaller.installOnPath()
                            systemStatus = "Installed at \(url.path)"
                        } catch {
                            systemStatus = error.localizedDescription
                        }
                    }
                }
                LabeledContent("Default app") {
                    Button("Use viewmd for .md files") {
                        guard let md = UTType("net.daringfireball.markdown") else { return }
                        NSWorkspace.shared.setDefaultApplication(
                            at: Bundle.main.bundleURL, toOpen: md) { error in
                            Task { @MainActor in
                                systemStatus = error.map { $0.localizedDescription }
                                    ?? "viewmd is now the default for Markdown."
                            }
                        }
                    }
                }
                if !systemStatus.isEmpty {
                    Text(systemStatus).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(.bottom, 8)
    }
}
