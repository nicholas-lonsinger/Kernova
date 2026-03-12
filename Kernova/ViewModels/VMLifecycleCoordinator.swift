import Foundation
import os

/// Coordinates VM lifecycle operations and macOS installation.
///
/// Groups all state-changing VM operations into a single type, keeping
/// `VMLibraryViewModel` focused on list management and UI state.
/// All methods re-throw errors — the caller is responsible for presentation.
///
/// **Operation serialization:** Each VM can have at most one in-flight lifecycle
/// operation at a time. Concurrent requests for the same VM are rejected with
/// ``VMLifecycleCoordinator/Error/operationInProgress``. Since the coordinator
/// is `@MainActor`, a simple `Set<UUID>` is sufficient — no locks required.
///
/// **Interruption-aware:** `stop` and `forceStop` bypass serialization so users
/// can always interrupt a hung or in-progress operation. On success they also
/// clear the active-operation flag for that VM.
@MainActor
final class VMLifecycleCoordinator {

    private static let logger = Logger(subsystem: "com.kernova.app", category: "VMLifecycleCoordinator")

    let virtualizationService: any VirtualizationProviding
    let installService: any MacOSInstallProviding
    let ipswService: any IPSWProviding

    /// Tracks VMs that currently have a lifecycle operation in flight.
    private var activeOperations: Set<UUID> = []

    init(
        virtualizationService: any VirtualizationProviding,
        installService: any MacOSInstallProviding,
        ipswService: any IPSWProviding
    ) {
        self.virtualizationService = virtualizationService
        self.installService = installService
        self.ipswService = ipswService
    }

    // MARK: - Operation Serialization

    /// Returns `true` if the given VM currently has a lifecycle operation in progress.
    func hasActiveOperation(for instanceID: UUID) -> Bool {
        activeOperations.contains(instanceID)
    }

    /// Executes `body` only if no other operation is already in flight for this VM.
    /// Inserts the VM's ID before running and removes it on completion (success or failure).
    private func serialized<T>(
        _ instance: VMInstance,
        action: String,
        body: () async throws -> T
    ) async throws -> T {
        guard !activeOperations.contains(instance.id) else {
            Self.logger.warning("Rejected \(action) for '\(instance.name)': operation already in progress")
            throw Error.operationInProgress(vmName: instance.name)
        }

        activeOperations.insert(instance.id)
        defer { activeOperations.remove(instance.id) }

        Self.logger.debug("Acquired operation lock for '\(instance.name)' (action: \(action))")
        return try await body()
    }

    // MARK: - Lifecycle

    func start(_ instance: VMInstance) async throws {
        try await serialized(instance, action: "start") {
            try await virtualizationService.start(instance)
        }
    }

    /// Requests a graceful stop. Bypasses serialization so users can always
    /// interrupt an in-progress operation (e.g. a hung start). On success,
    /// clears the active-operation flag for this VM.
    func stop(_ instance: VMInstance) throws {
        try virtualizationService.stop(instance)
        activeOperations.remove(instance.id)
    }

    /// Immediately terminates the VM. Bypasses serialization so users can
    /// always force-kill, even during another in-flight operation. On success,
    /// clears the active-operation flag for this VM.
    func forceStop(_ instance: VMInstance) async throws {
        try await virtualizationService.forceStop(instance)
        activeOperations.remove(instance.id)
    }

    func pause(_ instance: VMInstance) async throws {
        try await serialized(instance, action: "pause") {
            try await virtualizationService.pause(instance)
        }
    }

    func resume(_ instance: VMInstance) async throws {
        try await serialized(instance, action: "resume") {
            try await virtualizationService.resume(instance)
        }
    }

    func save(_ instance: VMInstance) async throws {
        try await serialized(instance, action: "save") {
            try await virtualizationService.save(instance)
        }
    }

    // MARK: - macOS Installation

    #if arch(arm64)
    func installMacOS(
        on instance: VMInstance,
        wizard: VMCreationViewModel,
        storageService: any VMStorageProviding
    ) async throws {
        try await serialized(instance, action: "installMacOS") {
            Self.logger.debug("installMacOS: entering for '\(instance.name)', source=\(String(describing: wizard.ipswSource))")
            do {
                let ipswURL: URL

                switch wizard.ipswSource {
                case .downloadLatest:
                    guard let downloadPath = wizard.ipswDownloadPath else {
                        throw IPSWError.noDownloadURL
                    }
                    let downloadDestination = URL(fileURLWithPath: downloadPath)

                    // Set up two-step install state before changing status
                    instance.installState = MacOSInstallState(
                        hasDownloadStep: true,
                        currentPhase: .downloading(progress: 0, bytesWritten: 0, totalBytes: 0)
                    )
                    instance.status = .installing

                    // Download the latest IPSW to user-chosen location
                    let remoteURL = try await ipswService.fetchLatestRestoreImageURL()
                    try await ipswService.downloadRestoreImage(
                        from: remoteURL,
                        to: downloadDestination
                    ) { progress, bytesWritten, totalBytes in
                        instance.installState?.currentPhase = .downloading(
                            progress: progress,
                            bytesWritten: bytesWritten,
                            totalBytes: totalBytes
                        )
                    }

                    // Mark download complete, transition to install phase
                    instance.installState?.downloadCompleted = true
                    instance.installState?.currentPhase = .installing(progress: 0)
                    ipswURL = downloadDestination

                case .localFile:
                    guard let path = wizard.ipswPath else {
                        throw IPSWError.noDownloadURL
                    }
                    ipswURL = URL(fileURLWithPath: path)

                    // Local file: single-step install (no download)
                    instance.installState = MacOSInstallState(
                        hasDownloadStep: false,
                        currentPhase: .installing(progress: 0)
                    )
                    instance.status = .installing
                }

                // Run macOS installation
                try await installService.install(
                    into: instance,
                    restoreImageURL: ipswURL
                ) { @MainActor progress in
                    instance.installState?.currentPhase = .installing(progress: progress)
                }
            } catch is CancellationError {
                Self.logger.info("macOS installation cancelled for '\(instance.name)'")
            } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                Self.logger.info("IPSW download cancelled for '\(instance.name)'")
            } catch {
                instance.status = .error
                instance.errorMessage = error.localizedDescription
                throw error
            }

            instance.installTask = nil
        }
    }
    #endif
}

// MARK: - VMLifecycleCoordinator.Error

extension VMLifecycleCoordinator {

    enum Error: LocalizedError {
        case operationInProgress(vmName: String)

        var errorDescription: String? {
            switch self {
            case .operationInProgress(let vmName):
                "An operation is already in progress for '\(vmName)'. Please wait for it to complete."
            }
        }
    }
}
