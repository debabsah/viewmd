import XCTest
@testable import viewmd

final class ComfortSettingsTests: XCTestCase {

    func testDefaults() {
        let c = ComfortSettings()
        XCTAssertEqual(c.themeID, "refined")
        XCTAssertEqual(c.fontSize, 15)
        XCTAssertEqual(c.codeBlocks, "auto")
        XCTAssertNil(c.fontFamily)
    }

    func testRoundTripThroughDefaults() {
        let defaults = UserDefaults(suiteName: "vmd-comfort-\(UUID().uuidString)")!
        var c = ComfortSettings()
        c.themeID = "dracula"; c.fontSize = 18; c.codeBlocks = "dark"
        c.save(to: defaults)
        XCTAssertEqual(ComfortSettings.load(from: defaults), c)
    }

    func testLoadWithNothingSavedReturnsDefaults() {
        let defaults = UserDefaults(suiteName: "vmd-comfort-empty-\(UUID().uuidString)")!
        XCTAssertEqual(ComfortSettings.load(from: defaults), ComfortSettings())
    }

    func testZoomClampsAtBounds() {
        var c = ComfortSettings()
        c.fontSize = 27
        c.zoomIn(); XCTAssertEqual(c.fontSize, 28)
        c.zoomIn(); XCTAssertEqual(c.fontSize, 28)   // clamped
        c.fontSize = 10
        c.zoomOut(); XCTAssertEqual(c.fontSize, 9)
        c.zoomOut(); XCTAssertEqual(c.fontSize, 9)   // clamped
        c.resetZoom(); XCTAssertEqual(c.fontSize, 15)
    }
}
