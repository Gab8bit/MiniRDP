import SwiftUI

/// Form di modifica. Lavora su una copia (draft) e salva solo su "Salva".
struct ConnectionFormView: View {
    @EnvironmentObject var store: ConnectionStore
    @State private var draft: Connection
    @State private var password: String
    @State private var confirmDelete = false
    let onDeleted: () -> Void
    let onConnect: (Connection) -> Void

    init(connection: Connection, onDeleted: @escaping () -> Void, onConnect: @escaping (Connection) -> Void) {
        _draft = State(initialValue: connection)
        _password = State(initialValue: Keychain.password(for: connection.id) ?? "")
        self.onDeleted = onDeleted
        self.onConnect = onConnect
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    LabeledContent("Nome") { TextField("", text: $draft.name, prompt: Text("Es. Server ufficio")) }
                    LabeledContent("Host / IP") { TextField("", text: $draft.host, prompt: Text("192.168.1.10")) }
                    LabeledContent("Porta") {
                        TextField("", value: $draft.port, format: .number.grouping(.never)).frame(width: 90)
                    }
                } header: { Label("Server", systemImage: "server.rack") }

                Section {
                    LabeledContent("Utente") { TextField("", text: $draft.username, prompt: Text("utente")) }
                    LabeledContent("Dominio") { TextField("", text: $draft.domain, prompt: Text("Opzionale")) }
                    LabeledContent("Password") { SecureField("", text: $password, prompt: Text("Salvata nel Keychain")) }
                } header: { Label("Credenziali", systemImage: "key") }

                Section {
                    Picker("Risoluzione", selection: $draft.resolutionMode) {
                        ForEach(ResolutionMode.allCases) { Text($0.label).tag($0) }
                    }
                    if draft.resolutionMode == .fixed {
                        LabeledContent("Dimensione") {
                            HStack {
                                TextField("", value: $draft.width, format: .number.grouping(.never)).frame(width: 70)
                                Text("×")
                                TextField("", value: $draft.height, format: .number.grouping(.never)).frame(width: 70)
                            }
                        }
                    }
                    Toggle("Condividi appunti", isOn: $draft.clipboard)
                    Toggle("Schermo intero", isOn: $draft.fullscreen)
                    Toggle("Ignora certificato", isOn: $draft.ignoreCertificate)
                } header: { Label("Schermo e opzioni", systemImage: "slider.horizontal.3") }

                Section {
                    LabeledContent("Argomenti extra") {
                        TextField("", text: $draft.extraArguments, prompt: Text("/gfx:AVC444 +auto-reconnect"))
                    }
                    Toggle("Password con /p: (visibile in ps)", isOn: $draft.passwordViaArgument)
                } header: { Label("Avanzate", systemImage: "wrench.and.screwdriver") } footer: {
                    Text("Di default la password viene passata via stdin, senza comparire nella lista dei processi.")
                }
            }
            .formStyle(.grouped)
            .multilineTextAlignment(.trailing)

            Divider()
            HStack {
                Button("Elimina", systemImage: "trash", role: .destructive) { confirmDelete = true }
                Spacer()
                Button("Salva", action: save).controlSize(.large)
                Button("Salva e connetti", systemImage: "play.fill") { save(); onConnect(draft) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.host.isEmpty)
            }
            .padding(14)
        }
        .navigationTitle(draft.name.isEmpty ? "Connessione" : draft.name)
        .confirmationDialog("Eliminare \"\(draft.name)\"?", isPresented: $confirmDelete) {
            Button("Elimina", role: .destructive) {
                store.delete(draft.id)
                onDeleted()
            }
        }
    }

    private func save() {
        store.save(draft)
        Keychain.setPassword(password, for: draft.id)
    }
}
