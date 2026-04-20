import AppKit
import Foundation

enum CLIInstaller {
    static let symlinkPath = "/usr/local/bin/mdv"

    static var bundledScriptURL: URL? {
        Bundle.main.url(forResource: "mdv", withExtension: nil)
    }

    static func install() {
        guard let source = bundledScriptURL else {
            showAlert(title: "Install failed", message: "Bundled mdv script not found.")
            return
        }

        let url = URL(fileURLWithPath: symlinkPath)
        do {
            if FileManager.default.fileExists(atPath: symlinkPath) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.createSymbolicLink(at: url, withDestinationURL: source)
            showAlert(title: "Installed", message: "\(symlinkPath) → \(source.path)\n\nTry it from Terminal: mdv path/to/file.md")
        } catch {
            copyManualCommandToPasteboard(source: source)
            showAlert(
                title: "Automatic install failed",
                message: """
                JamesViewer runs in App Sandbox and cannot write to /usr/local/bin.

                Open Terminal and run this command (it has been copied to your clipboard):

                sudo ln -sf "\(source.path)" \(symlinkPath)
                """
            )
        }
    }

    static func uninstall() {
        let url = URL(fileURLWithPath: symlinkPath)
        do {
            if FileManager.default.fileExists(atPath: symlinkPath) {
                try FileManager.default.removeItem(at: url)
                showAlert(title: "Removed", message: "\(symlinkPath) deleted.")
            } else {
                showAlert(title: "Not installed", message: "\(symlinkPath) does not exist.")
            }
        } catch {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString("sudo rm \(symlinkPath)", forType: .string)
            showAlert(
                title: "Automatic remove failed",
                message: """
                JamesViewer runs in App Sandbox and cannot modify /usr/local/bin.

                Open Terminal and run this command (it has been copied to your clipboard):

                sudo rm \(symlinkPath)
                """
            )
        }
    }

    private static func copyManualCommandToPasteboard(source: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("sudo ln -sf \"\(source.path)\" \(symlinkPath)", forType: .string)
    }

    private static func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
