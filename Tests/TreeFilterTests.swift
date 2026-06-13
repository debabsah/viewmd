import XCTest
@testable import viewmd

final class TreeFilterTests: XCTestCase {

    private func file(_ name: String) -> FileNode {
        FileNode(url: URL(fileURLWithPath: "/t/\(name)"), name: name,
                 isDirectory: false, children: [])
    }
    private func folder(_ name: String, _ children: [FileNode]) -> FileNode {
        FileNode(url: URL(fileURLWithPath: "/t/\(name)"), name: name,
                 isDirectory: true, children: children)
    }

    func testFuzzySubsequenceMatching() {
        XCTAssertTrue(TreeFilter.matches("ux-remediation.md", query: "urd"))
        XCTAssertTrue(TreeFilter.matches("README.md", query: "rdm"))
        XCTAssertTrue(TreeFilter.matches("Design.md", query: "design"))   // case-insensitive
        XCTAssertFalse(TreeFilter.matches("plan.md", query: "z"))
        XCTAssertTrue(TreeFilter.matches("anything", query: ""))          // empty matches all
    }

    func testFilterKeepsAncestorsOfMatches() {
        let tree = [
            folder("specs", [file("design.md"), file("notes.md")]),
            folder("plans", [file("plan.md")]),
            file("README.md")
        ]
        let filtered = TreeFilter.filter(tree, query: "design")
        XCTAssertEqual(filtered.map(\.name), ["specs"])
        XCTAssertEqual(filtered[0].children.map(\.name), ["design.md"])
    }

    func testFilterPrunesFoldersWithNoMatches() {
        let tree = [folder("plans", [file("plan.md")]), file("README.md")]
        let filtered = TreeFilter.filter(tree, query: "readme")
        XCTAssertEqual(filtered.map(\.name), ["README.md"])
    }

    func testEmptyQueryReturnsInputUnchanged() {
        let tree = [folder("specs", [file("design.md")])]
        XCTAssertEqual(TreeFilter.filter(tree, query: ""), tree)
    }

    func testFolderNamesDoNotMatchOnlyFiles() {
        // matching is on FILE names; a folder whose own name matches but has
        // no matching files is pruned
        let tree = [folder("design-docs", [file("notes.md")])]
        XCTAssertEqual(TreeFilter.filter(tree, query: "design"), [])
    }
}
