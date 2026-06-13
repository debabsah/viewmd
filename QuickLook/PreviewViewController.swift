import Cocoa
import WebKit
import Quartz

/// Quick Look preview: renders a Markdown file with viewmd's bundled pipeline so
/// Finder's spacebar shows formatted output (headings, tables, Mermaid, math),
/// not raw source.
///
/// The web bundle is embedded in THIS extension's own Resources. A sandboxed
/// Quick Look extension can reliably read its own bundle, but not the host app's
/// bundle, so reaching into `<app>/Contents/Resources/dist` hangs the preview.
/// The extension runs out-of-process and on demand, so this costs disk, not the
/// running app's memory.
final class PreviewViewController: NSViewController, QLPreviewingController {
    private var webView: WKWebView!
    private var pendingText: String?
    private var dist: URL?
    private var completion: ((Error?) -> Void)?
    private var didComplete = false

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        webView = WKWebView(frame: container.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        container.addSubview(webView)
        view = container
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        completion = handler
        didComplete = false
        guard let dist = bundledDistURL() else {
            finish(NSError(domain: "app.viewmd.quicklook", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: "Render bundle missing"]))
            return
        }
        let data = (try? Data(contentsOf: url)) ?? Data()
        pendingText = data.count > 5_000_000
            ? "File is too large for Quick Look. Open it in viewmd."
            : (String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self))
        self.dist = dist
        // safety net: never leave Finder's spinner hanging if WebKit stalls
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in self?.finish(nil) }
        webView.loadFileURL(dist.appendingPathComponent("template.html"), allowingReadAccessTo: dist)
    }

    /// The web bundle embedded in this extension's own Resources.
    private func bundledDistURL() -> URL? {
        guard let dist = Bundle(for: Self.self).resourceURL?
                .appendingPathComponent("dist", isDirectory: true),
              FileManager.default.fileExists(
                atPath: dist.appendingPathComponent("template.html").path)
        else { return nil }
        return dist
    }

    private func render(_ text: String, dist: URL) {
        let dark = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let css = (try? String(contentsOf: dist.appendingPathComponent("themes/refined.css"),
                               encoding: .utf8)) ?? ""
        let payload: [String: Any] = [
            "text": text,
            "appearance": dark ? "dark" : "light",
            "codeBlocks": "auto",
            "themeCSS": css,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.viewmd.render(\(json))")
    }

    /// Call the Quick Look completion exactly once.
    private func finish(_ error: Error?) {
        guard !didComplete else { return }
        didComplete = true
        completion?(error)
        completion = nil
    }
}

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let text = pendingText, let dist {
            render(text, dist: dist)
            pendingText = nil
        }
        // let the DOM lay out before Quick Look snapshots the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.finish(nil) }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        finish(error)
    }
}
