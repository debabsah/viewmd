import AppKit

/// Lightweight regex-based Markdown highlighting for the source editor.
/// Deliberately minimal: structure cues, not a full grammar.
enum MarkdownHighlighter {
    enum TokenKind: Equatable { case heading, codeBlock, inlineCode, bold, link }
    struct Token: Equatable {
        let range: NSRange
        let kind: TokenKind
    }

    private static let patterns: [(TokenKind, NSRegularExpression)] = {
        func re(_ p: String, _ opts: NSRegularExpression.Options = []) -> NSRegularExpression {
            try! NSRegularExpression(pattern: p, options: opts)
        }
        return [
            (.codeBlock, re("^```[\\s\\S]*?^```", [.anchorsMatchLines])),
            (.heading, re("^#{1,6} .*$", [.anchorsMatchLines])),
            (.inlineCode, re("`[^`\n]+`")),
            (.bold, re("\\*\\*[^*\n]+\\*\\*")),
            (.link, re("\\[[^\\]\n]+\\]\\([^)\n]+\\)"))
        ]
    }()

    static func tokenRanges(in text: String) -> [Token] {
        let full = NSRange(text.startIndex..., in: text)
        var tokens: [Token] = []
        var claimed: [NSRange] = []   // code blocks claim their span first
        for (kind, regex) in patterns {
            regex.enumerateMatches(in: text, range: full) { match, _, _ in
                guard let r = match?.range else { return }
                if kind != .codeBlock && claimed.contains(where: { NSIntersectionRange($0, r).length > 0 }) {
                    return
                }
                if kind == .codeBlock { claimed.append(r) }
                tokens.append(Token(range: r, kind: kind))
            }
        }
        return tokens.sorted { $0.range.location < $1.range.location }
    }

    static func apply(to storage: NSTextStorage, baseFont: NSFont) {
        let text = storage.string
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor
        ], range: full)
        let mono = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
        for token in tokenRanges(in: text) {
            switch token.kind {
            case .heading:
                storage.addAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold),
                    .foregroundColor: NSColor.controlAccentColor
                ], range: token.range)
            case .codeBlock, .inlineCode:
                storage.addAttributes([
                    .font: mono,
                    .foregroundColor: NSColor.systemPurple
                ], range: token.range)
            case .bold:
                storage.addAttribute(
                    .font,
                    value: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold),
                    range: token.range)
            case .link:
                storage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: token.range)
            }
        }
    }
}
