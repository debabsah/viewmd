import Foundation

/// Lightweight reading metrics for the active document.
///
/// Computed from the raw markdown with a light strip of YAML frontmatter, fenced
/// code, and leading block markers, so counts reflect prose rather than syntax.
/// Cheap O(n) scan, fine to recompute on change.
struct ReadingStats: Equatable {
    let words: Int
    let characters: Int        // non-whitespace prose characters
    let readingMinutes: Int    // 0 for empty, else ceil(words / wordsPerMinute), min 1

    static let wordsPerMinute = 200

    static func compute(_ markdown: String) -> ReadingStats {
        let prose = stripped(markdown)
        let words = prose
            .split(whereSeparator: { $0.isWhitespace })
            .filter { token in token.contains { $0.isLetter || $0.isNumber } }
            .count
        let characters = prose.reduce(0) { $1.isWhitespace ? $0 : $0 + 1 }
        let minutes = words == 0
            ? 0
            : max(1, Int((Double(words) / Double(wordsPerMinute)).rounded(.up)))
        return ReadingStats(words: words, characters: characters, readingMinutes: minutes)
    }

    /// Drop frontmatter and fenced code blocks, and strip leading block markers
    /// (heading #, blockquote >, list bullets/numbers) so they are not counted.
    static func stripped(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")

        // leading YAML frontmatter: --- ... ---
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---",
           let end = lines.dropFirst().firstIndex(where: {
               $0.trimmingCharacters(in: .whitespaces) == "---"
           }) {
            lines.removeSubrange(0...end)
        }

        var out: [String] = []
        var inFence = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            if inFence { continue }
            out.append(stripLeadingMarkers(line))
        }
        return out.joined(separator: "\n")
    }

    private static func stripLeadingMarkers(_ line: String) -> String {
        var s = line
        for pattern in [#"^\s*#{1,6}\s+"#, #"^\s*>\s?"#, #"^\s*([-*+]|\d+\.)\s+"#] {
            s = s.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return s
    }
}
