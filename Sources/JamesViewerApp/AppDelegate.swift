import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, open urls: [URL]) {
        NSLog("[JamesViewer] AppDelegate.application(_:open:) \(urls.count) url(s)")
        for url in urls {
            let alreadyOpen = NSDocumentController.shared.documents.contains { doc in
                guard let docURL = doc.fileURL else { return false }
                return docURL.standardizedFileURL == url.standardizedFileURL
            }
            if alreadyOpen {
                NSLog("[JamesViewer] already open: \(url.lastPathComponent), skipping")
                continue
            }
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true
            ) { _, _, error in
                if let error = error {
                    NSLog("[JamesViewer] openDocument error for \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
}
