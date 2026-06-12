import SwiftUI

struct FindBarView: View {
    @ObservedObject var document: OpenDocument
    let bridge: RenderBridge
    @State private var term = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Find in document", text: $term)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit { bridge.find(term) }
            Button { bridge.find(term, forward: false) } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(term.isEmpty)
            Button { bridge.find(term) } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(term.isEmpty)
            Button("Done") { document.showFindBar = false }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(Divider(), alignment: .bottom)
        .onAppear { focused = true }
        .onExitCommand { document.showFindBar = false }
    }
}
