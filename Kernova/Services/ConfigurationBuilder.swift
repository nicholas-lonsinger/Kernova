import Foundation
import Virtualization
import os

/// Translates a `VMConfiguration` into a `VZVirtualMachineConfiguration`.
///
/// Supports three boot paths:
/// - **macOS**: `VZMacPlatformConfiguration` + `VZMacOSBootLoader` (Apple Silicon only)
/// - **EFI**: `VZGenericPlatformConfiguration` + `VZEFIBootLoader` (Linux guests)
/// - **Linux Kernel**: `VZGenericPlatformConfiguration` + `VZLinuxBootLoader`
struct ConfigurationBuilder: Sendable {

    private static let logger = Logger(subsystem: "com.kernova.app", category: "ConfigurationBuilder")

    /// Builds a validated `VZVirtualMachineConfiguration` from the given VM configuration and bundle URL.
    func build(from config: VMConfiguration, bundleURL: URL) throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()

        // Resources
        vzConfig.cpuCount = config.cpuCount
        vzConfig.memorySize = config.memorySizeInBytes

        // Platform & boot loader
        switch config.bootMode {
        case .macOS:
            #if arch(arm64)
            try configureMacOSBoot(vzConfig, config: config, bundleURL: bundleURL)
            #else
            throw ConfigurationBuilderError.macOSGuestRequiresAppleSilicon
            #endif

        case .efi:
            try configureEFIBoot(vzConfig, config: config, bundleURL: bundleURL)

        case .linuxKernel:
            try configureLinuxKernelBoot(vzConfig, config: config)
        }

        // Common devices
        try configureStorage(vzConfig, config: config, bundleURL: bundleURL)
        configureNetwork(vzConfig, config: config)
        configureEntropy(vzConfig)
        configureAudio(vzConfig)

        // Validate
        try vzConfig.validate()

