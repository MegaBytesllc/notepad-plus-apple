import AppKit
import Foundation

// MARK: - Delegate Protocol

protocol EditorTextViewDelegate: AnyObject {
    func editorDidChange(_ textView: EditorTextView)
    func editorDidMoveCursor(_ textView: EditorTextView, line: Int, column: Int, selection: Int)
}

// MARK: - EditorTextView

final class EditorTextView: NSTextView {
    weak var editorDelegate: EditorTextViewDelegate?

    var document: Document? {
        didSet { applyDocumentSettings() }
    }

    var theme: SyntaxTheme = .light {
        didSet { applyTheme() }
    }

    var showLineNumbers: Bool = true {
        didSet {
            scrollView?.rulersVisible = showLineNumbers
            lineRuler?.needsDisplay = true
        }
    }

    var wordWrap: Bool = false {
        didSet { applyWordWrap() }
    }

    var showWhitespace: Bool = false {
        didSet { setNeedsDisplay(bounds) }
    }

    var editorFontSize: CGFloat = 13 {
        didSet { applyFont() }
    }

    private var highlightWorkItem: DispatchWorkItem?
    private(set) var lineRuler: LineNumberRulerView?

    // MARK: - Setup

    func setup(in scrollView: NSScrollView) {
        // Text container
        isVerticallyResizable = true
        isHorizontallyResizable = false
        autoresizingMask = [.width]
        textContainer?.widthTracksTextView = true
        textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Editing behavior
        isRichText = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        allowsUndo = true
        usesFindBar = false
        usesFontPanel = false

        // Tab stops: 4 spaces
        defaultParagraphStyle = makeParagraphStyle()

        // Line number ruler
        let ruler = LineNumberRulerView(scrollView: scrollView, orientation: .verticalRuler)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = showLineNumbers
        lineRuler = ruler

        applyTheme()
        applyFont()
        delegate = self
    }

    private func makeParagraphStyle() -> NSParagraphStyle {
        let ps = NSMutableParagraphStyle()
        let tabInterval: CGFloat = 28 // ~4 chars at 13pt
        ps.tabStops = []
        ps.defaultTabInterval = tabInterval
        return ps
    }

    private var scrollView: NSScrollView? {
        var view: NSView? = self
        while let v = view {
            if let sv = v as? NSScrollView { return sv }
            view = v.superview
        }
        return nil
    }

    // MARK: - Theme & Font

    private func applyTheme() {
        backgroundColor = theme.background
        insertionPointColor = theme.caretColor
        selectedTextAttributes = [
            .backgroundColor: theme.selectionColor
        ]
        lineRuler?.theme = theme
        textColor = theme.foreground
        scheduleHighlight()
    }

    private func applyFont() {
        let f = NSFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        font = f
        lineRuler?.fontSize = editorFontSize
        scheduleHighlight()
    }

    private func applyDocumentSettings() {
        guard let doc = document else { return }
        if string != doc.text {
            string = doc.text
        }
        scheduleHighlight()
    }

    private func applyWordWrap() {
        guard let container = textContainer,
              let scrollView = scrollView else { return }
        if wordWrap {
            isHorizontallyResizable = false
            container.widthTracksTextView = true
            container.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            autoresizingMask = [.width]
        } else {
            isHorizontallyResizable = true
            container.widthTracksTextView = false
            container.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            autoresizingMask = []
        }
        layoutManager?.ensureLayout(for: container)
        setNeedsDisplay(bounds)
    }

    // MARK: - Syntax Highlighting

