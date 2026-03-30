import Foundation
import AppKit
import SwiftUI
import Combine

final class DocumentManager: ObservableObject {
    @Published var documents: [Document] = []
    @Published var activeDocumentId: UUID?
    @Published var showFindReplace: Bool = false
    @Published var showFileBrowser: Bool = true
    @Published var wordWrap: Bool = false
    @Published var showWhitespace: Bool = false
    @Published var showLineNumbers: Bool = true
    @Published var fontSize: CGFloat = 13

    // Find/Replace state shared across tabs
    @Published var findText: String = ""
    @Published var replaceText: String = ""
    @Published var findMatchCase: Bool = false
    @Published var findWholeWord: Bool = false
    @Published var findUseRegex: Bool = false
    @Published var findWrapAround: Bool = true

    private var cancellables = Set<AnyCancellable>()

    var activeDocument: Document? {
        get { documents.first { $0.id == activeDocumentId } }
    }

    // MARK: - Session Persistence

    private static var sessionURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("NoteMacPlusPlus", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.json")
    }

    /// Persisted entry for a single tab
    private struct SessionEntry: Codable {
        /// Absolute path if the file was saved to disk, nil for unsaved tabs
        let filePath: String?
        /// Full text — always stored so unsaved content survives restart
        let text: String
        let language: String
        let encodingRawValue: UInt
        let lineEnding: String
        let isActive: Bool
    }

    func saveSession() {
        let entries = documents.map { doc in
            SessionEntry(
                filePath: doc.fileURL?.path,
                text: doc.text,
                language: doc.language.rawValue,
                encodingRawValue: doc.encoding.rawValue,
                lineEnding: doc.lineEnding.rawValue,
                isActive: doc.id == activeDocumentId
            )
        }
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: Self.sessionURL, options: .atomic)
        }
    }

    func restoreSession() {
        guard let data = try? Data(contentsOf: Self.sessionURL),
              let entries = try? JSONDecoder().decode([SessionEntry].self, from: data),
              !entries.isEmpty else { return }

        // Remove the blank starter document added in init()
        documents.removeAll()

        for entry in entries {
            let doc: Document
            if let path = entry.filePath {
                let url = URL(fileURLWithPath: path)
                // If the file still exists on disk, load it fresh; but use
                // the session text if the file was modified at quit time.
                if FileManager.default.fileExists(atPath: path),
                   let diskDoc = try? Document.load(from: url) {
                    // Use session text (may include unsaved edits)
                    diskDoc.text = entry.text
                    diskDoc.isModified = diskDoc.text != (try? String(contentsOf: url, encoding: diskDoc.encoding)) ?? ""
                    doc = diskDoc
                } else {
                    // File no longer exists — restore as unsaved
                    doc = Document(text: entry.text)
                }
            } else {
                // Unsaved tab — restore text as-is
                doc = Document(text: entry.text)
            }

            if let lang = Language(rawValue: entry.language) {
                doc.language = lang
            }
            doc.encoding = String.Encoding(rawValue: entry.encodingRawValue)
            if let le = LineEnding(rawValue: entry.lineEnding) {
                doc.lineEnding = le
            }

            documents.append(doc)
            if entry.isActive { activeDocumentId = doc.id }
        }

        if activeDocumentId == nil {
            activeDocumentId = documents.first?.id
        }
    }

    init() {
        newDocument()
        setupOpenFileListener()
        restoreSession()
    }

    // MARK: - Document Lifecycle

    func newDocument() {
        let doc = Document()
        documents.append(doc)
        activeDocumentId = doc.id
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                openDocument(at: url)
            }
        }
    }

    func openDocument(at url: URL) {
        // If already open, just activate
        if let existing = documents.first(where: { $0.fileURL == url }) {
            activeDocumentId = existing.id
            return
        }
        do {
            let doc = try Document.load(from: url)
            documents.append(doc)
            activeDocumentId = doc.id
        } catch {
            showError("Could not open \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func saveDocument(_ doc: Document) {
        if doc.fileURL != nil {
            do {
                try doc.save()
            } catch {
                showError("Save failed: \(error.localizedDescription)")
            }
        } else {
            saveDocumentAs(doc)
        }
    }

    func saveDocumentAs(_ doc: Document) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = doc.displayName
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try doc.save(to: url)
                objectWillChange.send()
            } catch {
                showError("Save failed: \(error.localizedDescription)")
            }
        }
    }

    func saveAllDocuments() {
        for doc in documents where doc.isModified {
            saveDocument(doc)
        }
    }

    func closeDocument(_ doc: Document) {
        if doc.isModified {
            let alert = NSAlert()
            alert.messageText = "Save changes to \"\(doc.displayName)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                saveDocument(doc)
            case .alertSecondButtonReturn:
                break
            default:
                return
            }
        }
        guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        documents.remove(at: index)

        if documents.isEmpty {
            newDocument()
        } else {
            let newIndex = min(index, documents.count - 1)
            activeDocumentId = documents[newIndex].id
        }
    }

    func closeCurrentDocument() {
        guard let doc = activeDocument else { return }
        closeDocument(doc)
    }

    // MARK: - Navigation

    func activateNextTab() {
        guard let idx = documents.firstIndex(where: { $0.id == activeDocumentId }) else { return }
        let next = (idx + 1) % documents.count
        activeDocumentId = documents[next].id
    }

    func activatePreviousTab() {
        guard let idx = documents.firstIndex(where: { $0.id == activeDocumentId }) else { return }
        let prev = (idx - 1 + documents.count) % documents.count
        activeDocumentId = documents[prev].id
    }

    // MARK: - Private

    private func setupOpenFileListener() {
        NotificationCenter.default.publisher(for: .openFileURL)
            .compactMap { $0.object as? URL }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.openDocument(at: url)
            }
            .store(in: &cancellables)
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
