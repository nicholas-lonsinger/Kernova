import Cocoa
import SwiftUI
import Virtualization

/// Manages a dedicated window displaying a single VM's screen, either as a
/// resizable pop-out window or in native macOS fullscreen.
///
/// On show the inline `VMDisplayView` in the main window is replaced by a placeholder
/// (via `VMInstance.displayMode`), and this controller creates its own
/// `VZVirtualMachineView` bound to the same `VZVirtualMachine`. On close the process
/// reverses so the inline display re-appears.
@MainActor
final class VMDisplayWindowController: NSWindowController, NSWindowDelegate {

    let vmID: UUID
    private(set) var closedProgrammatically = false
    private(set) var lastDisplayID: CGDirectDisplayID?
    let instance: VMInstance
    private let enterFullscreen: Bool
    private var observingStatus = false

    init(instance: VMInstance, enterFullscreen: Bool, onResume: @escaping () -> Void) {
        self.vmID = instance.instanceID
        self.instance = instance
        self.enterFullscreen = enterFullscreen

        let contentView = DetachedVMView(instance: instance, onResume: onResume)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = []

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "\(instance.name) — Display"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.fullScreenPrimary]
        window.setFrameAutosaveName("VMDisplay-\(instance.instanceID)")

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func showWindow(_ sender: Any?) {
        instance.displayMode = enterFullscreen ? .fullscreen : .popOut
        super.showWindow(sender)
        if enterFullscreen {
            window?.toggleFullScreen(nil)
        }
        observeStatus()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Capture display ID if not already set by the programmatic-close path
        if lastDisplayID == nil {
            lastDisplayID = window?.screen?.displayID
        }
        observingStatus = false
        instance.displayMode = .inline
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        instance.displayMode = .fullscreen
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        instance.displayMode = .popOut
    }

    // MARK: - Status Observation

    /// Automatically closes the display window when the VM stops, errors, or is cold-paused (save state).
    private func observeStatus() {
        observingStatus = true
        withObservationTracking {
            _ = self.instance.status
            _ = self.instance.virtualMachine
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self, self.observingStatus else { return }
                let status = self.instance.status
                if status == .stopped || status == .error || self.instance.isColdPaused {
                    self.lastDisplayID = self.window?.screen?.displayID
                    self.closedProgrammatically = true
                    self.window?.close()
                } else {
                    self.observeStatus()
                }
            }
        }
    }
}

// MARK: - NSScreen Display ID

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

// MARK: - Detached VM SwiftUI View

/// SwiftUI view used inside the display window. Shows the VM display when a
/// `VZVirtualMachine` is available (with a pause overlay when live-paused), or a placeholder otherwise.
private struct DetachedVMView: View {
    let instance: VMInstance
    var onResume: () -> Void

    var body: some View {
        if let vm = instance.virtualMachine {
            VMDisplayView(virtualMachine: vm)
                .ignoresSafeArea()
                .vmPauseOverlay(isPaused: instance.status == .paused, onResume: onResume)
                .vmTransitionOverlay(status: instance.status)
        } else if instance.status.isTransitioning || instance.isColdPaused {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(instance.isColdPaused ? "Restoring" : instance.status.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else {
            ContentUnavailableView(
                "No Display",
                systemImage: "display",
                description: Text("The virtual machine display is not available.")
            )
        }
    }
}
