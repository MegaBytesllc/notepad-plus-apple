import SwiftUI
import AppKit

struct FindReplaceView: View {
    @EnvironmentObject var manager: DocumentManager
    @State private var resultMessage: String = ""
    @FocusState private var findFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            Divider()

            HStack(spacing: 8) {
                // Close button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        manager.showFindReplace = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .frame(width: 16, height: 16)

                VStack(spacing: 4) {
                    // Find row
                    HStack(spacing: 6) {
                        Text("Find:")
                            .font(.system(size: 12))
                            .frame(width: 52, alignment: .trailing)

                        TextField("", text: $manager.findText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .focused($findFocused)
                            .onSubmit { findNext() }

                        Button("Find Next") { findNext() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Button("Find Prev") { findPrev() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Button("Find All") { findAll() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Spacer()

                        Text(resultMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .leading)
                    }

                    // Replace row
                    HStack(spacing: 6) {
                        Text("Replace:")
                            .font(.system(size: 12))
                            .frame(width: 52, alignment: .trailing)

                        TextField("", text: $manager.replaceText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .onSubmit { replaceNext() }

                        Button("Replace") { replaceNext() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Button("Replace All") { replaceAll() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Spacer()
                    }

                    // Options row
                    HStack(spacing: 12) {
                        Toggle("Match Case", isOn: $manager.findMatchCase)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 11))

                        Toggle("Whole Word", isOn: $manager.findWholeWord)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 11))

                        Toggle("Regex", isOn: $manager.findUseRegex)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 11))

                        Toggle("Wrap Around", isOn: $manager.findWrapAround)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 11))

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { findFocused = true }
    }

    // MARK: - Find Logic

    private func buildRegex() -> NSRegularExpression? {
        var pattern = manager.findText
        if pattern.isEmpty { return nil }

        if !manager.findUseRegex {
            pattern = NSRegularExpression.escapedPattern(for: pattern)
        }
        if manager.findWholeWord {
            pattern = #"\b"# + pattern + #"\b"#
        }
        var options: NSRegularExpression.Options = []
        if !manager.findMatchCase { options.insert(.caseInsensitive) }

        return try? NSRegularExpression(pattern: pattern, options: options)
    }

    private func currentTextView() -> EditorTextView? {
        // Walk the responder chain / key window
        guard let window = NSApp.keyWindow else { return nil }
        return findTextView(in: window.contentView)
    }

    private func findTextView(in view: NSView?) -> EditorTextView? {
        guard let view else { return nil }
        if let tv = view as? EditorTextView { return tv }
        for sub in view.subviews {
            if let found = findTextView(in: sub) { return found }
        }
        return nil
    }

    private func findNext() {
        guard let regex = buildRegex(),
              let tv = currentTextView() else { return }
        let text = tv.string
        let fullRange = NSRange(text.startIndex..., in: text)
        let currentLoc = tv.selectedRange().location + tv.selectedRange().length
        let searchRange = NSRange(location: currentLoc, length: text.count - currentLoc)

        if let match = regex.firstMatch(in: text, range: searchRange) {
            tv.setSelectedRange(match.range)
            tv.scrollRangeToVisible(match.range)
            resultMessage = ""
        } else if manager.findWrapAround {
            if let match = regex.firstMatch(in: text, range: fullRange) {
                tv.setSelectedRange(match.range)
                tv.scrollRangeToVisible(match.range)
                resultMessage = "Wrapped"
            } else {
                resultMessage = "Not found"
            }
        } else {
            resultMessage = "Not found"
        }
    }

    private func findPrev() {
        guard let regex = buildRegex(),
              let tv = currentTextView() else { return }
        let text = tv.string
        let currentLoc = tv.selectedRange().location
        let searchRange = NSRange(location: 0, length: currentLoc)

        let allMatches = regex.matches(in: text, range: searchRange)
        if let match = allMatches.last {
            tv.setSelectedRange(match.range)
            tv.scrollRangeToVisible(match.range)
            resultMessage = ""
        } else if manager.findWrapAround {
            let fullRange = NSRange(text.startIndex..., in: text)
            let allFull = regex.matches(in: text, range: fullRange)
            if let match = allFull.last {
                tv.setSelectedRange(match.range)
                tv.scrollRangeToVisible(match.range)
                resultMessage = "Wrapped"
            } else {
                resultMessage = "Not found"
            }
        } else {
            resultMessage = "Not found"
        }
    }

    private func findAll() {
        guard let regex = buildRegex(),
              let tv = currentTextView() else { return }
        let text = tv.string
        let fullRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: fullRange)
        resultMessage = "\(matches.count) found"
    }

    private func replaceNext() {
        guard let regex = buildRegex(),
              let tv = currentTextView() else { return }
        let text = tv.string
        let selRange = tv.selectedRange()

        // If current selection matches, replace it
        if selRange.length > 0 {
            let selText = (text as NSString).substring(with: selRange)
            let selFullRange = NSRange(selText.startIndex..., in: selText)
            if regex.firstMatch(in: selText, range: selFullRange) != nil {
                let replacement = manager.replaceText
                if tv.shouldChangeText(in: selRange, replacementString: replacement) {
                    tv.replaceCharacters(in: selRange, with: replacement)
                    tv.didChangeText()
                }
            }
        }
        findNext()
    }

    private func replaceAll() {
        guard let regex = buildRegex(),
              let tv = currentTextView() else { return }
        let text = tv.string
        let fullRange = NSRange(text.startIndex..., in: text)
        let result = regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: fullRange,
            withTemplate: manager.replaceText
        )
        if tv.shouldChangeText(in: fullRange, replacementString: result) {
            tv.string = result
            tv.didChangeText()
        }
        let count = regex.numberOfMatches(in: text, range: fullRange)
        resultMessage = "\(count) replaced"
    }
}
