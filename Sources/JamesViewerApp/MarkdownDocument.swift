import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        var types: [UTType] = []
        if let markdown = UTType("net.daringfireball.markdown") {
            types.append(markdown)
        }
        if let markdown = UTType("public.markdown") {
            types.append(markdown)
        }
        if types.isEmpty {
            types.append(.plainText)
        }
        return types
    }

    static var writableContentTypes: [UTType] { [] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = String(data: data, encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.featureUnsupported)
    }
}
