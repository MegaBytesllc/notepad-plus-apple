import SwiftUI
import AppKit

struct FileBrowserView: View {
    @EnvironmentObject var manager: DocumentManager
    @State private var rootURL: URL? = FileManager.default.homeDirectoryForCurrentUser
    @State private var expandedFolders: Set<URL> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("File Browser")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)

                Spacer()

                Button {
                    chooseFolder()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
                .help("Open Folder")
            }
            .frame(height: 26)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            // Tree
            if let root = rootURL {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        FolderRow(url: root, depth: 0, expandedFolders: $expandedFolders)
                            .environmentObject(manager)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("No folder open")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Button("Open Folder") { chooseFolder() }
                        .padding(.top, 4)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 180, idealWidth: 220)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            rootURL = panel.url
            expandedFolders = []
        }
    }
}

// MARK: - FolderRow / FileRow

struct FolderRow: View {
    let url: URL
    let depth: Int
    @Binding var expandedFolders: Set<URL>
    @EnvironmentObject var manager: DocumentManager

    private var isExpanded: Bool { expandedFolders.contains(url) }

    private var children: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ).sorted { a, b in
            let aIsDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            let bIsDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            if aIsDir != bIsDir { return aIsDir }
            return a.lastPathComponent.localizedCaseInsensitiveCompare(b.lastPathComponent) == .orderedAscending
        }) ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header row
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 10)
                    .foregroundColor(.secondary)

                Image(systemName: isExpanded ? "folder.open" : "folder")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text(url.lastPathComponent)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Spacer()
            }
            .padding(.leading, CGFloat(depth) * 12 + 6)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isExpanded {
                        expandedFolders.remove(url)
                    } else {
                        expandedFolders.insert(url)
                    }
                }
            }

            // Children
            if isExpanded {
                ForEach(children, id: \.self) { child in
                    let isDir = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                    if isDir {
                        FolderRow(url: child, depth: depth + 1, expandedFolders: $expandedFolders)
                            .environmentObject(manager)
                    } else {
                        FileRow(url: child, depth: depth + 1)
                            .environmentObject(manager)
                    }
                }
            }
        }
    }
}

struct FileRow: View {
    let url: URL
    let depth: Int
    @EnvironmentObject var manager: DocumentManager
    @State private var isHovering = false

    private var fileIcon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift":                return "swift"
        case "py":                   return "doc.text"
        case "js", "ts", "jsx","tsx": return "doc.text"
        case "html", "htm":          return "globe"
        case "css", "scss":          return "paintbrush"
        case "json":                 return "curlybraces"
        case "md", "markdown":       return "doc.richtext"
        case "sh", "bash":           return "terminal"
        case "png", "jpg", "jpeg",
             "gif", "svg", "pdf":   return "photo"
        default:                     return "doc"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: fileIcon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 14)

            Text(url.lastPathComponent)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()
        }
        .padding(.leading, CGFloat(depth) * 12 + 6 + 10)
        .padding(.vertical, 3)
        .background(isHovering ? Color(NSColor.selectedContentBackgroundColor).opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(count: 2) {
            manager.openDocument(at: url)
        }
        .onTapGesture(count: 1) { /* single tap: preview */ }
        .contextMenu {
            Button("Open") { manager.openDocument(at: url) }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.path, forType: .string)
            }
        }
    }
}
