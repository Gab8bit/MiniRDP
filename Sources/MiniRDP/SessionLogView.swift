import SwiftUI
import AppKit

/// Dettagli della sessione (default) con console opzionale attivabile da un pulsante.
struct SessionLogView: View {
    @ObservedObject var session: Session
    @State private var showConsole = false

    private var c: Connection { session.connection }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if showConsole { console } else { details }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "display")
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(statusColor.gradient, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name).font(.title2.bold())
                StatusBadge(state: session.state)
            }
            Spacer()
            Button {
                showConsole.toggle()
            } label: {
                Label(showConsole ? "Nascondi console" : "Mostra console", systemImage: "terminal")
            }
            .controlSize(.large)
            Button(role: .destructive) {
                SessionManager.shared.close(session)
            } label: {
                Label("Chiudi sessione", systemImage: "xmark.circle.fill")
            }
            .controlSize(.large)
            .disabled(session.state != .running)
        }
    }

    // MARK: Dettagli

    private var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(spacing: 0) {
                    row("Server", "\(c.host):\(c.port)", "server.rack")
                    Divider()
                    row("Utente", c.domain.isEmpty ? (c.username.isEmpty ? "—" : c.username)
                                                    : "\(c.domain)\\\(c.username)", "person")
                    Divider()
                    row("Risoluzione", c.resolutionMode == .dynamic ? "Dinamica" : "\(c.width) × \(c.height)",
                        "rectangle.expand.vertical")
                    Divider()
                    row("Schermo intero", c.fullscreen ? "Sì" : "No", "arrow.up.left.and.arrow.down.right")
                    Divider()
                    row("Appunti condivisi", c.clipboard ? "Attivi" : "Disattivati", "doc.on.clipboard")
                    Divider()
                    row("Certificato", c.ignoreCertificate ? "Ignorato" : "Verificato", "checkmark.shield")
                }
            } label: { Label("Connessione", systemImage: "network").font(.headline) }

            GroupBox {
                VStack(spacing: 0) {
                    row("Avviata alle", session.startedAt.formatted(date: .omitted, time: .standard), "clock")
                    Divider()
                    HStack {
                        Label("Durata", systemImage: "timer").foregroundStyle(.secondary)
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 1)) { ctx in
                            Text(duration(until: session.endedAt ?? ctx.date)).monospacedDigit()
                        }
                    }.padding(.vertical, 8)
                    Divider()
                    row("PID", String(session.pid), "number")
                }
            } label: { Label("Processo", systemImage: "gearshape.2").font(.headline) }

            Text("La finestra remota si apre separata (sdl-freerdp). Da qui puoi controllarne lo stato o aprire la console per il log.")
                .font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func row(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(.secondary)
            Spacer()
            Text(value).textSelection(.enabled)
        }.padding(.vertical, 8)
    }

    private func duration(until end: Date) -> String {
        let t = Int(end.timeIntervalSince(session.startedAt))
        return String(format: "%02d:%02d:%02d", t / 3600, (t / 60) % 60, t % 60)
    }

    private var statusColor: Color {
        switch session.state {
        case .running: return .green
        case .finished: return .gray
        case .failed: return .red
        }
    }

    // MARK: Console

    private var console: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Console").font(.headline)
                Spacer()
                Button("Copia log", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(session.log, forType: .string)
                }
            }
            ScrollViewReader { proxy in
                ScrollView {
                    Text(session.log)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                    Color.clear.frame(height: 1).id("bottom")
                }
                .onChange(of: session.log) { proxy.scrollTo("bottom") }
                .onAppear { proxy.scrollTo("bottom") }
            }
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
        }
    }
}

/// Pallino colorato + testo dello stato.
struct StatusBadge: View {
    let state: SessionState
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(state.label).font(.subheadline)
        }
        .padding(.horizontal, 10).padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
    }
    private var color: Color {
        switch state {
        case .running: return .green
        case .finished: return .gray
        case .failed: return .red
        }
    }
}
