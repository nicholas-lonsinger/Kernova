import SwiftUI

/// Console view with the VM display and lifecycle control toolbar.
struct VMConsoleView: View {
    @Bindable var instance: VMInstance
    @Bindable var viewModel: VMLibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            // VM Display
            if let vm = instance.virtualMachine {
                VMDisplayView(virtualMachine: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Display",
                    systemImage: "display",
                    description: Text("The virtual machine display is not available.")
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                controlButtons
            }
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        if instance.status.canPause {
            Button {
                Task { await viewModel.pause(instance) }
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .help("Pause the virtual machine")
        }

        if instance.status.canResume {
            Button {
                Task { await viewModel.resume(instance) }
            } label: {
                Label("Resume", systemImage: "play.fill")
            }
            .help("Resume the virtual machine")
        }

        if instance.status.canStop {
            Button {
                viewModel.stop(instance)
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .help("Stop the virtual machine")
        }

        if instance.status.canSave {
            Button {
                Task { await viewModel.save(instance) }
            } label: {
                Label("Save State", systemImage: "square.and.arrow.down")
            }
            .help("Save the virtual machine state to disk")
        }
    }
}
