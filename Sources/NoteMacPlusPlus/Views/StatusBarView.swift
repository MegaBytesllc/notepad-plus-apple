import SwiftUI

struct StatusBarView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var manager: DocumentManager

    var body: some View {
        HStack(spacing: 0) {
            // Left: cursor position
            Group {
                Text("Ln \(document.cursorLine), Col \(document.cursorColumn)")
                    .statusStyle()

                Divider().frame(height: 12)

                if document.selectionLength > 0 {
                    Text("Sel \(document.selectionLength)")
                        .statusStyle()
                    Divider().frame(height: 12)
                }

                Text("\(document.lineCount) lines")
                    .statusStyle()
            }

            Spacer()

            // Right: language, encoding, EOL
            Group {
                // Language picker
                Picker("", selection: languageBinding) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)
                .font(.system(size: 11))

                Divider().frame(height: 12)

                // Encoding picker
                Picker("", selection: encodingBinding) {
                    ForEach(String.Encoding.commonEncodings, id: \.rawValue) { enc in
                        Text(enc.displayName).tag(enc)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 70)
                .font(.system(size: 11))

                Divider().frame(height: 12)

                // Line ending picker
                Picker("", selection: lineEndingBinding) {
                    ForEach(LineEnding.allCases, id: \.self) { le in
                        Text(le.rawValue).tag(le)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 100)
                .font(.system(size: 11))
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .top)
        .font(.system(size: 11))
    }

    private var languageBinding: Binding<Language> {
        Binding(
            get: { document.language },
            set: { document.language = $0; manager.objectWillChange.send() }
        )
    }

    private var encodingBinding: Binding<String.Encoding> {
        Binding(
            get: { document.encoding },
            set: { document.encoding = $0 }
        )
    }

    private var lineEndingBinding: Binding<LineEnding> {
        Binding(
            get: { document.lineEnding },
            set: { document.lineEnding = $0 }
        )
    }
}

extension View {
    func statusStyle() -> some View {
        self.font(.system(size: 11))
            .padding(.horizontal, 6)
    }
}

extension String.Encoding {
    static let commonEncodings: [String.Encoding] = [
        .utf8, .utf16, .utf16LittleEndian, .utf16BigEndian,
        .isoLatin1, .isoLatin2, .windowsCP1252, .ascii
    ]

    var displayName: String {
        switch self {
        case .utf8:              return "UTF-8"
        case .utf16:             return "UTF-16"
        case .utf16LittleEndian: return "UTF-16 LE"
        case .utf16BigEndian:    return "UTF-16 BE"
        case .isoLatin1:         return "ISO-8859-1"
        case .isoLatin2:         return "ISO-8859-2"
        case .windowsCP1252:     return "Windows-1252"
        case .ascii:             return "ASCII"
        default:                 return "UTF-8"
        }
    }
}
