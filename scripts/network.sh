#!/bin/bash

# =====================================================================
# NETWORKMANAGER AUTOMATION & FIXED SETUP (STANDALONE / SUB-SCRIPT)
# =====================================================================
echo "🚀 Starting NetworkManager automation and fix setup..."

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ This script requires root privileges to modify network states."
    echo "Please run with sudo."
    exit 1
fi

# 1. Ensure NetworkManager and rfkill are installed first (Crucial for fresh setups)
MISSING_TOOLS=()
if ! command -v rfkill &> /dev/null; then MISSING_TOOLS+=("rfkill"); fi
if ! command -v network-manager &> /dev/null && ! command -v nmcli &> /dev/null; then MISSING_TOOLS+=("network-manager"); fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "⚙️ Missing core assets detected. Installing: ${MISSING_TOOLS[*]}..."
    apt update >/dev/null 2>&1
    # Strict minimal pull to avoid pulling down full heavy desktops/recommends
    apt install -y --no-install-recommends "${MISSING_TOOLS[@]}" >/dev/null 2>&1
fi

# 2. Unblock Wi-Fi globally via rfkill
echo "⚡ Unblocking Wi-Fi hardware/software locks..."
if command -v rfkill &> /dev/null; then
    rfkill unblock wifi
fi

# 3. Fix the NetworkManager.conf configuration automatically
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
if [ -f "$NM_CONF" ]; then
    echo "⚙️ Tweaking NetworkManager config to handle all interfaces..."
    if grep -q "\[ifupdown\]" "$NM_CONF"; then
        sed -i '/\[ifupdown\]/,/^$/ s/managed=false/managed=true/' "$NM_CONF"
    else
        echo -e "\n[ifupdown]\nmanaged=true" >> "$NM_CONF"
    fi
else
    echo "⚠️ NetworkManager.conf not found at $NM_CONF!"
fi

# 4. Handle systemd services (Disabling iwctl, wpa_supplicant, dhcpcd safely)
echo "🛑 Disabling systemd conflicting services..."
for service in iwd wpa_supplicant dhcpcd; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo "   -> Stopping and disabling ${service}.service"
        systemctl disable --now "${service}.service" 2>/dev/null || true
    fi
done

# 5. Forcefully kill non-systemd standalone processes
echo "💀 Forcefully killing rogue background network processes..."
killall -q dhcpcd wpa_supplicant iwd iwctl 2>/dev/null || true

# 6. Ensure NetworkManager is turned on and radio is enabled
echo "🌐 Turning NetworkManager on..."
systemctl enable --now NetworkManager 2>/dev/null || true
systemctl restart NetworkManager

# Wait a brief moment for NM to initialize the card physical layer
sleep 2.5
nmcli radio wifi on 2>/dev/null || true
nmcli device wifi rescan 2>/dev/null || true

echo "--------------------------------------------------------"
# 7. Automated Verification Checks
echo "🔍 VERIFICATION: Checking for remaining rogue processes..."
REMAINING=$(ps aux | grep -E 'iwctl|iwd|wpa_supplicant|dhcpcd' | grep -v 'grep' | grep -v 'network.sh')

if [ -z "$REMAINING" ]; then
    echo "   ✅ Clean slate! No rogue network managers running."
else
    echo "   ⚠️ Warning: Some processes are stubbornly active:"
    echo "$REMAINING"
fi

echo -e "\n🔍 VERIFICATION: Systemd Status Overview:"
systemctl status iwd wpa_supplicant dhcpcd NetworkManager 2>/dev/null | grep -E '●|Active:' || true

echo "--------------------------------------------------------"
echo "🎉 Network setup automated successfully!"