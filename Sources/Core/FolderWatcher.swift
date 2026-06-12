import Foundation
import CoreServices

/// Recursive folder watcher over FSEvents. Fires a coalesced callback on any
/// change under `url` (create/delete/rename/modify, any depth).
final class FolderWatcher {
    private let url: URL
    private let latency: TimeInterval
    private let handler: () -> Void
    private var streamRef: FSEventStreamRef?

    init(url: URL, latency: TimeInterval = 0.25, handler: @escaping () -> Void) {
        self.url = url
        self.latency = latency
        self.handler = handler
    }

    func start() {
        guard streamRef == nil else { return }
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async { watcher.handler() }
        }
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault, callback, &context,
            [url.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)) else { return }
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
        streamRef = stream
    }

    func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }

    deinit { stop() }
}
