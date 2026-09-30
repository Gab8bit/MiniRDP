import SwiftUI
import AppKit

/// Gestisce la chiusura dell'app: conferma se ci sono sessioni attive e termina i figli.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Scrivere su una pipe di un processo già morto non deve ammazzare l'app.
        signal(SIGPIPE, SIG_IGN)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let manager = SessionManager.shared
        guard manager.hasActiveSessions else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Ci sono sessioni RDP attive"
        alert.informativeText = "Uscendo da MiniRDP verranno chiuse tutte le sessioni in corso."
        alert.addButton(withTitle: "Chiudi tutto ed esci")
        alert.addButton(withTitle: "Annulla")
        alert.alertStyle = .warning
        guard alert.runModal() == .alertFirstButtonReturn else { return .terminateCancel }
        manager.terminateAll()
        return .terminateNow
    }
}

@main
struct MiniRDPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store = ConnectionStore()
    @StateObject private var sessions = SessionManager.shared

    var body: some Scene {
        WindowGroup("MiniRDP") {
            ContentView()
                .environmentObject(store)
                .environmentObject(sessions)
                .frame(minWidth: 820, minHeight: 520)
        }
    }
}
