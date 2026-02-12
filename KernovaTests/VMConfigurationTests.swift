import Testing
import Foundation
@testable import Kernova

@Suite("VMConfiguration Tests")
struct VMConfigurationTests {

    @Test("Default macOS configuration has correct defaults")
    func defaultMacOSConfig() {
        let config = VMConfiguration(
            name: "Test macOS VM",
            guestOS: .macOS,
            bootMode: .macOS
        )

        #expect(config.name == "Test macOS VM")
        #expect(config.guestOS == .macOS)
        #expect(config.bootMode == .macOS)
        #expect(config.cpuCount == VMGuestOS.macOS.defaultCPUCount)
        #expect(config.memorySizeInGB == VMGuestOS.macOS.defaultMemoryInGB)
        #expect(config.diskSizeInGB == VMGuestOS.macOS.defaultDiskSizeInGB)
        #expect(config.networkEnabled == true)
        #expect(config.displayWidth == 1920)
        #expect(config.displayHeight == 1200)
        #expect(config.displayPPI == 144)
    }

    @Test("Default Linux configuration has correct defaults")
    func defaultLinuxConfig() {
        let config = VMConfiguration(
            name: "Test Linux VM",
            guestOS: .linux,
            bootMode: .efi
        )

        #expect(config.guestOS == .linux)
        #expect(config.bootMode == .efi)
        #expect(config.cpuCount == VMGuestOS.linux.defaultCPUCount)
        #expect(config.memorySizeInGB == VMGuestOS.linux.defaultMemoryInGB)
        #expect(config.diskSizeInGB == VMGuestOS.linux.defaultDiskSizeInGB)
    }

    @Test("Configuration encodes and decodes via JSON")
    func codableRoundTrip() throws {
        let original = VMConfiguration(
            name: "Roundtrip VM",
            guestOS: .macOS,
            bootMode: .macOS,
            cpuCount: 8,
            memorySizeInGB: 16,
            diskSizeInGB: 200,
            notes: "Test notes"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(VMConfiguration.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.guestOS == original.guestOS)
        #expect(decoded.bootMode == original.bootMode)
        #expect(decoded.cpuCount == original.cpuCount)
        #expect(decoded.memorySizeInGB == original.memorySizeInGB)
        #expect(decoded.diskSizeInGB == original.diskSizeInGB)
        #expect(decoded.notes == original.notes)
        #expect(decoded.networkEnabled == original.networkEnabled)
    }

    @Test("Memory size in bytes is calculated correctly")
    func memorySizeInBytes() {
        let config = VMConfiguration(
            name: "Test",
            guestOS: .linux,
            bootMode: .efi,
            memorySizeInGB: 4
        )

        #expect(config.memorySizeInBytes == 4 * 1024 * 1024 * 1024)
    }

    @Test("Configuration preserves macOS-specific fields")
    func macOSSpecificFields() throws {
        let hardwareData = Data([0x01, 0x02, 0x03])
        let machineData = Data([0x04, 0x05, 0x06])

        let config = VMConfiguration(
            name: "macOS VM",
            guestOS: .macOS,
            bootMode: .macOS,
            hardwareModelData: hardwareData,
            machineIdentifierData: machineData
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let decoded = try JSONDecoder().decode(VMConfiguration.self, from: data)

        #expect(decoded.hardwareModelData == hardwareData)
        #expect(decoded.machineIdentifierData == machineData)
    }

    @Test("Configuration preserves Linux kernel fields")
    func linuxKernelFields() throws {
        let config = VMConfiguration(
            name: "Linux VM",
            guestOS: .linux,
            bootMode: .linuxKernel,
            kernelPath: "/path/to/vmlinuz",
            initrdPath: "/path/to/initrd",
            kernelCommandLine: "console=hvc0 root=/dev/vda1"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let decoded = try JSONDecoder().decode(VMConfiguration.self, from: data)

        #expect(decoded.kernelPath == "/path/to/vmlinuz")
        #expect(decoded.initrdPath == "/path/to/initrd")
        #expect(decoded.kernelCommandLine == "console=hvc0 root=/dev/vda1")
    }

    @Test("Generic machine identifier data round-trips through JSON")
    func genericMachineIdentifierRoundTrip() throws {
        let identifierData = Data([0xDE, 0xAD, 0xBE, 0xEF])

        let config = VMConfiguration(
            name: "EFI Linux VM",
            guestOS: .linux,
            bootMode: .efi,
            genericMachineIdentifierData: identifierData
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let decoded = try JSONDecoder().decode(VMConfiguration.self, from: data)

        #expect(decoded.genericMachineIdentifierData == identifierData)
    }

    @Test("Backward compatibility: decoding JSON without genericMachineIdentifierData")
    func backwardCompatibilityGenericMachineIdentifier() throws {
        // Simulate a config.json from before the genericMachineIdentifierData field existed
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "name": "Old VM",
            "guestOS": "linux",
            "bootMode": "efi",
            "cpuCount": 4,
            "memorySizeInGB": 8,
            "diskSizeInGB": 64,
            "displayWidth": 1920,
            "displayHeight": 1200,
            "displayPPI": 144,
            "networkEnabled": true,
            "createdAt": "2025-01-01T00:00:00Z",
            "notes": ""
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let config = try decoder.decode(VMConfiguration.self, from: Data(json.utf8))

        #expect(config.name == "Old VM")
        #expect(config.genericMachineIdentifierData == nil)
        #expect(config.macAddress == nil)
    }

    @Test("VMStatus.canStart returns true for stopped and error states")
    func canStartStates() {
        #expect(VMStatus.stopped.canStart == true)
        #expect(VMStatus.error.canStart == true)
        #expect(VMStatus.running.canStart == false)
        #expect(VMStatus.paused.canStart == false)
        #expect(VMStatus.starting.canStart == false)
    }

    @Test("VMStatus.canEditSettings returns true for stopped and error states")
    func canEditSettingsStates() {
        #expect(VMStatus.stopped.canEditSettings == true)
        #expect(VMStatus.error.canEditSettings == true)
        #expect(VMStatus.running.canEditSettings == false)
        #expect(VMStatus.paused.canEditSettings == false)
    }
}
