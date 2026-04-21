# Almond

**Minimal markdown viewer for macOS.** Typora-style WYSIWYG reading, no editing.

[![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Status: v0.1.0 MVP](https://img.shields.io/badge/status-v0.1.0%20MVP-orange)](doc/app_005_md_viewer.md)

Open a `.md` file, see rendered markdown. That's it. No live editing, no subscriptions, no telemetry, fully offline.

---

## Why Almond?

- **Free & open-source.** Drop-in alternative to Typora (€14.99) or Marked 2 ($13.99) when all you need is a viewer.
- **Focused.** Reader-only UI — no mode toggles, no source pane, no clutter.
- **Native.** Swift + SwiftUI + WKWebView. Universal binary (Apple Silicon + Intel).
- **Offline.** Zero network calls. Styles and syntax highlighting are bundled.

---

## Download & Install

> v0.1.0 ships **unsigned** (no Apple Developer Program yet). macOS will show a Gatekeeper warning on first launch — see below.

1. Download the latest DMG from [Releases](https://github.com/Jamescode7/almond/releases/latest).
2. Open the DMG and drag **Almond.app** into your Applications folder.
3. In Finder, **right-click** (or Control-click) Almond.app and choose **Open**.
4. In the dialog, click **Open**. macOS will remember this decision.

After the one-time approval, double-click the app as usual.

---

## Features (v0.1.0)

Supports CommonMark + GitHub Flavored Markdown:

- Headings (H1–H6), paragraphs, line breaks
- `*italic*`, `**bold**`, `~~strikethrough~~`
- Blockquotes, horizontal rules
- Ordered / unordered lists (nested)
- Task lists (`- [ ]`, `- [x]`)
- Inline `` `code` `` + fenced code blocks with syntax highlighting ([highlight.js](https://highlightjs.org/))
- Tables with column alignment (`:---:`, `---:`, `:---`)
- Links (inline + autolinks)
- Images (relative / absolute / http)
- YAML frontmatter (stripped silently)

UI:

- System / Light / Dark appearance (cycle with ⇧⌘D, per window)
- Zoom 80–200% (⌘= / ⌘- / ⌘0)
- Find in document (⌘F, ESC to close)
- Auto-reload on external edits (FSEvents), scroll position preserved
- Word / character count + scroll percent in the status bar
- File drag-drop onto the window
- `almond <file.md>` command-line launcher (install from Preferences)

---

## Not in v0.1.0 (roadmap)

- Editing — viewer only. See [spec §11](doc/app_005_md_viewer.md) for the full negative-rules list.
- LaTeX (KaTeX), Mermaid diagrams
- PDF / HTML export
- TOC sidebar, file browser sidebar
- In-app auto-update (Sparkle)
- Multi-tab windows
- iCloud sync

See [spec §13](doc/app_005_md_viewer.md) for the full v2 roadmap.

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `⌘O` | Open file |
| `⌘W` | Close window |
| `⌘,` | Preferences |
| `⌘+` / `⌘=` / `⌘-` / `⌘0` | Zoom in / in / out / reset |
| `⌘R` | Reload current file |
| `⇧⌘D` | Cycle appearance (System → Light → Dark) |
| `⌘F` / `ESC` | Open / close search |
| `⌘Q` | Quit |

---

## Build from source

### Requirements

- macOS 13 Ventura or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [create-dmg](https://github.com/create-dmg/create-dmg) (for DMG packaging only): `brew install create-dmg`

### Commands

```bash
# Clone + generate project
git clone https://github.com/Jamescode7/almond.git
cd almond
xcodegen generate

# Run tests (pure-logic core)
swift test

# Debug build (ad-hoc signed)
xcodebuild -project Almond.xcodeproj -scheme Almond -configuration Debug build

# Release build + DMG
./scripts/build-release.sh
./scripts/make-dmg.sh
# → dist/Almond-0.1.0.dmg
```

`project.yml` is the single source of truth. `Almond.xcodeproj`, `Info.plist`, and the `.entitlements` file are regenerated from it.

---

## Architecture

- **`AlmondCore`** (`Sources/AlmondCore/`) — pure Swift, no AppKit. Markdown → HTML pipeline. Testable in isolation via `swift test`.
  - `MarkdownRenderer` — `MarkupVisitor` over Apple [swift-markdown](https://github.com/apple/swift-markdown)
  - `HTMLTemplate` — wraps body HTML with bundled CSS/JS
  - `FrontMatterStripper` — removes leading YAML block
  - `TextStats` — word / character count
- **`AlmondApp`** (`Sources/AlmondApp/`) — SwiftUI macOS app.
  - `DocumentGroup(viewing:)` handles Open / Open Recent / drag-to-icon
  - `WKWebView` renders HTML with `file://` base URL for image resolution
  - `FileWatcher` (DispatchSourceFileSystemObject) for auto-reload
  - `WKScriptMessageHandler` for live scroll percent

---

## Third-party assets

Bundled under their respective licenses (see [`Resources/LICENSES.txt`](Resources/LICENSES.txt)):

- [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) v5.5.1 — MIT
- [highlight.js](https://github.com/highlightjs/highlight.js) v11.9.0 — BSD-3-Clause

Apple [swift-markdown](https://github.com/apple/swift-markdown) is fetched via Swift Package Manager at build time.

---

## License

MIT — see [LICENSE](LICENSE).
