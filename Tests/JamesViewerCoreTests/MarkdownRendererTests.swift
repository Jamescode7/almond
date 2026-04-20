import XCTest
@testable import JamesViewerCore

final class MarkdownRendererTests: XCTestCase {
    func testH1Renders() {
        let html = MarkdownRenderer.render("# Hello")
        XCTAssertTrue(html.contains("<h1>Hello</h1>"), "got: \(html)")
    }

    func testH2ThroughH6Render() {
        for level in 2...6 {
            let prefix = String(repeating: "#", count: level)
            let html = MarkdownRenderer.render("\(prefix) Heading")
            XCTAssertTrue(html.contains("<h\(level)>Heading</h\(level)>"), "level \(level) got: \(html)")
        }
    }

    func testCodeBlockCarriesLanguageClass() {
        let md = """
        ```swift
        let x = 1
        ```
        """
        let html = MarkdownRenderer.render(md)
        XCTAssertTrue(html.contains("<code class=\"language-swift\">"), "got: \(html)")
        XCTAssertTrue(html.contains("let x = 1"), "got: \(html)")
    }

    func testCodeBlockWithoutLanguage() {
        let md = """
        ```
        plain code
        ```
        """
        let html = MarkdownRenderer.render(md)
        XCTAssertTrue(html.contains("<pre><code>plain code"), "got: \(html)")
        XCTAssertFalse(html.contains("language-"), "got: \(html)")
    }

    func testTableRenders() {
        let md = """
        | a | b | c |
        |---|:---:|---:|
        | 1 | 2 | 3 |
        | 4 | 5 | 6 |
        """
        let html = MarkdownRenderer.render(md)
        XCTAssertTrue(html.contains("<table>"), "got: \(html)")
        XCTAssertTrue(html.contains("<thead>"), "got: \(html)")
        XCTAssertTrue(html.contains("<tbody>"), "got: \(html)")
        XCTAssertTrue(html.contains("<th>a</th>") || html.contains("<th align=\"left\">a</th>"), "got: \(html)")
        XCTAssertTrue(html.contains("align=\"center\""), "got: \(html)")
        XCTAssertTrue(html.contains("align=\"right\""), "got: \(html)")
    }

    func testTaskListCheckbox() {
        let md = """
        - [x] done
        - [ ] todo
        """
        let html = MarkdownRenderer.render(md)
        XCTAssertTrue(html.contains("<input type=\"checkbox\" checked disabled />"), "got: \(html)")
        XCTAssertTrue(html.contains("<input type=\"checkbox\" disabled />"), "got: \(html)")
        XCTAssertTrue(html.contains("task-list-item"), "got: \(html)")
    }

    func testHTMLEscaping() {
        let md = "Inline `<script>alert(1)</script>` should be escaped."
        let html = MarkdownRenderer.render(md)
        XCTAssertTrue(html.contains("&lt;script&gt;"), "got: \(html)")
        XCTAssertFalse(html.contains("<script>alert(1)"), "got: \(html)")
    }

    func testLinkRenders() {
        let html = MarkdownRenderer.render("[example](https://example.com)")
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">example</a>"), "got: \(html)")
    }

    func testImageRenders() {
        let html = MarkdownRenderer.render("![alt text](image.png)")
        XCTAssertTrue(html.contains("<img src=\"image.png\""), "got: \(html)")
        XCTAssertTrue(html.contains("alt=\"alt text\""), "got: \(html)")
    }

    func testStrikethroughAndStrongAndEmphasis() {
        let html = MarkdownRenderer.render("~~s~~ **b** *i*")
        XCTAssertTrue(html.contains("<del>s</del>"), "got: \(html)")
        XCTAssertTrue(html.contains("<strong>b</strong>"), "got: \(html)")
        XCTAssertTrue(html.contains("<em>i</em>"), "got: \(html)")
    }

    func testNestedList() {
        let md = """
        - a
          - b
          - c
        - d
        """
        let html = MarkdownRenderer.render(md)
        XCTAssertEqual(html.components(separatedBy: "<ul>").count - 1, 2, "expected 2 <ul>, got: \(html)")
    }
}
