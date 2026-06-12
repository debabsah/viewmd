import SwiftUI

struct SettingsView: View {
    @AppStorage(SessionStore.restoreEnabledKey) private var restoreSession = true

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Restore previous session on launch", isOn: $restoreSession)
            }
            // Section("System") gains Install CLI / Default app in Task 19
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(.bottom, 8)
    }
}
