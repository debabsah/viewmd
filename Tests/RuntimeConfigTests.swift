import XCTest
@testable import viewmd

final class RuntimeConfigTests: XCTestCase {

    private func def(_ json: String) -> RuntimeConfig.Definition? {
        RuntimeConfig.parse(json.data(using: .utf8))
    }

    func testParsesAllKeys() {
        let d = def(#"""
        {
          "general.defaultOpenDirectory": "/tmp/docs",
          "reader.largeFileThresholdMB": 5.5,
          "reader.userCSSEnabled": false
        }
        """#)
        XCTAssertEqual(d?.defaultOpenDirectory, "/tmp/docs")
        XCTAssertEqual(d?.largeFileThresholdMB, 5.5)
        XCTAssertEqual(d?.userCSSEnabled, false)
    }

    func testPartialJSONLeavesMissingKeysNil() {
        let d = def(#"{ "reader.largeFileThresholdMB": 1.0 }"#)
        XCTAssertEqual(d?.largeFileThresholdMB, 1.0)
        XCTAssertNil(d?.defaultOpenDirectory)
        XCTAssertNil(d?.userCSSEnabled)
    }

    func testGarbageJSONReturnsNil() {
        XCTAssertNil(RuntimeConfig.parse("not json".data(using: .utf8)))
        XCTAssertNil(RuntimeConfig.parse(nil))
    }

    func testUserCSSEnabledDefaultsTrue() {
        XCTAssertTrue(RuntimeConfig.resolvedUserCSSEnabled(nil))
        XCTAssertTrue(RuntimeConfig.resolvedUserCSSEnabled(def("{}")))
        XCTAssertFalse(RuntimeConfig.resolvedUserCSSEnabled(def(#"{ "reader.userCSSEnabled": false }"#)))
    }

    func testDefaultOpenDirectoryResolves() {
        XCTAssertNil(RuntimeConfig.resolvedDefaultOpenDirectory(nil))
        XCTAssertNil(RuntimeConfig.resolvedDefaultOpenDirectory(def(#"{ "general.defaultOpenDirectory": "" }"#)))
        let url = RuntimeConfig.resolvedDefaultOpenDirectory(def(#"{ "general.defaultOpenDirectory": "/tmp/docs" }"#))
        XCTAssertEqual(url?.path, "/tmp/docs")
    }

    func testDefaultOpenDirectoryExpandsTilde() {
        let url = RuntimeConfig.resolvedDefaultOpenDirectory(def(#"{ "general.defaultOpenDirectory": "~/Documents" }"#))
        XCTAssertFalse(url?.path.hasPrefix("~") ?? true)
        XCTAssertTrue(url?.path.hasSuffix("/Documents") ?? false)
    }

    func testLargeFileThresholdPassesThrough() {
        XCTAssertNil(RuntimeConfig.resolvedLargeFileThresholdMB(nil))
        XCTAssertEqual(RuntimeConfig.resolvedLargeFileThresholdMB(def(#"{ "reader.largeFileThresholdMB": 3.0 }"#)), 3.0)
    }
}
