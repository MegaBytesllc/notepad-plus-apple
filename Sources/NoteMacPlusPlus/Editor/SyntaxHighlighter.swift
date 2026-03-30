import AppKit
import Foundation

// MARK: - Theme

struct SyntaxTheme {
    var background: NSColor
    var foreground: NSColor
    var keyword: NSColor
    var string: NSColor
    var comment: NSColor
    var number: NSColor
    var function_: NSColor
    var type_: NSColor
    var preprocessor: NSColor
    var operator_: NSColor
    var lineNumberBackground: NSColor
    var lineNumberForeground: NSColor
    var currentLineBackground: NSColor
    var selectionColor: NSColor
    var caretColor: NSColor

    static let light = SyntaxTheme(
        background:             NSColor(hex: "#FFFFFF"),
        foreground:             NSColor(hex: "#000000"),
        keyword:                NSColor(hex: "#0000FF"),
        string:                 NSColor(hex: "#CE7B00"),
        comment:                NSColor(hex: "#008000"),
        number:                 NSColor(hex: "#FF6600"),
        function_:              NSColor(hex: "#6F008C"),
        type_:                  NSColor(hex: "#008080"),
        preprocessor:           NSColor(hex: "#804000"),
        operator_:              NSColor(hex: "#404040"),
        lineNumberBackground:   NSColor(hex: "#E4E4E4"),
        lineNumberForeground:   NSColor(hex: "#808080"),
        currentLineBackground:  NSColor(hex: "#E8F2FF"),
        selectionColor:         NSColor(hex: "#0078D4").withAlphaComponent(0.3),
        caretColor:             NSColor(hex: "#000000")
    )

    static let dark = SyntaxTheme(
        background:             NSColor(hex: "#1E1E1E"),
        foreground:             NSColor(hex: "#D4D4D4"),
        keyword:                NSColor(hex: "#569CD6"),
        string:                 NSColor(hex: "#CE9178"),
        comment:                NSColor(hex: "#6A9955"),
        number:                 NSColor(hex: "#B5CEA8"),
        function_:              NSColor(hex: "#DCDCAA"),
        type_:                  NSColor(hex: "#4EC9B0"),
        preprocessor:           NSColor(hex: "#C586C0"),
        operator_:              NSColor(hex: "#D4D4D4"),
        lineNumberBackground:   NSColor(hex: "#1E1E1E"),
        lineNumberForeground:   NSColor(hex: "#858585"),
        currentLineBackground:  NSColor(hex: "#282828"),
        selectionColor:         NSColor(hex: "#264F78"),
        caretColor:             NSColor(hex: "#AEAFAD")
    )
}

