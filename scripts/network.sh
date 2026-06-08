#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define file paths (Adjust these if your configs are in non-standard locations)
BSPWM_CONF="$HOME/.config/bspwm/bspwmrc"
POLYBAR_CONF="$HOME/.config/polybar/config.ini"

echo "========================================================"
echo "==> Starting Automated Network & Polybar Integration..."
echo "========================================================"

# Step 1: Install System Dependencies
echo "==> Installing NetworkManager and Applet dependencies..."
sudo apt update
sudo apt install -y network-manager network-manager-gnome

# Step 2: Fix Services & Permissions (Crucial to prevent device locks)
echo "==> Configuring system services..."
sudo systemctl stop wpa_supplicant 2>/dev/null || true
sudo systemctl disable wpa_supplicant 2>/dev/null || true

echo "==> Ensuring NetworkManager has management permissions..."
if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
    sudo sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
fi
sudo systemctl enable NetworkManager
sudo systemctl restart NetworkManager

# Step 3: Automatically Configure bspwmrc
echo "==> Injecting nm-applet background process into bspwmrc..."
if [ -f "$BSPWM_CONF" ]; then
    # Check if nm-applet is already mentioned, if not, add it before execution loop
    if ! grep -q "nm-applet" "$BSPWM_CONF"; then
        # Append to the end of bspwmrc
        echo "" >> "$BSPWM_CONF"
        echo "# Network management tray applet" >> "$BSPWM_CONF"
        echo "pgrep -x nm-applet > /dev/null || nm-applet &" >> "$BSPWM_CONF"
        echo "Successfully added nm-applet to $BSPWM_CONF"
    else
        echo "nm-applet configuration already exists in bspwmrc. Skipping."
    fi
else
    echo "Warning: bspwmrc not found at $BSPWM_CONF. Please check path."
fi

# Step 4: Automatically Update Polybar Configuration & Add Modules to the Bar
echo "==> Appending automated network modules to Polybar config..."
if [ -f "$POLYBAR_CONF" ]; then
    
    # Backup existing configuration just in case
    cp "$POLYBAR_CONF" "${POLYBAR_CONF}.bak"

    # 1. Automatically update modules-right line to include our network and tray modules
    if grep -E -q "modules-right[[:space:]]*=" "$POLYBAR_CONF"; then
        # Ensure we don't accidentally duplicate them if script is re-run
        if ! grep -q "systray" "$POLYBAR_CONF"; then
            sed -i '/modules-right[[:space:]]*=/ s/$/ wired-network wireless-network systray/' "$POLYBAR_CONF"
            echo "Successfully injected network and tray modules into modules-right line."
        else
            echo "Modules already found in modules-right line. Skipping injection."
        fi
    else
        echo "Warning: Could not find 'modules-right' line to append modules automatically."
    fi

    # 2. Append our universal, hardware-detecting network modules to the end of the file
    cat << 'EOF' >> "$POLYBAR_CONF"

;; ==========================================
;; Automated Universal Network Configuration
;; ==========================================

[module/systray]
type = internal/tray
tray-spacing = 8px

[module/wireless-network]
type = internal/network
interface = ${env:WIRELESS_INT:}
interface-type = wireless
interval = 3.0
format-connected = <label-connected>
label-connected =  %essid%
label-connected-foreground = #88c0d0
format-disconnected = 

[module/wired-network]
type = internal/network
interface = ${env:WIRED_INT:}
interface-type = wired
interval = 3.0
format-connected = <label-connected>
label-connected =  %local_ip%
label-connected-foreground = #88c0d0
format-disconnected = 
EOF
    echo "Successfully appended modules to the bottom of $POLYBAR_CONF"
else
    echo "Warning: Polybar configuration file not found at $POLYBAR_CONF."
fi

echo "========================================================"
echo "Installation and automated script configuration complete!"
echo "========================================================"