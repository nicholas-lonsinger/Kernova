import SwiftUI

/// A single row in the sidebar representing a virtual machine.
struct VMRowView: View {
    let instance: VMInstance

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(instance.name)
                    .font(.body)
                    .lineLimit(1)

                Text(instance.configuration.guestOS.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(instance.status.statusColor)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch instance.configuration.guestOS {
        case .macOS: "macwindow"
        case .linux: "terminal"
        }
    }
}
