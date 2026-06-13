import AppKit

/// Minimal, dependency-free update check.
///
/// Fetches a small appcast JSON and, if a newer version is published, offers to
/// open the download page. No background daemon and no framework (Sparkle would
/// add several MB): the renderer is the weight viewmd pays for, so updates add
/// ~nothing. Security model: this only routes the user to a download. The actual
/// install is a user-driven, Developer-ID-notarized DMG, so the check itself
/// never needs to verify or execute a payload.
enum Updater {
    /// The appcast location. Placeholder until a release feed is hosted; see
    /// docs/RELEASE.md. Auto-check on launch stays off until this is real.
    static let feedURL = URL(string: "https://viewmd.app/appcast.json")

    struct Appcast: Codable {
        let version: String       // e.g. "0.3.0"
        let downloadURL: String   // release page or DMG URL
        let notes: String?
    }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// True if `latest` is strictly newer than `current`. Dotted numeric compare;
    /// uneven lengths pad with zero, non-numeric components count as zero.
    static func isNewer(_ latest: String, than current: String) -> Bool {
        let a = components(latest), b = components(current)
        for i in 0..<max(a.count, b.count) {
            let l = i < a.count ? a[i] : 0
            let r = i < b.count ? b[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    private static func components(_ v: String) -> [Int] {
        v.split(separator: ".").map { Int($0.prefix(while: \.isNumber)) ?? 0 }
    }

    // MARK: - User-facing check

    @MainActor
    static func checkForUpdates(userInitiated: Bool) {
        guard let feedURL else { return }
        URLSession.shared.dataTask(with: feedURL) { data, _, _ in
            let cast = data.flatMap { try? JSONDecoder().decode(Appcast.self, from: $0) }
            Task { @MainActor in present(cast, userInitiated: userInitiated) }
        }.resume()
    }

    @MainActor
    private static func present(_ cast: Appcast?, userInitiated: Bool) {
        guard let cast else {
            if userInitiated { info("Unable to check for updates", "Please try again later.") }
            return
        }
        guard isNewer(cast.version, than: currentVersion) else {
            if userInitiated { info("You are up to date", "viewmd \(currentVersion) is the latest version.") }
            return
        }
        let alert = NSAlert()
        alert.messageText = "viewmd \(cast.version) is available"
        alert.informativeText = cast.notes ?? "You have \(currentVersion)."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: cast.downloadURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    private static func info(_ title: String, _ body: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = body
        a.runModal()
    }
}
