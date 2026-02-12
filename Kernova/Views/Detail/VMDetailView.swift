import SwiftUI

/// Detail area that switches between settings (when stopped) and console (when running).
struct VMDetailView: View {
    @Bindable var instance: VMInstance
    @Bindable var viewModel: VMLibraryViewModel

    var body: some View {
        Group {
            switch instance.status {
            case .stopped, .error:
                VMSettingsView(instance: instance, viewModel: viewModel)

            case .installing:
                if let installState = instance.installState {
                    MacOSInstallProgressView(installState: installState)
                } else {
                    transitionView
                }

            case .running, .paused:
                VMConsoleView(instance: instance, viewModel: viewModel)

            default:
                transitionView
            }
        }
        .navigationTitle(instance.name)
        .alert(
            "Delete Virtual Machine",
            isPresented: $viewModel.showDeleteConfirmation,
            presenting: viewModel.instanceToDelete
        ) { vm in
            Button("Move to Trash", role: .destructive) {
                viewModel.deleteConfirmed(vm)
            }
            Button("Cancel", role: .cancel) {}
        } message: { vm in
            Text("\"\(vm.name)\" will be moved to the Trash. You can restore it using Finder's Put Back command. Empty the Trash to permanently delete the VM and reclaim disk space.")
        }
    }

    private var transitionView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(instance.status.displayName)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
