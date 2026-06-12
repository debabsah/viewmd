import XCTest
@testable import viewmd

final class FileWatcherTests: XCTestCase {
    var dir: URL!
    var file: URL!
    var watcher: FileWatcher?

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-watch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        file = dir.appendingPathComponent("doc.md")
        try "hello".write(to: file, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        watcher?.stop()
        watcher = nil
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeWatcher(_ handler: @escaping (FileWatcher.Event) -> Void) {
        watcher = FileWatcher(url: file, debounce: 0.1, handler: handler)
        watcher?.start()
    }

    func testDetectsInPlaceWrite() throws {
        let exp = expectation(description: "changed")
        makeWatcher { if $0 == .changed { exp.fulfill() } }
        try "hello world".write(to: file, atomically: false, encoding: .utf8)
        wait(for: [exp], timeout: 2)
    }

    func testDetectsAtomicReplaceAndStaysArmed() throws {
        var events: [FileWatcher.Event] = []
        let first = expectation(description: "first change")
        let second = expectation(description: "second change")
        makeWatcher { event in
            events.append(event)
            if events.count == 1 { first.fulfill() }
            if events.count == 2 { second.fulfill() }
        }
        // atomic replace = write temp + rename over (what editors and agents do)
        try "v2".write(to: file, atomically: true, encoding: .utf8)
        wait(for: [first], timeout: 2)
        // the watcher must have re-armed on the NEW inode
        try "v3".write(to: file, atomically: true, encoding: .utf8)
        wait(for: [second], timeout: 2)
        XCTAssertEqual(events, [.changed, .changed])
    }

    func testDeleteReportsDisappeared() throws {
        let exp = expectation(description: "disappeared")
        makeWatcher { if $0 == .disappeared { exp.fulfill() } }
        try FileManager.default.removeItem(at: file)
        wait(for: [exp], timeout: 2)
    }

    func testDebounceCoalescesBursts() throws {
        var count = 0
        let exp = expectation(description: "coalesced")
        exp.assertForOverFulfill = false
        makeWatcher { _ in count += 1; exp.fulfill() }
        for i in 0..<5 {
            try "burst \(i)".write(to: file, atomically: false, encoding: .utf8)
            usleep(10_000) // 10ms apart, inside the 100ms debounce window
        }
        wait(for: [exp], timeout: 2)
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))   // let any stragglers fire
        XCTAssertLessThanOrEqual(count, 2)   // 5 writes collapse to 1–2 events
    }

    func testSuppressionSwallowsOwnSave() throws {
        var count = 0
        makeWatcher { _ in count += 1 }
        watcher?.suppress(for: 0.5)
        try "our own save".write(to: file, atomically: true, encoding: .utf8)
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(count, 0)
    }

    func testSuppressionCoversReArmLatency() throws {
        var count = 0
        makeWatcher { _ in count += 1 }
        // window deliberately SHORTER than the 50ms re-arm + 100ms debounce chain
        watcher?.suppress(for: 0.05)
        try "own atomic save".write(to: file, atomically: true, encoding: .utf8) // rename path
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(count, 0)
    }
}
