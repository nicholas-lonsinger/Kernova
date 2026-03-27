#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  Kernova Guest Agent — Installer"
echo "========================================"
echo ""
echo "This will install the Kernova guest agent on this Mac."
echo ""
echo "  Binary:      ~/Library/Application Support/Kernova/kernova-agent"
echo "  LaunchAgent: ~/Library/LaunchAgents/com.kernova.agent.plist"
echo ""
echo "To uninstall later, run uninstall.command from this disk."
echo ""
read -p "Proceed with installation? [y/N] " choice
if [[ "${choice}" =~ ^[Yy]$ ]]; then
    echo ""
    echo "----------------------------------------"

    LABEL="com.kernova.agent"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    INSTALL_DIR="${HOME}/Library/Application Support/Kernova"
    LAUNCHAGENTS_DIR="${HOME}/Library/LaunchAgents"
    BINARY_NAME="kernova-agent"
    PLIST_NAME="${LABEL}.plist"

    echo "Installing..."

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

    echo ""
    echo "Installed: $("${INSTALL_DIR}/${BINARY_NAME}" --version)"
    echo "LaunchAgent registered as ${LABEL}"
    echo ""
    echo "========================================"
    echo "  Installation complete."
    echo "========================================"
else
    echo ""
    echo "Cancelled — no changes were made."
fi

echo ""
read -p "Press Enter to exit..."
