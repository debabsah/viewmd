import XCTest
@testable import viewmd

final class FolderWatcherTests: XCTestCase {
    func testFiresWhenFileCreatedInSubdirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-folder-\(UUID().uuidString)")
        let sub = root.appendingPathComponent("docs")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let exp = expectation(description: "folder event")
        exp.assertForOverFulfill = false
        let watcher = FolderWatcher(url: root, latency: 0.1) { exp.fulfill() }
        watcher.start()
        defer { watcher.stop() }

        // FSEvents needs a beat to start delivering
        Thread.sleep(forTimeInterval: 0.3)
        try "new".write(to: sub.appendingPathComponent("new.md"), atomically: true, encoding: .utf8)
        wait(for: [exp], timeout: 5)
    }
}
