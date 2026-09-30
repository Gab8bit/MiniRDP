import Foundation

/// Elenco delle connessioni salvate, persistito come JSON in Application Support (senza password).
final class ConnectionStore: ObservableObject {
    @Published private(set) var connections: [Connection] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MiniRDP", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("connections.json")
    }()

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let list = try? JSONDecoder().decode([Connection].self, from: data) {
            connections = list
        }
    }

    func connection(id: UUID) -> Connection? { connections.first { $0.id == id } }

    /// Inserisce o aggiorna.
    func save(_ c: Connection) {
        if let i = connections.firstIndex(where: { $0.id == c.id }) { connections[i] = c }
        else { connections.append(c) }
        persist()
    }

    func delete(_ id: UUID) {
        connections.removeAll { $0.id == id }
        Keychain.deletePassword(for: id)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(connections) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
