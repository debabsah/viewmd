import XCTest
@testable import viewmd

final class ReadingStatsTests: XCTestCase {

    func testCountsWordsAndStripsHeadingMarker() {
        let s = ReadingStats.compute("# Heading\n\nThe quick brown fox jumps over the lazy dog.")
        XCTAssertEqual(s.words, 10)   // "Heading" + 9 sentence words
    }

    func testExcludesFencedCode() {
        let md = "Real words here\n\n```swift\nlet ignored = code(value)\n```\n\nMore real words"
        XCTAssertEqual(ReadingStats.compute(md).words, 6)
    }

    func testExcludesFrontmatter() {
        let md = "---\ntitle: Hi\ntags: [a, b]\n---\n\nJust three words"
        XCTAssertEqual(ReadingStats.compute(md).words, 3)
    }

    func testPunctuationOnlyTokensDoNotCount() {
        // the lone em dash and bullet markers must not inflate the count
        let s = ReadingStats.compute("- one\n- two\n\nthree — four")
        XCTAssertEqual(s.words, 4)
    }

    func testReadingMinutesRoundsUp() {
        let md = String(repeating: "word ", count: 201)
        XCTAssertEqual(ReadingStats.compute(md).readingMinutes, 2)
    }

    func testEmptyDocumentIsZero() {
        let s = ReadingStats.compute("")
        XCTAssertEqual(s.words, 0)
        XCTAssertEqual(s.readingMinutes, 0)
        XCTAssertEqual(s.characters, 0)
    }

    func testCharactersExcludeWhitespace() {
        XCTAssertEqual(ReadingStats.compute("ab cd").characters, 4)
    }
}
