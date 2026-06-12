import SwiftUI

/// Observes the active document so mode/banner changes re-render the content area.
struct ActiveDocumentView: View {
    @ObservedObject var document: OpenDocument
    let bridge: RenderBridge

    var body: some View {
        VStack(spacing: 0) {
            BannerView(document: document)
            if document.showFindBar && document.mode == .rendered {
                FindBarView(document: document, bridge: bridge)
            }
            if document.mode == .source {
                SourceEditorView(document: document)
            } else {
                RenderView(bridge: bridge)
            }
        }
    }
}
