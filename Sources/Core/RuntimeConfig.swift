import Foundation

/// Power-user configuration not surfaced in the Aa panel, read once at launch
/// from `~/Library/Application Support/viewmd/settings.json`.
///
/// Pattern mirrors a pro "settings.json": a clean UI for everyone, deep config
/// for power users. Missing file or keys fall back to defaults; invalid JSON is
/// ignored (defaults used). Changes to settings.json apply on next launch;
/// `user.css` is re-read on every render, so its edits apply live.
enum RuntimeConfig {
    struct Definition: Codable {
        let defaultOpenDirectory: String?
        let largeFileThresholdMB: Double?
        let userCSSEnabled: Bool?

        enum CodingKeys: String, CodingKey {
            case defaultOpenDirectory = "general.defaultOpenDirectory"
            case largeFileThresholdMB = "reader.largeFileThresholdMB"
            case userCSSEnabled = "reader.userCSSEnabled"
        }
    }

    // MARK: - File locations

    static var supportDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("viewmd", isDirectory: true)
    }

    static var settingsURL: URL { supportDirectory.appendingPathComponent("settings.json") }
    static var userCSSURL: URL { supportDirectory.appendingPathComponent("user.css") }

    // MARK: - Pure helpers (testable, no file access)

    static func parse(_ data: Data?) -> Definition? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(Definition.self, from: data)
    }

    static func resolvedDefaultOpenDirectory(_ d: Definition?) -> URL? {
        guard let path = d?.defaultOpenDirectory,
              !path.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    }

    static func resolvedUserCSSEnabled(_ d: Definition?) -> Bool { d?.userCSSEnabled ?? true }
    static func resolvedLargeFileThresholdMB(_ d: Definition?) -> Double? { d?.largeFileThresholdMB }

    // MARK: - Live accessors (file-backed, cached at first use)

    private static let definition = parse(try? Data(contentsOf: settingsURL))

    static var defaultOpenDirectory: URL? { resolvedDefaultOpenDirectory(definition) }
    static var userCSSEnabled: Bool { resolvedUserCSSEnabled(definition) }
    static var largeFileThresholdMB: Double? { resolvedLargeFileThresholdMB(definition) }

    /// The contents of `user.css` if present, non-empty, and enabled. Appended
    /// after the active theme CSS so its rules win.
    static var userCSS: String? {
        guard userCSSEnabled,
              let css = try? String(contentsOf: userCSSURL, encoding: .utf8),
              !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return css
    }

    /// Create the support directory and seed example files (idempotent). Call
    /// before any live accessor so first launch finds the documented template.
    static func bootstrap() {
        try? FileManager.default.createDirectory(
            at: supportDirectory, withIntermediateDirectories: true)
        seed(settingsURL, contents: """
        {
          "general.defaultOpenDirectory": "",
          "reader.largeFileThresholdMB": 2.0,
          "reader.userCSSEnabled": true
        }

        """)
        seed(userCSSURL, contents:
            "/* viewmd user stylesheet. Rules here override the active theme. */\n")
    }

    private static func seed(_ url: URL, contents: String) {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try? contents.data(using: .utf8)?.write(to: url)
    }
}
