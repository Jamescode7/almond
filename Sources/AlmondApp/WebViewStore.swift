import Foundation
import WebKit

final class WebViewStore: ObservableObject {
    weak var webView: WKWebView?

    func findNext(query: String) {
        guard !query.isEmpty else { return }
        let escaped = MarkdownWebView.escapeJSString(query)
        let js = "window.find(\"\(escaped)\", false, false, true, false, true, false);"
        webView?.evaluateJavaScript(js) { _, _ in }
    }
}
