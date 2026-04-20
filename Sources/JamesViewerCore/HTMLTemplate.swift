import Foundation

public enum HTMLTemplate {
    public enum Theme: String {
        case light
        case dark
    }

    public static func wrap(
        bodyHTML: String,
        theme: Theme,
        zoomPercent: Int,
        bundleURL: URL
    ) -> String {
        let zoom = max(80, min(200, zoomPercent))
        let fontSize = Int((Double(zoom) * 16.0 / 100.0).rounded())

        let markdownCSS: String
        let highlightCSS: String
        switch theme {
        case .light:
            markdownCSS = cssURL(bundleURL: bundleURL, file: "github-markdown-light.css")
            highlightCSS = cssURL(bundleURL: bundleURL, file: "highlight-github.css")
        case .dark:
            markdownCSS = cssURL(bundleURL: bundleURL, file: "github-markdown-dark.css")
            highlightCSS = cssURL(bundleURL: bundleURL, file: "highlight-atom-one-dark.css")
        }

        let highlightJS = jsURL(bundleURL: bundleURL, file: "highlight.min.js")
        let themeAttr = theme == .dark ? "dark" : "light"

        return """
        <!DOCTYPE html>
        <html lang="en" data-theme="\(themeAttr)">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link rel="stylesheet" href="\(markdownCSS)">
          <link rel="stylesheet" href="\(highlightCSS)">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background-color: \(theme == .dark ? "#0d1117" : "#ffffff");
            }
            body {
              font-size: \(fontSize)px;
              line-height: 1.6;
            }
            .markdown-body {
              box-sizing: border-box;
              min-width: 200px;
              max-width: 760px;
              margin: 0 auto;
              padding: 32px 16px 64px;
            }
            @media (max-width: 760px) {
              .markdown-body {
                padding: 16px;
              }
            }
          </style>
        </head>
        <body>
          <article class="markdown-body">
        \(bodyHTML)
          </article>
          <script src="\(highlightJS)"></script>
          <script>
            if (window.hljs) { hljs.highlightAll(); }
          </script>
        </body>
        </html>
        """
    }

    private static func cssURL(bundleURL: URL, file: String) -> String {
        return bundleURL.appendingPathComponent(file).absoluteString
    }

    private static func jsURL(bundleURL: URL, file: String) -> String {
        return bundleURL.appendingPathComponent(file).absoluteString
    }
}