    func scheduleHighlight() {
        highlightWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.performHighlight()
        }
        highlightWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: item)
    }

    private func performHighlight() {
        guard let storage = textStorage,
              let lang = document?.language else { return }
        SyntaxHighlighter.highlight(storage: storage, language: lang, theme: theme)
        lineRuler?.needsDisplay = true
    }

    // MARK: - Cursor Position

    private func updateCursorPosition() {
        let loc = selectedRange().location
        let text = string as NSString
        var line = 1
        var col = 1
        var i = 0
        while i < min(loc, text.length) {
            let c = text.character(at: i)
            if c == 0x0A { // \n
                line += 1
                col = 1
            } else {
                col += 1
            }
            i += 1
        }
        let sel = selectedRange().length
        editorDelegate?.editorDidMoveCursor(self, line: line, column: col, selection: sel)
    }

    // MARK: - Key Handling

    override func keyDown(with event: NSEvent) {
        // Tab → insert spaces or tab character
        if event.keyCode == 48 && !event.modifierFlags.contains(.shift) {
            insertTab(nil)
            return
        }
        // Shift-Tab → outdent
        if event.keyCode == 48 && event.modifierFlags.contains(.shift) {
            insertBacktab(nil)
            return
        }
        super.keyDown(with: event)
    }

    override func insertNewline(_ sender: Any?) {
        // Auto-indent: copy leading whitespace from current line
        let nsStr = string as NSString
        let cursorLoc = selectedRange().location
        var lineStart = 0
        nsStr.getLineStart(&lineStart, end: nil, contentsEnd: nil,
                           for: NSRange(location: cursorLoc, length: 0))
        var indent = ""
        var idx = lineStart
        while idx < cursorLoc {
            let ch = nsStr.character(at: idx)
            if ch == 0x20 || ch == 0x09 { // space or tab
                indent.append(Character(UnicodeScalar(ch)!))
                idx += 1
            } else {
                break
            }
        }
        super.insertNewline(sender)
        if !indent.isEmpty {
            insertText(indent, replacementRange: selectedRange())
        }
    }

    // MARK: - Bracket Matching

    private func highlightMatchingBracket(at location: Int) {
        // Simple bracket highlighting (flash)
        let text = string as NSString
        guard location > 0 else { return }
        let closers: [unichar: unichar] = [
            0x29: 0x28, // ) → (
            0x5D: 0x5B, // ] → [
            0x7D: 0x7B  // } → {
        ]
        let openers: [unichar: unichar] = [
            0x28: 0x29,
            0x5B: 0x5D,
            0x7B: 0x7D
        ]

        let ch = text.character(at: location - 1)
        if let openChar = closers[ch] {
            // Search backward
            var depth = 0
            var i = location - 1
            while i >= 0 {
                let c = text.character(at: i)
                if c == ch { depth += 1 }
                else if c == openChar {
                    depth -= 1
                    if depth == 0 {
                        flashBracket(at: i)
                        return
                    }
                }
                if i == 0 { break }
                i -= 1
            }
        } else if let closeChar = openers[ch] {
            var depth = 0
            var i = location - 1
            while i < text.length {
                let c = text.character(at: i)
                if c == ch { depth += 1 }
                else if c == closeChar {
                    depth -= 1
                    if depth == 0 {
                        flashBracket(at: i)
                        return
                    }
                }
                i += 1
            }
        }
    }

    private func flashBracket(at index: Int) {
        let range = NSRange(location: index, length: 1)
        let original = textStorage?.attribute(.backgroundColor, at: index, effectiveRange: nil)
        textStorage?.addAttribute(.backgroundColor,
                                  value: NSColor.selectedTextBackgroundColor,
                                  range: range)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let orig = original {
                self?.textStorage?.addAttribute(.backgroundColor, value: orig, range: range)
            } else {
                self?.textStorage?.removeAttribute(.backgroundColor, range: range)
            }
        }
    }
}

// MARK: - NSTextViewDelegate

extension EditorTextView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let doc = document else { return }
        let newText = string
        if doc.text != newText {
            doc.text = newText
            doc.isModified = true
        }
        scheduleHighlight()
        editorDelegate?.editorDidChange(self)
        updateCursorPosition()
        lineRuler?.needsDisplay = true
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateCursorPosition()
        let loc = selectedRange().location
        if loc > 0 { highlightMatchingBracket(at: loc) }
    }
}
