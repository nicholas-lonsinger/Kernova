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
                installProgressView

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
            Button("Delete", role: .destructive) {
                viewModel.deleteConfirmed(vm)
            }
            Button("Cancel", role: .cancel) {}
        } message: { vm in
            Text("Are you sure you want to delete \"\(vm.name)\"? This will permanently remove the VM and all its data.")
        }
    }

    private var installProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: instance.installProgress) {
                Text("Installing macOS...")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(instance.installProgress * 100))%")
            }
            .progressViewStyle(.linear)
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
