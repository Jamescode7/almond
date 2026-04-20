import SwiftUI

@main
struct JamesViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { configuration in
            ContentView(
                document: configuration.document,
                fileURL: configuration.fileURL
            )
        }

        Settings {
            SettingsView()
        }
    }
}
