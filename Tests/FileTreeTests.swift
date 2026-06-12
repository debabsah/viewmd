import XCTest
@testable import viewmd

final class FileTreeTests: XCTestCase {
    var root: URL!

    override func setUpWithError() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-tree-\(UUID().uuidString)")
        let fm = FileManager.default
        try fm.createDirectory(at: base.appendingPathComponent("docs/specs"), withIntermediateDirectories: true)
        // Resolve after creation so the URL matches what contentsOfDirectory returns
        root = base.resolvingSymlinksInPath()
        try fm.createDirectory(at: root.appendingPathComponent("empty"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent(".hidden"), withIntermediateDirectories: true)
        try "a".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "b".write(to: root.appendingPathComponent("docs/guide.markdown"), atomically: true, encoding: .utf8)
        try "c".write(to: root.appendingPathComponent("docs/specs/design.md"), atomically: true, encoding: .utf8)
        try "d".write(to: root.appendingPathComponent(".hidden/secret.md"), atomically: true, encoding: .utf8)
        try "x".write(to: root.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testScanFindsMarkdownPrunesEverythingElse() throws {
        let nodes = FileTree.scan(root: root)
        let names = nodes.map(\.name)
        XCTAssertEqual(names, ["docs", "README.md"])          // dirs first, then files
        let docs = nodes[0]
        XCTAssertTrue(docs.isDirectory)
        XCTAssertEqual(docs.children.map(\.name), ["specs", "guide.markdown"])
        XCTAssertEqual(docs.children[0].children.map(\.name), ["design.md"])
        // pruned: empty dir, hidden dir, non-markdown file
        XCTAssertFalse(names.contains("empty"))
        XCTAssertFalse(names.contains(".hidden"))
        XCTAssertFalse(names.contains("notes.txt"))
    }

    func testNodeURLsAreAbsolute() throws {
        let nodes = FileTree.scan(root: root)
        // resolvingSymlinksInPath normalises /var -> /private/var on macOS
        let expected = root.appendingPathComponent("README.md").resolvingSymlinksInPath()
        XCTAssertEqual(nodes.last?.url.resolvingSymlinksInPath(), expected)
    }
}
