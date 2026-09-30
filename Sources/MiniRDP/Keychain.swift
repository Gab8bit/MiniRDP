import Foundation
import Security

/// Wrapper minimale sul Keychain (generic password). Account = UUID della connessione.
enum Keychain {
    private static let service = "com.minirdp.MiniRDP"

    private static func query(_ id: UUID) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: id.uuidString]
    }

    static func password(for id: UUID) -> String? {
        var q = query(id)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Salva (o sostituisce) la password; stringa vuota = cancella.
    static func setPassword(_ pw: String, for id: UUID) {
        SecItemDelete(query(id) as CFDictionary)
        guard !pw.isEmpty else { return }
        var q = query(id)
        q[kSecValueData as String] = Data(pw.utf8)
        SecItemAdd(q as CFDictionary, nil)
    }

    static func deletePassword(for id: UUID) {
        SecItemDelete(query(id) as CFDictionary)
    }
}
