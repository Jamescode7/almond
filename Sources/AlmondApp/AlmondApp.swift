import SwiftUI

@main
struct AlmondApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
