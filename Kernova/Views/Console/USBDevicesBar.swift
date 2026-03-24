import SwiftUI
import UniformTypeIdentifiers

/// Compact bar at the bottom of the console view for managing USB devices on a running VM.
struct USBDevicesBar: View {
    @Bindable var instance: VMInstance
    @Bindable var viewModel: VMLibraryViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cable.connector")
                .foregroundStyle(.secondary)

            if instance.attachedUSBDevices.isEmpty {
                Text("No USB devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(instance.attachedUSBDevices) { device in
                    HStack(spacing: 4) {
                        Image(systemName: device.readOnly ? "lock.fill" : "externaldrive.fill")
                            .font(.caption2)
                        Text(device.displayName)
                            .font(.caption)
                            .lineLimit(1)
                        Button {
                            viewModel.detachUSBDevice(device, from: instance)
                        } label: {
                            Image(systemName: "eject.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .help("Eject \(device.displayName)")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Spacer()

            Button {
                browseAndAttach()
            } label: {
                Label("Attach USB Image", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func browseAndAttach() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = UTType.diskImageTypes
        panel.message = "Select a disk image to attach as USB storage"
        panel.prompt = "Attach"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.attachUSBDevice(diskImagePath: url.path(percentEncoded: false), readOnly: false, to: instance)
    }
}
