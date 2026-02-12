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

## Commit Messages

Use the following format for all commits:

```
<type>: <concise subject line>

## Summary
<1-2 sentence overview of what changed and why>

## Changes
- <bullet points describing each discrete change>

## Validation
- <how the changes were verified (build, tests, manual testing, etc.)>

## Notes
- <optional: anything reviewers should know, follow-ups, caveats>
```

### Type prefixes

| Prefix     | Usage                                      |
|------------|--------------------------------------------|
| `feat`     | New feature or capability                  |
| `fix`      | Bug fix                                    |
| `refactor` | Code restructuring with no behavior change |
| `docs`     | Documentation only                         |
| `test`     | Adding or updating tests                   |
| `chore`    | Build, CI, tooling, or dependency updates  |
| `style`    | Formatting, whitespace, or cosmetic changes|

### Example

```
feat: Add VM snapshot support

## Summary
Adds the ability to take and restore snapshots of running virtual machines,
enabling users to save and revert VM state at any point.

## Changes
- Add SnapshotService with create/restore/delete operations
- Add snapshot UI to VMDetailView toolbar
- Persist snapshot metadata in VMConfiguration

## Validation
- Built successfully on macOS 26
- Tested snapshot create/restore cycle with macOS and Linux guests
- All existing tests pass

## Notes
- Snapshot files are stored alongside the VM bundle
```

The `Co-Authored-By` trailer is automatically appended by Claude and should not be included manually.
