import Foundation

public enum FrontMatterStripper {
    public static func strip(_ source: String) -> String {
        guard source.hasPrefix("---\n") || source.hasPrefix("---\r\n") else {
            return source
        }
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 3 else { return source }

        for index in 1..<lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed == "---" || trimmed == "..." {
                let remaining = lines[(index + 1)...].joined(separator: "\n")
                return remaining.drop(while: { $0 == "\n" || $0 == "\r" }).description
            }
        }
        return source
    }
}
