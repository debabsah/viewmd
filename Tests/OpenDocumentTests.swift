import XCTest
@testable import viewmd

@MainActor
final class OpenDocumentTests: XCTestCase {
    var dir: URL!
    var file: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-doc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        file = dir.appendingPathComponent("doc.md")
        try "# One".write(to: file, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func waitUntil(timeout: TimeInterval = 3, _ cond: @escaping () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !cond() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(cond())
    }

    func testOpenLoadsText() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        XCTAssertEqual(doc.text, "# One")
        XCTAssertEqual(doc.stateMachine.state, .clean)
    }

    func testExternalChangeAutoReloadsWhenClean() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        try "# Two".write(to: file, atomically: true, encoding: .utf8)
        waitUntil { doc.text == "# Two" }
        XCTAssertEqual(doc.banner, .none)
    }

    func testExternalChangeWithEditsShowsConflictNotClobber() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        doc.text = "# Mine"
        doc.noteUserEdit()
        try "# Theirs".write(to: file, atomically: true, encoding: .utf8)
        waitUntil { doc.banner == .conflict }
        XCTAssertEqual(doc.text, "# Mine")        // buffer untouched
        XCTAssertEqual(doc.stateMachine.state, .conflicted)
    }

    func testConflictReloadTakesDisk() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        doc.text = "# Mine"; doc.noteUserEdit()
        try "# Theirs".write(to: file, atomically: true, encoding: .utf8)
        waitUntil { doc.banner == .conflict }
        doc.reloadFromDisk()
        XCTAssertEqual(doc.text, "# Theirs")
        XCTAssertEqual(doc.stateMachine.state, .clean)
        XCTAssertEqual(doc.banner, .none)
    }

    func testSaveWritesDiskAndDoesNotBounceBack() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        var reloads = 0
        doc.onDiskReload = { reloads += 1 }
        doc.text = "# Saved"; doc.noteUserEdit()
        try doc.save()
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "# Saved")
        XCTAssertEqual(doc.stateMachine.state, .clean)
        // suppression: our own atomic save must not trigger a reload loop
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(reloads, 0)
        XCTAssertEqual(doc.text, "# Saved")
    }

    func testDeleteShowsMissingBannerAndKeepsBuffer() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        try FileManager.default.removeItem(at: file)
        waitUntil { doc.banner == .missing }
        XCTAssertEqual(doc.text, "# One")
    }

    func testConflictKeepMineWritesBufferAndClears() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        var reloads = 0
        doc.onDiskReload = { reloads += 1 }
        doc.text = "# Mine"; doc.noteUserEdit()
        try "# Theirs".write(to: file, atomically: true, encoding: .utf8)
        waitUntil { doc.banner == .conflict }
        try doc.keepMine()
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "# Mine")
        XCTAssertEqual(doc.stateMachine.state, .clean)
        XCTAssertEqual(doc.banner, .none)
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(reloads, 0)               // no bounce-back reload
        XCTAssertEqual(doc.text, "# Mine")
    }

    func testSaveAsRebindsURLAndWatchesNewFile() throws {
        let doc = OpenDocument(url: file, watcherDebounce: 0.05)
        try doc.open()
        defer { doc.teardown() }
        let newURL = dir.appendingPathComponent("renamed.md")
        doc.text = "# Moved"
        try doc.saveAs(newURL)
        XCTAssertEqual(doc.url, newURL)
        XCTAssertEqual(try String(contentsOf: newURL, encoding: .utf8), "# Moved")
        // watcher must now track the NEW file
        try "# External".write(to: newURL, atomically: true, encoding: .utf8)
        waitUntil { doc.text == "# External" }
    }
}
