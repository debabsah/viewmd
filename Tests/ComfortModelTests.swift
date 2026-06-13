import XCTest
@testable import viewmd

@MainActor
final class ComfortModelTests: XCTestCase {

    func testOnChangeIsDebounced() {
        let defaults = UserDefaults(suiteName: "vmd-cm-\(UUID().uuidString)")!
        let model = ComfortModel(themeStore: ThemeStore(), defaults: defaults)
        var fires = 0
        model.onChange = { fires += 1 }

        for size in 16...20 {                  // a slider drag burst
            model.settings.fontSize = Double(size)
        }
        XCTAssertEqual(fires, 0, "debounce must hold during the burst")
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(fires, 1, "burst coalesces to one render")
        XCTAssertEqual(ComfortSettings.load(from: defaults).fontSize, 20,
                       "persistence is immediate even while renders debounce")
    }
}
