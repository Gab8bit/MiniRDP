#!/bin/bash
# Compila in release e assembla MiniRDP.app (nessun sandbox: niente entitlements, firma ad-hoc).
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=MiniRDP.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/MiniRDP "$APP/Contents/MacOS/MiniRDP"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'P'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>MiniRDP</string>
<key>CFBundleDisplayName</key><string>MiniRDP</string>
<key>CFBundleIdentifier</key><string>com.minirdp.MiniRDP</string>
<key>CFBundleExecutable</key><string>MiniRDP</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
P
codesign --force --sign - "$APP"
echo "Creata: $(pwd)/$APP"
