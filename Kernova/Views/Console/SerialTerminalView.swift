import SwiftUI
import AppKit

/// `NSViewRepresentable` wrapping a custom `NSTextView` subclass that displays
/// serial console output and forwards keyboard input to the guest VM.
struct SerialTerminalView: NSViewRepresentable {
    @Bindable var instance: VMInstance

    func makeCoordinator() -> Coordinator {
        Coordinator(instance: instance)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = SerialTextView()
        textView.coordinator = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isFieldEditor = false
        textView.allowsUndo = false
        textView.usesFindPanel = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .init(white: 0.9, alpha: 1.0)
        textView.backgroundColor = .init(white: 0.1, alpha: 1.0)
        textView.insertionPointColor = .init(white: 0.9, alpha: 1.0)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        // Container sizing
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .init(white: 0.1, alpha: 1.0)

        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SerialTextView else { return }
        context.coordinator.instance = instance

        let currentText = textView.string
        let newText = instance.serialOutputText

        guard currentText != newText else { return }

        // Check if user is scrolled to the bottom before updating
        let clipView = scrollView.contentView
        let contentHeight = textView.frame.height
        let scrollOffset = clipView.bounds.origin.y + clipView.bounds.height
        let isAtBottom = scrollOffset >= contentHeight - 10

        textView.string = newText

        // Auto-scroll to bottom if user was already there
        if isAtBottom {
            textView.scrollToEndOfDocument(nil)
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        var instance: VMInstance
        weak var textView: SerialTextView?

        init(instance: VMInstance) {
            self.instance = instance
        }

        func sendInput(_ string: String) {
            instance.sendSerialInput(string)
        }
    }
}

// MARK: - SerialTextView

/// Custom `NSTextView` that intercepts keyboard input and forwards it
/// to the guest VM's serial input pipe instead of editing the text buffer.
final class SerialTextView: NSTextView {
    weak var coordinator: SerialTerminalView.Coordinator?

    override func keyDown(with event: NSEvent) {
        // Forward raw characters to the serial port
        if let characters = event.characters, !characters.isEmpty {
            Task { @MainActor [weak self] in
                self?.coordinator?.sendInput(characters)
            }
            return
        }
        super.keyDown(with: event)
    }

    override func insertNewline(_ sender: Any?) {
        Task { @MainActor [weak self] in
            self?.coordinator?.sendInput("\r")
        }
    }

    override func deleteBackward(_ sender: Any?) {
        Task { @MainActor [weak self] in
            self?.coordinator?.sendInput("\u{7f}")
        }
    }

    override func insertTab(_ sender: Any?) {
        Task { @MainActor [weak self] in
            self?.coordinator?.sendInput("\t")
        }
    }

    // Allow the text view to become first responder for keyboard input
    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        true
    }
}
