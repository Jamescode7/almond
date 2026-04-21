import XCTest
@testable import AlmondCore

final class HTMLTemplateTests: XCTestCase {
    private let bundleURL = URL(fileURLWithPath: "/tmp/almond-test-bundle", isDirectory: true)

    func testLightThemeDataAttr() {
        let html = HTMLTemplate.wrap(bodyHTML: "<p>hi</p>", theme: .light, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("data-theme=\"light\""), "got: \(html)")
        XCTAssertFalse(html.contains("data-theme=\"dark\""), "got: \(html)")
    }

    func testDarkThemeDataAttr() {
        let html = HTMLTemplate.wrap(bodyHTML: "<p>hi</p>", theme: .dark, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("data-theme=\"dark\""), "got: \(html)")
        XCTAssertFalse(html.contains("data-theme=\"light\""), "got: \(html)")
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

    func testHighlightJSBootScriptIncluded() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("hljs.highlightAll"), "got: \(html)")
    }

    func testFixedBaseFontSize() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("font-size: 16px"), "줌은 WKWebView.pageZoom 으로 적용")
    }

    func testDarkBackgroundColor() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .dark, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("#0d1117"), "got: \(html)")
    }

    func testLightBackgroundColor() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: bundleURL)
        XCTAssertTrue(html.contains("#ffffff"), "got: \(html)")
    }

    func testCSSInlinedWhenBundleAvailable() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jv-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let cssContent = ".markdown-body-sentinel { color: red; }"
        try cssContent.data(using: .utf8)!.write(to: tmpDir.appendingPathComponent("github-markdown-light.css"))

        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: tmpDir)
        XCTAssertTrue(html.contains("markdown-body-sentinel"), "CSS 내용이 인라인되지 않음. got: \(html)")
        XCTAssertFalse(html.contains("<link rel=\"stylesheet\""), "file:// link 가 남아있으면 안 됨")
    }

    func testNoFileURLReferencesLeaking() {
        let html = HTMLTemplate.wrap(bodyHTML: "", theme: .light, bundleURL: bundleURL)
        XCTAssertFalse(html.contains("<link rel=\"stylesheet\""), "file:// link tag 없어야 함")
        XCTAssertFalse(html.contains("<script src="), "file:// script src 없어야 함")
    }
}
