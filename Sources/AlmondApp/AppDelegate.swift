import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleAEOpenDocuments(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        openURLs(urls)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        openURLs([URL(fileURLWithPath: filename)])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        openURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    @objc func handleAEOpenDocuments(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let listDescriptor = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else { return }
        var urls: [URL] = []
        let count = listDescriptor.numberOfItems
        if count == 0 {
            if let url = extractURL(from: listDescriptor) {
                urls.append(url)
            }
        } else {
            for index in 1...count {
                if let item = listDescriptor.atIndex(index),
                   let url = extractURL(from: item) {
                    urls.append(url)
                }
            }
        }
        openURLs(urls)
    }

    private func extractURL(from descriptor: NSAppleEventDescriptor) -> URL? {
        if let coerced = descriptor.coerce(toDescriptorType: DescType(typeFileURL)),
           let data = coerced.data as Data?,
           let str = String(data: data, encoding: .utf8),
           let url = URL(string: str) {
            return url
        }
        if let str = descriptor.stringValue {
            if let u = URL(string: str), u.isFileURL { return u }
            return URL(fileURLWithPath: str)
        }
        return nil
    }

    private func openURLs(_ urls: [URL]) {
        for url in urls {
            let existing = NSDocumentController.shared.documents.first { doc in
                doc.fileURL?.standardizedFileURL == url.standardizedFileURL
            }
            if let existing = existing {
                existing.windowControllers.first?.window?.makeKeyAndOrderFront(nil)
                continue
            }
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true
            ) { _, _, _ in }
        }
    }
}
