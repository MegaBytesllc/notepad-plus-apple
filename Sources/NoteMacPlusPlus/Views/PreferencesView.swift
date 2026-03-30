import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var manager: DocumentManager
    @AppStorage("tabWidth") private var tabWidth: Int = 4
    @AppStorage("autoIndent") private var autoIndent: Bool = true
    @AppStorage("theme") private var theme: String = "auto"

    var body: some View {
        TabView {
            // General tab
            Form {
                Section("Editor") {
                    Picker("Font Size", selection: $manager.fontSize) {
                        ForEach([8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24], id: \.self) { size in
                            Text("\(size)pt").tag(CGFloat(size))
                        }
                    }
                    Stepper("Font Size: \(Int(manager.fontSize))pt",
                            value: $manager.fontSize, in: 8...40, step: 1)

                    Picker("Tab Width", selection: $tabWidth) {
                        Text("2 spaces").tag(2)
                        Text("4 spaces").tag(4)
                        Text("8 spaces").tag(8)
                    }

                    Toggle("Auto Indent", isOn: $autoIndent)
                    Toggle("Show Line Numbers", isOn: $manager.showLineNumbers)
                    Toggle("Word Wrap", isOn: $manager.wordWrap)
                    Toggle("Show Whitespace", isOn: $manager.showWhitespace)
                }

                Section("Appearance") {
                    Picker("Color Theme", selection: $theme) {
                        Text("Auto (follows system)").tag("auto")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            .padding(20)
            .tabItem { Label("General", systemImage: "gear") }

            // File tab
            Form {
                Section("Saving") {
                    Toggle("Create Backup on Save", isOn: .constant(false))
                        .disabled(true)
                    Toggle("Trim Trailing Whitespace on Save", isOn: .constant(false))
                        .disabled(true)
                }
            }
            .padding(20)
            .tabItem { Label("Files", systemImage: "doc") }
        }
        .frame(width: 400, height: 300)
    }
}
