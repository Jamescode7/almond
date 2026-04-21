import XCTest
@testable import AlmondCore

final class FrontMatterStripperTests: XCTestCase {
    func testYamlFrontMatterRemoved() {
        let input = """
        ---
        title: Hello
        author: James
        ---

        # Heading
        body text
        """
        let stripped = FrontMatterStripper.strip(input)
        XCTAssertFalse(stripped.contains("title:"), "got: \(stripped)")
        XCTAssertFalse(stripped.contains("author:"), "got: \(stripped)")
        XCTAssertTrue(stripped.hasPrefix("# Heading"), "got: \(stripped)")
    }

    func testNoFrontMatterPreserved() {
        let input = "# Heading\nbody"
        let stripped = FrontMatterStripper.strip(input)
        XCTAssertEqual(stripped, input)
    }

    func testMalformedFrontMatterLeftAlone() {
        let input = """
        ---
        title: no terminator
        # Heading
        """
        let stripped = FrontMatterStripper.strip(input)
        XCTAssertEqual(stripped, input, "malformed frontmatter should be preserved as-is")
    }

    func testDotDotDotTerminator() {
        let input = """
        ---
        title: Hello
        ...

        # Heading
        """
        let stripped = FrontMatterStripper.strip(input)
        XCTAssertTrue(stripped.hasPrefix("# Heading"), "got: \(stripped)")
    }

    func testDoesNotStripHorizontalRule() {
        let input = """
        # Heading

        ---

        paragraph
        """
        let stripped = FrontMatterStripper.strip(input)
        XCTAssertEqual(stripped, input, "leading --- not followed by closing delim should be preserved")
    }
}
