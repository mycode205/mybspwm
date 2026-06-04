#!/bin/bash

# ==================================
# INTERACTIVE FILE MANAGER CHOICE
# ==================================

echo "=================================="
echo "    CHOOSE YOUR FILE MANAGER"
echo "=================================="
echo "1) Thunar (Lightweight - Recommended for bspwm)"
echo "2) Dolphin (KDE - Feature rich, heavier)"
echo "3) Nautilus (GNOME - Clean, modern)"
echo "4) Skip / Don't install a file manager"
echo "=================================="
echo -n "Enter your choice [1-4]: "
read -r CHOICE

# Core background services needed for ANY file manager to work cleanly in bspwm
install_dependencies() {
    echo "[+] Installing core system dependencies..."
    sudo apt install -y \
        dbus-x11 \
        gvfs \
        gvfs-backends \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk
}

case $CHOICE in
    1)
        if dpkg -l | grep -q " thunar "; then
            echo "[✔] Thunar is already installed"
        else
            install_dependencies
            echo "[+] Installing Thunar (No Recommends)..."
            sudo apt install -y --no-install-recommends thunar
        fi
        ;;
    2)
        if dpkg -l | grep -q " dolphin "; then
            echo "[✔] Dolphin is already installed"
        else
            install_dependencies
            echo "[+] Installing Dolphin (No Recommends)..."
            sudo apt install -y --no-install-recommends dolphin kio-extras
        fi
        ;;
    3)
        if dpkg -l | grep -q " nautilus "; then
            echo "[✔] Nautilus is already installed"
        else
            install_dependencies
            echo "[+] Installing Nautilus (No Recommends)..."
            sudo apt install -y --no-install-recommends nautilus
        fi
        ;;
    4)
        echo "[-] Skipping file manager installation."
        ;;
    *)
        echo "[✘] Invalid choice. Skipping file manager installation."
        ;;
esac