import XCTest
@testable import JamesViewerCore

final class HTMLTemplateTests: XCTestCase {
    private let bundleURL = URL(fileURLWithPath: "/tmp/jamesviewer-test-bundle", isDirectory: true)

    func testLightThemeLinksLightCSS() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "<p>hi</p>",
            theme: .light,
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
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("github-markdown-dark.css"), "got: \(html)")
        XCTAssertTrue(html.contains("highlight-atom-one-dark.css"), "got: \(html)")
        XCTAssertFalse(html.contains("github-markdown-light.css"), "got: \(html)")
        XCTAssertTrue(html.contains("data-theme=\"dark\""), "got: \(html)")
    }

    func testBodyHTMLInsertedIntoArticle() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "<h1>Unique-Content-Marker</h1>",
            theme: .light,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("Unique-Content-Marker"), "got: \(html)")
        XCTAssertTrue(html.contains("class=\"markdown-body\""), "got: \(html)")
    }

    func testHighlightJSScriptIncluded() {
        let html = HTMLTemplate.wrap(
            bodyHTML: "",
            theme: .light,
            bundleURL: bundleURL
        )
        XCTAssertTrue(html.contains("highlight.min.js"), "got: \(html)")
        XCTAssertTrue(html.contains("hljs.highlightAll"), "got: \(html)")
    }

    func testFixedBaseFontSize() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("font-size: 16px"), "줌은 WKWebView.pageZoom 으로 적용, HTMLTemplate 는 항상 16px 기본")
    }

    func testDarkBackgroundColor() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .dark, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("#0d1117"), "got: \(html)")
    }
}
