import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            SystemSettings()
                .tabItem { Label("System", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 440)
        .padding(.bottom, 8)
    }
}

private struct GeneralSettings: View {
    @AppStorage(SessionStore.restoreEnabledKey) private var restoreSession = true
    @AppStorage(OpenDocument.largeFileThresholdKey) private var thresholdMB = 2.0
    @State private var widthStatus = ""

    var body: some View {
        Form {
            Toggle("Restore previous session on launch", isOn: $restoreSession)
            LabeledContent("Large-file notice above") {
                HStack(spacing: 4) {
                    Stepper(value: $thresholdMB, in: 1...50, step: 1) {
                        Text("\(Int(thresholdMB)) MB")
                    }
                }
            }
            LabeledContent("Sidebar width") {
                Button("Reset to default") {
                    SidebarDefaults.reset(in: .standard)
                    widthStatus = "Reset. Takes effect on next window."
                }
            }
            if !widthStatus.isEmpty {
                Text(widthStatus).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct SystemSettings: View {
    @State private var systemStatus = ""

    var body: some View {
        Form {
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
        .formStyle(.grouped)
    }
}
