import Cocoa
import WebKit
import Quartz

/// Quick Look preview: renders a Markdown file with viewmd's bundled pipeline so
/// Finder's spacebar shows formatted output (headings, tables, Mermaid, math),
/// not raw source.
///
/// It reuses the host app's web bundle at `Contents/Resources/dist` rather than
/// embedding a second copy, so the extension adds ~nothing to the bundle. The
/// extension runs out-of-process and on demand, so it adds nothing to viewmd's
/// resident memory either.
final class PreviewViewController: NSViewController, QLPreviewingController {
    private var webView: WKWebView!
    private var pendingText: String?
    private var dist: URL?
    private var completion: ((Error?) -> Void)?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        webView = WKWebView(frame: container.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        container.addSubview(webView)
        view = container
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        guard let dist = hostDistURL() else {
            handler(NSError(domain: "app.viewmd.quicklook", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Missing render bundle"]))
            return
        }
        let data = (try? Data(contentsOf: url)) ?? Data()
        if data.count > 5_000_000 {
            pendingText = "_File is too large for Quick Look. Open it in viewmd._"
        } else {
            pendingText = String(data: data, encoding: .utf8)
                ?? String(decoding: data, as: UTF8.self)
        }
        self.dist = dist
        completion = handler
        webView.loadFileURL(dist.appendingPathComponent("template.html"), allowingReadAccessTo: dist)
    }

    /// Resolve the host app's shared web bundle from the extension's own location:
    /// `<app>.app/Contents/PlugIns/<name>.appex` -> `.../Contents/Resources/dist`.
    private func hostDistURL() -> URL? {
        let contents = Bundle(for: Self.self).bundleURL
            .deletingLastPathComponent()   // PlugIns
            .deletingLastPathComponent()   // Contents
        let dist = contents.appendingPathComponent("Resources/dist", isDirectory: true)
        return FileManager.default.fileExists(
            atPath: dist.appendingPathComponent("template.html").path) ? dist : nil
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
}

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let text = pendingText, let dist {
            render(text, dist: dist)
            pendingText = nil
        }
        completion?(nil)
        completion = nil
    }
}
