import SwiftUI

/// Root view using `NavigationSplitView` with a sidebar listing VMs and a detail area.
struct ContentView: View {
    @Bindable var viewModel: VMLibraryViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            if let selected = viewModel.selectedInstance {
                VMDetailView(instance: selected, viewModel: viewModel)
            } else {
                ContentUnavailableView {
                    Label("No Virtual Machine Selected", systemImage: "desktopcomputer")
                } description: {
                    Text("Select a virtual machine from the sidebar or create a new one.")
                } actions: {
                    Button("New Virtual Machine") {
                        viewModel.showCreationWizard = true
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreationWizard) {
            VMCreationWizardView(viewModel: viewModel)
        }
        .alert(
            "Error",
            isPresented: $viewModel.showError,
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}
