import SwiftUI
import AppKit
import Combine

/// Owns ComfortSettings: persists immediately, debounces re-renders 150ms
/// so slider drags don't thrash mermaid-heavy documents (spec, Aa panel).
@MainActor
final class ComfortModel: ObservableObject {
    @Published var settings: ComfortSettings {
        didSet { settings.save(to: defaults) }
    }
    let themeStore: ThemeStore
    var onChange: (() -> Void)?
    private let defaults: UserDefaults
    private var cancellable: AnyCancellable?

    init(themeStore: ThemeStore = ThemeStore(), defaults: UserDefaults = .standard) {
        self.themeStore = themeStore
        self.defaults = defaults
        self.settings = ComfortSettings.load(from: defaults)
        cancellable = $settings
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.onChange?() }
    }

    var themes: [Theme] { themeStore.themes() }
}

/// The "Theme & display" popover — the single home of all display
/// customization (spec, "The Aa panel"). Palette colors only.
struct AaPanelView: View {
    @ObservedObject var controller: WorkspaceWindowController
    @ObservedObject var model: ComfortModel

    private var palette: ShellPalette { controller.palette }

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { model.settings.appearanceOverride ?? "auto" },
            set: { model.settings.appearanceOverride = $0 == "auto" ? nil : $0 })
    }

    private var customFamilyBinding: Binding<String> {
        Binding(
            get: { model.settings.fontFamily ?? "—" },
            set: { model.settings.fontFamily = $0 == "—" ? nil : $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Aa  Theme & display")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.text.color)
                .padding(.bottom, 4)

            sectionLabel("Theme")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(model.themes) { theme in
                    themeCard(theme)
                }
            }

            sectionLabel("Appearance")
            Picker("", selection: appearanceBinding) {
                Text("☀︎ Light").tag("light")
                Text("Auto").tag("auto")
                Text("☾ Dark").tag("dark")
            }
            .pickerStyle(.segmented).labelsHidden()

            sectionLabel("Font")
            Picker("", selection: $model.settings.fontPack) {
                Text("Theme default").tag(FontPack.themeDefault)
                Text("Serif").tag(FontPack.serif)
                Text("Mono").tag(FontPack.mono)
            }
            .pickerStyle(.segmented).labelsHidden()
            Picker("Custom family", selection: customFamilyBinding) {
                Text("—").tag("—")
                ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .font(.system(size: 12))

            sectionLabel("Reading")
            slider("A", $model.settings.fontSize,
                   in: ComfortSettings.fontSizeRange, step: 1)
            slider("Width", $model.settings.lineWidth, in: 480...1200, step: 20)
            slider("Spacing", $model.settings.lineSpacing, in: 1.2...2.2, step: 0.05)

            sectionLabel("Code blocks")
            Picker("", selection: $model.settings.codeBlocks) {
                Text("Auto").tag("auto")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented).labelsHidden()
        }
        .padding(14)
        .frame(width: 312)
        .background(palette.background.color)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .kerning(0.5)
            .foregroundStyle(palette.mutedText.color)
            .padding(.top, 8)
    }

    private func themeCard(_ theme: Theme) -> some View {
        let selected = theme.id == model.settings.themeID
        let dotColor = theme
            .shellPalette(appearance: model.settings.appearanceOverride ?? "light")
            .accent.color
        return HStack(spacing: 8) {
            Circle().fill(dotColor).frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(palette.wash2.color, lineWidth: 1))
            Text(theme.name)
                .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
                .foregroundStyle((selected ? palette.accentText : palette.softText).color)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 9)
            .fill(selected ? palette.tint.color : palette.sideBackground.color))
        .overlay(RoundedRectangle(cornerRadius: 9)
            .strokeBorder(selected ? palette.accent.color : .clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { model.settings.themeID = theme.id }
    }

    private func slider(_ label: String, _ value: Binding<Double>,
                        in range: ClosedRange<Double>, step: Double) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(palette.softText.color)
                .frame(width: 52, alignment: .leading)
            Slider(value: value, in: range, step: step)
        }
    }
}
