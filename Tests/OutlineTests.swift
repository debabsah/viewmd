import XCTest
@testable import viewmd

final class OutlineTests: XCTestCase {

    func testParseDecodesHeadings() {
        let items: [[String: Any]] = [
            ["key": "Intro#0", "level": 1, "text": "Intro"],
            ["key": "Design#0", "level": 2, "text": "Design"]
        ]
        let heads = Heading.parse(items)
        XCTAssertEqual(heads.count, 2)
        XCTAssertEqual(heads[0], Heading(key: "Intro#0", level: 1, text: "Intro"))
        XCTAssertEqual(heads[1].level, 2)
        XCTAssertEqual(heads[1].text, "Design")
    }

    func testParseDefaultsMissingLevelToOne() {
        let heads = Heading.parse([["key": "A#0", "text": "A"]])
        XCTAssertEqual(heads.first?.level, 1)
    }

    func testParseSkipsMalformedEntries() {
        let items: [[String: Any]] = [
            ["key": "Good#0", "level": 2, "text": "Good"],
            ["level": 2, "text": "NoKey"],      // missing key
            ["key": "NoText#0", "level": 1]      // missing text
        ]
        XCTAssertEqual(Heading.parse(items).map(\.key), ["Good#0"])
    }

    func testHeadingIdentifiableUsesKey() {
        XCTAssertEqual(Heading(key: "X#1", level: 3, text: "X").id, "X#1")
    }
}
