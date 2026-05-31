#!/bin/bash

set -e

# ============================
# AUTO PERMISSION FIX
# ============================
SCRIPT_PATH="$(realpath "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null || true

echo "=================================="
echo "   BSPWM SMART INSTALL SCRIPT"
echo "=================================="

# ----------------------------
# Function: check and install
# ----------------------------
check_install() {
    PKG=$1

    if dpkg -l | grep -q " $PKG "; then
        echo "[✔] $PKG already installed"
    else
        echo "[!] $PKG NOT installed → installing..."
        sudo apt install -y "$PKG"
    fi
}

# ----------------------------
# Update system
# ----------------------------
echo "[+] Updating system..."
sudo apt update

# ----------------------------
# Core packages
# ----------------------------
echo "[+] Installing core packages..."

for pkg in \
    bspwm sxhkd polybar picom rofi alacritty feh \
    brightnessctl alsa-utils pulseaudio pavucontrol \
    xorg xinit lxappearance papirus-icon-theme \
    fonts-font-awesome fonts-inter curl git unzip x11-xserver-utils
do
    check_install "$pkg"
done

# ----------------------------
# Thunar (minimal)
# ----------------------------
echo "[+] Installing Thunar (minimal)..."

for pkg in thunar thunar-volman gvfs udisks2; do
    check_install "$pkg"
done

# ----------------------------
# Brave Browser
# ----------------------------
echo "[+] Installing Brave Browser..."

if ! command -v brave-browser >/dev/null; then
    echo "[!] Brave not found → installing..."

    sudo apt install -y curl

    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    sudo apt update
    sudo apt install -y brave-browser
else
    echo "[✔] Brave already installed"
fi

# ----------------------------
# Fonts
# ----------------------------
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

# ----------------------------
# Config copy
# ----------------------------
echo "[+] Copying configs..."

mkdir -p ~/.config/{alacritty,bspwm,picom,polybar,rofi/themes,sxhkd}

cp -f alacritty/alacritty.toml ~/.config/alacritty/
cp -f bspwm/bspwmrc ~/.config/bspwm/
cp -f picom/picom.conf ~/.config/picom/
cp -f polybar/config.ini ~/.config/polybar/
cp -f polybar/launch.sh ~/.config/polybar/
cp -f rofi/config.rasi ~/.config/rofi/
cp -f rofi/themes/rofi.rasi ~/.config/rofi/themes/
cp -f sxhkd/sxhkdrc ~/.config/sxhkd/

chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/polybar/launch.sh

# ----------------------------
# .xinitrc
# ----------------------------
echo "[+] Creating .xinitrc..."

cat <<EOF > ~/.xinitrc
#!/bin/sh
exec bspwm
EOF

chmod +x ~/.xinitrc

# ----------------------------
# Final message
# ----------------------------
echo "=================================="
echo "[✔] INSTALLATION COMPLETE!"
echo "Run: startx"
echo "=================================="