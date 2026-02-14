import Testing
import Foundation
@testable import Kernova

@Suite("VirtualizationService Tests")
@MainActor
struct VirtualizationServiceTests {

    private let service = VirtualizationService()

    private func makeInstance(status: VMStatus = .stopped) -> VMInstance {
        let config = VMConfiguration(
            name: "Test VM",
            guestOS: .linux,
            bootMode: .efi
        )
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(config.id.uuidString, isDirectory: true)
        return VMInstance(configuration: config, bundleURL: bundleURL, status: status)
    }

    // MARK: - Start Guards

    @Test("start throws when VM is already running")
    func startThrowsWhenRunning() async {
        let instance = makeInstance(status: .running)

        await #expect(throws: VirtualizationError.self) {
            try await service.start(instance)
        }
    }

    @Test("start throws when VM is paused")
    func startThrowsWhenPaused() async {
        let instance = makeInstance(status: .paused)

        await #expect(throws: VirtualizationError.self) {
            try await service.start(instance)
        }
    }

    @Test("start throws when VM is starting")
    func startThrowsWhenStarting() async {
        let instance = makeInstance(status: .starting)

        await #expect(throws: VirtualizationError.self) {
            try await service.start(instance)
        }
    }

    // MARK: - Stop Guards

    @Test("stop throws when VM is stopped")
    func stopThrowsWhenStopped() {
        let instance = makeInstance(status: .stopped)

        #expect(throws: VirtualizationError.self) {
            try service.stop(instance)
        }
    }

    @Test("stop throws when VM is starting")
    func stopThrowsWhenStarting() {
        let instance = makeInstance(status: .starting)

        #expect(throws: VirtualizationError.self) {
            try service.stop(instance)
        }
    }

    // MARK: - Pause Guards

    @Test("pause throws when VM is stopped")
    func pauseThrowsWhenStopped() async {
        let instance = makeInstance(status: .stopped)

        await #expect(throws: VirtualizationError.self) {
            try await service.pause(instance)
        }
    }

    @Test("pause throws when VM is paused")
    func pauseThrowsWhenAlreadyPaused() async {
        let instance = makeInstance(status: .paused)

        await #expect(throws: VirtualizationError.self) {
            try await service.pause(instance)
        }
    }

    // MARK: - Resume Guards

    @Test("resume throws when VM is stopped")
    func resumeThrowsWhenStopped() async {
        let instance = makeInstance(status: .stopped)

        await #expect(throws: VirtualizationError.self) {
            try await service.resume(instance)
        }
    }

    @Test("resume throws when VM is running")
    func resumeThrowsWhenRunning() async {
        let instance = makeInstance(status: .running)

        await #expect(throws: VirtualizationError.self) {
            try await service.resume(instance)
        }
    }

    // MARK: - Save Guards

    @Test("save throws when VM is stopped")
    func saveThrowsWhenStopped() async {
        let instance = makeInstance(status: .stopped)

        await #expect(throws: VirtualizationError.self) {
            try await service.save(instance)
        }
    }

    // MARK: - ForceStop Guards

    @Test("forceStop throws when no virtual machine exists and not cold-paused")
    func forceStopThrowsWhenNoVM() async {
        let instance = makeInstance(status: .running)
        // No virtualMachine assigned, and not cold-paused (status is .running)

        await #expect(throws: VirtualizationError.self) {
            try await service.forceStop(instance)
        }
    }
}
