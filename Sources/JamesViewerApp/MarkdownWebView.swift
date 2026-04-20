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
    let onScrollChange: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScrollChange: onScrollChange)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "scrollHandler")

        let scrollScript = WKUserScript(
            source: Coordinator.scrollTrackingJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(scrollScript)
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webViewStore.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onScrollChange = onScrollChange
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

        if context.coordinator.hasLoadedOnce {
            webView.evaluateJavaScript("window.scrollY") { result, _ in
                let scrollY = (result as? NSNumber)?.doubleValue ?? 0
                context.coordinator.pendingScrollY = scrollY
                context.coordinator.lastHTML = html
                webView.loadHTMLString(html, baseURL: nil)
            }
        } else {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var pendingScrollY: Double?
        var lastHTML: String?
        var lastSearchQuery: String?
        var hasLoadedOnce: Bool = false
        var onScrollChange: (Double) -> Void

        init(onScrollChange: @escaping (Double) -> Void) {
            self.onScrollChange = onScrollChange
        }

        static let scrollTrackingJS: String = """
        (function() {
          function postScrollPercent() {
            var max = document.documentElement.scrollHeight - window.innerHeight;
            var pct = max > 0 ? Math.max(0, Math.min(100, (window.scrollY / max) * 100)) : 0;
            window.webkit.messageHandlers.scrollHandler.postMessage(pct);
          }
          window.addEventListener('scroll', postScrollPercent, { passive: true });
          window.addEventListener('load', postScrollPercent);
          window.addEventListener('resize', postScrollPercent);
          postScrollPercent();
        })();
        """

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "scrollHandler",
                  let percent = (message.body as? NSNumber)?.doubleValue
            else { return }
            DispatchQueue.main.async { self.onScrollChange(percent) }
        }

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
