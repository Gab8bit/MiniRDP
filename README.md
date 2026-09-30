# MiniRDP

Launcher nativo macOS (SwiftUI) per connessioni RDP. Non implementa il protocollo: lancia il client `sdl-freerdp` di FreeRDP.

**Sito:** https://gab8bit.github.io/MiniRDP/

## Funzioni
- Connessione rapida (IP, utente, password) con certificato ignorato, risoluzione dinamica e appunti attivi
- Connessioni salvate; password nel Keychain (passata a FreeRDP via stdin)
- Multi-sessione, stato e console log per sessione
- Opzioni per connessione: risoluzione, schermo intero, appunti, certificato, argomenti extra

## Requisiti
macOS 14+, `brew install freerdp`. Download: [ultima release](https://github.com/Gab8bit/MiniRDP/releases/latest/download/MiniRDP-macOS.zip). Al primo avvio: Impostazioni di Sistema → Privacy e sicurezza → **Apri comunque**.

## Build
```bash
./build_app.sh   # produce MiniRDP.app (firma ad-hoc, senza App Sandbox)
open MiniRDP.app
```

## Struttura
`Sources/MiniRDP`: `Connection` (modello), `ConnectionStore`, `Keychain`, `Session`, `SessionManager` (processi) e le View SwiftUI.
