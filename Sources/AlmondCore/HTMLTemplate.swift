import Foundation

public enum HTMLTemplate {
    public enum Theme: String {
        case light
        case dark
    }

    public static func wrap(
        bodyHTML: String,
        theme: Theme,
        bundleURL: URL
    ) -> String {
        let markdownCSS = loadResource(bundleURL: bundleURL, file: theme == .dark ? "github-markdown-dark.css" : "github-markdown-light.css")
        let highlightCSS = loadResource(bundleURL: bundleURL, file: theme == .dark ? "highlight-atom-one-dark.css" : "highlight-github.css")
        let highlightJS = loadResource(bundleURL: bundleURL, file: "highlight.min.js")
        let themeAttr = theme == .dark ? "dark" : "light"
        let bodyBg = theme == .dark ? "#0d1117" : "#ffffff"

        return """
        <!DOCTYPE html>
        <html lang="en" data-theme="\(themeAttr)">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
        \(markdownCSS)
          </style>
          <style>
        \(highlightCSS)
          </style>
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background-color: \(bodyBg);
            }
            body {
              font-size: 16px;
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
          <script>
        \(highlightJS)
          </script>
          <script>
            if (window.hljs) { hljs.highlightAll(); }
          </script>
        </body>
        </html>
        """
    }

    private static func loadResource(bundleURL: URL, file: String) -> String {
        let url = bundleURL.appendingPathComponent(file)
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
