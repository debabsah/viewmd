import Foundation

/// Persisted sidebar width with spec bounds (180-340, default 232).
enum SidebarDefaults {
    static let widthKey = "sidebar.width"
    static let widthRange: ClosedRange<Double> = 180...340
    static let defaultWidth: Double = 232

    static func loadWidth(from defaults: UserDefaults = .standard) -> Double {
        guard let number = defaults.object(forKey: widthKey) as? Double else {
            return defaultWidth
        }
        return min(max(number, widthRange.lowerBound), widthRange.upperBound)
    }

    static func saveWidth(_ width: Double, to defaults: UserDefaults = .standard) {
        let clamped = min(max(width, widthRange.lowerBound), widthRange.upperBound)
        defaults.set(clamped, forKey: widthKey)
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: widthKey)
    }
}
