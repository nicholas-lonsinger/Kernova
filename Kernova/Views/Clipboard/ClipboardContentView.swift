import SwiftUI

/// SwiftUI content view for the per-VM clipboard sharing window.
///
/// A single editable text area serves as a unified clipboard buffer:
/// - When the guest copies text, it appears here automatically
/// - The user can edit or paste new text freely
/// - When the window loses focus, any changes are announced to the guest via
///   `CLIPBOARD_GRAB` — the guest requests the data on its next paste
struct ClipboardContentView: View {

    let instance: VMInstance

    private var service: SpiceClipboardService? {
        instance.clipboardService
    }

    private var clipboardTextBinding: Binding<String> {
        Binding(
            get: { service?.clipboardText ?? "" },
            set: { service?.clipboardText = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: clipboardTextBinding)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
            Divider()
            statusBar
        }
        .background(.background.secondary)
        .frame(minWidth: 320, idealWidth: 480, minHeight: 200, idealHeight: 300)
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(service?.isConnected ?? false ? .green : .secondary)
                .frame(width: 8, height: 8)

            Text(service?.isConnected ?? false ? "Connected" : "Waiting for guest agent")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.background)
    }
}
