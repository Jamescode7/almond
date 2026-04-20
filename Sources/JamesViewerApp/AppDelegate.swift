import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    override init() {
        super.init()
        NSLog("[JamesViewer] AppDelegate.init")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSLog("[JamesViewer] applicationWillFinishLaunching — registering AEEventManager odoc handler")
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleAEOpenDocuments(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[JamesViewer] applicationDidFinishLaunching")
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSLog("[JamesViewer] applicationShouldOpenUntitledFile → false")
        return false
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        NSLog("[JamesViewer] application(_:open:) urls=\(urls.map { $0.path })")
        openURLs(urls)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        NSLog("[JamesViewer] application(_:openFile:) \(filename)")
        openURLs([URL(fileURLWithPath: filename)])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        NSLog("[JamesViewer] application(_:openFiles:) \(filenames)")
        openURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    @objc func handleAEOpenDocuments(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        NSLog("[JamesViewer] handleAEOpenDocuments fired, items=\(event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.numberOfItems ?? 0)")
        guard let listDescriptor = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            NSLog("[JamesViewer] AE: no direct object")
            return
        }
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
        NSLog("[JamesViewer] AE parsed \(urls.count) url(s)")
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
            let alreadyOpen = NSDocumentController.shared.documents.contains { doc in
                doc.fileURL?.standardizedFileURL == url.standardizedFileURL
            }
            if alreadyOpen {
                NSLog("[JamesViewer] already open: \(url.lastPathComponent)")
                if let window = NSDocumentController.shared.documents.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL })?.windowControllers.first?.window {
                    window.makeKeyAndOrderFront(nil)
                }
                continue
            }
            NSLog("[JamesViewer] opening via NSDocumentController: \(url.lastPathComponent)")
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true
            ) { doc, alreadyOpened, error in
                if let error = error {
                    NSLog("[JamesViewer] openDocument error: \(error.localizedDescription)")
                } else {
                    NSLog("[JamesViewer] openDocument success, alreadyOpened=\(alreadyOpened), doc=\(String(describing: doc))")
                }
            }
        }
    }
}
