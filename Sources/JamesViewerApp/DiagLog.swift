import Foundation
import os

enum DiagLog {
    private static let logger = Logger(subsystem: "com.jamescode.JamesViewer", category: "diag")

    private static let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("jamesviewer-diag.log")
    }()

    private static let queue = DispatchQueue(label: "com.jamescode.JamesViewer.diag")

    private static var didAnnouncePath = false

    static func log(_ message: String) {
        logger.info("\(message, privacy: .public)")
        NSLog("[JamesViewer] %@", message)

        queue.async {
            if !didAnnouncePath {
                didAnnouncePath = true
                let header = "=== JamesViewer diag log — \(Date()) ===\n=== path: \(fileURL.path) ===\n"
                try? header.data(using: .utf8)?.write(to: fileURL)
            }
            let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                try? handle.write(contentsOf: data)
                try? handle.close()
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    static var logPath: String { fileURL.path }
}
