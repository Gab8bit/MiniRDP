import Foundation
import AppKit

/// Lancia e tiene traccia dei processi sdl-freerdp.
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var sessions: [Session] = []
    /// Messaggio d'errore da mostrare in un alert (binario mancante, launch fallito...).
    @Published var alertMessage: String?

    var hasActiveSessions: Bool { sessions.contains { $0.state == .running } }

    /// Cerca il client FreeRDP nei percorsi Homebrew.
    static func findBinary() -> URL? {
        for dir in ["/opt/homebrew/bin", "/usr/local/bin"] {
            for name in ["sdl-freerdp", "sdl-freerdp3"] {
                let p = "\(dir)/\(name)"
                if FileManager.default.isExecutableFile(atPath: p) { return URL(fileURLWithPath: p) }
            }
        }
        return nil
    }

    /// Avvia una nuova sessione (si può chiamare più volte anche per lo stesso server).
    @discardableResult
    func connect(_ c: Connection, password passwordOverride: String? = nil) -> Session? {
        guard let binary = Self.findBinary() else {
            alertMessage = "sdl-freerdp non trovato in /opt/homebrew/bin né in /usr/local/bin.\n\nInstallalo da Terminale con:\n\nbrew install freerdp"
            return nil
        }
        // Password esplicita (connessione rapida) oppure quella nel Keychain.
        let password = passwordOverride ?? Keychain.password(for: c.id)
        let session = Session(connection: c)
        let p = session.process
        p.executableURL = binary
        p.arguments = c.arguments(password: password)
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin")
        p.environment = env

        let out = Pipe(), err = Pipe(), inPipe = Pipe()
        p.standardOutput = out
        p.standardError = err
        p.standardInput = inPipe

        // Log: stdout e stderr confluiscono nella stessa vista.
        for pipe in [out, err] {
            pipe.fileHandleForReading.readabilityHandler = { h in
                let data = h.availableData
                if data.isEmpty { h.readabilityHandler = nil; return }
                let text = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async { session.append(text) }
            }
        }

        p.terminationHandler = { proc in
            // Svuota quanto resta nelle pipe prima di chiudere.
            for pipe in [out, err] {
                pipe.fileHandleForReading.readabilityHandler = nil
                if let rest = try? pipe.fileHandleForReading.readToEnd(), !rest.isEmpty {
                    let t = String(decoding: rest, as: UTF8.self)
                    DispatchQueue.main.async { session.append(t) }
                }
            }
            DispatchQueue.main.async {
                let code = proc.terminationStatus
                let signaled = proc.terminationReason == .uncaughtSignal
                // 0 = uscita pulita; 1/2 = disconnessione/logoff richiesti dal server o dall'utente;
                // 131 = FreeRDP quando l'utente chiude la finestra SDL. Nessuno di questi è un errore.
                let benign: Set<Int32> = [0, 1, 2, 131]
                if session.closedByUser || (benign.contains(code) && !signaled) {
                    session.state = .finished
                } else {
                    session.state = .failed(code)
                }
                session.endedAt = Date()
                session.append("\n[MiniRDP] Processo terminato (\(session.state.label))\n")
                self.objectWillChange.send()
            }
        }

        let shownArgs = p.arguments!.map { $0.hasPrefix("/p:") ? "/p:********" : $0 }
        session.append("[MiniRDP] \(binary.path) \(shownArgs.joined(separator: " "))\n")

        do {
            try p.run()
        } catch {
            alertMessage = "Impossibile avviare \(binary.path):\n\(error.localizedDescription)"
            return nil
        }

        // Password via stdin (non compare in `ps`). Se il processo muore subito, SIGPIPE è ignorato (vedi App).
        if let password, !password.isEmpty, !c.passwordViaArgument {
            try? inPipe.fileHandleForWriting.write(contentsOf: Data((password + "\n").utf8))
        }
        try? inPipe.fileHandleForWriting.close()

        sessions.append(session)
        return session
    }

    /// Chiude una sessione (SIGTERM).
    func close(_ s: Session) {
        guard s.state == .running else { return }
        s.closedByUser = true
        s.process.terminate()
    }

    func terminateAll() {
        for s in sessions where s.state == .running { close(s) }
    }

    /// Rimuove dall'elenco le sessioni non più attive.
    func removeFinished() {
        sessions.removeAll { $0.state != .running }
    }
}
