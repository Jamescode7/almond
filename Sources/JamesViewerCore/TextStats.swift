import Foundation

public enum TextStats {
    public static func wordCount(_ text: String) -> Int {
        return text.split(whereSeparator: { $0.isWhitespace }).count
    }

    public static func charCount(_ text: String) -> Int {
        return text.count
    }
}
