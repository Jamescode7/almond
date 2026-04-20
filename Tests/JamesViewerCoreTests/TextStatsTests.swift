import XCTest
@testable import JamesViewerCore

final class TextStatsTests: XCTestCase {
    func testEnglishWordCount() {
        XCTAssertEqual(TextStats.wordCount("hello world"), 2)
        XCTAssertEqual(TextStats.wordCount("The quick brown fox"), 4)
    }

    func testKoreanWordCount() {
        XCTAssertEqual(TextStats.wordCount("안녕 세상"), 2)
        XCTAssertEqual(TextStats.wordCount("안녕하세요 반갑습니다 만나서"), 3)
    }

    func testMixedEnglishAndKorean() {
        XCTAssertEqual(TextStats.wordCount("hello 안녕 world 세상"), 4)
    }

    func testEmptyString() {
        XCTAssertEqual(TextStats.wordCount(""), 0)
        XCTAssertEqual(TextStats.charCount(""), 0)
    }

    func testWhitespaceOnly() {
        XCTAssertEqual(TextStats.wordCount("    "), 0)
        XCTAssertEqual(TextStats.wordCount("\t\n\r"), 0)
    }

    func testMultipleSpacesCountsAsOneSeparator() {
        XCTAssertEqual(TextStats.wordCount("a   b    c"), 3)
    }

    func testNewlineSeparatesWords() {
        XCTAssertEqual(TextStats.wordCount("line1\nline2\nline3"), 3)
    }

    func testCharCountIncludesWhitespace() {
        XCTAssertEqual(TextStats.charCount("hello world"), 11)
        XCTAssertEqual(TextStats.charCount("안녕"), 2)
    }

    func testCharCountWithEmoji() {
        XCTAssertEqual(TextStats.charCount("👍"), 1)
        XCTAssertEqual(TextStats.charCount("a👍b"), 3)
    }

    func testMarkdownSyntaxCountsAsWord() {
        XCTAssertEqual(TextStats.wordCount("# Heading"), 2)
        XCTAssertEqual(TextStats.wordCount("**bold**"), 1)
    }
}
