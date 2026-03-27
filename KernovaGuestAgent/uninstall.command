#!/bin/bash
set -euo pipefail

# Kernova Guest Agent — Uninstaller
#
# Removes the Kernova guest agent from a macOS virtual machine.
# Run this script from the mounted DMG:
#   ./uninstall.sh

LABEL="com.kernova.agent"
INSTALL_DIR="${HOME}/Library/Application Support/Kernova"
LAUNCHAGENTS_DIR="${HOME}/Library/LaunchAgents"
BINARY_NAME="kernova-agent"
PLIST_NAME="${LABEL}.plist"

echo "Uninstalling Kernova Guest Agent..."

# Stop the agent
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true

# Remove files
rm -f "${INSTALL_DIR}/${BINARY_NAME}"
rm -f "${LAUNCHAGENTS_DIR}/${PLIST_NAME}"

# Remove directory if empty
rmdir "${INSTALL_DIR}" 2>/dev/null || true

echo "Kernova Guest Agent has been removed."
