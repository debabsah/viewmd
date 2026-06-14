import XCTest
@testable import viewmd

final class ShellPaletteTests: XCTestCase {

    private func bundledCSS(_ name: String) -> String {
        guard let url = Bundle.main.resourceURL?
            .appendingPathComponent("dist/themes/\(name).css"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("bundled theme \(name) missing"); return ""
        }
        return css
    }

    func testRGBAHexParsing() {
        XCTAssertEqual(RGBA(hex: "#ffffff"), RGBA(r: 1, g: 1, b: 1))
        XCTAssertEqual(RGBA(hex: "#000000"), RGBA(r: 0, g: 0, b: 0))
        let indigo = RGBA(hex: "#6366f1")!
        XCTAssertEqual(indigo.r, 99.0/255, accuracy: 0.001)
        XCTAssertEqual(indigo.g, 102.0/255, accuracy: 0.001)
        XCTAssertEqual(indigo.b, 241.0/255, accuracy: 0.001)
        XCTAssertNil(RGBA(hex: "not-a-color"))
        XCTAssertNil(RGBA(hex: "#12345"))
    }

    func testRGBAHexUppercaseAndTrailingWhitespace() {
        XCTAssertEqual(RGBA(hex: "#FFFFFF"), RGBA(r: 1, g: 1, b: 1))
        XCTAssertEqual(RGBA(hex: "#6366F1"), RGBA(hex: "#6366f1"))
        // trailing CR (as a CRLF-authored theme would yield) must not break parsing
        XCTAssertEqual(RGBA(hex: "#112233\r"), RGBA(hex: "#112233"))
    }

    func testMixMovesTowardTarget() {
        let white = RGBA(r: 1, g: 1, b: 1)
        let black = RGBA(r: 0, g: 0, b: 0)
        let mixed = white.mixed(with: black, amount: 0.1)
        XCTAssertEqual(mixed.r, 0.9, accuracy: 0.001)
        XCTAssertEqual(mixed.g, 0.9, accuracy: 0.001)
    }

    func testRefinedLightParses() {
        let p = ShellPalette.parse(css: bundledCSS("refined"), appearance: "light")
        XCTAssertEqual(p.background, RGBA(hex: "#ffffff"))
        XCTAssertEqual(p.sideBackground, RGBA(hex: "#fafafa"))   // --vmd-thead-bg
        XCTAssertEqual(p.text, RGBA(hex: "#09090b"))             // --vmd-heading
        XCTAssertEqual(p.softText, RGBA(hex: "#18181b"))         // --vmd-fg
        XCTAssertEqual(p.mutedText, RGBA(hex: "#52525b"))        // --vmd-quote-fg
        XCTAssertEqual(p.accent, RGBA(hex: "#6366f1"))
        XCTAssertEqual(p.accentText, RGBA(hex: "#4f46e5"))       // --vmd-link
        // derivations
        XCTAssertEqual(p.wash, p.sideBackground.mixed(with: p.text, amount: 0.06))
        XCTAssertEqual(p.wash2, p.sideBackground.mixed(with: p.text, amount: 0.12))
        XCTAssertEqual(p.tint, p.accent.withAlpha(0.12))
    }

    func testRefinedDarkParses() {
        let p = ShellPalette.parse(css: bundledCSS("refined"), appearance: "dark")
        XCTAssertEqual(p.background, RGBA(hex: "#121214"))
        XCTAssertEqual(p.accent, RGBA(hex: "#818cf8"))
    }

    func testDarkNativeThemeServesBothAppearances() {
        // dracula.css uses the combined selector for light AND dark
        let light = ShellPalette.parse(css: bundledCSS("dracula"), appearance: "light")
        let dark = ShellPalette.parse(css: bundledCSS("dracula"), appearance: "dark")
        XCTAssertEqual(light.background, RGBA(hex: "#282a36"))
        XCTAssertEqual(dark.background, RGBA(hex: "#282a36"))
        XCTAssertEqual(light.accent, RGBA(hex: "#bd93f9"))
    }

    func testEveryBundledThemeYieldsCompletePalettes() {
        for theme in ["refined", "familiar", "paper", "dracula", "nord",
                      "solarized", "catppuccin", "one-dark"] {
            for appearance in ["light", "dark"] {
                let p = ShellPalette.parse(css: bundledCSS(theme), appearance: appearance)
                // alpha sanity: real colors, not zeroed placeholders
                XCTAssertGreaterThan(p.background.a, 0, "\(theme)/\(appearance)")
                XCTAssertNotEqual(p.background, p.text, "\(theme)/\(appearance)")
            }
        }
    }

    func testPartialCSSFallsBackPerField() {
        let css = #"/* viewmd-theme: Tiny; appearances: light */"# + "\n" +
            #":root[data-appearance="light"] { --vmd-bg: #112233; }"#
        let p = ShellPalette.parse(css: css, appearance: "light")
        XCTAssertEqual(p.background, RGBA(hex: "#112233"))
        // missing side surface derives from background toward text
        XCTAssertEqual(p.sideBackground, p.background.mixed(with: p.text, amount: 0.04))
        // missing accent falls back to Refined's
        XCTAssertEqual(p.accent, RGBA(hex: "#6366f1"))
    }

    func testGarbageCSSFallsBackToRefined() {
        let light = ShellPalette.parse(css: "not css at all", appearance: "light")
        XCTAssertEqual(light, ShellPalette.refinedLight)
        let dark = ShellPalette.parse(css: "not css at all", appearance: "dark")
        XCTAssertEqual(dark, ShellPalette.refinedDark)
    }

    // The Aa panel (and any future panel) draws hairlines in `border`. It must
    // stay visible against the panel background for EVERY theme, including light
    // themes where background and sideBackground are nearly equal. This is the
    // contrast guarantee that replaces the white-on-white surface bug.
    func testBorderStaysVisibleForEveryBundledTheme() {
        for theme in ["refined", "familiar", "paper", "dracula", "nord",
                      "solarized", "catppuccin", "one-dark"] {
            for appearance in ["light", "dark"] {
                let p = ShellPalette.parse(css: bundledCSS(theme), appearance: appearance)
                let delta = abs(p.border.luminance - p.background.luminance)
                XCTAssertGreaterThanOrEqual(delta, 0.045,
                    "\(theme)/\(appearance): border too faint against background (\(delta))")
            }
        }
    }

    func testBorderClampsForALowContrastCustomTheme() {
        // a pathological custom theme: near-white text on a white background.
        // it is barely readable, but the border must still be guaranteed visible.
        let css = #"/* viewmd-theme: Bad; appearances: light */"# + "\n" +
            #":root[data-appearance="light"] { --vmd-bg: #ffffff; --vmd-heading: #f4f4f4; }"#
        let p = ShellPalette.parse(css: css, appearance: "light")
        XCTAssertGreaterThanOrEqual(abs(p.border.luminance - p.background.luminance), 0.1)
    }
}
