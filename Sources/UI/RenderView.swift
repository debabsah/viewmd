import SwiftUI
import WebKit

struct RenderView: NSViewRepresentable {
    let bridge: RenderBridge
    func makeNSView(context: Context) -> WKWebView { bridge.webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
