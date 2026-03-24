import UniformTypeIdentifiers

extension UTType {
    /// The document type for Kernova VM bundles (`.kernova` packages).
    static let kernovaVM = UTType("com.kernova.vm")!

    /// All disk image types accepted by `VZDiskImageStorageDeviceAttachment`.
    static let diskImageTypes: [UTType] = [
        .diskImage,
        UTType(filenameExtension: "iso") ?? .diskImage,
        UTType(filenameExtension: "img") ?? .data,
        UTType(filenameExtension: "raw") ?? .data,
        UTType(filenameExtension: "asif") ?? .data,
    ]
}
