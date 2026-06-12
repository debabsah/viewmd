import Foundation

struct Theme: Identifiable, Equatable {
    let id: String                 // filename stem, e.g. "refined"
    let name: String               // display name from the header comment
    let appearances: Set<String>   // "light" / "dark"
    let css: String
}

final class ThemeStore {
    private let bundledDir: URL
    private let userDir: URL

    /// Default locations: the app bundle's dist/themes and
    /// ~/Library/Application Support/viewmd/themes (created on init).
    init(bundledDir: URL? = nil, userDir: URL? = nil) {
        self.bundledDir = bundledDir
            ?? Bundle.main.resourceURL!.appendingPathComponent("dist/themes")
        let defaultUser = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("viewmd/themes")
        self.userDir = userDir ?? defaultUser
        try? FileManager.default.createDirectory(
            at: self.userDir, withIntermediateDirectories: true)
    }

    func themes() -> [Theme] {
        scan(bundledDir) + scan(userDir)
    }

    func theme(id: String) -> Theme? {
        themes().first { $0.id == id }
    }

    /// Header contract: `/* viewmd-theme: Name; appearances: light,dark */`
    static func parseHeader(_ css: String) -> (name: String, appearances: Set<String>)? {
        let pattern = #"/\*\s*viewmd-theme:\s*([^;]+);\s*appearances:\s*([^*]+?)\s*\*/"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: css, range: NSRange(css.startIndex..., in: css)),
              let nameRange = Range(match.range(at: 1), in: css),
              let appsRange = Range(match.range(at: 2), in: css) else { return nil }
        let name = css[nameRange].trimmingCharacters(in: .whitespaces)
        let apps = Set(css[appsRange].split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) })
        return (name, apps)
    }

    private func scan(_ dir: URL) -> [Theme] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files
            .filter { $0.pathExtension == "css" && $0.lastPathComponent != "base.css" }
            .compactMap { url -> Theme? in
                guard let css = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let stem = url.deletingPathExtension().lastPathComponent
                let header = Self.parseHeader(css)
                return Theme(id: stem,
                             name: header?.name ?? stem,
                             appearances: header?.appearances ?? ["light", "dark"],
                             css: css)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
