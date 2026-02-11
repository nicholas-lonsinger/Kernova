import Foundation

extension FileManager {

    /// Returns the Kernova application support directory, creating it if necessary.
    var kernovaAppSupportDirectory: URL {
        get throws {
            let appSupport = try url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let kernovaDir = appSupport.appendingPathComponent("Kernova", isDirectory: true)

            if !fileExists(atPath: kernovaDir.path) {
                try createDirectory(at: kernovaDir, withIntermediateDirectories: true)
            }

            return kernovaDir
        }
    }

    /// Returns the VMs directory within the Kernova app support folder.
    var kernovaVMsDirectory: URL {
        get throws {
            let vmsDir = try kernovaAppSupportDirectory
                .appendingPathComponent("VMs", isDirectory: true)

            if !fileExists(atPath: vmsDir.path) {
                try createDirectory(at: vmsDir, withIntermediateDirectories: true)
            }

            return vmsDir
        }
    }

    /// Returns the size of a file or directory in bytes.
    func sizeOfItem(atPath path: String) throws -> UInt64 {
        let attributes = try attributesOfItem(atPath: path)
        return attributes[.size] as? UInt64 ?? 0
    }

    /// Returns the total size of a directory and all its contents.
    func sizeOfDirectory(at url: URL) throws -> UInt64 {
        let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        var totalSize: UInt64 = 0
        while let fileURL = enumerator?.nextObject() as? URL {
            let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += UInt64(attributes.fileSize ?? 0)
        }
        return totalSize
    }
}
