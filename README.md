# NoteMac++

A native macOS rebuild of [Notepad++](https://notepad-plus-plus.org/), written entirely in Swift using AppKit and SwiftUI. Built to bring the full Notepad++ experience to macOS — tabs, syntax highlighting, find/replace, file browser, and more — without running Windows emulation or wrappers.

---

## Features

### Editing
- Multi-tab editing — open as many files as you want, each in its own tab
- Full undo/redo history per document
- Auto-indent — new lines inherit the leading whitespace of the line above
- Bracket matching — flash-highlights the paired bracket when your cursor lands next to one
- Word wrap toggle — soft-wrap long lines or scroll horizontally
- Zoom in/out — adjustable font size from the toolbar or View menu

### Syntax Highlighting
Highlighting for 21 languages out of the box:

| Language | Language | Language |
|---|---|---|
| Swift | Python | JavaScript |
| TypeScript | C | C++ |
| Java | Kotlin | Rust |
| Go | Ruby | PHP |
| HTML | CSS | XML |
| JSON | YAML | SQL |
| Shell Script | Markdown | Plain Text |

Each language includes keyword highlighting, string detection, comment highlighting (line and block), number literals, preprocessor directives, and decorators/annotations.

### Find & Replace
- Find Next / Find Previous / Find All
- Replace / Replace All
- **Regular expression** support (full PCRE via NSRegularExpression)
- Match case toggle
- Whole word toggle
- Wrap around toggle
- Result count feedback inline

### File Browser
- Collapsible folder tree in the left sidebar
- Open any folder as the root
- Double-click any file to open it as a new tab
- Right-click context menu: Open, Reveal in Finder, Copy Path
- File type icons per extension

### Status Bar
Every open document shows at the bottom:
- Line number and column
- Selection length (when text is selected)
- Total line count
- **Language picker** — change syntax highlighting on the fly
- **Encoding picker** — UTF-8, UTF-16, UTF-16 LE/BE, ISO-8859-1/2, Windows-1252, ASCII
- **Line ending picker** — Unix (LF), Windows (CRLF), Classic Mac (CR)

### Session Restore
When you quit and reopen the app, everything comes back exactly as you left it:
- All open tabs restored in order
- Unsaved files restored with their full content
- Saved files with unsaved edits restored with those edits intact
- Active tab preserved
- Files deleted from disk since last quit are restored as unsaved tabs

### Appearance
- Follows macOS system appearance — automatic light/dark mode switching
- Light theme modeled after Notepad++ default (white background, blue keywords, green comments)
- Dark theme modeled after VS Code Dark+ (dark gray background, muted token colors)

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ **or** Swift 5.9+ toolchain (for command-line builds)

---

## Building & Running

### Option 1 — Xcode (recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/MegaBytesllc/notepad-plus-apple.git
   cd notepad-plus-apple
   ```

2. Open the package in Xcode:
   ```bash
   open Package.swift
   ```
   Xcode will automatically resolve the package and configure the build target.

3. Select the `NoteMacPlusPlus` scheme and your Mac as the destination, then press **Run** (⌘R).

### Option 2 — Command Line

1. Clone the repository:
   ```bash
   git clone https://github.com/MegaBytesllc/notepad-plus-apple.git
   cd notepad-plus-apple
   ```

2. Build:
   ```bash
   swift build
   ```

3. Run:
   ```bash
   swift run
   ```

   Or run the compiled binary directly:
   ```bash
   .build/debug/NoteMacPlusPlus
   ```

### Option 3 — Release Build

For a faster, optimized binary:
```bash
swift build -c release
.build/release/NoteMacPlusPlus
```

---

## Project Structure

```
notemac++/
├── Package.swift                          # Swift Package Manager manifest
└── Sources/
    └── NoteMacPlusPlus/
        ├── NoteMacPlusPlusApp.swift       # App entry point, scene & menu setup
        ├── AppDelegate.swift              # macOS app lifecycle, session save on quit
        ├── Models/
        │   ├── Document.swift             # Document model (text, encoding, line endings)
        │   ├── DocumentManager.swift      # Tab management, file I/O, session persistence
        │   └── Language.swift            # 21 language definitions with keyword sets
        ├── Editor/
        │   ├── EditorTextView.swift       # NSTextView subclass (auto-indent, bracket match)
        │   ├── LineNumberRulerView.swift  # Line number gutter (NSRulerView subclass)
        │   ├── SyntaxHighlighter.swift    # Regex-based token highlighter + theme engine
        │   └── EditorView.swift           # SwiftUI wrapper for the editor
        └── Views/
            ├── ContentView.swift          # Main window layout + toolbar + menu commands
            ├── TabBarView.swift           # Notepad++-style tab bar with close buttons
            ├── StatusBarView.swift        # Bottom status bar
            ├── FindReplaceView.swift      # Find & Replace panel
            ├── FileBrowserView.swift      # Collapsible file tree sidebar
            └── PreferencesView.swift      # Settings window
```

---

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| New file | ⌘N |
| Open file | ⌘O |
| Save | ⌘S |
| Save As | ⇧⌘S |
| Save All | ⌥⌘S |
| Close tab | ⌘W |
| Find & Replace | ⌘F |
| Go To Line | ⇧⌘G |
| Zoom In | ⌘+ |
| Zoom Out | ⌘- |
| Reset Zoom | ⌘0 |
| Toggle File Browser | ⇧⌘B |

---

## License

GPL — same as the original Notepad++. See [notepad-plus-plus.org](https://notepad-plus-plus.org/) for the upstream project.
