import Foundation

/// Abstraction for disk image creation and inspection.
protocol DiskImageProviding: Sendable {
    func createDiskImage(at url: URL, sizeInGB: Int) async throws
    func physicalSize(of url: URL) throws -> UInt64
}
