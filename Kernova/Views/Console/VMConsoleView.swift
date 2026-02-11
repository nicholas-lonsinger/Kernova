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
    }
}
