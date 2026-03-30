import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var manager: DocumentManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(manager.documents) { doc in
                    TabItem(doc: doc, isActive: doc.id == manager.activeDocumentId)
                        .environmentObject(manager)
                }
            }
        }
        .frame(height: 30)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }
}

struct TabItem: View {
    @ObservedObject var doc: Document
    @EnvironmentObject var manager: DocumentManager
    let isActive: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            // Modified indicator (dot)
            Circle()
                .fill(doc.isModified ? Color.orange : Color.clear)
                .frame(width: 6, height: 6)

            Text(doc.displayName)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: 160, alignment: .leading)
                .foregroundColor(isActive ? .primary : .secondary)

            // Close button
            Button {
                manager.closeDocument(doc)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(isHovering ? .primary : .secondary)
                    .frame(width: 14, height: 14)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isHovering ? Color(NSColor.quaternaryLabelColor) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tabBackground)
        .overlay(tabBorder, alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.activeDocumentId = doc.id
        }
        .onHover { hover in
            isHovering = hover
        }
        .contextMenu {
            Button("Close") { manager.closeDocument(doc) }
            Button("Close All") {
                let all = manager.documents
                for d in all { manager.closeDocument(d) }
            }
            Divider()
            Button("Save") { manager.saveDocument(doc) }
            Button("Save As...") { manager.saveDocumentAs(doc) }
            if let url = doc.fileURL {
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

    @ViewBuilder
    private var tabBackground: some View {
        if isActive {
            Color(NSColor.controlBackgroundColor)
        } else {
            Color(NSColor.windowBackgroundColor)
        }
    }

    @ViewBuilder
    private var tabBorder: some View {
        if isActive {
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 2)
        } else {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1)
        }
    }
}
