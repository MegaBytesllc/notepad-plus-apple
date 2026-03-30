import SwiftUI
import AppKit

// MARK: - SwiftUI Wrapper

struct EditorView: NSViewRepresentable {
    @ObservedObject var document: Document
    @EnvironmentObject var manager: DocumentManager

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = EditorTextView(frame: .zero)
        textView.setup(in: scrollView)
        textView.editorDelegate = context.coordinator
        textView.document = document

        scrollView.documentView = textView

        // Load initial content
        textView.string = document.text
        textView.scheduleHighlight()

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? EditorTextView else { return }

        // Sync text if changed externally
        if textView.string != document.text {
            let selectedRange = textView.selectedRange()
            textView.string = document.text
            let clampedLoc = min(selectedRange.location, document.text.count)
            textView.setSelectedRange(NSRange(location: clampedLoc, length: 0))
            textView.scheduleHighlight()
        }

        // Apply settings
        let isDark = NSApp.effectiveAppearance.name == .darkAqua
        let theme = isDark ? SyntaxTheme.dark : SyntaxTheme.light
        if textView.theme.background != theme.background {
            textView.theme = theme
        }

        textView.document = document
        textView.showLineNumbers = manager.showLineNumbers
        textView.wordWrap = manager.wordWrap
        textView.showWhitespace = manager.showWhitespace
        textView.editorFontSize = manager.fontSize
    }

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    // MARK: - Coordinator

    class Coordinator: EditorTextViewDelegate {
        let document: Document
        weak var textView: EditorTextView?

        init(document: Document) {
            self.document = document
        }

        func editorDidChange(_ textView: EditorTextView) {
            // text already synced inside EditorTextView
        }

        func editorDidMoveCursor(_ textView: EditorTextView, line: Int, column: Int, selection: Int) {
            document.cursorLine = line
            document.cursorColumn = column
            document.selectionLength = selection
        }
    }
}
