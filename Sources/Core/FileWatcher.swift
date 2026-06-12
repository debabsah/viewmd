import Foundation

/// Watches a single file via a vnode dispatch source.
/// - Debounces bursts of writes.
/// - Re-arms on rename/delete (atomic saves replace the inode).
/// - `suppress(for:)` swallows events caused by our own saves.
final class FileWatcher {
    enum Event: Equatable {
        case changed
        case disappeared
    }

    private let url: URL
    private let debounce: TimeInterval
    private let queue: DispatchQueue
    private let handler: (Event) -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?
    private var suppressedUntil: Date = .distantPast
    private var stopped = false

    init(url: URL,
         debounce: TimeInterval = 0.1,
         queue: DispatchQueue = DispatchQueue(label: "viewmd.filewatcher"),
         handler: @escaping (Event) -> Void) {
        self.url = url
        self.debounce = debounce
        self.queue = queue
        self.handler = handler
    }

    func start() {
        // synchronous so the vnode source is armed before start() returns —
        // an immediate external write must not race the arm
        queue.sync { self.arm() }
    }

    func stop() {
        queue.async {
            self.stopped = true
            self.pending?.cancel()
            self.source?.cancel()
            self.source = nil
        }
    }

    func suppress(for interval: TimeInterval) {
        queue.async { self.suppressedUntil = Date().addingTimeInterval(interval) }
    }

    // MARK: - Private (all on `queue`)

    private func arm() {
        guard !stopped else { return }
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            emit(.disappeared)
            return
        }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: queue)
        src.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = src.data
            if flags.contains(.delete) || flags.contains(.rename) {
                src.cancel()                  // cancel handler closes fd
                self.rearmAfterReplace()
            } else {
                self.scheduleEmit(.changed)
            }
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    private func rearmAfterReplace() {
        // Atomic save = new file renamed over ours. Give the rename a moment,
        // then try to attach to the new inode.
        queue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, !self.stopped else { return }
            if FileManager.default.fileExists(atPath: self.url.path) {
                self.arm()
                self.scheduleEmit(.changed)
            } else {
                self.emit(.disappeared)
            }
        }
    }

    private func scheduleEmit(_ event: Event) {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.emit(event) }
        pending = work
        queue.asyncAfter(deadline: .now() + debounce, execute: work)
    }

    private func emit(_ event: Event) {
        guard !stopped, Date() >= suppressedUntil else { return }
        let handler = self.handler
        DispatchQueue.main.async { handler(event) }
    }
}
