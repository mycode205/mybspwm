#!/bin/bash

# ============================
# SAFE INSTALL MODE (NO EXIT ON ERROR)
# ============================

FAILED_PACKAGES=()
FAILED_FILES=()

# ============================
# AUTO PERMISSION FIX
# ============================
SCRIPT_PATH="$(realpath "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================="
echo "   BSPWM SMART SAFE INSTALLER"
echo "=================================="

# ============================
# FUNCTION: INSTALL PACKAGE SAFELY
# ============================
check_install() {
    PKG=$1

    if dpkg -l | grep -q " $PKG "; then
        echo "[✔] $PKG already installed"
    else
        echo "[+] Installing $PKG ..."

        if sudo apt install -y "$PKG"; then
            echo "[✔] Installed: $PKG"
        else
            echo "[✘] FAILED: $PKG"
            FAILED_PACKAGES+=("$PKG")
        fi
    fi
}

# ============================
# FUNCTION: SAFE COPY
# ============================
safe_cp() {
    SRC=$1
    DEST=$2

    if cp -f "$SRC" "$DEST" 2>/dev/null; then
        echo "[✔] Copied: $SRC"
    else
        echo "[✘] FAILED COPY: $SRC"
        FAILED_FILES+=("$SRC")
    fi
}

# ============================
# UPDATE SYSTEM
# ============================
echo "[+] Updating system..."
sudo apt update

# ============================
# CORE PACKAGES
# ============================
echo "[+] Installing core packages..."

for pkg in \
    bspwm sxhkd polybar picom rofi alacritty feh \
    brightnessctl alsa-utils pulseaudio pavucontrol \
    xorg xinit lxappearance papirus-icon-theme \
    fonts-font-awesome fonts-inter curl git unzip x11-xserver-utils
do
    check_install "$pkg"
done

# ============================
# THUNAR MINIMAL
# ============================
echo "[+] Installing Thunar..."

for pkg in thunar thunar-volman gvfs udisks2; do
    check_install "$pkg"
done

# ============================
# BRAVE BROWSER
# ============================
echo "[+] Installing Brave..."

if ! command -v brave-browser >/dev/null; then
    sudo apt install -y curl

    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    sudo apt update
    sudo apt install -y brave-browser || FAILED_PACKAGES+=("brave-browser")
else
    echo "[✔] Brave already installed"
fi

# ============================
# FONTS
# ============================
echo "[+] Installing Nerd Fonts..."

mkdir -p "$HOME/.local/share/fonts"
cd /tmp

wget -q -O JetBrainsMono.zip \
https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

wget -q -O FiraCode.zip \
https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip

unzip -oq JetBrainsMono.zip -d "$HOME/.local/share/fonts/JetBrainsMono"
unzip -oq FiraCode.zip -d "$HOME/.local/share/fonts/FiraCode"

fc-cache -fv

# ============================
# CONFIG COPY (SAFE MODE)
# ============================
echo "[+] Copying configs..."

mkdir -p ~/.config/{alacritty,bspwm,picom,polybar,rofi/themes,sxhkd}

safe_cp "$SCRIPT_DIR/alacritty/alacritty.toml" ~/.config/alacritty/
safe_cp "$SCRIPT_DIR/bspwm/bspwmrc" ~/.config/bspwm/
safe_cp "$SCRIPT_DIR/picom/picom.conf" ~/.config/picom/
safe_cp "$SCRIPT_DIR/polybar/config.ini" ~/.config/polybar/
safe_cp "$SCRIPT_DIR/polybar/launch.sh" ~/.config/polybar/
safe_cp "$SCRIPT_DIR/rofi/config.rasi" ~/.config/rofi/
safe_cp "$SCRIPT_DIR/rofi/themes/rofi.rasi" ~/.config/rofi/themes/
safe_cp "$SCRIPT_DIR/sxhkd/sxhkdrc" ~/.config/sxhkd/

chmod +x ~/.config/bspwm/bspwmrc 2>/dev/null || true
chmod +x ~/.config/polybar/launch.sh 2>/dev/null || true

# ============================
# .xinitrc
# ============================
echo "[+] Creating .xinitrc..."

cat <<EOF > ~/.xinitrc
#!/bin/sh
exec bspwm
EOF

chmod +x ~/.xinitrc

# ============================
# FINAL REPORT
# ============================
echo ""
echo "=================================="
echo " INSTALLATION SUMMARY"
echo "=================================="

if [ ${#FAILED_PACKAGES[@]} -eq 0 ] && [ ${#FAILED_FILES[@]} -eq 0 ]; then
    echo "[✔] ALL INSTALLED SUCCESSFULLY"
else
    echo "[!] Some items failed:"
    echo ""

    if [ ${#FAILED_PACKAGES[@]} -ne 0 ]; then
        echo "Failed Packages:"
        for p in "${FAILED_PACKAGES[@]}"; do
            echo " - $p"
        done
    fi

    if [ ${#FAILED_FILES[@]} -ne 0 ]; then
        echo ""
        echo "Failed Files:"
        for f in "${FAILED_FILES[@]}"; do
            echo " - $f"
        done
    fi
fi

echo ""
echo "Run: startx"
echo "=================================="