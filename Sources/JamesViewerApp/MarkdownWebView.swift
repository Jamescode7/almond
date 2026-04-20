import SwiftUI
import WebKit
import JamesViewerCore

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let fileURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let bundleURL = Bundle.main.resourceURL else { return }
        let stripped = FrontMatterStripper.strip(markdown)
        let bodyHTML = MarkdownRenderer.render(stripped)
        let html = HTMLTemplate.wrap(
            bodyHTML: bodyHTML,
            theme: .light,
            zoomPercent: 100,
            bundleURL: bundleURL
        )
        let baseURL = fileURL?.deletingLastPathComponent() ?? bundleURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }
}
