import AppKit
import Foundation

final class LineNumberRulerView: NSRulerView {
    // Injected from outside so the ruler can pick up theme changes
    var theme: SyntaxTheme = .light {
        didSet { needsDisplay = true }
    }
    var fontSize: CGFloat = 13 {
        didSet { needsDisplay = true }
    }

    private var lineWrappingCache: [Int: CGFloat] = [:]

    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation: orientation)
        clientView = scrollView?.documentView
        ruleThickness = 50
    }

    required init(coder: NSCoder) { fatalError() }

    var textView: NSTextView? { clientView as? NSTextView }

    override func viewWillDraw() {
        super.viewWillDraw()
        updateThickness()
    }

    private func updateThickness() {
        guard let tv = textView else { return }
        let lineCount = (tv.string as NSString).components(separatedBy: "\n").count
        let digits = max(3, "\(lineCount)".count)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        ]
        let sampleWidth = ("0" as NSString).size(withAttributes: attrs).width
        ruleThickness = sampleWidth * CGFloat(digits) + 12
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let tv = textView,
              let layoutManager = tv.layoutManager,
              let textContainer = tv.textContainer else { return }

        // Background
        theme.lineNumberBackground.setFill()
        rect.fill()

        // Right border
        let borderColor = theme.lineNumberForeground.withAlphaComponent(0.3)
        borderColor.setStroke()
        let borderPath = NSBezierPath()
        borderPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: rect.minY))
        borderPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: rect.maxY))
        borderPath.lineWidth = 1
        borderPath.stroke()

        let font = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.lineNumberForeground
        ]

        let visibleRect = tv.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let nsString = tv.string as NSString
        var lineNumber = 1

        // Count lines before visible range
        let textBeforeVisible = nsString.substring(to: charRange.location)
        lineNumber = textBeforeVisible.components(separatedBy: "\n").count

        var charIndex = charRange.location

        while charIndex < NSMaxRange(charRange) {
            var lineRange = NSRange()
            nsString.getLineStart(nil, end: nil, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
            nsString.getLineStart(nil, end: &lineRange.length, contentsEnd: nil,
                                  for: NSRange(location: charIndex, length: 0))
            lineRange.location = charIndex

            var effectiveRange = NSRange()
            let rect = layoutManager.lineFragmentRect(
                forGlyphAt: layoutManager.glyphIndexForCharacter(at: charIndex),
                effectiveRange: &effectiveRange
            )

            let yPos = rect.minY - visibleRect.minY + convert(.zero, from: tv).y
            let label = "\(lineNumber)" as NSString
            let labelSize = label.size(withAttributes: attrs)
            let drawRect = NSRect(
                x: bounds.maxX - labelSize.width - 6,
                y: yPos + (rect.height - labelSize.height) / 2,
                width: labelSize.width,
                height: labelSize.height
            )
            label.draw(in: drawRect, withAttributes: attrs)

            // Advance to next line
            var nextLine = NSMaxRange(lineRange)
            if nextLine <= charIndex { nextLine = charIndex + 1 }
            charIndex = nextLine
            lineNumber += 1
        }

        // Draw line number for empty trailing newline
        if nsString.hasSuffix("\n") || nsString.length == 0 {
            if let glyphIndex = layoutManager.glyphRange(forCharacterRange: NSRange(location: nsString.length, length: 0), actualCharacterRange: nil).location as Int?,
               glyphIndex <= layoutManager.numberOfGlyphs {
                // handled above
            }
        }
    }
}
