#!/usr/bin/env zsh
set -e
cd "$(dirname "$0")"

APP_NAME="MacRufus"
APP_BUNDLE="${APP_NAME}.app"
EXECUTABLE="MacRufusSwift"

#echo "==> Generating app icon..."
#swift generate_icon.swift
#iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns
#echo "  ✓ Resources/AppIcon.icns created"

echo "==> Building Swift package (release)..."
swift build -c release
echo "  ✓ Build complete"

echo "==> Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/${EXECUTABLE}"   "${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE}"
cp "Resources/Info.plist"           "${APP_BUNDLE}/Contents/Info.plist"
cp "Resources/AppIcon.icns"         "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

chmod +x "${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE}"

echo ""
echo "✅  ${APP_BUNDLE} is ready!"
echo "   To launch:  open ${APP_BUNDLE}"
