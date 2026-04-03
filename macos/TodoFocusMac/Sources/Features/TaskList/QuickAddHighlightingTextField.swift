import AppKit
import SwiftUI

struct QuickAddHighlightingTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    let placeholder: String
    let highlightColor: NSColor
    var nowProvider: () -> Date = Date.init
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: "")
        field.isBezeled = false
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byClipping
        field.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.maximumNumberOfLines = 1
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        context.coordinator.applyHighlight(to: field, text: text, preserveSelection: false)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        if nsView.stringValue != text {
            context.coordinator.applyHighlight(to: nsView, text: text, preserveSelection: true)
        }
        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }

        guard let window = nsView.window else { return }
        let firstResponder = window.firstResponder
        let editor = nsView.currentEditor()
        let isCurrentlyFocused = (firstResponder === nsView) || (editor != nil && firstResponder === editor)

        if isFocused && !isCurrentlyFocused {
            window.makeFirstResponder(nsView)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: QuickAddHighlightingTextField
        private var isProgrammaticChange = false

        init(parent: QuickAddHighlightingTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            if let field = obj.object as? NSTextField, field.currentEditor() != nil {
                // Ignore transient end-edit callbacks caused by attributed-text refresh during active editing.
                return
            }
            if parent.isFocused {
                parent.isFocused = false
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard !isProgrammaticChange, let field = obj.object as? NSTextField else { return }
            let newText = field.stringValue
            if parent.text != newText {
                parent.text = newText
            }
            if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() {
                return
            }
            applyHighlight(to: field, text: newText, preserveSelection: true)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }

        func applyHighlight(to field: NSTextField, text: String, preserveSelection: Bool) {
            let selectedRange = field.currentEditor()?.selectedRange
            let attributed = NSMutableAttributedString(string: text)
            let normalFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            attributed.addAttributes(
                [
                    .font: normalFont,
                    .foregroundColor: NSColor.textColor,
                ],
                range: NSRange(location: 0, length: attributed.length)
            )

            let ranges = QuickAddNaturalLanguageParser.highlightedTokenRanges(
                in: text,
                now: parent.nowProvider(),
                calendar: .current
            )
            for range in ranges {
                let nsRange = NSRange(range, in: text)
                attributed.addAttributes(
                    [
                        .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
                        .foregroundColor: parent.highlightColor,
                    ],
                    range: nsRange
                )
            }

            isProgrammaticChange = true
            if let editor = field.currentEditor() as? NSTextView {
                editor.textStorage?.setAttributedString(attributed)
                field.stringValue = text
            } else {
                field.attributedStringValue = attributed
            }
            isProgrammaticChange = false

            if preserveSelection,
               let editor = field.currentEditor(),
               let selectedRange {
                let maxLength = (text as NSString).length
                let clampedLocation = min(selectedRange.location, maxLength)
                let maxTail = max(0, maxLength - clampedLocation)
                let clampedLength = min(selectedRange.length, maxTail)
                editor.selectedRange = NSRange(location: clampedLocation, length: clampedLength)
                editor.scrollRangeToVisible(editor.selectedRange)
            }
        }
    }
}
