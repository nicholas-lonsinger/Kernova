import Foundation
import Virtualization
import os

/// Fetches and downloads macOS restore images (IPSWs) for macOS guest installation.
struct IPSWService: Sendable {

    private static let logger = Logger(subsystem: "com.kernova.app", category: "IPSWService")

    /// Fetches metadata about the latest supported macOS restore image.
    ///
    /// - Returns: The `VZMacOSRestoreImage` for the latest compatible macOS version.
    #if arch(arm64)
    func fetchLatestSupportedImage() async throws -> VZMacOSRestoreImage {
        Self.logger.info("Fetching latest supported macOS restore image...")
        return try await VZMacOSRestoreImage.latestSupported
    }

    /// Downloads a macOS restore image to the specified URL.
    ///
    /// - Parameters:
    ///   - restoreImage: The restore image metadata to download.
    ///   - destinationURL: The local file URL to save the IPSW to.
    ///   - progressHandler: Called periodically with (fraction, totalBytesWritten, totalBytesExpectedToWrite).
    func downloadRestoreImage(
        _ restoreImage: VZMacOSRestoreImage,
        to destinationURL: URL,
        progressHandler: @MainActor @Sendable @escaping (Double, Int64, Int64) -> Void
    ) async throws {
        let downloadURL = restoreImage.url

        Self.logger.info("Downloading restore image from \(downloadURL)")

        let tempURL: URL = try await withCheckedThrowingContinuation { continuation in
            let delegate = SessionDelegate(progressHandler: progressHandler, continuation: continuation)
            let session = URLSession(
                configuration: .default,
                delegate: delegate,
                delegateQueue: nil
            )
            delegate.session = session
            session.downloadTask(with: downloadURL).resume()
        }

        // Move the downloaded file to the destination
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        Self.logger.info("Restore image downloaded to \(destinationURL.lastPathComponent)")
    }

    /// Loads a restore image from a local IPSW file.
    func loadRestoreImage(from url: URL) async throws -> VZMacOSRestoreImage {
        try await VZMacOSRestoreImage.image(from: url)
    }
    #endif
}

// MARK: - Session Delegate

/// Session-level delegate that reliably receives download progress callbacks.
private final class SessionDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let progressHandler: @MainActor @Sendable (Double, Int64, Int64) -> Void
    private var continuation: CheckedContinuation<URL, any Error>?
    var session: URLSession?

    init(
        progressHandler: @MainActor @Sendable @escaping (Double, Int64, Int64) -> Void,
        continuation: CheckedContinuation<URL, any Error>
    ) {
        self.progressHandler = progressHandler
        self.continuation = continuation
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let handler = progressHandler
        Task { @MainActor in
            handler(fraction, totalBytesWritten, totalBytesExpectedToWrite)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Move file to a temp location that won't be cleaned up when the session invalidates
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".ipsw")
        do {
            try FileManager.default.moveItem(at: location, to: tempURL)
            continuation?.resume(returning: tempURL)
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
        self.session?.finishTasksAndInvalidate()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
            self.session?.finishTasksAndInvalidate()
        }
    }
}

// MARK: - Errors

enum IPSWError: LocalizedError {
    case noDownloadURL
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .noDownloadURL:
            "The restore image does not have a download URL."
        case .downloadFailed(let message):
            "Failed to download restore image: \(message)"
        }
    }
}
