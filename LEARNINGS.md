# Learnings

This file is an append-only knowledge base maintained by Claude Code. Each entry captures a non-obvious discovery, resolved pitfall, or codebase-specific pattern learned during a development session. Future sessions read this file to avoid repeating mistakes and to apply proven approaches.

**Format:** Each entry is a concise, actionable item under a category heading. Entries should be specific to this codebase — not general Swift/programming knowledge.

---

## Build & Environment

- The project requires macOS 26 and Xcode 26. Builds will fail on earlier versions with no clear error message — check the environment first if xcodebuild fails unexpectedly.
- This is an Xcode project, not SPM. Do not attempt `swift build` or `swift test` — use `xcodebuild` commands from CLAUDE.md.

## Concurrency & Actor Isolation

- All `VZVirtualMachine` interactions must be `@MainActor`. Forgetting this causes Swift 6 strict concurrency errors that can be confusing — the compiler error points to the call site, not the missing annotation.
- VZ delegate callbacks require `nonisolated(unsafe)` with `MainActor.assumeIsolated` to bridge back. This pattern is intentional and used in VirtualizationService — don't try to refactor it away.

## Testing

- Tests use Swift Testing (`@Suite`, `@Test`, `#expect`), not XCTest. Mixing frameworks in the same file causes compilation errors.
- Mock services use `throwError` properties for error injection. Set `mockService.throwError = SomeError()` before calling the method under test, not after.
- Test factories like `makeInstance()` and `makeViewModel()` exist in test files — check existing tests before writing new setup code.

## Architecture Patterns

- `VMConfiguration` is `Codable` and `Sendable` — any new properties must also be `Codable` and `Sendable` or the project won't compile under Swift 6.
- Services are protocol-backed (see `Services/Protocols/`). New services should follow the same pattern: define a protocol, implement it, create a mock for tests.
- The app uses `os.Logger` with `com.kernova.app` subsystem. Never use `print()` — it won't show in production logs and violates the codebase convention.
