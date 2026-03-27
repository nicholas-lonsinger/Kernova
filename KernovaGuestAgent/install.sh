#!/bin/bash
set -euo pipefail

# Kernova Guest Agent — Installer
#
# Installs or upgrades the Kernova guest agent on a macOS virtual machine.
# Run this script from the mounted DMG:
#   ./install.sh
#
# The agent binary is installed to ~/Library/Application Support/Kernova/
# and a LaunchAgent is registered to start it automatically at login.
# No sudo required — everything is user-space.

LABEL="com.kernova.agent"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/Library/Application Support/Kernova"
LAUNCHAGENTS_DIR="${HOME}/Library/LaunchAgents"
BINARY_NAME="kernova-agent"
PLIST_NAME="${LABEL}.plist"

echo "Installing Kernova Guest Agent..."

# Stop existing agent if running
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true

# Copy binary
mkdir -p "${INSTALL_DIR}"
cp "${SCRIPT_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
chmod 755 "${INSTALL_DIR}/${BINARY_NAME}"

# Install plist with resolved install path
mkdir -p "${LAUNCHAGENTS_DIR}"
sed "s|__INSTALL_DIR__|${INSTALL_DIR}|g" "${SCRIPT_DIR}/${PLIST_NAME}" > "${LAUNCHAGENTS_DIR}/${PLIST_NAME}"

# Register with launchd
launchctl bootstrap "gui/$(id -u)" "${LAUNCHAGENTS_DIR}/${PLIST_NAME}"

echo "Installed: $("${INSTALL_DIR}/${BINARY_NAME}" --version)"
echo "LaunchAgent registered as ${LABEL}"
