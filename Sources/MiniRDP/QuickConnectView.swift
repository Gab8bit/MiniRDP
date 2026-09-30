import SwiftUI

/// Connessione immediata: IP/host, utente, password. Non salva nulla (password mai nel Keychain).
/// Default: ignora certificato, risoluzione dinamica, clipboard attiva.
struct QuickConnectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var host = ""
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focus: Field?
    private enum Field { case host, user, pass }
    let onConnect: (Connection, String) -> Void

    private var canConnect: Bool { !host.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title2).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading) {
                    Text("Connessione rapida").font(.title3.bold())
                    Text("Non viene salvato nulla").font(.callout).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                field("Indirizzo", "network") {
                    TextField("192.168.1.10 oppure host:porta", text: $host).focused($focus, equals: .host)
                }
                field("Utente", "person") {
                    TextField("utente oppure DOMINIO\\utente", text: $username).focused($focus, equals: .user)
                }
                field("Password", "key") {
                    SecureField("Password", text: $password).focused($focus, equals: .pass)
                }
            }

            HStack(spacing: 8) {
                chip("Certificato ignorato", "checkmark.shield")
                chip("Risoluzione dinamica", "rectangle.expand.vertical")
                chip("Appunti attivi", "doc.on.clipboard")
            }

            HStack {
                Spacer()
                Button("Annulla") { dismiss() }.keyboardShortcut(.cancelAction).controlSize(.large)
                Button("Connetti", action: connect)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canConnect)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { focus = .host }
    }

    /// Riga con etichetta sopra e campo con icona.
    private func field<F: View>(_ title: String, _ icon: String,
                                @ViewBuilder content: () -> F) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 18)
                content().textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
        }
    }

    private func chip(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption).foregroundStyle(.secondary)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.quaternary.opacity(0.5), in: Capsule())
    }

    private func connect() {
        guard canConnect else { return }
        var c = Connection()
        var h = host.trimmingCharacters(in: .whitespaces)
        // "host:porta" (solo se c'è un unico ':' per non rompere gli IPv6)
        let parts = h.split(separator: ":", omittingEmptySubsequences: false)
        if parts.count == 2, let p = Int(parts[1]) { h = String(parts[0]); c.port = p }
        c.host = h
        c.name = h
        // "DOMINIO\utente" → /d: e /u:
        if let i = username.firstIndex(of: "\\") {
            c.domain = String(username[..<i])
            c.username = String(username[username.index(after: i)...])
        } else {
            c.username = username
        }
        c.ignoreCertificate = true
        c.resolutionMode = .dynamic
        c.clipboard = true
        dismiss()
        onConnect(c, password)
    }
}
