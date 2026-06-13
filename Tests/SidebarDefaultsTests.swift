import XCTest
@testable import viewmd

final class SidebarDefaultsTests: XCTestCase {

    func testDefaultWidth() {
        let defaults = UserDefaults(suiteName: "vmd-side-\(UUID().uuidString)")!
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 232)
    }

    func testRoundTripAndClamp() {
        let defaults = UserDefaults(suiteName: "vmd-side-rt-\(UUID().uuidString)")!
        SidebarDefaults.saveWidth(300, to: defaults)
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 300)
        SidebarDefaults.saveWidth(80, to: defaults)      // below min
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 180)
        SidebarDefaults.saveWidth(900, to: defaults)     // above max
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 340)
    }

    func testCorruptValueResets() {
        let defaults = UserDefaults(suiteName: "vmd-side-bad-\(UUID().uuidString)")!
        defaults.set("garbage", forKey: SidebarDefaults.widthKey)
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 232)
    }

    func testReset() {
        let defaults = UserDefaults(suiteName: "vmd-side-reset-\(UUID().uuidString)")!
        SidebarDefaults.saveWidth(300, to: defaults)
        SidebarDefaults.reset(in: defaults)
        XCTAssertEqual(SidebarDefaults.loadWidth(from: defaults), 232)
    }
}
