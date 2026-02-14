import Foundation
@testable import Kernova

/// No-op mock for `MacOSInstallProviding`.
@MainActor
final class MockMacOSInstallService: MacOSInstallProviding {

    var installCallCount = 0

    #if arch(arm64)
    func install(
        into instance: VMInstance,
        restoreImageURL: URL,
        progressHandler: @MainActor @Sendable @escaping (Double) -> Void
    ) async throws {
        installCallCount += 1
        instance.resetToStopped()
    }
    #endif
}
