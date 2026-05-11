#!/usr/bin/env bash
# Builds Starling.app — a proper macOS bundle so permission prompts (Microphone,
# Accessibility, Input Monitoring) attach to a stable bundle ID instead of the
# raw `swift run` binary.
set -euo pipefail

cd "$(dirname "$0")"

swift build -c release

APP="Starling.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/Starling "$APP/Contents/MacOS/Starling"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/icon.png "$APP/Contents/Resources/icon.png"

# Ad-hoc sign so TCC (privacy daemon) tracks a stable identity for this binary.
codesign --force --deep --sign - "$APP"

echo
echo "Built $APP"
echo "Run with: open $APP"
echo
echo "First launch will prompt for Microphone. Re-grant Input Monitoring and"
echo "Accessibility for $(pwd)/$APP/Contents/MacOS/Starling (the old .build/release entries can be removed)."
