# Kernova

A macOS GUI application for creating and managing virtual machines using Apple's [Virtualization.framework](https://developer.apple.com/documentation/virtualization).

## Features

- **macOS & Linux guests** — Run macOS virtual machines on Apple Silicon and Linux VMs with EFI or direct kernel boot
- **ASIF disk images** — Uses Apple Sparse Image Format for near-native SSD performance with space-efficient storage
- **Full VM lifecycle** — Start, stop, pause, resume, save state, and restore
- **Creation wizard** — Step-by-step VM creation with IPSW download for macOS guests
- **Native UI** — AppKit app with SwiftUI views, Liquid Glass design language

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon (required for macOS guests)
- Xcode 26 or later
- Swift 6

## Building

1. Open `Kernova.xcodeproj` in Xcode 26
2. Select the `Kernova` scheme
3. Build and run (Cmd+R)

The app requires the `com.apple.security.virtualization` entitlement, which is included in the project configuration.

## Architecture

```
Kernova/
├── App/          # AppDelegate, MainWindowController
├── Models/       # VMConfiguration, VMInstance, enums
├── Services/     # VM lifecycle, storage, disk images, IPSW, installation
├── Views/        # SwiftUI views (sidebar, detail, console, creation wizard)
├── ViewModels/   # Observable view models
└── Utilities/    # Formatters, extensions
```

### Key Components

- **VMConfiguration** — Codable model persisted as `config.json` in each VM bundle
- **VMInstance** — Runtime wrapper combining config, VZVirtualMachine, and status
- **ConfigurationBuilder** — Translates VMConfiguration into VZVirtualMachineConfiguration
- **VirtualizationService** — VM lifecycle management (start/stop/pause/save/restore)
- **VMStorageService** — VM bundle CRUD at `~/Library/Application Support/Kernova/VMs/`

### VM Bundle Structure

Each VM is stored as a directory under `~/Library/Application Support/Kernova/VMs/<UUID>/`:

```
<UUID>/
  config.json           # Serialized VMConfiguration
  Disk.asif             # ASIF sparse disk image
  AuxiliaryStorage      # macOS auxiliary storage
  HardwareModel         # VZMacHardwareModel data
  MachineIdentifier     # VZMacMachineIdentifier data
  SaveFile.vzvmsave     # Saved VM state (suspend/resume)
```

## License

MIT License. See [LICENSE](LICENSE) for details.
