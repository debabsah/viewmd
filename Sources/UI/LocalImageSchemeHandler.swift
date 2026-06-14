import WebKit
import UniformTypeIdentifiers

/// Serves images referenced by local paths in Markdown through a custom URL
/// scheme, so the render WebView (whose base is the app bundle) can still
/// display them. Relative paths resolve against the open document's folder;
/// absolute and `~` paths are used as-is. viewmd is not sandboxed, so the files
/// are read directly. Only image file types are served, so a document cannot
/// pull arbitrary files off disk.
final class LocalImageSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "vmdimg"

    /// The open document's folder; relative image paths resolve against it.
    var baseDirectory: URL?

    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp",
        "tiff", "tif", "heic", "heif", "avif", "ico", "apng",
    ]

    /// Resolve a Markdown image `src` to a file URL, or nil if it is not an
    /// image type or a relative path is given with no base. Pure, for testing.
    static func fileURL(for src: String, base: URL?) -> URL? {
        let ext = (src as NSString).pathExtension.lowercased()
        guard imageExtensions.contains(ext) else { return nil }
        if src.hasPrefix("/") {
            return URL(fileURLWithPath: src).standardizedFileURL
        }
        if src.hasPrefix("~") {
            return URL(fileURLWithPath: (src as NSString).expandingTildeInPath).standardizedFileURL
        }
        guard let base else { return nil }
        return base.appendingPathComponent(src).standardizedFileURL
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url,
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let src = comps.queryItems?.first(where: { $0.name == "src" })?.value,
              let fileURL = Self.fileURL(for: src, base: baseDirectory),
              let data = try? Data(contentsOf: fileURL) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mime = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        let response = URLResponse(url: url, mimeType: mime,
                                   expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
