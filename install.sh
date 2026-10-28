#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Mapping"
BUILD_APP_PATH="${ROOT_DIR}/build/${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_NAME}.app"

"${ROOT_DIR}/build.sh"

osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
sleep 0.5

rm -rf "${INSTALL_PATH}"
cp -R "${BUILD_APP_PATH}" "${INSTALL_PATH}"
touch "${INSTALL_PATH}"

echo "==> Installed and signed to ${INSTALL_PATH}"
