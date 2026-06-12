import SwiftUI
import AppKit

@MainActor
final class ComfortModel: ObservableObject {
    @Published var settings: ComfortSettings {
        didSet {
            settings.save()
            onChange?()
        }
    }
    let themeStore: ThemeStore
    var onChange: (() -> Void)?

    init(themeStore: ThemeStore = ThemeStore()) {
        self.themeStore = themeStore
        self.settings = ComfortSettings.load()
    }

    var themes: [Theme] { themeStore.themes() }
}

struct ComfortPopoverView: View {
    @ObservedObject var model: ComfortModel

    var body: some View {
        Form {
            Picker("Theme", selection: $model.settings.themeID) {
                ForEach(model.themes) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
            Picker("Font", selection: $model.settings.fontFamily) {
                Text("Theme default").tag(String?.none)
                ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { family in
                    Text(family).tag(String?.some(family))
                }
            }
            LabeledContent("Size") {
                Slider(value: $model.settings.fontSize,
                       in: ComfortSettings.fontSizeRange, step: 1) {
                } minimumValueLabel: { Text("A").font(.caption2) }
                  maximumValueLabel: { Text("A").font(.title3) }
            }
            LabeledContent("Line width") {
                Slider(value: $model.settings.lineWidth, in: 480...1200, step: 20)
            }
            LabeledContent("Line spacing") {
                Slider(value: $model.settings.lineSpacing, in: 1.2...2.2, step: 0.05)
            }
            Picker("Code blocks", selection: $model.settings.codeBlocks) {
                Text("Auto").tag("auto")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            Picker("Appearance", selection: $model.settings.appearanceOverride) {
                Text("Follow System").tag(String?.none)
                Text("Light").tag(String?.some("light"))
                Text("Dark").tag(String?.some("dark"))
            }
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .padding(8)
    }
}

/// Titlebar accessory: sidebar toggle + comfort popover button.
struct TitlebarAccessoryView: View {
    @ObservedObject var model: ComfortModel
    let toggleSidebar: () -> Void
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: toggleSidebar) {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle Sidebar (⌘B)")
            Button { showPopover.toggle() } label: {
                Image(systemName: "textformat.size")
            }
            .help("Reading comfort")
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                ComfortPopoverView(model: model)
            }
        }
        .buttonStyle(.borderless)
        .padding(.trailing, 8)
    }
}
