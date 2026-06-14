import Foundation

/// A plain sRGB color value. Parsed from theme CSS hex literals.
struct RGBA: Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// Accepts #rgb, #rrggbb, #rrggbbaa (leading # required).
    init?(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix("#") else { return nil }
        var digits = String(s.dropFirst())
        if digits.count == 3 {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        guard digits.count == 6 || digits.count == 8,
              digits.allSatisfy({ $0.isHexDigit }) else { return nil }
        func channel(_ i: Int) -> Double {
            let start = digits.index(digits.startIndex, offsetBy: i * 2)
            let end = digits.index(start, offsetBy: 2)
            return Double(Int(digits[start..<end], radix: 16) ?? 0) / 255.0
        }
        self.init(r: channel(0), g: channel(1), b: channel(2),
                  a: digits.count == 8 ? channel(3) : 1)
    }

    /// Linear interpolation toward `other` by `amount` (0 = self, 1 = other).
    func mixed(with other: RGBA, amount: Double) -> RGBA {
        let t = min(max(amount, 0), 1)
        return RGBA(r: r + (other.r - r) * t,
                    g: g + (other.g - g) * t,
                    b: b + (other.b - b) * t,
                    a: a + (other.a - a) * t)
    }

    func withAlpha(_ alpha: Double) -> RGBA {
        RGBA(r: r, g: g, b: b, a: alpha)
    }

    /// Rec. 709 relative luminance, 0 (black) to 1 (white). Used to guarantee
    /// that derived surface tones keep enough contrast across any theme.
    var luminance: Double { 0.2126 * r + 0.7152 * g + 0.0722 * b }
}

/// Native shell colors derived from a theme's CSS variables, so the app
/// chrome (strip, sidebar, washes, tints) follows the document theme.
/// Spec: UX remediation design, "Shell theming architecture".
struct ShellPalette: Equatable {
    var background: RGBA
    var sideBackground: RGBA
    var text: RGBA
    var softText: RGBA
    var mutedText: RGBA
    var wash: RGBA
    var wash2: RGBA
    var accent: RGBA
    var accentText: RGBA
    var tint: RGBA

    /// A hairline tone guaranteed to read against `background`, even on a light
    /// theme where `background` and `sideBackground` are nearly equal. Derived
    /// from background-to-text, so any theme readable enough to use also gets a
    /// visible border. See `borderTone`.
    var border: RGBA { Self.borderTone(bg: background, text: text) }

    /// Derive a visible hairline against `bg`. Normally mixed toward `text` so
    /// it stays on theme; if a theme's text is too close to its background, mix
    /// toward the opposite luminance pole instead, so the step is always met.
    static func borderTone(bg: RGBA, text: RGBA) -> RGBA {
        let candidate = bg.mixed(with: text, amount: 0.15)
        if abs(candidate.luminance - bg.luminance) >= 0.05 { return candidate }
        let pole: RGBA = bg.luminance > 0.5 ? RGBA(r: 0, g: 0, b: 0) : RGBA(r: 1, g: 1, b: 1)
        return bg.mixed(with: pole, amount: 0.14)
    }

    static let refinedLight = ShellPalette(
        background: RGBA(hex: "#ffffff")!,
        sideBackground: RGBA(hex: "#fafafa")!,
        text: RGBA(hex: "#09090b")!,
        softText: RGBA(hex: "#18181b")!,
        mutedText: RGBA(hex: "#52525b")!,
        wash: RGBA(hex: "#fafafa")!.mixed(with: RGBA(hex: "#09090b")!, amount: 0.06),
        wash2: RGBA(hex: "#fafafa")!.mixed(with: RGBA(hex: "#09090b")!, amount: 0.12),
        accent: RGBA(hex: "#6366f1")!,
        accentText: RGBA(hex: "#4f46e5")!,
        tint: RGBA(hex: "#6366f1")!.withAlpha(0.12))

