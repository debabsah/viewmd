import XCTest
@testable import viewmd

@MainActor
final class RenderBridgeTests: XCTestCase {

    func testTemplateLoadsAndRendersHeading() throws {
        let bridge = RenderBridge()
        let rendered = expectation(description: "rendered")
        bridge.onRendered = { rendered.fulfill() }
        bridge.render(RenderBridge.Payload(
            text: "# Hello viewmd",
            appearance: "light", codeBlocks: "auto",
            themeCSS: nil, comfort: nil, scroll: nil))
        wait(for: [rendered], timeout: 10)

        let queried = expectation(description: "queried")
        bridge.webView.evaluateJavaScript("document.querySelector('h1').textContent") { result, _ in
            XCTAssertEqual(result as? String, "Hello viewmd")
            queried.fulfill()
        }
        wait(for: [queried], timeout: 5)
    }

    func testBundledThemeCSSLoads() {
        let css = RenderBridge.bundledThemeCSS("refined")
        XCTAssertNotNil(css)
        XCTAssertTrue(css!.contains("viewmd-theme: Refined"))
    }

    func testHeadingsArePostedToNative() {
        let bridge = RenderBridge()
        let got = expectation(description: "headings")
        got.assertForOverFulfill = false
        bridge.onHeadings = { heads in
            if heads.contains(where: { $0.text == "Alpha" })
                && heads.contains(where: { $0.text == "Beta" && $0.level == 2 }) {
                got.fulfill()
            }
        }
        bridge.render(RenderBridge.Payload(
            text: "# Alpha\n\n## Beta",
            appearance: "light", codeBlocks: "auto",
            themeCSS: nil, comfort: nil, scroll: nil))
        wait(for: [got], timeout: 10)
    }

    func testExportPDFProducesPDFData() {
        let bridge = RenderBridge()
        let rendered = expectation(description: "rendered")
        bridge.onRendered = { rendered.fulfill() }
        bridge.render(RenderBridge.Payload(
            text: "# Hello\n\nSome body text for the page.",
            appearance: "light", codeBlocks: "auto",
            themeCSS: nil, comfort: nil, scroll: nil))
        wait(for: [rendered], timeout: 10)

        let pdf = expectation(description: "pdf")
        bridge.exportPDF { data in
            XCTAssertGreaterThan(data?.count ?? 0, 100)
            XCTAssertEqual(data.map { Array($0.prefix(4)) }, Array("%PDF".utf8))  // PDF magic
            pdf.fulfill()
        }
        wait(for: [pdf], timeout: 10)
    }

    func testRenderedHTMLContainsHeading() {
        let bridge = RenderBridge()
        let rendered = expectation(description: "rendered")
        bridge.onRendered = { rendered.fulfill() }
        bridge.render(RenderBridge.Payload(
            text: "# Hello viewmd",
            appearance: "light", codeBlocks: "auto",
            themeCSS: nil, comfort: nil, scroll: nil))
        wait(for: [rendered], timeout: 10)

        let html = expectation(description: "html")
        bridge.renderedHTML { markup in
            XCTAssertTrue(markup?.contains("<h1") ?? false)
            html.fulfill()
        }
        wait(for: [html], timeout: 10)
    }
}
