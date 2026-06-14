import XCTest
@testable import viewmd

final class LocalImageTests: XCTestCase {
    let base = URL(fileURLWithPath: "/docs/notes")

    func testRelativeResolvesAgainstBase() {
        XCTAssertEqual(LocalImageSchemeHandler.fileURL(for: "img/a.png", base: base)?.path,
                       "/docs/notes/img/a.png")
    }

    func testParentRelativeResolves() {
        XCTAssertEqual(LocalImageSchemeHandler.fileURL(for: "../assets/a.png", base: base)?.path,
                       "/docs/assets/a.png")
    }

    func testAbsolutePathUsedAsIs() {
        XCTAssertEqual(LocalImageSchemeHandler.fileURL(for: "/Users/x/a.png", base: base)?.path,
                       "/Users/x/a.png")
    }

    func testCaseInsensitiveExtension() {
        XCTAssertNotNil(LocalImageSchemeHandler.fileURL(for: "a.PNG", base: base))
        XCTAssertNotNil(LocalImageSchemeHandler.fileURL(for: "diagram.SVG", base: base))
    }

    func testNonImageExtensionRejected() {
        // a document must not be able to pull arbitrary files off disk
        XCTAssertNil(LocalImageSchemeHandler.fileURL(for: "../secret.txt", base: base))
        XCTAssertNil(LocalImageSchemeHandler.fileURL(for: "/etc/passwd", base: base))
        XCTAssertNil(LocalImageSchemeHandler.fileURL(for: "notes.md", base: base))
    }

    func testRelativeWithoutBaseIsNil() {
        XCTAssertNil(LocalImageSchemeHandler.fileURL(for: "a.png", base: nil))
    }
}
