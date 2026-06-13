import Foundation

/// One document heading, surfaced in the sidebar outline panel.
///
/// `key` matches the web-side scroll-anchor key (`text#occurrence`) so a tap in
/// the outline maps back to a scroll position via `RenderBridge.scrollToHeading`.
struct Heading: Codable, Equatable, Identifiable {
    let key: String
    let level: Int
    let text: String

    var id: String { key }

    /// Decode the loosely-typed `headings` bridge message. JS numbers arrive as
    /// `NSNumber`; entries missing a key or text are skipped, missing level is 1.
    static func parse(_ items: [[String: Any]]) -> [Heading] {
        items.compactMap { item in
            guard let key = item["key"] as? String,
                  let text = item["text"] as? String else { return nil }
            let level = (item["level"] as? NSNumber)?.intValue ?? 1
            return Heading(key: key, level: level, text: text)
        }
    }
}
