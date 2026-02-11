import Foundation

/// Formatting utilities for display values.
enum DataFormatters {

    private nonisolated(unsafe) static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    /// Formats a byte count into a human-readable string (e.g., "4.2 GB").
    static func formatBytes(_ bytes: UInt64) -> String {
        byteFormatter.string(fromByteCount: Int64(bytes))
    }

    /// Formats a CPU count for display.
    static func formatCPUCount(_ count: Int) -> String {
        count == 1 ? "1 core" : "\(count) cores"
    }

    /// Formats a duration in seconds into a human-readable string.
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "\(Int(seconds))s"
    }
}
