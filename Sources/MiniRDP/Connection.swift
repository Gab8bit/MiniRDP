import Foundation

/// Modalità di risoluzione della sessione.
enum ResolutionMode: String, Codable, CaseIterable, Identifiable {
    case dynamic, fixed
    var id: String { rawValue }
    var label: String { self == .dynamic ? "Dinamica (segue la finestra)" : "Fissa" }
}

/// Una connessione salvata. La password NON è qui: sta nel Keychain (vedi Keychain.swift).
struct Connection: Identifiable, Codable, Hashable {
    var id = UUID()
    var name = "Nuova connessione"
    var host = ""
    var port = 3389
    var username = ""
    var domain = ""

    var resolutionMode: ResolutionMode = .dynamic
    var width = 1600
    var height = 900
    var clipboard = true
    var fullscreen = false
    var ignoreCertificate = true
    var extraArguments = ""

    /// Fallback meno sicuro: password con /p: (visibile in `ps`) invece che via stdin.
    var passwordViaArgument = false

    /// Costruisce gli argomenti per sdl-freerdp.
    /// - Parameter password: se presente, viene passata via stdin (default) o /p: (se abilitato).
    func arguments(password: String?) -> [String] {
        var args = ["/v:\(host):\(port)"]
        if !username.isEmpty { args.append("/u:\(username)") }
        if !domain.isEmpty { args.append("/d:\(domain)") }
        args.append(clipboard ? "+clipboard" : "-clipboard")
        switch resolutionMode {
        case .dynamic: args.append("/dynamic-resolution")
        case .fixed: args.append("/size:\(width)x\(height)")
        }
        if fullscreen { args.append("/f") }
        if ignoreCertificate { args.append("/cert:ignore") }
        if let password, !password.isEmpty {
            args.append(passwordViaArgument ? "/p:\(password)" : "/from-stdin:force")
        }
        args += Connection.splitArguments(extraArguments)
        return args
    }

    /// Spezza una stringa in argomenti rispettando apici singoli/doppi (niente shell coinvolta).
    static func splitArguments(_ s: String) -> [String] {
        var result: [String] = [], current = "", quote: Character? = nil, has = false
        for ch in s {
            if let q = quote {
                if ch == q { quote = nil } else { current.append(ch) }
            } else if ch == "\"" || ch == "'" {
                quote = ch; has = true
            } else if ch.isWhitespace {
                if has || !current.isEmpty { result.append(current); current = ""; has = false }
            } else {
                current.append(ch)
            }
        }
        if has || !current.isEmpty { result.append(current) }
        return result
    }
}
