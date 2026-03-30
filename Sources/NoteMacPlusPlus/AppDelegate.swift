import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // Injected by the App struct so the delegate can save the session on quit
    var documentManager: DocumentManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        documentManager?.saveSession()
    }

    // Also save when the last window is hidden / app resigns active,
    // so a force-quit still captures the latest state.
    func applicationWillResignActive(_ notification: Notification) {
        documentManager?.saveSession()
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        NotificationCenter.default.post(
            name: .openFileURL,
            object: URL(fileURLWithPath: filename)
        )
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for filename in filenames {
            NotificationCenter.default.post(
                name: .openFileURL,
                object: URL(fileURLWithPath: filename)
            )
        }
    }
}

extension Notification.Name {
    static let openFileURL = Notification.Name("openFileURL")
    static let showFindReplace = Notification.Name("showFindReplace")
    static let hideFindReplace = Notification.Name("hideFindReplace")
}
