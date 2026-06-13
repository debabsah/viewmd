import XCTest
@testable import viewmd

final class ComfortSettingsTests: XCTestCase {

    func testDefaults() {
        let c = ComfortSettings()
        XCTAssertEqual(c.themeID, "refined")
        XCTAssertEqual(c.fontSize, 15)
        XCTAssertEqual(c.codeBlocks, "auto")
        XCTAssertNil(c.fontFamily)
        XCTAssertEqual(c.fontPack, .themeDefault)
        XCTAssertNil(c.appearanceOverride)
    }

    func testRoundTripThroughDefaults() {
        let defaults = UserDefaults(suiteName: "vmd-comfort-\(UUID().uuidString)")!
        var c = ComfortSettings()
        c.themeID = "dracula"; c.fontSize = 18; c.codeBlocks = "dark"
        c.fontPack = .serif
        c.save(to: defaults)
        XCTAssertEqual(ComfortSettings.load(from: defaults), c)
    }

    func testV1PayloadMigratesWithDefaultFontPack() {
        // exactly what v0.1.0 persisted: no fontPack field
        let v1JSON = #"{"themeID":"nord","fontSize":17,"lineWidth":800,"lineSpacing":1.7,"codeBlocks":"light"}"#
        let defaults = UserDefaults(suiteName: "vmd-comfort-mig-\(UUID().uuidString)")!
        defaults.set(v1JSON.data(using: .utf8), forKey: ComfortSettings.defaultsKey)
        let c = ComfortSettings.load(from: defaults)
        XCTAssertEqual(c.themeID, "nord")
        XCTAssertEqual(c.fontSize, 17)
        XCTAssertEqual(c.fontPack, .themeDefault)   // migrated default
        XCTAssertNil(c.fontFamily)
    }

    func testEffectiveFontFamilyPrecedence() {
        var c = ComfortSettings()
        XCTAssertNil(c.effectiveFontFamily)                       // theme default
        c.fontPack = .serif
        XCTAssertEqual(c.effectiveFontFamily, "Charter, Georgia, serif")
        c.fontPack = .mono
        XCTAssertEqual(c.effectiveFontFamily, "\"SF Mono\", Menlo, monospace")
        c.fontFamily = "Avenir"                                   // custom beats pack
        XCTAssertEqual(c.effectiveFontFamily, "Avenir")
    }

    func testZoomClampsAtBounds() {
        var c = ComfortSettings()
        c.fontSize = 27
        c.zoomIn(); XCTAssertEqual(c.fontSize, 28)
        c.zoomIn(); XCTAssertEqual(c.fontSize, 28)
        c.fontSize = 10
        c.zoomOut(); XCTAssertEqual(c.fontSize, 9)
        c.zoomOut(); XCTAssertEqual(c.fontSize, 9)
        c.resetZoom(); XCTAssertEqual(c.fontSize, 15)
    }
}
