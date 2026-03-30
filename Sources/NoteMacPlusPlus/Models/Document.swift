import Foundation
import AppKit
import Combine

final class Document: ObservableObject, Identifiable {
    let id: UUID
    private static var untitledCounter = 0

    @Published var text: String
    @Published var isModified: Bool = false
    @Published var language: Language
    @Published var encoding: String.Encoding
    @Published var lineEnding: LineEnding

    var fileURL: URL?
    private let untitledNumber: Int

    // Cursor / selection state (updated by editor)
    var cursorLine: Int = 1
    var cursorColumn: Int = 1
    var selectionLength: Int = 0

    init(text: String = "", fileURL: URL? = nil) {
        self.id = UUID()
        Self.untitledCounter += 1
        self.untitledNumber = Self.untitledCounter
        self.text = text
        self.fileURL = fileURL
        self.encoding = .utf8
        self.lineEnding = LineEnding.detect(in: text)

        if let url = fileURL {
            self.language = Language.detect(from: url)
        } else {
            self.language = .plainText
        }
    }

    var displayName: String {
        fileURL?.lastPathComponent ?? "new \(untitledNumber)"
    }

    var lineCount: Int {
        text.components(separatedBy: .newlines).count
    }

    var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }

    // MARK: - File Operations

    static func load(from url: URL) throws -> Document {
        // Try common encodings
        let encodings: [String.Encoding] = [.utf8, .windowsCP1252, .isoLatin1, .utf16]
        for encoding in encodings {
            if let text = try? String(contentsOf: url, encoding: encoding) {
                let doc = Document(text: text, fileURL: url)
                doc.encoding = encoding
                doc.lineEnding = LineEnding.detect(in: text)
                return doc
            }
        }
        throw CocoaError(.fileReadUnknownStringEncoding)
    }

    func save(to url: URL? = nil) throws {
        let target = url ?? fileURL
        guard let target else { throw CocoaError(.fileNoSuchFile) }
        // Normalize line endings
        let normalized = normalizeLineEndings(text, to: lineEnding)
        try normalized.write(to: target, atomically: true, encoding: encoding)
        fileURL = target
        isModified = false
    }

    private func normalizeLineEndings(_ text: String, to ending: LineEnding) -> String {
        // Strip all \r first, then re-apply desired ending
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
        result = result.replacingOccurrences(of: "\r", with: "\n")
        if ending != .lf {
            result = result.replacingOccurrences(of: "\n", with: ending.characters)
        }
        return result
    }
}
