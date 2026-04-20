import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    @State private var text: String
    @State private var fileMissing: Bool = false
    @State private var watcher: FileWatcher?

    init(document: MarkdownDocument, fileURL: URL?) {
        self.document = document
        self.fileURL = fileURL
        self._text = State(initialValue: document.text)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MarkdownWebView(markdown: text, fileURL: fileURL)
            if fileMissing {
                MissingFileBanner(fileURL: fileURL) {
                    fileMissing = false
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: startWatching)
        .onDisappear { watcher?.stop() }
    }

    private func startWatching() {
        guard let fileURL = fileURL else { return }
        let newWatcher = FileWatcher(url: fileURL) { event in
            switch event {
            case .modified:
                reloadFromDisk()
            case .deleted, .renamed:
                fileMissing = true
            }
        }
        watcher?.stop()
        watcher = newWatcher
        newWatcher.start()
    }

    private func reloadFromDisk() {
        guard let fileURL = fileURL else { return }
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: fileURL),
              let newText = String(data: data, encoding: .utf8)
        else { return }
        text = newText
        fileMissing = false
    }
}
