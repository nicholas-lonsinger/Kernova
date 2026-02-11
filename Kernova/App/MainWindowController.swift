import Cocoa
import SwiftUI

/// Hosts the main SwiftUI `ContentView` inside an AppKit window.
final class MainWindowController: NSWindowController {

    convenience init(viewModel: VMLibraryViewModel) {
        let contentView = ContentView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "Kernova"
        window.setContentSize(NSSize(width: 1100, height: 700))
        window.minSize = NSSize(width: 800, height: 500)
        window.center()
        window.setFrameAutosaveName("KernovaMainWindow")

        self.init(window: window)
    }
}
