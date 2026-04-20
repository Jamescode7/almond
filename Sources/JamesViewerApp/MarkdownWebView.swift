import SwiftUI
import WebKit
import JamesViewerCore

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let fileURL: URL?
    let zoomPercent: Int
    let theme: HTMLTemplate.Theme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let bundleURL = Bundle.main.resourceURL else { return }
        let stripped = FrontMatterStripper.strip(markdown)
        let bodyHTML = MarkdownRenderer.render(stripped)
        let html = HTMLTemplate.wrap(
            bodyHTML: bodyHTML,
            theme: theme,
            zoomPercent: zoomPercent,
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
        var hasLoadedOnce: Bool = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasLoadedOnce = true
            guard let scrollY = pendingScrollY, scrollY > 0 else { return }
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollY));") { _, _ in }
            pendingScrollY = nil
        }
    }
}
