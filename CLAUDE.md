# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

This is an Xcode project (not Swift Package Manager). Build and test via `xcodebuild`:

```bash
# Build
xcodebuild -project Kernova.xcodeproj -scheme Kernova -destination 'platform=macOS' build

# Run tests
xcodebuild -project Kernova.xcodeproj -scheme Kernova -destination 'platform=macOS' test

# Run a single test suite
xcodebuild -project Kernova.xcodeproj -scheme Kernova -destination 'platform=macOS' test -only-testing:KernovaTests/VMConfigurationTests
```

Requires **macOS 26 (Tahoe)**, **Xcode 26**, **Swift 6**, and **Apple Silicon** (for macOS guest support). The app uses the `com.apple.security.virtualization` entitlement.

## Architecture

Kernova is an AppKit app hosting SwiftUI views that manages virtual machines via Apple's `Virtualization.framework`.

**Data flow:** `AppDelegate` → `VMLibraryViewModel` → services + SwiftUI views

### Key types

- **`VMConfiguration`** (Model) — Codable struct persisted as `config.json` per VM bundle. Holds identity, resources, display, network, and OS-specific fields (macOS hardware model data, Linux kernel paths).
- **`VMInstance`** (Runtime) — `@Observable` class wrapping a `VMConfiguration` + `VZVirtualMachine` + `VMStatus`. Owns bundle path references (disk image, save file, aux storage). Not persisted directly.
- **`VMLibraryViewModel`** — Central `@Observable` view model owning all service instances and the array of `VMInstance`s. All VM lifecycle calls go through here.
- **`ConfigurationBuilder`** — Translates `VMConfiguration` → `VZVirtualMachineConfiguration`. Handles three boot paths: macOS (`VZMacOSBootLoader`), EFI (`VZEFIBootLoader`), and Linux kernel (`VZLinuxBootLoader`).
- **`VirtualizationService`** — VM lifecycle (start/stop/pause/resume/save/restore). All `@MainActor` since `VZVirtualMachine` is main-thread-only.
- **`VMStorageService`** — CRUD for VM bundle directories at `~/Library/Application Support/Kernova/VMs/`.
- **`DiskImageService`** — Creates ASIF (Apple Sparse Image Format) disk images via `hdiutil`.

### Concurrency model

Everything touching `VZVirtualMachine` is `@MainActor`. The codebase uses Swift 6 strict concurrency. `VMConfiguration` is `Sendable`; `VMInstance` and services are `@MainActor`-isolated. Some `VZVirtualMachine` callback APIs use `nonisolated(unsafe)` with `MainActor.assumeIsolated` to bridge delegate callbacks.

### Tests

Tests use Swift Testing (`@Suite`, `@Test`, `#expect`) — not XCTest. Test files are in `KernovaTests/`.
