import XCTest
@testable import viewmd

final class UpdaterTests: XCTestCase {

    func testNewerVersionDetected() {
        XCTAssertTrue(Updater.isNewer("0.3.0", than: "0.2.0"))
        XCTAssertTrue(Updater.isNewer("1.0.0", than: "0.9.9"))
        XCTAssertTrue(Updater.isNewer("0.2.1", than: "0.2.0"))
    }

    func testEqualOrOlderIsNotNewer() {
        XCTAssertFalse(Updater.isNewer("0.2.0", than: "0.2.0"))
        XCTAssertFalse(Updater.isNewer("0.2.0", than: "0.3.0"))
        XCTAssertFalse(Updater.isNewer("0.9.9", than: "1.0.0"))
    }

    func testUnevenComponentCounts() {
        XCTAssertTrue(Updater.isNewer("0.3", than: "0.2.9"))
        XCTAssertFalse(Updater.isNewer("0.2", than: "0.2.0"))
        XCTAssertTrue(Updater.isNewer("0.2.0.1", than: "0.2.0"))
    }

    func testNonNumericComponentsTreatedAsZero() {
        XCTAssertTrue(Updater.isNewer("1.0", than: "0.x"))
        XCTAssertFalse(Updater.isNewer("0.0", than: "0.0"))
    }
}
