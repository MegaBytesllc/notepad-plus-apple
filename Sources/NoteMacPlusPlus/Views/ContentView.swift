import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var manager: DocumentManager

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            EditorToolbarView()
                .environmentObject(manager)

            HSplitView {
                // Left panel: File browser
                if manager.showFileBrowser {
                    FileBrowserView()
                        .environmentObject(manager)
                        .frame(minWidth: 150, maxWidth: 300)
                }

                // Main editor area
                VStack(spacing: 0) {
                    // Tab bar
                    TabBarView()
                        .environmentObject(manager)

                    // Editor
                    if let doc = manager.activeDocument {
                        EditorView(document: doc)
                            .environmentObject(manager)
                            .id(doc.id) // Force recreate on tab switch
                    } else {
                        WelcomeView()
                            .environmentObject(manager)
                    }

                    // Find/Replace panel
                    if manager.showFindReplace {
                        FindReplaceView()
                            .environmentObject(manager)
                            .transition(.move(edge: .bottom))
                    }

                    // Status bar
                    if let doc = manager.activeDocument {
                        StatusBarView(document: doc)
                            .environmentObject(manager)
                    }
                }
                .frame(minWidth: 400)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFindReplace)) { _ in
            withAnimation { manager.showFindReplace = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .hideFindReplace)) { _ in
            withAnimation { manager.showFindReplace = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileURL)) { note in
            if let url = note.object as? URL {
                manager.openDocument(at: url)
            }
        }
    }
}

// MARK: - Toolbar

struct EditorToolbarView: View {
    @EnvironmentObject var manager: DocumentManager

    var body: some View {
        HStack(spacing: 2) {
            toolbarButton("doc.badge.plus", "New", action: manager.newDocument)
            toolbarButton("folder", "Open", action: manager.openDocument)

            Divider().frame(height: 20).padding(.horizontal, 2)

            toolbarButton("square.and.arrow.down", "Save") {
                if let doc = manager.activeDocument { manager.saveDocument(doc) }
            }
            toolbarButton("square.and.arrow.down.on.square", "Save All", action: manager.saveAllDocuments)

            Divider().frame(height: 20).padding(.horizontal, 2)

            toolbarButton("magnifyingglass", "Find & Replace") {
                withAnimation { manager.showFindReplace.toggle() }
            }

            Divider().frame(height: 20).padding(.horizontal, 2)

            // Word wrap toggle
            toolbarToggle("text.alignleft", "Word Wrap", isOn: $manager.wordWrap)

            // Line numbers toggle
            toolbarToggle("list.number", "Line Numbers", isOn: $manager.showLineNumbers)

            // Whitespace toggle
            toolbarToggle("paragraph", "Show Whitespace", isOn: $manager.showWhitespace)

            Divider().frame(height: 20).padding(.horizontal, 2)

            // Zoom
            toolbarButton("minus.magnifyingglass", "Zoom Out") {
                manager.fontSize = max(8, manager.fontSize - 1)
            }
            Text("\(Int(manager.fontSize))pt")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 34)
            toolbarButton("plus.magnifyingglass", "Zoom In") {
                manager.fontSize = min(40, manager.fontSize + 1)
            }

            Divider().frame(height: 20).padding(.horizontal, 2)

            // Sidebar toggle
            toolbarToggle("sidebar.left", "File Browser", isOn: $manager.showFileBrowser)

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder
    private func toolbarButton(_ icon: String, _ tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 26, height: 22)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    @ViewBuilder
    private func toolbarToggle(_ icon: String, _ tooltip: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 26, height: 22)
                .background(
                    isOn.wrappedValue
                        ? RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.2))
                        : nil
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Welcome Screen

struct WelcomeView: View {
    @EnvironmentObject var manager: DocumentManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("NoteMac++")
                .font(.system(size: 28, weight: .light))
            Text("A powerful text editor for macOS")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("New File") { manager.newDocument() }
                    .buttonStyle(.borderedProminent)
                Button("Open File...") { manager.openDocument() }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Menu Commands

struct FileCommands: Commands {
    let documentManager: DocumentManager

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") { documentManager.newDocument() }
                .keyboardShortcut("n")
            Button("Open...") { documentManager.openDocument() }
                .keyboardShortcut("o")
            Divider()
            Button("Save") {
                if let doc = documentManager.activeDocument {
                    documentManager.saveDocument(doc)
                }
            }
            .keyboardShortcut("s")
            Button("Save As...") {
                if let doc = documentManager.activeDocument {
                    documentManager.saveDocumentAs(doc)
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            Button("Save All") { documentManager.saveAllDocuments() }
                .keyboardShortcut("s", modifiers: [.command, .option])
            Divider()
            Button("Close") { documentManager.closeCurrentDocument() }
                .keyboardShortcut("w")
        }
    }
}

struct EditCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .undoRedo) {
            // Standard edit commands are handled by NSTextView automatically
        }
    }
}

struct ViewCommands: Commands {
    let documentManager: DocumentManager

    var body: some Commands {
        CommandMenu("View") {
            Button("Zoom In") { documentManager.fontSize = min(40, documentManager.fontSize + 1) }
                .keyboardShortcut("+")
            Button("Zoom Out") { documentManager.fontSize = max(8, documentManager.fontSize - 1) }
                .keyboardShortcut("-")
            Button("Reset Zoom") { documentManager.fontSize = 13 }
                .keyboardShortcut("0")
            Divider()
            Toggle("Word Wrap", isOn: .init(
                get: { documentManager.wordWrap },
                set: { documentManager.wordWrap = $0 }
            ))
            Toggle("Show Line Numbers", isOn: .init(
                get: { documentManager.showLineNumbers },
                set: { documentManager.showLineNumbers = $0 }
            ))
            Toggle("Show Whitespace", isOn: .init(
                get: { documentManager.showWhitespace },
                set: { documentManager.showWhitespace = $0 }
            ))
            Divider()
            Toggle("File Browser", isOn: .init(
                get: { documentManager.showFileBrowser },
                set: { documentManager.showFileBrowser = $0 }
            ))
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }
    }
}

struct SearchCommands: Commands {
    let documentManager: DocumentManager

    var body: some Commands {
        CommandMenu("Search") {
            Button("Find...") {
                NotificationCenter.default.post(name: .showFindReplace, object: nil)
            }
            .keyboardShortcut("f")

            Button("Replace...") {
                NotificationCenter.default.post(name: .showFindReplace, object: nil)
            }
            .keyboardShortcut("h")

            Button("Go To Line...") {
                goToLine(documentManager: documentManager)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }
    }

    private func goToLine(documentManager: DocumentManager) {
        let alert = NSAlert()
        alert.messageText = "Go To Line"
        alert.informativeText = "Enter a line number:"
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 22))
        alert.accessoryView = input
        alert.addButton(withTitle: "Go")
        alert.addButton(withTitle: "Cancel")
        input.becomeFirstResponder()
        if alert.runModal() == .alertFirstButtonReturn {
            // Notify editor to scroll to line
            if let lineNum = Int(input.stringValue) {
                NotificationCenter.default.post(
                    name: .init("goToLine"),
                    object: lineNum
                )
            }
        }
    }
}
