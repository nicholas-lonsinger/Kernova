import Foundation
import Virtualization
import os

/// Manages macOS guest installation using `VZMacOSInstaller`.
///
/// Handles the full installation pipeline:
/// 1. Load restore image and extract hardware model
/// 2. Create platform configuration (auxiliary storage, hardware model, machine identifier)
/// 3. Build VZ configuration and create the virtual machine
/// 4. Run the installer with progress tracking via KVO
@MainActor
final class MacOSInstallService {

    private static let logger = Logger(subsystem: "com.kernova.app", category: "MacOSInstallService")

    private let configBuilder = ConfigurationBuilder()
    private let storageService = VMStorageService()
    private var progressObservation: NSKeyValueObservation?

    // MARK: - Installation

    #if arch(arm64)
    /// Installs macOS from a restore image into the given VM instance.
    ///
    /// - Parameters:
    ///   - instance: The VM instance to install into.
    ///   - restoreImageURL: The local URL of the IPSW file.
    ///   - progressHandler: Called with installation progress (0.0–1.0).
    func install(
        into instance: VMInstance,
        restoreImageURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        instance.status = .installing

        Self.logger.info("Starting macOS installation for '\(instance.name)'")

        // 1. Load restore image
        let restoreImage = try await loadRestoreImage(from: restoreImageURL)

        guard let supportedConfig = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw MacOSInstallError.unsupportedRestoreImage
        }

        guard supportedConfig.hardwareModel.isSupported else {
            throw MacOSInstallError.unsupportedHardwareModel
        }

        // 2. Set up platform configuration
        try setupPlatformFiles(
            for: instance,
            hardwareModel: supportedConfig.hardwareModel
        )

        // 3. Update the VM configuration with hardware model data
        instance.configuration.hardwareModelData = supportedConfig.hardwareModel.dataRepresentation

        let machineIDURL = instance.machineIdentifierURL
        let machineIDData = try Data(contentsOf: machineIDURL)
        instance.configuration.machineIdentifierData = machineIDData

        try storageService.saveConfiguration(instance.configuration, to: instance.bundleURL)

        // 4. Build VZ configuration and create VM
        let vzConfig = try configBuilder.build(
            from: instance.configuration,
            bundleURL: instance.bundleURL
        )

        let vm = VZVirtualMachine(configuration: vzConfig)
        instance.virtualMachine = vm
        instance.setupDelegate()

        // 5. Run installer with progress tracking
        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: restoreImageURL)

        // Observe progress via KVO
        progressObservation = installer.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            let fraction = progress.fractionCompleted
            Task { @MainActor in
                progressHandler(fraction)
                instance.installProgress = fraction
            }
        }

        Self.logger.info("Running macOS installer...")
        try await installer.install()

        progressObservation?.invalidate()
        progressObservation = nil

        instance.status = .stopped
        instance.virtualMachine = nil
        instance.installProgress = 1.0

        Self.logger.info("macOS installation completed for '\(instance.name)'")
    }

    // MARK: - Platform Setup

    /// Creates the auxiliary storage, hardware model, and machine identifier files.
    private func setupPlatformFiles(
        for instance: VMInstance,
        hardwareModel: VZMacHardwareModel
    ) throws {
        // Write hardware model
        try hardwareModel.dataRepresentation.write(to: instance.hardwareModelURL)

        // Create machine identifier
        let machineIdentifier = VZMacMachineIdentifier()
        try machineIdentifier.dataRepresentation.write(to: instance.machineIdentifierURL)

        // Create auxiliary storage
        _ = try VZMacAuxiliaryStorage(
            creatingStorageAt: instance.auxiliaryStorageURL,
            hardwareModel: hardwareModel
        )

        Self.logger.info("Created platform files for '\(instance.name)'")
    }

    // MARK: - Helpers

    private func loadRestoreImage(from url: URL) async throws -> VZMacOSRestoreImage {
        try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.load(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }
    #endif
}

// MARK: - Errors

enum MacOSInstallError: LocalizedError {
    case unsupportedRestoreImage
    case unsupportedHardwareModel

    var errorDescription: String? {
        switch self {
        case .unsupportedRestoreImage:
            "The restore image does not contain a supported macOS configuration."
        case .unsupportedHardwareModel:
            "The hardware model in the restore image is not supported on this machine."
        }
    }
}
