import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    override init() {
        super.init()
        DiagLog.log("AppDelegate.init (log path: \(DiagLog.logPath))")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        DiagLog.log("applicationWillFinishLaunching — registering AEEventManager odoc handler")
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleAEOpenDocuments(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DiagLog.log("applicationDidFinishLaunching (bundleID=\(Bundle.main.bundleIdentifier ?? "nil"))")
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        DiagLog.log("applicationShouldOpenUntitledFile → false")
        return false
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        DiagLog.log("application(_:open:) urls=\(urls.map { $0.path })")
        openURLs(urls)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        DiagLog.log("application(_:openFile:) \(filename)")
        openURLs([URL(fileURLWithPath: filename)])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        DiagLog.log("application(_:openFiles:) \(filenames)")
        openURLs(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    @objc func handleAEOpenDocuments(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        let directObjectCount = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.numberOfItems ?? 0
        DiagLog.log("handleAEOpenDocuments fired, items=\(directObjectCount)")
        guard let listDescriptor = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            DiagLog.log("AE: no direct object")
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
        DiagLog.log("AE parsed \(urls.count) url(s): \(urls.map { $0.path })")
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
                DiagLog.log("already open: \(url.lastPathComponent)")
                if let window = NSDocumentController.shared.documents.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL })?.windowControllers.first?.window {
                    window.makeKeyAndOrderFront(nil)
                }
                continue
            }
            DiagLog.log("opening via NSDocumentController: \(url.lastPathComponent)")
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true
            ) { doc, alreadyOpened, error in
                if let error = error {
                    DiagLog.log("openDocument error: \(error.localizedDescription)")
                } else {
                    DiagLog.log("openDocument success, alreadyOpened=\(alreadyOpened), doc=\(String(describing: doc))")
                }
            }
        }
    }
}
