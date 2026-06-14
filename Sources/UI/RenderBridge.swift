import WebKit

@MainActor
final class RenderBridge: NSObject {
    struct Comfort: Codable {
        var fontFamily: String?
        var fontSize: Double?
        var lineWidth: Double?
        var lineSpacing: Double?
    }
    struct Scroll: Codable {
        var mode: String          // "anchor" | "absolute"
        var top: Double?
    }
    struct Payload: Codable {
        var text: String
        var appearance: String    // "light" | "dark"
        var codeBlocks: String    // "auto" | "light" | "dark"
        var themeCSS: String?
        var comfort: Comfort?
        var scroll: Scroll?
    }

    let webView: WKWebView
    let imageHandler: LocalImageSchemeHandler
    var onRendered: (() -> Void)?
    var onHeadings: (([Heading]) -> Void)?
    var onOpenExternal: ((URL) -> Void)?
    var onOpenRelative: ((String) -> Void)?

    private var isReady = false
    private var pendingPayload: Payload?
    private var lastPayload: Payload?

    override init() {
        let handler = LocalImageSchemeHandler()
        imageHandler = handler
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(handler, forURLScheme: LocalImageSchemeHandler.scheme)
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        config.userContentController.add(MessageProxy(self), name: "viewmd")
        webView.navigationDelegate = self
        loadTemplate()
    }

    /// Where relative image paths in the current document resolve from.
    func setImageBaseDirectory(_ url: URL?) {
        imageHandler.baseDirectory = url
    }

    static func distURL() -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent("dist")
    }

    static func bundledThemeCSS(_ name: String) -> String? {
        guard let url = distURL()?.appendingPathComponent("themes/\(name).css") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func loadTemplate() {
        guard let dist = Self.distURL() else { return }
        isReady = false
        webView.loadFileURL(dist.appendingPathComponent("template.html"), allowingReadAccessTo: dist)
    }

    func render(_ payload: Payload) {
        lastPayload = payload
        guard isReady else {
            pendingPayload = payload
            return
        }
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.viewmd.render(\(json))")
    }

    func find(_ term: String, forward: Bool = true) {
        guard !term.isEmpty else { return }
        let config = WKFindConfiguration()
        config.backwards = !forward
        config.wraps = true
        config.caseSensitive = false
        webView.find(term, configuration: config) { _ in }
    }

    func currentScrollTop(_ completion: @escaping (Double) -> Void) {
        webView.evaluateJavaScript("window.viewmd.scrollTop()") { value, _ in
            completion((value as? NSNumber)?.doubleValue ?? 0)
        }
    }

    func scrollToHeading(_ key: String) {
        // encode the key as a JS string literal so quotes/specials can't break out
        guard let data = try? JSONEncoder().encode(key),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.viewmd.scrollToHeading(\(json))")
    }

    // MARK: - Export

    /// Rasterize the rendered document to a PDF (native WebKit, no dependency).
    func exportPDF(_ completion: @escaping (Data?) -> Void) {
        webView.createPDF(configuration: WKPDFConfiguration()) { result in
            completion(try? result.get())
        }
    }

    /// The rendered document fragment's HTML (the `#vmd-doc` inner markup).
    func renderedHTML(_ completion: @escaping (String?) -> Void) {
        webView.evaluateJavaScript("document.getElementById('vmd-doc').innerHTML") { value, _ in
            completion(value as? String)
        }
    }

    /// A print operation over the rendered document, paginated by WebKit.
    func printOperation() -> NSPrintOperation {
        webView.printOperation(with: NSPrintInfo.shared)
    }

    fileprivate func handleMessage(_ body: Any) {
        guard let dict = body as? [String: Any],
              let type = dict["type"] as? String else { return }
        switch type {
        case "ready":
            isReady = true
            if let p = pendingPayload {
                pendingPayload = nil
                render(p)
            }
        case "rendered":
            onRendered?()
        case "headings":
            if let items = dict["items"] as? [[String: Any]] {
                onHeadings?(Heading.parse(items))
            }
        case "openExternal":
            if let href = dict["href"] as? String, let url = URL(string: href) {
                onOpenExternal?(url)
            }
        case "openRelative":
            if let href = dict["href"] as? String {
                onOpenRelative?(href)
            }
        default:
            break
        }
    }
}

extension RenderBridge: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // spec: render surface auto-relaunches and re-renders silently
        pendingPayload = lastPayload
        loadTemplate()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // pin the render surface to the bundled template: dropped files and
        // stray links must never navigate the webview away (subresources and
        // in-page fragments don't hit this; only main-frame navigations do)
        if let url = navigationAction.request.url,
           url.isFileURL,
           url.lastPathComponent == "template.html" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}

/// Breaks the WKUserContentController → handler retain cycle.
private final class MessageProxy: NSObject, WKScriptMessageHandler {
    private weak var bridge: RenderBridge?
    init(_ bridge: RenderBridge) { self.bridge = bridge }
    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        let body = message.body
        Task { @MainActor in self.bridge?.handleMessage(body) }
    }
}
