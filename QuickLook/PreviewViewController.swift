import Cocoa
import WebKit
import QuickLookUI
import os.log

private let qlLog = OSLog(subsystem: "com.debabsah.viewmd.quicklook", category: "preview")

/// Quick Look preview: renders a Markdown file with viewmd's bundled pipeline so
/// Finder's spacebar shows formatted output (headings, tables, Mermaid, math),
/// not raw source.
///
/// A sandboxed Quick Look extension cannot navigate a WKWebView to a file:// URL
/// and pull file:// subresources (the 3 MB render.js, CSS): that stalls forever.
/// So we inline the bundle into one self-contained HTML string and load that,
/// the same approach MarkEdit's preview extension uses. The bundle is embedded
/// in this extension's own Resources. The extension runs out-of-process and on
/// demand, so this costs disk, not the running app's memory.
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
        os_log("prepare START %{public}@", log: qlLog, type: .info, url.lastPathComponent)
        completion = handler
        didComplete = false
        guard let dist = bundledDistURL() else {
            os_log("prepare: bundledDistURL NIL", log: qlLog, type: .error)
            finish(NSError(domain: "app.viewmd.quicklook", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: "Render bundle missing"]))
            return
        }
        let data = (try? Data(contentsOf: url)) ?? Data()
        pendingText = data.count > 5_000_000
            ? "File is too large for Quick Look. Open it in viewmd."
            : (String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self))
        self.dist = dist

        guard let html = buildSelfContainedHTML(dist: dist) else {
            os_log("prepare: could not build HTML", log: qlLog, type: .error)
            finish(NSError(domain: "app.viewmd.quicklook", code: 2))
            return
        }
        // safety net: never leave Finder's spinner hanging if WebKit stalls
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            os_log("watchdog FIRED", log: qlLog, type: .error)
            self?.finish(nil)
        }
        os_log("prepare: loadHTMLString len=%d", log: qlLog, type: .info, html.count)
        webView.loadHTMLString(html, baseURL: URL(string: "http://localhost/"))
    }

    /// The web bundle embedded in this extension's own Resources.
    private func bundledDistURL() -> URL? {
        guard let dist = Bundle(for: Self.self).resourceURL?
                .appendingPathComponent("dist", isDirectory: true),
              FileManager.default.fileExists(
                atPath: dist.appendingPathComponent("render.js").path)
        else { return nil }
        return dist
    }

    /// Build one self-contained page: CSS and render.js inlined, theme applied via
    /// the render payload. No file:// subresources, so nothing for the sandbox to
    /// block. KaTeX webfonts will not resolve (no base server) and fall back to
    /// system fonts, which is fine for a preview.
    private func buildSelfContainedHTML(dist: URL) -> String? {
        func read(_ rel: String) -> String {
            (try? String(contentsOf: dist.appendingPathComponent(rel), encoding: .utf8)) ?? ""
        }
        let katexCSS = read("katex/katex.min.css")
        let baseCSS = read("base.css")
        // escape any literal </script in the bundle so it cannot close the inline tag
        let renderJS = read("render.js").replacingOccurrences(of: "</script", with: "<\\/script")
        guard !renderJS.isEmpty else { return nil }
        let dark = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let appearance = dark ? "dark" : "light"
        return """
        <!DOCTYPE html>
        <html data-appearance="\(appearance)" data-code="\(appearance)">
        <head>
        <meta charset="utf-8">
        <style>\(katexCSS)</style>
        <style>\(baseCSS)</style>
        <style id="vmd-theme"></style>
        </head>
        <body>
        <article id="vmd-doc"></article>
        <script>\(renderJS)</script>
        </body>
        </html>
        """
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
        webView.evaluateJavaScript("window.viewmd && window.viewmd.render(\(json)); void 0")
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
        os_log("didFinish navigation", log: qlLog, type: .info)
        if let text = pendingText, let dist {
            render(text, dist: dist)
            pendingText = nil
        }
        // let the DOM lay out before Quick Look snapshots the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.finish(nil) }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log("didFail: %{public}@", log: qlLog, type: .error, error.localizedDescription)
        finish(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        os_log("didFailProvisional: %{public}@", log: qlLog, type: .error, error.localizedDescription)
        finish(error)
    }
}
