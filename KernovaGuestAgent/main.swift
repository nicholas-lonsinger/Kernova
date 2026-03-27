import Foundation
import os

// KernovaGuestAgent
//
// A guest-side agent that runs inside macOS virtual machines managed by Kernova.
// This is currently a stub that validates the build-package-install pipeline.
// The real agent will implement host-guest communication via SPICE.
//
// Usage: kernova-agent [--version]

private let logger = Logger(subsystem: "com.kernova.agent", category: "GuestAgent")

private let version = "0.1.0"

if CommandLine.arguments.contains("--version") {
    print("kernova-agent \(version)")
    exit(0)
}

logger.notice("Kernova Guest Agent v\(version, privacy: .public) started (stub)")
print("Kernova Guest Agent v\(version) — stub running (no-op, waiting for termination).")
dispatchMain()
