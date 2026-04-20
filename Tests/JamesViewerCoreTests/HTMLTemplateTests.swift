import XCTest
@testable import JamesViewerCore

final class HTMLTemplateTests: XCTestCase {
    private let bundleURL = URL(fileURLWithPath: "/tmp/jamesviewer-test-bundle", isDirectory: true)

    func testLightThemeLinksLightCSS() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "<p>hi</p>",
            theme: .light,
            zoomPercent: 100,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("github-markdown-light.css"), "got: \(html)")
        XCTAssertTrue(html.contains("highlight-github.css"), "got: \(html)")
        XCTAssertFalse(html.contains("github-markdown-dark.css"), "got: \(html)")
        XCTAssertTrue(html.contains("data-theme=\"light\""), "got: \(html)")
    }

    func testDarkThemeLinksDarkCSS() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "<p>hi</p>",
            theme: .dark,
            zoomPercent: 100,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("github-markdown-dark.css"), "got: \(html)")
        XCTAssertTrue(html.contains("highlight-atom-one-dark.css"), "got: \(html)")
        XCTAssertFalse(html.contains("github-markdown-light.css"), "got: \(html)")
        XCTAssertTrue(html.contains("data-theme=\"dark\""), "got: \(html)")
    }

    func testZoomAffectsFontSize() {
        let zoomed = HTMLTemplate.wrap(bodyHTML: "", theme: .light, zoomPercent: 150, bundleURL: bundleURL)
        XCTAssertTrue(zoomed.contains("font-size: 24px"), "150% → 24px, got: \(zoomed)")

        let reset = HTMLTemplate.wrap(bodyHTML: "", theme: .light, zoomPercent: 100, bundleURL: bundleURL)
        XCTAssertTrue(reset.contains("font-size: 16px"), "100% → 16px, got: \(reset)")

        let min = HTMLTemplate.wrap(bodyHTML: "", theme: .light, zoomPercent: 80, bundleURL: bundleURL)
        XCTAssertTrue(min.contains("font-size: 13px"), "80% → 13px (rounded 12.8), got: \(min)")
    }

    func testZoomClamping() {
        let overMax = HTMLTemplate.wrap(bodyHTML: "", theme: .light, zoomPercent: 500, bundleURL: bundleURL)
        XCTAssertTrue(overMax.contains("font-size: 32px"), "clamp to 200% → 32px, got: \(overMax)")

        let underMin = HTMLTemplate.wrap(bodyHTML: "", theme: .light, zoomPercent: 10, bundleURL: bundleURL)
        XCTAssertTrue(underMin.contains("font-size: 13px"), "clamp to 80% → 13px, got: \(underMin)")
    }

    func testBodyHTMLInsertedIntoArticle() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "<h1>Unique-Content-Marker</h1>",
            theme: .light,
            zoomPercent: 100,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("Unique-Content-Marker"), "got: \(html)")
        XCTAssertTrue(html.contains("class=\"markdown-body\""), "got: \(html)")
    }

    func testHighlightJSScriptIncluded() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "",
            theme: .light,
            zoomPercent: 100,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("highlight.min.js"), "got: \(html)")
        XCTAssertTrue(html.contains("hljs.highlightAll"), "got: \(html)")
    }
}
