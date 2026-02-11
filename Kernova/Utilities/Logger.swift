import os

extension Logger {

    /// Shared logger for general Kernova operations.
    static let kernova = Logger(subsystem: "com.kernova.app", category: "General")

    /// Logger for virtualization operations.
    static let virtualization = Logger(subsystem: "com.kernova.app", category: "Virtualization")

    /// Logger for storage operations.
    static let storage = Logger(subsystem: "com.kernova.app", category: "Storage")
}
