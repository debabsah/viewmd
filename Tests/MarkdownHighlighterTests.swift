import XCTest
@testable import viewmd

final class MarkdownHighlighterTests: XCTestCase {

    private func kinds(_ text: String) -> [MarkdownHighlighter.TokenKind] {
        MarkdownHighlighter.tokenRanges(in: text).map(\.kind)
    }

    func testHeadingLine() {
        let tokens = MarkdownHighlighter.tokenRanges(in: "# Title\nbody")
        XCTAssertEqual(tokens.first?.kind, .heading)
        XCTAssertEqual(tokens.first?.range, NSRange(location: 0, length: 7))
    }

    func testFencedCodeBlockSpansLines() {
        let text = "a\n```\nlet x = 1\n```\nb"
        XCTAssertTrue(kinds(text).contains(.codeBlock))
    }

    func testInlineCodeBoldAndLink() {
        let text = "use `cmd` with **force** see [docs](https://x.y)"
        let found = kinds(text)
        XCTAssertTrue(found.contains(.inlineCode))
        XCTAssertTrue(found.contains(.bold))
        XCTAssertTrue(found.contains(.link))
    }

    func testPlainTextHasNoTokens() {
        XCTAssertTrue(MarkdownHighlighter.tokenRanges(in: "just words").isEmpty)
    }
}
