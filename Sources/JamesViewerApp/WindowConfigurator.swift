import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {
    let preferredSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configureIfNeeded(view: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureIfNeeded(view: nsView)
        }
    }

    private func configureIfNeeded(view: NSView) {
        guard let window = view.window else { return }
        guard !window.isSheet else { return }

        if window.identifier?.rawValue == "com.jamescode.JamesViewer.configured" {
            return
        }
        window.identifier = NSUserInterfaceItemIdentifier("com.jamescode.JamesViewer.configured")

        let frameAutosaveName = "JamesViewerDocument"
        let hadStoredFrame = window.setFrameAutosaveName(frameAutosaveName)

        if !hadStoredFrame {
            let screenFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
            let size = CGSize(
                width: min(preferredSize.width, screenFrame.width * 0.9),
                height: min(preferredSize.height, screenFrame.height * 0.9)
            )
            let origin = CGPoint(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2
            )
            window.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
        }
    }
}
