#!/bin/bash

# ============================
# SAFE INSTALL MODE 
# ============================

FAILED_PACKAGES=()
FAILED_FILES=()

SCRIPT_PATH="$(realpath "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WALLPAPER="$HOME/Pictures/wallpapers/Debian.jpg"

echo "=================================="
echo "   BSPWM SMART SAFE INSTALLER"
echo "=================================="

# ============================
# INSTALL FUNCTION
# ============================
check_install() {
    PKG=$1
    EXTRA=${2:-}

    if dpkg -l | grep -q " $PKG "; then
        echo "[✔] $PKG already installed"
    else
        echo "[+] Installing $PKG ..."

        if sudo apt install -y $EXTRA "$PKG"; then
            echo "[✔] Installed: $PKG"
        else
            echo "[✘] FAILED: $PKG"
            FAILED_PACKAGES+=("$PKG")
        fi
    fi
}

# ============================
# SAFE COPY
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
    breeze-icon-theme bibata-cursor-theme fastfetch \
    fonts-font-awesome fonts-inter curl git unzip x11-xserver-utils \
    libinput-tools
do
    check_install "$pkg"
done

# ============================
# TOUCHPAD CONFIG
# ============================
echo "[+] Configuring touchpad..."

sudo mkdir -p /etc/X11/xorg.conf.d 2>/dev/null || true

sudo tee /etc/X11/xorg.conf.d/30-touchpad.conf >/dev/null <<EOF
Section "InputClass"
    Identifier "Touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"

    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "DisableWhileTyping" "true"
    Option "ClickMethod" "clickfinger"
EndSection
EOF

echo "[✔] Touchpad config applied"

# ============================
# BRAVE BROWSER
# ============================
echo "[+] Installing Brave..."

if ! command -v brave-browser >/dev/null; then
    sudo apt install -y curl

    sudo curl -fsSLo /usr/share/keyrings/brave-browser.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave.list

    sudo apt update
    sudo apt install -y brave-browser || FAILED_PACKAGES+=("brave-browser")
else
    echo "[✔] Brave already installed"
fi

# ============================
# 🔥 FONTS (FIXED + SAFE)
# ============================
echo "[+] Installing fonts safely..."

mkdir -p "$HOME/.local/share/fonts"
cd /tmp || exit

# ----------------------------
# JetBrains Mono
# ----------------------------
echo "[+] JetBrains Mono..."
wget -q -O JetBrainsMono.zip \
https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip

unzip -oq JetBrainsMono.zip -d JetBrainsMono
cp JetBrainsMono/fonts/ttf/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true

# ----------------------------
# FiraCode Nerd Font (FIXED)
# ----------------------------
echo "[+] FiraCode Nerd Font..."
wget -q -O FiraCode.zip \
https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip

mkdir -p FiraCodeTemp
unzip -oq FiraCode.zip -d FiraCodeTemp

find FiraCodeTemp -name "*.ttf" -exec cp {} "$HOME/.local/share/fonts/" \;

# ----------------------------
# MesloLGS NF
# ----------------------------
echo "[+] MesloLGS NF..."
wget -q -O Meslo-Regular.ttf \
https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf

wget -q -O Meslo-Bold.ttf \
https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf

wget -q -O Meslo-Italic.ttf \
https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf

wget -q -O Meslo-BoldItalic.ttf \
https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

cp Meslo*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true

# ----------------------------
# Refresh font cache
# ----------------------------
fc-cache -fv

cd - >/dev/null || true

echo "[✔] Fonts installed successfully"

# ============================
# CONFIG COPY
# ============================
echo "[+] Copying configs..."

mkdir -p ~/.config/{alacritty,fastfetch,bspwm,picom,polybar,rofi/themes,sxhkd}

safe_cp "$SCRIPT_DIR/alacritty/alacritty.toml" ~/.config/alacritty/
safe_cp "$SCRIPT_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/
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
# GTK THEMES
# ============================
echo "[+] Installing GTK themes..."

mkdir -p "$HOME/.themes"

# Nordic Theme
if [ ! -d "$HOME/.themes/Nordic" ]; then
    echo "[+] Installing Nordic..."
    git clone https://github.com/EliverLara/Nordic.git \
    "$HOME/.themes/Nordic" || FAILED_FILES+=("Nordic Theme")
else
    echo "[✔] Nordic already installed"
fi

# Dracula Theme
if [ ! -d "$HOME/.themes/Dracula" ]; then
    echo "[+] Installing Dracula..."
    git clone https://github.com/dracula/gtk.git \
    "$HOME/.themes/Dracula" || FAILED_FILES+=("Dracula Theme")
else
    echo "[✔] Dracula already installed"
fi

echo "[✔] GTK themes installed"

# ============================
# PULSEAUDIO
# ============================
pulseaudio --start 2>/dev/null || true

# ============================
# .xinitrc
# ============================
cat > "$HOME/.xinitrc" <<EOF
#!/bin/sh
pulseaudio --start &
exec bspwm
EOF

chmod +x "$HOME/.xinitrc"

# ============================
# AUTO START X ON TTY1
# ============================
echo "[+] Configuring auto start BSPWM..."

cat > "$HOME/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

echo "[✔] Auto-start configured"

# ============================
# WALLPAPER SETUP
# ============================
echo "[+] Installing wallpaper..."

mkdir -p "$HOME/Pictures/wallpapers"

safe_cp "$SCRIPT_DIR/wallpapers/Debian.jpg" \
"$HOME/Pictures/wallpapers/Debian.jpg"

echo "[✔] Wallpaper installed"

# ============================
# FINAL + REBOOT
# ============================
echo ""
echo "=================================="
echo " INSTALL COMPLETE"
echo "=================================="
echo "✔ BSPWM ready"
echo "✔ Fonts installed"
echo "✔ GTK themes installed"
echo "✔ Auto-start configured"
echo "=================================="

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "Failed Packages:"
    printf ' - %s\n' "${FAILED_PACKAGES[@]}"
fi

if [ ${#FAILED_FILES[@]} -gt 0 ]; then
    echo ""
    echo "Failed Files:"
    printf ' - %s\n' "${FAILED_FILES[@]}"
fi

echo ""
echo "SYSTEM REBOOT INITIATED"
echo ""

for i in 5 4 3 2 1; do
    echo -ne "Reboot in... [$i]\r"
    sleep 1
done

echo ""
echo "[✔] Rebooting..."

sync
sudo reboot