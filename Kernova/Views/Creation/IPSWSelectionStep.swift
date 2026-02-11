import SwiftUI

/// Step 2 (macOS): Choose an IPSW restore image source.
struct IPSWSelectionStep: View {
    @Bindable var creationVM: VMCreationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("macOS Restore Image")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose how to obtain the macOS restore image (IPSW) for installation.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                sourceButton(
                    title: "Download Latest",
                    description: "Download the latest compatible macOS restore image from Apple.",
                    icon: "arrow.down.circle",
                    isSelected: creationVM.ipswSource == .downloadLatest
                ) {
                    creationVM.ipswSource = .downloadLatest
                    creationVM.ipswPath = nil
                }

                sourceButton(
                    title: "Choose Local File",
                    description: "Select an IPSW file already on your Mac.",
                    icon: "folder",
                    isSelected: creationVM.ipswSource == .localFile
                ) {
                    creationVM.ipswSource = .localFile
                    selectIPSWFile()
                }
            }

            if creationVM.ipswSource == .localFile, let path = creationVM.ipswPath {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.secondary)
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func sourceButton(
        title: String,
        description: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func selectIPSWFile() {
        let panel = NSOpenPanel()
        panel.title = "Select macOS Restore Image"
        panel.allowedContentTypes = [.init(filenameExtension: "ipsw")!]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            creationVM.ipswPath = url.path
        }
    }
}