extension NSColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >>  8) & 0xFF) / 255
        let b = CGFloat((rgb >>  0) & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Highlighter

final class SyntaxHighlighter {

    static func highlight(
        storage: NSTextStorage,
        language: Language,
        theme: SyntaxTheme
    ) {
        let text = storage.string
        guard !text.isEmpty else { return }

        let fullRange = NSRange(text.startIndex..., in: text)

        storage.beginEditing()

        // Reset to base style
        storage.addAttribute(.foregroundColor, value: theme.foreground, range: fullRange)
        let font = storage.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        storage.addAttribute(.font, value: font, range: fullRange)

        if language == .plainText || language == .markdown {
            storage.endEditing()
            return
        }

        // Apply token colors
        applyPatterns(to: storage, text: text, language: language, theme: theme)

        storage.endEditing()
    }

    // MARK: - Pattern Application

    private static func applyPatterns(
        to storage: NSTextStorage,
        text: String,
        language: Language,
        theme: SyntaxTheme
    ) {
        // Order matters: later patterns can override earlier ones
        // 1. Comments (highest priority — applied last so they override)
        // 2. Strings
        // 3. Numbers
        // 4. Keywords
        // 5. Preprocessor / decorators

        applyNumbers(to: storage, text: text, theme: theme)
        applyStrings(to: storage, text: text, language: language, theme: theme)
        applyPreprocessor(to: storage, text: text, language: language, theme: theme)
        applyKeywords(to: storage, text: text, language: language, theme: theme)
        applyComments(to: storage, text: text, language: language, theme: theme)
    }

    // MARK: Numbers

    private static func applyNumbers(
        to storage: NSTextStorage,
        text: String,
        theme: SyntaxTheme
    ) {
        let pattern = #"(?<![a-zA-Z_])\b(0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?[fFuUlL]*)\b"#
        applyRegex(pattern, to: storage, text: text, color: theme.number)
    }

    // MARK: Strings

    private static func applyStrings(
        to storage: NSTextStorage,
        text: String,
        language: Language,
        theme: SyntaxTheme
    ) {
        // Double-quoted strings
        applyRegex(#"(?<!\\)"(?:[^"\\]|\\.)*(?:"|$)"#,
                   to: storage, text: text, color: theme.string)
        // Single-quoted strings (not for SQL identifiers)
        if language != .sql {
            applyRegex(#"(?<!\\)'(?:[^'\\]|\\.)*(?:'|$)"#,
                       to: storage, text: text, color: theme.string)
        }
        // Backtick strings (JS template literals, Go raw strings)
        if language == .javascript || language == .typescript || language == .go {
            applyRegex(#"`(?:[^`\\]|\\.)*`"#,
                       to: storage, text: text, color: theme.string)
        }
        // Python triple-quoted strings
        if language == .python {
            applyRegex(#""""[\s\S]*?""""#,
                       to: storage, text: text, color: theme.string, options: [.dotMatchesLineSeparators])
            applyRegex(#"'''[\s\S]*?'''"#,
                       to: storage, text: text, color: theme.string, options: [.dotMatchesLineSeparators])
        }
        // Swift multi-line strings
        if language == .swift {
            applyRegex(#""""[\s\S]*?""""#,
                       to: storage, text: text, color: theme.string, options: [.dotMatchesLineSeparators])
        }
    }

    // MARK: Keywords

    private static func applyKeywords(
        to storage: NSTextStorage,
        text: String,
        language: Language,
        theme: SyntaxTheme
    ) {
        let keywords = language.keywords
        guard !keywords.isEmpty else { return }

        // Build a single regex alternation for all keywords
        let sorted = keywords.sorted(by: { $0.count > $1.count }) // longer first
        let escaped = sorted.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = #"(?<![a-zA-Z0-9_])("# + escaped.joined(separator: "|") + #")(?![a-zA-Z0-9_])"#

        applyRegex(pattern, to: storage, text: text, color: theme.keyword)
    }

    // MARK: Preprocessor / Decorators / Annotations

    private static func applyPreprocessor(
        to storage: NSTextStorage,
        text: String,
        language: Language,
        theme: SyntaxTheme
    ) {
        switch language {
        case .cLang, .cpp:
            applyRegex(#"^\s*#\s*\w+"#, to: storage, text: text,
                       color: theme.preprocessor, options: [.anchorsMatchLines])
        case .swift:
            applyRegex(#"@\w+"#, to: storage, text: text, color: theme.type_)
            applyRegex(#"#\w+"#, to: storage, text: text, color: theme.preprocessor)
        case .python:
            applyRegex(#"@\w+"#, to: storage, text: text, color: theme.type_)
        case .java, .kotlin:
            applyRegex(#"@\w+"#, to: storage, text: text, color: theme.type_)
        default:
            break
        }
    }

    // MARK: Comments (applied last, override everything)

    private static func applyComments(
        to storage: NSTextStorage,
        text: String,
        language: Language,
        theme: SyntaxTheme
    ) {
        // Line comments
        if let prefix = language.lineCommentPrefix {
            let escaped = NSRegularExpression.escapedPattern(for: prefix)
            applyRegex(escaped + #"[^\n]*"#,
                       to: storage, text: text, color: theme.comment)
        }

        // Block comments
        if let (open, close) = language.blockCommentDelimiters {
            let eo = NSRegularExpression.escapedPattern(for: open)
            let ec = NSRegularExpression.escapedPattern(for: close)
            applyRegex(eo + #"[\s\S]*?"# + ec,
                       to: storage, text: text, color: theme.comment,
                       options: [.dotMatchesLineSeparators])
        }
    }

    // MARK: - Regex Helper

    private static func applyRegex(
        _ pattern: String,
        to storage: NSTextStorage,
        text: String,
        color: NSColor,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let fullRange = NSRange(text.startIndex..., in: text)
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            storage.addAttribute(.foregroundColor, value: color, range: range)
        }
    }
}
