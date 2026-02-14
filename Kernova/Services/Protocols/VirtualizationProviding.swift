import Foundation

/// Abstraction for VM lifecycle operations (start, stop, pause, resume, save, restore).
@MainActor
protocol VirtualizationProviding: Sendable {
    func start(_ instance: VMInstance) async throws
    func stop(_ instance: VMInstance) throws
    func forceStop(_ instance: VMInstance) async throws
    func pause(_ instance: VMInstance) async throws
    func resume(_ instance: VMInstance) async throws
    func save(_ instance: VMInstance) async throws
    func restore(_ instance: VMInstance) async throws
}
