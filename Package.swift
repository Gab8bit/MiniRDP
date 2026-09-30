// swift-tools-version:5.9
import PackageDescription

// Eseguibile SwiftUI puro, nessuna dipendenza esterna.
// Il bundle .app viene assemblato da build_app.sh.
let package = Package(
    name: "MiniRDP",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MiniRDP", path: "Sources/MiniRDP")
    ]
)
