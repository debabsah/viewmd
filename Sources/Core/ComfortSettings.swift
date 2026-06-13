import Foundation

enum FontPack: String, Codable {
    case themeDefault
    case serif
    case mono
}

struct ComfortSettings: Codable, Equatable {
    var themeID: String = "refined"
    var fontFamily: String? = nil      // custom family; overrides fontPack
    var fontPack: FontPack = .themeDefault
    var fontSize: Double = 15
    var lineWidth: Double = 760
    var lineSpacing: Double = 1.65
    var codeBlocks: String = "auto"    // "auto" | "light" | "dark"
    var appearanceOverride: String? = nil   // nil = follow macOS

    static let defaultsKey = "comfort.settings"
    static let fontSizeRange: ClosedRange<Double> = 9...28

    init() {}

    // Tolerant decoding: every field optional in the payload so v1 settings
    // (no fontPack) and future additions migrate without data loss.
    enum CodingKeys: String, CodingKey {
        case themeID, fontFamily, fontPack, fontSize, lineWidth, lineSpacing,
             codeBlocks, appearanceOverride
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        themeID = try c.decodeIfPresent(String.self, forKey: .themeID) ?? "refined"
        fontFamily = try c.decodeIfPresent(String.self, forKey: .fontFamily)
        fontPack = try c.decodeIfPresent(FontPack.self, forKey: .fontPack) ?? .themeDefault
        fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? 15
        lineWidth = try c.decodeIfPresent(Double.self, forKey: .lineWidth) ?? 760
        lineSpacing = try c.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? 1.65
        codeBlocks = try c.decodeIfPresent(String.self, forKey: .codeBlocks) ?? "auto"
        appearanceOverride = try c.decodeIfPresent(String.self, forKey: .appearanceOverride)
    }

    /// Resolved CSS font-family for --vmd-font-body. nil = theme default.
    /// Precedence: custom family > font pack > theme default.
    var effectiveFontFamily: String? {
        if let fontFamily { return fontFamily }
        switch fontPack {
        case .themeDefault: return nil
        case .serif: return "Charter, Georgia, serif"
        case .mono: return "\"SF Mono\", Menlo, monospace"
        }
    }

    static func load(from defaults: UserDefaults = .standard) -> ComfortSettings {
        guard let data = defaults.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(ComfortSettings.self, from: data)
        else { return ComfortSettings() }
        return settings
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    mutating func zoomIn() { fontSize = min(fontSize + 1, Self.fontSizeRange.upperBound) }
    mutating func zoomOut() { fontSize = max(fontSize - 1, Self.fontSizeRange.lowerBound) }
    mutating func resetZoom() { fontSize = 15 }
}