    static let refinedDark = ShellPalette(
        background: RGBA(hex: "#121214")!,
        sideBackground: RGBA(hex: "#1c1c1f")!,
        text: RGBA(hex: "#fafafa")!,
        softText: RGBA(hex: "#d4d4d8")!,
        mutedText: RGBA(hex: "#a1a1aa")!,
        wash: RGBA(hex: "#1c1c1f")!.mixed(with: RGBA(hex: "#fafafa")!, amount: 0.06),
        wash2: RGBA(hex: "#1c1c1f")!.mixed(with: RGBA(hex: "#fafafa")!, amount: 0.12),
        accent: RGBA(hex: "#818cf8")!,
        accentText: RGBA(hex: "#a5b4fc")!,
        tint: RGBA(hex: "#818cf8")!.withAlpha(0.12))

    /// Parse the palette for one appearance ("light" | "dark") out of a theme's CSS.
    /// Per-field fallback per the spec table; wholly unparsable CSS falls back to Refined.
    static func parse(css: String, appearance: String) -> ShellPalette {
        let vars = cssVariables(css: css, appearance: appearance)
        let fallback = appearance == "dark" ? refinedDark : refinedLight
        guard !vars.isEmpty else { return fallback }

        func hex(_ name: String) -> RGBA? {
            vars[name].flatMap { RGBA(hex: $0) }
        }

        let background = hex("--vmd-bg") ?? fallback.background
        let text = hex("--vmd-heading") ?? fallback.text
        let sideBackground = hex("--vmd-thead-bg")
            ?? background.mixed(with: text, amount: 0.04)
        let softText = hex("--vmd-fg") ?? fallback.softText
        let mutedText = hex("--vmd-quote-fg") ?? fallback.mutedText
        let accent = hex("--vmd-accent") ?? fallback.accent
        let accentText = hex("--vmd-link") ?? accent

        return ShellPalette(
            background: background,
            sideBackground: sideBackground,
            text: text,
            softText: softText,
            mutedText: mutedText,
            wash: sideBackground.mixed(with: text, amount: 0.06),
            wash2: sideBackground.mixed(with: text, amount: 0.12),
            accent: accent,
            accentText: accentText,
            tint: accent.withAlpha(0.12))
    }

    /// Collect var declarations from every block whose selector mentions the
    /// requested appearance (dark-native themes use a combined selector).
    private static func cssVariables(css: String, appearance: String) -> [String: String] {
        var result: [String: String] = [:]
        let blockPattern = #"([^{}]+)\{([^}]*)\}"#
        guard let blockRegex = try? NSRegularExpression(pattern: blockPattern) else { return result }
        let varPattern = #"(--[A-Za-z0-9-]+)\s*:\s*([^;]+);"#
        guard let varRegex = try? NSRegularExpression(pattern: varPattern) else { return result }

        let full = NSRange(css.startIndex..., in: css)
        blockRegex.enumerateMatches(in: css, range: full) { match, _, _ in
            guard let match,
                  let selRange = Range(match.range(at: 1), in: css),
                  let bodyRange = Range(match.range(at: 2), in: css) else { return }
            let selector = String(css[selRange])
            guard selector.contains("data-appearance=\"\(appearance)\"") else { return }
            let body = String(css[bodyRange])
            let bodyNSRange = NSRange(body.startIndex..., in: body)
            varRegex.enumerateMatches(in: body, range: bodyNSRange) { vm, _, _ in
                guard let vm,
                      let nameRange = Range(vm.range(at: 1), in: body),
                      let valueRange = Range(vm.range(at: 2), in: body) else { return }
                result[String(body[nameRange])] =
                    String(body[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result
    }
}

extension Theme {
    /// The native shell palette for this theme under the given appearance.
    func shellPalette(appearance: String) -> ShellPalette {
        ShellPalette.parse(css: css, appearance: appearance)
    }
}
