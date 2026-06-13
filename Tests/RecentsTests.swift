import XCTest
@testable import viewmd

final class RecentsTests: XCTestCase {

    func testEntriesDetectFoldersAndMissingPaths() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-recents-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.md")
        try "a".write(to: file, atomically: true, encoding: .utf8)
        let missing = dir.appendingPathComponent("gone.md")

        let entries = Recents.entries(from: [file, dir, missing])
        XCTAssertEqual(entries.count, 3)
        XCTAssertFalse(entries[0].isFolder); XCTAssertTrue(entries[0].exists)
        XCTAssertTrue(entries[1].isFolder); XCTAssertTrue(entries[1].exists)
        XCTAssertFalse(entries[2].exists)
    }

    func testLimitApplies() {
        let urls = (0..<10).map { URL(fileURLWithPath: "/tmp/r\($0).md") }
        XCTAssertEqual(Recents.entries(from: urls, limit: 4).count, 4)
    }
}
