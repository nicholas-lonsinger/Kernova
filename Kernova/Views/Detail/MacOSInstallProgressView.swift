import SwiftUI

/// Two-step progress UI for macOS installation (download → install).
///
/// When the installation includes a download step (remote IPSW), the view shows
/// numbered step indicators with connector lines. For local IPSW installations,
/// only the install progress bar is shown without step numbering.
struct MacOSInstallProgressView: View {
    let installState: MacOSInstallState

    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: NSImage.computerName) ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)

            Text("Installing macOS")
                .font(.title2)
                .fontWeight(.semibold)

            if installState.hasDownloadStep {
                twoStepIndicator
            }

            activeProgressBar

            activeDetailText
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Two-Step Indicator

    private var twoStepIndicator: some View {
        VStack(spacing: 0) {
            stepRow(number: 1, label: "Download", state: downloadStepState)
            connectorLine
            stepRow(number: 2, label: "Install", state: installStepState)
        }
    }

    private var downloadStepState: StepState {
        if installState.downloadCompleted {
            return .completed
        }
        if case .downloading = installState.currentPhase {
            return .active
        }
        return .pending
    }

    private var installStepState: StepState {
        if case .installing = installState.currentPhase {
            return installState.downloadCompleted ? .active : .pending
        }
        return .pending
    }

    private func stepRow(number: Int, label: String, state: StepState) -> some View {
        HStack(spacing: 10) {
            stepCircle(number: number, state: state)

            Text(label)
                .font(.body)
                .fontWeight(state == .active ? .medium : .regular)
                .foregroundStyle(state == .pending ? .secondary : .primary)

            Spacer()

            switch state {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            case .active:
                ProgressView()
                    .controlSize(.small)
            case .pending:
                EmptyView()
            }
        }
    }

    private func stepCircle(number: Int, state: StepState) -> some View {
        ZStack {
            Circle()
                .fill(state == .pending ? .clear : Color.accentColor)
                .stroke(state == .pending ? Color.secondary : Color.clear, lineWidth: 1.5)
                .frame(width: 24, height: 24)

            switch state {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            case .active, .pending:
                Text("\(number)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(state == .pending ? .secondary : .white)
            }
        }
    }

    private var connectorLine: some View {
        HStack {
            Rectangle()
                .fill(installState.downloadCompleted ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 11) // Center under 24pt circle
            Spacer()
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var activeProgressBar: some View {
        switch installState.currentPhase {
        case .downloading(let progress, _, _):
            ProgressView(value: progress)
                .progressViewStyle(.linear)

        case .installing(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
    }

    // MARK: - Detail Text

    @ViewBuilder
    private var activeDetailText: some View {
        switch installState.currentPhase {
        case .downloading(let progress, let bytesWritten, let totalBytes):
            let written = DataFormatters.formatBytes(UInt64(bytesWritten))
            let total = DataFormatters.formatBytes(UInt64(totalBytes))
            Text("Downloading: \(written) / \(total) — \(Int(progress * 100))%")

        case .installing(let progress):
            Text("Installing macOS: \(Int(progress * 100))%")
        }
    }
}

// MARK: - Step State

private enum StepState {
    case pending
    case active
    case completed
}
