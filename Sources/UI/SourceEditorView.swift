import SwiftUI
import AppKit

struct SourceEditorView: NSViewRepresentable {
    @ObservedObject var document: OpenDocument

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let textView = scroll.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 24, height: 20)
        textView.string = document.text
        context.coordinator.textView = textView
        context.coordinator.rehighlight()
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        // external reload (disk change) → sync buffer into the editor
        if textView.string != document.text && !context.coordinator.isEditing {
            textView.string = document.text
            context.coordinator.rehighlight()
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        let document: OpenDocument
        weak var textView: NSTextView?
        var isEditing = false

        init(document: OpenDocument) { self.document = document }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            isEditing = true
            document.text = textView.string
            document.noteUserEdit()
            rehighlight()
            isEditing = false
        }

        func rehighlight() {
            guard let storage = textView?.textStorage else { return }
            let base = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            storage.beginEditing()
            MarkdownHighlighter.apply(to: storage, baseFont: base)
            storage.endEditing()
        }
    }
}
