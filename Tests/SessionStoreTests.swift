import XCTest
@testable import viewmd

@MainActor
final class SessionStoreTests: XCTestCase {

    func testSnapshotRoundTripsThroughDefaults() {
        let defaults = UserDefaults(suiteName: "vmd-session-test-\(UUID().uuidString)")!
        let snapshot = SessionSnapshot(
            folderPath: "/tmp/docs",
            openFilePaths: ["/tmp/docs/a.md", "/tmp/docs/b.md"],
            activeFilePath: "/tmp/docs/b.md")
        SessionStore.save(snapshot, to: defaults)
        XCTAssertEqual(SessionStore.load(from: defaults), snapshot)
    }

    func testLoadWithNothingSavedReturnsNil() {
        let defaults = UserDefaults(suiteName: "vmd-session-empty-\(UUID().uuidString)")!
        XCTAssertNil(SessionStore.load(from: defaults))
    }

    func testCaptureReflectsWorkspace() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-session-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.md")
        try "a".write(to: file, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFolder(dir)
        ws.openFile(file)
        let snapshot = SessionStore.capture(ws)
        XCTAssertEqual(snapshot.folderPath, dir.standardizedFileURL.path)
        XCTAssertEqual(snapshot.openFilePaths, [file.standardizedFileURL.path])
        XCTAssertEqual(snapshot.activeFilePath, file.standardizedFileURL.path)
        ws.teardown()
    }
}
