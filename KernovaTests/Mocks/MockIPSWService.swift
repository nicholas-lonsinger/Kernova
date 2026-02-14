import Foundation
@testable import Kernova

/// No-op mock for `IPSWProviding`.
final class MockIPSWService: IPSWProviding, @unchecked Sendable {

    var fetchCallCount = 0
    var downloadCallCount = 0

    #if arch(arm64)
    func fetchLatestRestoreImageURL() async throws -> URL {
        fetchCallCount += 1
        return URL(string: "https://example.com/restore.ipsw")!
    }

    func downloadRestoreImage(
        from remoteURL: URL,
        to destinationURL: URL,
        progressHandler: @MainActor @Sendable @escaping (Double, Int64, Int64) -> Void
    ) async throws {
        downloadCallCount += 1
    }
    #endif
}
