import SwiftUI

struct ContentView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    var body: some View {
        MarkdownWebView(
            markdown: document.text,
            fileURL: fileURL
        )
        .frame(minWidth: 600, minHeight: 400)
    }
}
