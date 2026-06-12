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
}
