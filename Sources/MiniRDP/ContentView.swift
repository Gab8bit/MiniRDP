import SwiftUI

enum SidebarItem: Hashable {
    case connection(UUID)
    case session(UUID)
}

/// Sidebar (connessioni + sessioni attive) e dettaglio (form o log).
struct ContentView: View {
    @EnvironmentObject var store: ConnectionStore
    @EnvironmentObject var manager: SessionManager
    @State private var selection: SidebarItem?
    @State private var showQuickConnect = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Connessioni") {
                    ForEach(store.connections) { c in
                        ConnectionRow(connection: c) { connect(c) }
                            .tag(SidebarItem.connection(c.id))
                    }
                }
                Section("Sessioni attive") {
                    if manager.sessions.isEmpty {
                        Text("Nessuna sessione attiva").font(.callout).foregroundStyle(.secondary)
                    }
                    ForEach(manager.sessions) { s in
                        SessionRow(session: s).tag(SidebarItem.session(s.id))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
            .toolbar {
                ToolbarItem { Button("Connessione rapida", systemImage: "bolt.fill") { showQuickConnect = true } }
                ToolbarItem { Button("Nuova connessione", systemImage: "plus", action: addConnection) }
                ToolbarItem {
                    Button("Rimuovi sessioni terminate", systemImage: "trash.slash") { manager.removeFinished() }
                        .disabled(!manager.sessions.contains { $0.state != .running })
                }
            }
        } detail: {
            switch selection {
            case .connection(let id):
                if let c = store.connection(id: id) {
                    ConnectionFormView(connection: c, onDeleted: { selection = nil }, onConnect: connect)
                        .id(id)
                }
            case .session(let id):
                if let s = manager.sessions.first(where: { $0.id == id }) { SessionLogView(session: s).id(id) }
            case nil:
                ContentUnavailableView {
                    Label("MiniRDP", systemImage: "display")
                } description: {
                    Text("Scegli una connessione o una sessione dalla barra laterale.")
                } actions: {
                    Button("Connessione rapida", systemImage: "bolt.fill") { showQuickConnect = true }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                    Button("Nuova connessione", systemImage: "plus", action: addConnection).controlSize(.large)
                }
            }
        }
        .sheet(isPresented: $showQuickConnect) {
            QuickConnectView { c, pw in
                if let s = manager.connect(c, password: pw) { selection = .session(s.id) }
            }
        }
        .alert("MiniRDP", isPresented: Binding(get: { manager.alertMessage != nil },
                                                set: { if !$0 { manager.alertMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(manager.alertMessage ?? "") }
    }

    private func addConnection() {
        let c = Connection()
        store.save(c)
        selection = .connection(c.id)
    }

    private func connect(_ c: Connection) {
        if let s = manager.connect(c) { selection = .session(s.id) }
    }
}

struct ConnectionRow: View {
    let connection: Connection
    let onConnect: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "desktopcomputer")
                .foregroundStyle(.blue).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.name.isEmpty ? "Senza nome" : connection.name).fontWeight(.medium)
                Text(connection.host.isEmpty ? "Host non impostato" : "\(connection.host):\(connection.port)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onConnect) { Image(systemName: "play.circle.fill").font(.title3) }
                .buttonStyle(.borderless).foregroundStyle(.green)
                .help("Connetti (nuova sessione)")
                .disabled(connection.host.isEmpty)
        }
        .padding(.vertical, 2)
    }
}

struct SessionRow: View {
    @ObservedObject var session: Session
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name).fontWeight(.medium)
                Text(session.state.label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if session.state == .running {
                Button(action: { SessionManager.shared.close(session) }) {
                    Image(systemName: "xmark.circle.fill").font(.title3)
                }
                .buttonStyle(.borderless).foregroundStyle(.red)
                .help("Chiudi sessione")
            }
        }
        .padding(.vertical, 2)
    }
    private var color: Color {
        switch session.state {
        case .running: return .green
        case .finished: return .gray
        case .failed: return .red
        }
    }
}
