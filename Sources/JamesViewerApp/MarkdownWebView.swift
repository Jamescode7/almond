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
        DiagLog.log("MarkdownWebView.makeNSView called, markdown.count=\(markdown.count), fileURL=\(fileURL?.path ?? "nil")")
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
        webView.uiDelegate = context.coordinator
        webViewStore.webView = webView
        DiagLog.log("makeNSView returning webView, delegate set: \(webView.navigationDelegate != nil)")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onScrollChange = onScrollChange
        webView.pageZoom = Double(zoomPercent) / 100.0

        if searchQuery != context.coordinator.lastSearchQuery {
            context.coordinator.lastSearchQuery = searchQuery
            runFind(query: searchQuery, webView: webView)
        }

        guard let bundleURL = Bundle.main.resourceURL else {
            DiagLog.log("updateNSView: Bundle.main.resourceURL is nil — aborting")
            return
        }
        let stripped = FrontMatterStripper.strip(markdown)
        let bodyHTML = MarkdownRenderer.render(stripped)
        let html = HTMLTemplate.wrap(
            bodyHTML: bodyHTML,
            theme: theme,
            bundleURL: bundleURL
        )

        if html == context.coordinator.lastHTML {
            DiagLog.log("updateNSView: HTML unchanged, skipping")
            return
        }

        DiagLog.log("updateNSView: about to load HTML (markdown=\(markdown.count), html=\(html.count), webView.isLoading=\(webView.isLoading))")

        // 디버그: 렌더 대상 HTML 을 temp 에 저장해 직접 브라우저로 열어볼 수 있게
        let debugPath = FileManager.default.temporaryDirectory.appendingPathComponent("jamesviewer-render.html")
        try? html.data(using: .utf8)?.write(to: debugPath)
        DiagLog.log("debug HTML saved: \(debugPath.path)")

        if context.coordinator.hasLoadedOnce {
            webView.evaluateJavaScript("window.scrollY") { result, _ in
                let scrollY = (result as? NSNumber)?.doubleValue ?? 0
                context.coordinator.pendingScrollY = scrollY
                context.coordinator.lastHTML = html
                DiagLog.log("loadHTMLString (reload) baseURL=nil")
                webView.loadHTMLString(html, baseURL: nil)
            }
        } else {
            context.coordinator.lastHTML = html
            DiagLog.log("loadHTMLString (first) baseURL=nil")
            webView.loadHTMLString(html, baseURL: nil)
            DiagLog.log("loadHTMLString returned, webView.isLoading=\(webView.isLoading)")
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
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
            if message.name == "scrollHandler",
               let percent = (message.body as? NSNumber)?.doubleValue {
                DispatchQueue.main.async { self.onScrollChange(percent) }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            DiagLog.log("webView decidePolicyFor navigationAction url=\(navigationAction.request.url?.absoluteString ?? "nil")")
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DiagLog.log("webView didStartProvisionalNavigation")
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DiagLog.log("webView didCommit navigation")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DiagLog.log("webView didFinish navigation")
            hasLoadedOnce = true
            guard let scrollY = pendingScrollY, scrollY > 0 else { return }
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollY));") { _, _ in }
            pendingScrollY = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DiagLog.log("webView didFail: \(error.localizedDescription) — \((error as NSError).userInfo)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DiagLog.log("webView didFailProvisionalNavigation: \(error.localizedDescription) — \((error as NSError).userInfo)")
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            DiagLog.log("webViewWebContentProcessDidTerminate — WebContent process crashed!")
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
