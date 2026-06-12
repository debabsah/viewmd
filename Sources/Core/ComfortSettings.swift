import Foundation

struct ComfortSettings: Codable, Equatable {
    var themeID: String = "refined"
    var fontFamily: String? = nil      // nil = theme default
    var fontSize: Double = 15
    var lineWidth: Double = 760
    var lineSpacing: Double = 1.65
    var codeBlocks: String = "auto"    // "auto" | "light" | "dark"
    var appearanceOverride: String? = nil   // nil = follow macOS

    static let defaultsKey = "comfort.settings"
    static let fontSizeRange: ClosedRange<Double> = 9...28

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