        Self.logger.info("Built VZ configuration for '\(config.name)' (\(config.bootMode.displayName))")
        return vzConfig
    }

    // MARK: - macOS Boot

    #if arch(arm64)
    private func configureMacOSBoot(
        _ vzConfig: VZVirtualMachineConfiguration,
        config: VMConfiguration,
        bundleURL: URL
    ) throws {
        let platform = VZMacPlatformConfiguration()

        // Auxiliary storage
        let auxStorageURL = bundleURL.appendingPathComponent("AuxiliaryStorage")
        platform.auxiliaryStorage = try VZMacAuxiliaryStorage(contentsOf: auxStorageURL)

        // Hardware model
        if let modelData = config.hardwareModelData,
           let hardwareModel = VZMacHardwareModel(dataRepresentation: modelData) {
            platform.hardwareModel = hardwareModel
        } else {
            let modelURL = bundleURL.appendingPathComponent("HardwareModel")
            let modelData = try Data(contentsOf: modelURL)
            guard let hardwareModel = VZMacHardwareModel(dataRepresentation: modelData) else {
                throw ConfigurationBuilderError.invalidHardwareModel
            }
            platform.hardwareModel = hardwareModel
        }

        // Machine identifier
        if let idData = config.machineIdentifierData,
           let machineID = VZMacMachineIdentifier(dataRepresentation: idData) {
            platform.machineIdentifier = machineID
        } else {
            let idURL = bundleURL.appendingPathComponent("MachineIdentifier")
            let idData = try Data(contentsOf: idURL)
            guard let machineID = VZMacMachineIdentifier(dataRepresentation: idData) else {
                throw ConfigurationBuilderError.invalidMachineIdentifier
            }
            platform.machineIdentifier = machineID
        }

        vzConfig.platform = platform
        vzConfig.bootLoader = VZMacOSBootLoader()

        // macOS-specific devices
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: config.displayWidth,
                heightInPixels: config.displayHeight,
                pixelsPerInch: config.displayPPI
            )
        ]
        vzConfig.graphicsDevices = [graphics]

        vzConfig.pointingDevices = [VZMacTrackpadConfiguration()]
        vzConfig.keyboards = [VZMacKeyboardConfiguration()]
    }
    #endif

    // MARK: - EFI Boot

    private func configureEFIBoot(
        _ vzConfig: VZVirtualMachineConfiguration,
        config: VMConfiguration,
        bundleURL: URL
    ) throws {
        vzConfig.platform = VZGenericPlatformConfiguration()

        let efiVariableStoreURL = bundleURL.appendingPathComponent("EFIVariableStore")
        let variableStore: VZEFIVariableStore
        if FileManager.default.fileExists(atPath: efiVariableStoreURL.path) {
            variableStore = try VZEFIVariableStore(contentsOf: efiVariableStoreURL)
        } else {
            variableStore = try VZEFIVariableStore(creatingVariableStoreAt: efiVariableStoreURL)
        }

        let bootLoader = VZEFIBootLoader()
        bootLoader.variableStore = variableStore
        vzConfig.bootLoader = bootLoader

        // Linux graphics
        let graphics = VZVirtioGraphicsDeviceConfiguration()
        graphics.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(
                widthInPixels: config.displayWidth,
                heightInPixels: config.displayHeight
            )
        ]
        vzConfig.graphicsDevices = [graphics]

        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
    }

    // MARK: - Linux Kernel Boot

    private func configureLinuxKernelBoot(
        _ vzConfig: VZVirtualMachineConfiguration,
        config: VMConfiguration
    ) throws {
        vzConfig.platform = VZGenericPlatformConfiguration()

        guard let kernelPath = config.kernelPath else {
            throw ConfigurationBuilderError.missingKernelPath
        }

        let bootLoader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: kernelPath))
        if let initrdPath = config.initrdPath {
            bootLoader.initialRamdiskURL = URL(fileURLWithPath: initrdPath)
        }
        bootLoader.commandLine = config.kernelCommandLine ?? "console=hvc0"
        vzConfig.bootLoader = bootLoader

        // Linux graphics
        let graphics = VZVirtioGraphicsDeviceConfiguration()
        graphics.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(
                widthInPixels: config.displayWidth,
                heightInPixels: config.displayHeight
            )
        ]
        vzConfig.graphicsDevices = [graphics]

        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
    }

    // MARK: - Common Devices

    private func configureStorage(
        _ vzConfig: VZVirtualMachineConfiguration,
        config: VMConfiguration,
        bundleURL: URL
    ) throws {
        let diskURL = bundleURL.appendingPathComponent("Disk.asif")
        guard FileManager.default.fileExists(atPath: diskURL.path) else {
            throw ConfigurationBuilderError.diskImageNotFound(diskURL)
        }

        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
        let storage = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        vzConfig.storageDevices = [storage]
    }

    private func configureNetwork(_ vzConfig: VZVirtualMachineConfiguration, config: VMConfiguration) {
        guard config.networkEnabled else { return }

        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()

        if let macString = config.macAddress,
           let macAddress = VZMACAddress(string: macString) {
            networkDevice.macAddress = macAddress
        }

        vzConfig.networkDevices = [networkDevice]
    }

    private func configureEntropy(_ vzConfig: VZVirtualMachineConfiguration) {
        vzConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
    }

    private func configureAudio(_ vzConfig: VZVirtualMachineConfiguration) {
        let audioDevice = VZVirtioSoundDeviceConfiguration()

        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()

        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()

        audioDevice.streams = [inputStream, outputStream]
        vzConfig.audioDevices = [audioDevice]
    }
}

// MARK: - Errors

enum ConfigurationBuilderError: LocalizedError {
    case macOSGuestRequiresAppleSilicon
    case invalidHardwareModel
    case invalidMachineIdentifier
    case missingKernelPath
    case diskImageNotFound(URL)

    var errorDescription: String? {
        switch self {
        case .macOSGuestRequiresAppleSilicon:
            "macOS guests can only run on Apple Silicon."
        case .invalidHardwareModel:
            "The stored hardware model data is invalid."
        case .invalidMachineIdentifier:
            "The stored machine identifier data is invalid."
        case .missingKernelPath:
            "A kernel path is required for Linux kernel boot mode."
        case .diskImageNotFound(let url):
            "Disk image not found at \(url.path)."
        }
    }
}
