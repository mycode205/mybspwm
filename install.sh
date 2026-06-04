#!/bin/bash

# ============================
# INSTALL MODE 
# ============================

FAILED_PACKAGES=()
FAILED_FILES=()

SCRIPT_PATH="$(realpath "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WALLPAPER="$HOME/Pictures/wallpapers/Debian.jpg"

# ============================
# COOL COLORFUL UI FUNCTION
# ============================
show_status() {
    local task_name="$1"
    local status_type="$2" # "RUN", "SUCCESS", "FAIL"
    
    # ANSI Color Codes (Nord Palette Inspired)
    local NORD_BLUE="\033[1;36m"
    local NORD_GREEN="\033[1;32m"
    local NORD_RED="\033[1;31m"
    local RESET="\033[0m"

    case "$status_type" in
        "RUN")
            clear
            echo -e "${NORD_BLUE}╭──────────────────────────────────────────────────────────╮${RESET}"
            echo -e "${NORD_BLUE}│${RESET}  [ 󱑤 ] Downloading & Installing...                      ${NORD_BLUE}│${RESET}"
            echo -e "${NORD_BLUE}├──────────────────────────────────────────────────────────┤${RESET}"
            printf "${NORD_BLUE}│${RESET}  ➜ %-52s ${NORD_BLUE}│\n" "$task_name"
            echo -e "${NORD_BLUE}╰──────────────────────────────────────────────────────────╯${RESET}"
            ;;
        "SUCCESS")
            echo -e "     ${NORD_GREEN}✔ Successfully Processed${RESET}\n"
            sleep 0.4
            ;;
        "FAIL")
            echo -e "     ${NORD_RED}✘ Installation Failed${RESET}\n"
            sleep 1
            ;;
    esac
}

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
        sleep 0.1
    else
        # Call the cool rounded status box UI
        show_status "$PKG" "RUN"

        # Redirect standard output to hide terminal clutter during apt install
        if sudo apt install -y $EXTRA "$PKG" >/dev/null 2>&1; then
            show_status "$PKG" "SUCCESS"
        else
            show_status "$PKG" "FAIL"
            FAILED_PACKAGES+=("$PKG")
        fi
    fi
}

# ============================
#  COPY
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
show_status "Updating system package repositories" "RUN"
if sudo apt update >/dev/null 2>&1; then
    show_status "System update complete" "SUCCESS"
else
    show_status "System update failed" "FAIL"
fi

# ============================
# CORE PACKAGES
# ============================
for pkg in \
    bspwm sxhkd polybar picom rofi alacritty feh \
    brightnessctl alsa-utils pulseaudio pavucontrol \
    xorg xinit lxappearance papirus-icon-theme \
    breeze-icon-theme bibata-cursor-theme fastfetch flameshot \
    fonts-font-awesome fonts-inter curl git unzip x11-xserver-utils \
    libinput-tools
do
    check_install "$pkg"
done

# ==================================
# INTERACTIVE FILE MANAGER MENU
# ==================================
if [ -f "$SCRIPT_DIR/filemanager.sh" ]; then
    chmod +x "$SCRIPT_DIR/filemanager.sh"
    "$SCRIPT_DIR/filemanager.sh"
else
    echo "[✘] ERROR: filemanager.sh not found in $SCRIPT_DIR"
    FAILED_FILES+=("filemanager.sh script missing")
fi

# ============================
# TOUCHPAD CONFIG
# ============================
show_status "Configuring touchpad options (libinput)" "RUN"

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

show_status "Touchpad configuration" "SUCCESS"

# ============================
# BRAVE BROWSER
# ============================
if ! command -v brave-browser >/dev/null; then
    show_status "Adding Brave Browser repository & keys" "RUN"
    sudo apt install -y curl >/dev/null 2>&1

    sudo curl -fsSLo /usr/share/keyrings/brave-browser.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg >/dev/null 2>&1

    echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] \
    https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave.list >/dev/null 2>&1

    sudo apt update >/dev/null 2>&1
    
    show_status "Installing Brave Browser" "RUN"
    if sudo apt install -y brave-browser >/dev/null 2>&1; then
        show_status "Brave Browser" "SUCCESS"
    else
        show_status "Brave Browser" "FAIL"
        FAILED_PACKAGES+=("brave-browser")
    fi
