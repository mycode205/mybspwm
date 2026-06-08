# =====================================================================
# NETWORKMANAGER AUTOMATION & FIXED SETUP
# =====================================================================
echo "🚀 Starting NetworkManager automation and fix setup..."

# 1. Unblock Wi-Fi globally via rfkill
echo "⚡ Unblocking Wi-Fi hardware/software locks..."
if command -v rfkill &> /dev/null; then
    rfkill unblock wifi
else
    echo "⚠️ rfkill not installed, skipping..."
fi

# 2. Fix the NetworkManager.conf configuration automatically
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
if [ -f "$NM_CONF" ]; then
    echo "⚙️ Tweaking NetworkManager config to handle all interfaces..."
    # Check if [ifupdown] section exists, if so fix managed=true
    if grep -q "\[ifupdown\]" "$NM_CONF"; then
        sed -i '/\[ifupdown\]/,/^$/ s/managed=false/managed=true/' "$NM_CONF"
    else
        # If it doesn't exist, append it cleanly to the end of the file
        echo -e "\n[ifupdown]\nmanaged=true" >> "$NM_CONF"
    fi
else
    echo "⚠️ NetworkManager.conf not found at $NM_CONF!"
fi

# 3. Handle systemd services (Disabling iwctl, wpa_supplicant, dhcpcd safely)
echo "🛑 Disabling systemd conflicting services..."
for service in iwd wpa_supplicant dhcpcd; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo "   -> Stopping and disabling ${service}.service"
        systemctl disable --now "${service}.service" 2>/dev/null
    fi
done

# 4. Forcefully kill non-systemd standalone processes (like rogue installer scripts)
echo "💀 Forcefully killing rogue background network processes..."
killall -q dhcpcd wpa_supplicant iwd iwctl 2>/dev/null

# 5. Ensure NetworkManager is turned on and radio is enabled
echo "🌐 Turning NetworkManager on..."
systemctl enable --now NetworkManager 2>/dev/null
systemctl restart NetworkManager

# Wait a brief moment for NM to initialize the card
sleep 2
nmcli radio wifi on 2>/dev/null || true
nmcli device wifi rescan 2>/dev/null || true

echo "--------------------------------------------------------"
# 6. Automated Verification Checks
echo "🔍 VERIFICATION: Checking for remaining rogue processes..."
REMAINING=$(ps aux | grep -E 'iwctl|iwd|wpa_supplicant|dhcpcd' | grep -v 'grep' | grep -v '.install.sh')

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
# =====================================================================
