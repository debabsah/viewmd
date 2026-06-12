import XCTest
@testable import viewmd

@MainActor
final class WorkspaceTests: XCTestCase {
    var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-ws-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "a".write(to: dir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)
        try "b".write(to: dir.appendingPathComponent("b.md"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testOpenFileCreatesAndActivatesTab() {
        let ws = Workspace()
        let doc = ws.openFile(dir.appendingPathComponent("a.md"))
        XCTAssertNotNil(doc)
        XCTAssertEqual(ws.tabs.count, 1)
        XCTAssertEqual(ws.activeTab?.id, doc?.id)
    }

    func testOpeningSameFileFocusesExistingTab() {
        let ws = Workspace()
        let first = ws.openFile(dir.appendingPathComponent("a.md"))
        _ = ws.openFile(dir.appendingPathComponent("b.md"))
        let again = ws.openFile(dir.appendingPathComponent("a.md"))
        XCTAssertEqual(ws.tabs.count, 2)
        XCTAssertEqual(again?.id, first?.id)
        XCTAssertEqual(ws.activeTab?.id, first?.id)
    }

    func testOpenFolderPopulatesTree() {
        let ws = Workspace()
        ws.openFolder(dir)
        XCTAssertEqual(ws.folderURL, dir)
        XCTAssertEqual(ws.tree.map(\.name), ["a.md", "b.md"])
    }

    func testCloseActiveTabActivatesNeighbor() {
        let ws = Workspace()
        let a = ws.openFile(dir.appendingPathComponent("a.md"))!
        let b = ws.openFile(dir.appendingPathComponent("b.md"))!
        ws.activeTabID = a.id
        ws.closeTab(id: a.id)
        XCTAssertEqual(ws.tabs.map(\.id), [b.id])
        XCTAssertEqual(ws.activeTabID, b.id)
    }

    func testCloseLastTabLeavesNoActive() {
        let ws = Workspace()
        let a = ws.openFile(dir.appendingPathComponent("a.md"))!
        ws.closeTab(id: a.id)
        XCTAssertTrue(ws.tabs.isEmpty)
        XCTAssertNil(ws.activeTabID)
    }
}
