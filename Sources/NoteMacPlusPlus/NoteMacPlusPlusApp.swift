import SwiftUI
import AppKit

@main
struct NoteMacPlusPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var documentManager = DocumentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    appDelegate.documentManager = documentManager
                }
        }
        .commands {
            FileCommands(documentManager: documentManager)
            EditCommands()
            ViewCommands(documentManager: documentManager)
            SearchCommands(documentManager: documentManager)
        }

        Settings {
            PreferencesView()
                .environmentObject(documentManager)
        }
    }
}
