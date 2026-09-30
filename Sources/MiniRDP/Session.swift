import Foundation

enum SessionState: Equatable {
    case running
    case finished            // uscita normale o chiusa dall'utente
    case failed(Int32)       // exit code != 0 (o segnale)

    var label: String {
        switch self {
        case .running: return "In esecuzione"
        case .finished: return "Terminata"
        case .failed(let c): return "Errore (exit code \(c))"
        }
    }
}

/// Una sessione = un processo sdl-freerdp con il suo log.
final class Session: ObservableObject, Identifiable {
    let id = UUID()
    let connection: Connection
    var name: String { connection.name }
    let startedAt = Date()
    let process = Process()

    @Published var state: SessionState = .running
    @Published var endedAt: Date?
    var pid: Int32 { process.processIdentifier }
    @Published var log = ""

    /// True se l'utente ha chiesto la chiusura (così SIGTERM non conta come errore).
    var closedByUser = false

    private static let maxLogChars = 200_000

    init(connection: Connection) { self.connection = connection }

    /// Da chiamare sempre sul main thread.
    func append(_ text: String) {
        log += text
        if log.count > Self.maxLogChars { log = String(log.suffix(Self.maxLogChars)) }
    }
}
