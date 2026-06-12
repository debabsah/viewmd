import XCTest
@testable import viewmd

final class ThemeStoreTests: XCTestCase {
    var bundledDir: URL!
    var userDir: URL!

    override func setUpWithError() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-themes-\(UUID().uuidString)")
        bundledDir = root.appendingPathComponent("bundled")
        userDir = root.appendingPathComponent("user")
        try FileManager.default.createDirectory(at: bundledDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        try "/* viewmd-theme: Refined; appearances: light,dark */\n:root{}"
            .write(to: bundledDir.appendingPathComponent("refined.css"), atomically: true, encoding: .utf8)
        try "/* viewmd-theme: Dracula; appearances: dark */\n:root{}"
            .write(to: bundledDir.appendingPathComponent("dracula.css"), atomically: true, encoding: .utf8)
        try "structural only".write(
            to: bundledDir.appendingPathComponent("base.css"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: bundledDir.deletingLastPathComponent())
    }

    func testDiscoversBundledThemesExcludingBase() {
        let store = ThemeStore(bundledDir: bundledDir, userDir: userDir)
        let themes = store.themes()
        XCTAssertEqual(themes.map(\.id), ["dracula", "refined"])
        XCTAssertEqual(themes.map(\.name), ["Dracula", "Refined"])
        XCTAssertEqual(themes.first?.appearances, ["dark"])
    }

    func testUserThemesAppearAfterBundled() throws {
        try "/* viewmd-theme: My Custom; appearances: light,dark */\n:root{}"
            .write(to: userDir.appendingPathComponent("custom.css"), atomically: true, encoding: .utf8)
        let store = ThemeStore(bundledDir: bundledDir, userDir: userDir)
        XCTAssertEqual(store.themes().map(\.id), ["dracula", "refined", "custom"])
    }

    func testMalformedHeaderFallsBackToFilename() throws {
        try ":root{ --no-header: 1 }"
            .write(to: userDir.appendingPathComponent("mystery.css"), atomically: true, encoding: .utf8)
        let store = ThemeStore(bundledDir: bundledDir, userDir: userDir)
        let mystery = store.theme(id: "mystery")
        XCTAssertEqual(mystery?.name, "mystery")
        XCTAssertEqual(mystery?.appearances, ["light", "dark"])
    }

    func testThemeByIDReturnsCSS() {
        let store = ThemeStore(bundledDir: bundledDir, userDir: userDir)
        XCTAssertTrue(store.theme(id: "refined")!.css.contains("viewmd-theme: Refined"))
        XCTAssertNil(store.theme(id: "nope"))
    }
}
