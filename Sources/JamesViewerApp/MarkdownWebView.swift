import SwiftUI
import WebKit
import JamesViewerCore

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let fileURL: URL?
    let zoomPercent: Int
    let theme: HTMLTemplate.Theme
    let searchQuery: String
    let webViewStore: WebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        webViewStore.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.pageZoom = Double(zoomPercent) / 100.0

        if searchQuery != context.coordinator.lastSearchQuery {
            context.coordinator.lastSearchQuery = searchQuery
            runFind(query: searchQuery, webView: webView)
        }

        guard let bundleURL = Bundle.main.resourceURL else { return }
        let stripped = FrontMatterStripper.strip(markdown)
        let bodyHTML = MarkdownRenderer.render(stripped)
        let html = HTMLTemplate.wrap(
            bodyHTML: bodyHTML,
            theme: theme,
            bundleURL: bundleURL
        )

        if html == context.coordinator.lastHTML {
            return
        }

        let baseURL = fileURL?.deletingLastPathComponent() ?? bundleURL

        if context.coordinator.hasLoadedOnce {
            webView.evaluateJavaScript("window.scrollY") { result, _ in
                let scrollY = (result as? NSNumber)?.doubleValue ?? 0
                context.coordinator.pendingScrollY = scrollY
                context.coordinator.lastHTML = html
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        } else {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var pendingScrollY: Double?
        var lastHTML: String?
        var lastSearchQuery: String?
        var hasLoadedOnce: Bool = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasLoadedOnce = true
            guard let scrollY = pendingScrollY, scrollY > 0 else { return }
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollY));") { _, _ in }
            pendingScrollY = nil
        }
    }

    static func escapeJSString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }

    private func runFind(query: String, webView: WKWebView) {
        guard !query.isEmpty else {
            webView.evaluateJavaScript("getSelection().removeAllRanges();") { _, _ in }
            return
        }
        let escaped = Self.escapeJSString(query)
        let js = "window.find(\"\(escaped)\", false, false, true, false, true, false);"
        webView.evaluateJavaScript(js) { _, _ in }
    }
}
