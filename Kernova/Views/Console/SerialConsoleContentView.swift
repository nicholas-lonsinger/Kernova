import SwiftUI

/// SwiftUI view composing the serial terminal and a status bar.
struct SerialConsoleContentView: View {
    @Bindable var instance: VMInstance

    var body: some View {
        VStack(spacing: 0) {
            SerialTerminalView(instance: instance)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Status bar
            HStack {
                Circle()
                    .fill(isConnected ? .green : .secondary)
                    .frame(width: 8, height: 8)

                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(instance.serialOutputText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.bar)
        }
    }

    private var isConnected: Bool {
        instance.status == .running || instance.status == .paused
    }
}
