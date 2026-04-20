import SwiftUI
import AppKit
import UniformTypeIdentifiers
import JamesViewerCore

struct ContentView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    @State private var text: String
    @State private var fileMissing: Bool = false
    @State private var watcher: FileWatcher?
    @StateObject private var viewState = DocumentViewState()
    @StateObject private var webViewStore = WebViewStore()

    init(document: MarkdownDocument, fileURL: URL?) {
        DiagLog.log("ContentView.init text.count=\(document.text.count), fileURL=\(fileURL?.path ?? "nil")")
        self.document = document
        self.fileURL = fileURL
        self._text = State(initialValue: document.text)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                MarkdownWebView(
                    markdown: text,
                    fileURL: fileURL,
                    zoomPercent: viewState.zoomPercent,
                    theme: resolvedTheme,
                    searchQuery: viewState.showSearch ? viewState.searchQuery : "",
                    webViewStore: webViewStore,
                    onScrollChange: { viewState.scrollPercent = $0 }
                )
                VStack(spacing: 0) {
                    if viewState.showSearch {
                        SearchBar(
                            query: $viewState.searchQuery,
                            onSubmit: { webViewStore.findNext(query: viewState.searchQuery) },
                            onDismiss: { closeSearch() }
                        )
                    }
                    if fileMissing {
                        MissingFileBanner(fileURL: fileURL) {
                            fileMissing = false
                        }
                    }
                }
            }
            StatusBar(
                wordCount: TextStats.wordCount(text),
                charCount: TextStats.charCount(text),
                scrollPercent: viewState.scrollPercent
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar { toolbarContent }
        .background(WindowConfigurator(preferredSize: CGSize(width: 960, height: 720)))
        .background(keyboardShortcuts)
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        .onAppear {
            ensureContentLoaded()
            startWatching()
        }
        .onDisappear { watcher?.stop() }
    }

    private func ensureContentLoaded() {
        guard text.isEmpty, fileURL != nil else { return }
        reloadFromDisk()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: viewState.cycleAppearance) {
                Image(systemName: viewState.appearanceOverride.symbolName)
            }
            .help("Cycle appearance (⇧⌘D)")

            Button(action: viewState.zoomOut) {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom out (⌘-)")

            Button(action: viewState.zoomIn) {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom in (⌘=)")
        }
    }

    private var keyboardShortcuts: some View {
        ZStack {
            Button("", action: viewState.zoomIn)
                .keyboardShortcut("=", modifiers: .command).hidden()
            Button("", action: viewState.zoomIn)
                .keyboardShortcut("+", modifiers: .command).hidden()
            Button("", action: viewState.zoomOut)
                .keyboardShortcut("-", modifiers: .command).hidden()
            Button("", action: viewState.zoomReset)
                .keyboardShortcut("0", modifiers: .command).hidden()
            Button("", action: reloadFromDisk)
                .keyboardShortcut("r", modifiers: .command).hidden()
            Button("", action: viewState.cycleAppearance)
                .keyboardShortcut("d", modifiers: [.shift, .command]).hidden()
            Button("", action: openSearch)
                .keyboardShortcut("f", modifiers: .command).hidden()
            if viewState.showSearch {
                Button("", action: closeSearch)
                    .keyboardShortcut(.escape, modifiers: []).hidden()
            }
        }
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
    }

    private var resolvedTheme: HTMLTemplate.Theme {
        switch viewState.appearanceOverride {
        case .light: return .light
        case .dark: return .dark
        case .system:
            return NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
        }
    }

    private func openSearch() {
        viewState.showSearch = true
    }

    private func closeSearch() {
        viewState.showSearch = false
        viewState.searchQuery = ""
    }

    private func startWatching() {
        guard let fileURL = fileURL else { return }
        let newWatcher = FileWatcher(url: fileURL) { event in
            switch event {
            case .modified:
                reloadFromDisk()
            case .deleted, .renamed:
                fileMissing = true
            }
        }
        watcher?.stop()
        watcher = newWatcher
        newWatcher.start()
    }

    private func reloadFromDisk() {
        guard let fileURL = fileURL else { return }
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: fileURL),
              let newText = String(data: data, encoding: .utf8)
        else { return }
        text = newText
        fileMissing = false
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
                continue
            }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(url)
                }
            }
            handled = true
        }
        return handled
    }
}

private struct StatusBar: View {
    let wordCount: Int
    let charCount: Int
    let scrollPercent: Double

    var body: some View {
        HStack(spacing: 8) {
            Text("\(wordCount.formatted()) words")
            Text("·")
            Text("\(charCount.formatted()) chars")
            Text("·")
            Text("\(Int(scrollPercent))%")
            Spacer()
        }
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
}
