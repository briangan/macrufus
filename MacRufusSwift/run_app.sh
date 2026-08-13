#!/usr/bin/env zsh
APP_NAME="MacRufus"
APP_BUNDLE="${APP_NAME}.app"
EXECUTABLE="MacRufusSwift"

echo "Launching ${APP_NAME}"
"${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE}" 2>&1 
