import SwiftUI

/// Settings form for editing a stopped VM's configuration.
struct VMSettingsView: View {
    @Bindable var instance: VMInstance
    @Bindable var viewModel: VMLibraryViewModel

    var body: some View {
        ScrollView {
            Form {
                generalSection
                resourcesSection
                displaySection
                networkSection
                notesSection
            }
            .formStyle(.grouped)
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtons
            }
        }
        .onChange(of: instance.configuration) { _, _ in
            viewModel.saveConfiguration(for: instance)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var generalSection: some View {
        Section("General") {
            TextField("Name", text: $instance.configuration.name)
            LabeledContent("Type", value: instance.configuration.guestOS.displayName)
            LabeledContent("Boot Mode", value: instance.configuration.bootMode.displayName)
            LabeledContent("Created", value: instance.configuration.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    @ViewBuilder
    private var resourcesSection: some View {
        Section("Resources") {
            let os = instance.configuration.guestOS

            Stepper(
                "CPU Cores: \(instance.configuration.cpuCount)",
                value: $instance.configuration.cpuCount,
                in: os.minCPUCount...os.maxCPUCount
            )

            Stepper(
                "Memory: \(instance.configuration.memorySizeInGB) GB",
                value: $instance.configuration.memorySizeInGB,
                in: os.minMemoryInGB...os.maxMemoryInGB
            )

            LabeledContent("Disk Size", value: "\(instance.configuration.diskSizeInGB) GB")
        }
    }

    @ViewBuilder
    private var displaySection: some View {
        Section("Display") {
            LabeledContent("Resolution", value: "\(instance.configuration.displayWidth) x \(instance.configuration.displayHeight)")
            LabeledContent("PPI", value: "\(instance.configuration.displayPPI)")
        }
    }

    @ViewBuilder
    private var networkSection: some View {
        Section("Network") {
            Toggle("Networking Enabled", isOn: $instance.configuration.networkEnabled)
            if let mac = instance.configuration.macAddress {
                LabeledContent("MAC Address", value: mac)
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $instance.configuration.notes)
                .frame(minHeight: 60)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButtons: some View {
        if instance.status.canStart {
            Button {
                Task { await viewModel.start(instance) }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .help("Start this virtual machine")
        }

        Button(role: .destructive) {
            viewModel.confirmDelete(instance)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Delete this virtual machine")
    }
}