else
    echo "[✔] Brave already installed"
fi

# ============================
#  FONTS 
# ============================
mkdir -p "$HOME/.local/share/fonts"
cd /tmp || exit

# ----------------------------
# JetBrains Mono
# ----------------------------
show_status "Downloading JetBrains Mono Fonts" "RUN"
if wget -q -O JetBrainsMono.zip https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip; then
    unzip -oq JetBrainsMono.zip -d JetBrainsMono
    cp JetBrainsMono/fonts/ttf/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
    show_status "JetBrains Mono" "SUCCESS"
else
    show_status "JetBrains Mono Download" "FAIL"
fi

# ----------------------------
# FiraCode Nerd Font
# ----------------------------
show_status "Downloading FiraCode Nerd Font" "RUN"
if wget -q -O FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip; then
    mkdir -p FiraCodeTemp
    unzip -oq FiraCode.zip -d FiraCodeTemp
    find FiraCodeTemp -name "*.ttf" -exec cp {} "$HOME/.local/share/fonts/" \; >/dev/null 2>&1
    show_status "FiraCode Nerd Font" "SUCCESS"
else
    show_status "FiraCode Nerd Font Download" "FAIL"
fi

# ----------------------------
# MesloLGS NF
# ----------------------------
show_status "Downloading MesloLGS NF Fonts" "RUN"
wget -q -O Meslo-Regular.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget -q -O Meslo-Bold.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget -q -O Meslo-Italic.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget -q -O Meslo-BoldItalic.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

cp Meslo*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
show_status "MesloLGS NF Fonts" "SUCCESS"

# Refresh font cache quietly
fc-cache -f >/dev/null 2>&1
cd - >/dev/null || true

# ============================
# CONFIG COPY
# ============================
clear
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
# FASTFETCH SETUP
# ============================
echo "[+] Configuring Fastfetch..."
touch "$HOME/.bashrc"

if ! grep -q "fastfetch" "$HOME/.bashrc"; then
cat >> "$HOME/.bashrc" <<'EOF'

# Fastfetch
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
EOF
fi

echo "[✔] Fastfetch configured"

# ============================
# GTK THEMES
# ============================
echo "[+] Installing GTK themes..."
mkdir -p "$HOME/.themes"

# Nordic Theme
if [ ! -d "$HOME/.themes/Nordic" ]; then
    show_status "Cloning Nordic GTK Theme" "RUN"
    if git clone https://github.com/EliverLara/Nordic.git "$HOME/.themes/Nordic" >/dev/null 2>&1; then
        show_status "Nordic Theme" "SUCCESS"
    else
        show_status "Nordic Theme" "FAIL"
        FAILED_FILES+=("Nordic Theme")
    fi
fi

# Dracula Theme
if [ ! -d "$HOME/.themes/Dracula" ]; then
    show_status "Cloning Dracula GTK Theme" "RUN"
    if git clone https://github.com/dracula/gtk.git "$HOME/.themes/Dracula" >/dev/null 2>&1; then
        show_status "Dracula Theme" "SUCCESS"
    else
        show_status "Dracula Theme" "FAIL"
        FAILED_FILES+=("Dracula Theme")
    fi
fi

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
exec dbus-launch --sh-syntax --exit-with-session bspwm
EOF

chmod +x "$HOME/.xinitrc"

# ============================
# AUTO START X ON TTY1
# ============================
cat > "$HOME/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

# ============================
# WALLPAPER SETUP
# ============================
mkdir -p "$HOME/Pictures/wallpapers"
safe_cp "$SCRIPT_DIR/wallpapers/Debian.jpg" "$HOME/Pictures/wallpapers/Debian.jpg"

# ============================
# FINAL + REBOOT
# ============================
clear
echo "=================================="
echo " INSTALL COMPLETE"
echo "=================================="
echo "✔ BSPWM environment ready"
echo "✔ Fonts cached successfully"
echo "✔ GTK themes installed"
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
    echo -ne "Rebooting in... [$i]\r"
    sleep 1
done

echo ""
echo "[✔] Rebooting..."

sync
sudo reboot