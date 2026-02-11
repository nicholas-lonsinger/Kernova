import Cocoa
import SwiftUI

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var mainWindowController: MainWindowController?
    private let viewModel = VMLibraryViewModel()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowController = MainWindowController(viewModel: viewModel)
        windowController.showWindow(nil)
        mainWindowController = windowController
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save any running VMs before termination
        let runningInstances = viewModel.instances.filter {
            $0.status == .running || $0.status == .paused
        }

        guard !runningInstances.isEmpty else {
            return .terminateNow
        }

        Task { @MainActor in
            for instance in runningInstances {
                do {
                    try await viewModel.virtualizationService.save(instance)
                    try viewModel.storageService.saveConfiguration(
                        instance.configuration,
                        to: instance.bundleURL
                    )
                } catch {
                    // Best-effort save; force-stop if save fails
                    try? viewModel.virtualizationService.forceStop(instance)
                }
            }
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    // MARK: - Menu Actions

    @IBAction func newVM(_ sender: Any?) {
        viewModel.showCreationWizard = true
    }
}
