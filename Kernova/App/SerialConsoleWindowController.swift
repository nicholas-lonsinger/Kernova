import Cocoa
import SwiftUI

/// Manages a serial console window for a single VM instance.
///
/// Each VM gets its own window controller. The window hosts a `SerialConsoleContentView`
/// via `NSHostingController` and persists its frame position per VM ID.
@MainActor
final class SerialConsoleWindowController: NSWindowController {

    let vmID: UUID

    init(instance: VMInstance) {
        self.vmID = instance.instanceID

        let contentView = SerialConsoleContentView(instance: instance)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = []

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "\(instance.name) — Serial Console"
        window.minSize = NSSize(width: 400, height: 200)

        super.init(window: window)

        // Restore saved frame or center on first open
        let frameName = "SerialConsole-\(instance.instanceID.uuidString)"
        if !window.setFrameUsingName(frameName) {
            window.center()
        }
        window.setFrameAutosaveName(frameName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
