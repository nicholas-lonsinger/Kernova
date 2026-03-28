import Foundation
import os

/// Discovers and opens the SPICE agent serial device inside a macOS guest VM.
///
/// The host creates a `VZVirtioConsoleDeviceConfiguration` with a port named
/// `com.redhat.spice.0`. Inside the guest this appears as a character device
/// under `/dev/`. This enum scans known candidate paths and opens the first match.
enum SerialPortDiscovery {

    private static let logger = Logger(subsystem: "com.kernova.agent", category: "SerialPortDiscovery")

    /// Known device path patterns for the SPICE agent console port.
    /// The port is configured at index 0 of a `VZVirtioConsoleDeviceConfiguration`.
    private static let candidatePaths = [
        "/dev/cu.virtio-port0",
        "/dev/cu.virtio",
    ]

    /// Discovers and opens the SPICE agent serial device.
    ///
    /// Scans candidate paths, opens the first matching device with `O_RDWR | O_NOCTTY | O_NONBLOCK`,
    /// and returns a `FileHandle` for bidirectional communication.
    ///
    /// - Returns: A `FileHandle` wrapping the opened device, or `nil` if no device was found.
    static func openDevice() -> FileHandle? {
        logAvailableSerialDevices()

        for path in candidatePaths {
            guard FileManager.default.fileExists(atPath: path) else { continue }

            let fd = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
            if fd >= 0 {
                logger.notice("Opened SPICE device at '\(path, privacy: .public)' (fd=\(fd, privacy: .public))")
                return FileHandle(fileDescriptor: fd, closeOnDealloc: true)
            } else {
                logger.warning("Found '\(path, privacy: .public)' but open() failed: \(String(cString: strerror(errno)), privacy: .public)")
            }
        }

        logger.debug("No SPICE serial device found")
        return nil
    }

    /// Logs all `/dev/cu.*` devices at debug level to aid device path discovery during development.
    private static func logAvailableSerialDevices() {
        do {
            let devContents = try FileManager.default.contentsOfDirectory(atPath: "/dev")
            let serialDevices = devContents.filter { $0.hasPrefix("cu.") }.sorted()
            if serialDevices.isEmpty {
                logger.debug("No /dev/cu.* serial devices found")
            } else {
                logger.debug("Available serial devices: \(serialDevices, privacy: .public)")
            }
        } catch {
            logger.debug("Failed to enumerate /dev: \(error.localizedDescription, privacy: .public)")
        }
    }
}
