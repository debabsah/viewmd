import Foundation

@MainActor
final class OpenDocument: ObservableObject, Identifiable {
    enum Mode: Equatable { case rendered, source }
    enum Banner: Equatable { case none, conflict, missing, notice(String) }

    nonisolated let id = UUID()
    static let largeFileThresholdKey = "largeFile.thresholdMB"
    private(set) var url: URL
    @Published var text: String = ""
    @Published var mode: Mode = .rendered
    @Published var banner: Banner = .none
    @Published var showFindBar = false
    @Published private(set) var stateMachine = DocumentStateMachine()
    @Published private(set) var lossyDecoded = false
    @Published private(set) var isWatching = false
    var savedScrollTop: Double = 0          // remembered across tab switches
    var onDiskReload: (() -> Void)?         // UI hook: trigger re-render

    private let watcherDebounce: TimeInterval
    private let settingsDefaults: UserDefaults
    private var watcher: FileWatcher?

    init(url: URL, watcherDebounce: TimeInterval = 0.1,
         settingsDefaults: UserDefaults = .standard) {
        self.url = url.standardizedFileURL
        self.watcherDebounce = watcherDebounce
        self.settingsDefaults = settingsDefaults
    }

    var displayName: String { url.lastPathComponent }

    func open() throws {
        text = try readFromDisk()
        startWatching()
    }

    func teardown() {
        isWatching = false
        watcher?.stop()
        watcher = nil
    }

    func noteUserEdit() {
        dispatch(.userEdited)
    }

    func save() throws {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        watcher?.suppress(for: 0.3)
        try data.write(to: url, options: .atomic)
        dispatch(.saved)
        banner = .none
        // atomic write replaced the inode our watcher held — re-arm on the new one
        watcher?.stop()
        startWatching()
        watcher?.suppress(for: 0.3)
    }

    func reloadFromDisk() {
        guard let fresh = try? readFromDisk() else { return }
        text = fresh
        dispatch(.reloadedFromDisk)
        banner = .none
        if watcher != nil { isWatching = true }
        onDiskReload?()
    }

    /// "Keep mine" on the conflict banner: write the buffer over the disk version.
    func keepMine() throws {
        try save()
    }

    /// Save the buffer to a new location and rebind watching to it.
    func saveAs(_ newURL: URL) throws {
        teardown()
        url = newURL.standardizedFileURL
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        try data.write(to: url, options: .atomic)
        dispatch(.saved)
        banner = .none
        startWatching()
    }

    // MARK: - Private

    private func startWatching() {
        let w = FileWatcher(url: url, debounce: watcherDebounce) { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                switch event {
                case .changed: self.dispatch(.diskChanged)
                case .disappeared: self.dispatch(.fileDisappeared)
                }
            }
        }
        w.start()
        watcher = w
        isWatching = true
    }

    private func dispatch(_ event: DocumentEvent) {
        var sm = stateMachine
        let action = sm.handle(event)
        stateMachine = sm
        switch action {
        case .reloadFromDisk: reloadFromDisk()
        case .showConflictBanner: banner = .conflict
        case .showMissingBanner:
            // the file is gone; the watcher's vnode source is now dead. Release
            // it so isWatching (and the watcher != nil guard) stay truthful —
            // a Save / Save As re-arms a fresh watcher on the restored file.
            isWatching = false
            watcher?.stop()
            watcher = nil
            banner = .missing
        case .none: break
        }
    }

    private func readFromDisk() throws -> String {
        let data = try Data(contentsOf: url)
        let thresholdMB = settingsDefaults.object(forKey: Self.largeFileThresholdKey) as? Double ?? 2.0
        if Double(data.count) > thresholdMB * 1_000_000, banner == .none {
            banner = .notice("Large file. Rendering may take a moment.")
        }
        if let s = String(data: data, encoding: .utf8) {
            lossyDecoded = false
            return s
        }
        lossyDecoded = true
        banner = .notice("File is not UTF-8; shown with lossy decoding.")
        return String(decoding: data, as: UTF8.self)
    }
}
