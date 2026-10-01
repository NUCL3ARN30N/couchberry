#!/bin/bash
# pi-steamlink-kiosk installer
#
# Turns a Raspberry Pi 4B running Raspberry Pi OS (Trixie, Desktop) into a
# dedicated Steam Link box: it boots straight into Steam Link, with no desktop
# ever visible, and sound goes out over HDMI.
#
# Usage:  ./install.sh [--with-xpadneo | --no-xpadneo] [--no-upgrade] [--no-reboot]
#
# Safe to run more than once.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH_FILE="$HOME/.steamlink-branch"
LIGHTDM_CONF=/etc/lightdm/lightdm.conf
CMDLINE=/boot/firmware/cmdline.txt

XPADNEO=ask        # ask | yes | no
UPGRADE=yes
REBOOT=ask         # ask | no

for arg in "$@"; do
    case "$arg" in
        --with-xpadneo) XPADNEO=yes ;;
        --no-xpadneo)   XPADNEO=no ;;
        --no-upgrade)   UPGRADE=no ;;
        --no-reboot)    REBOOT=no ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
    esac
done

# ------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    echo "Please run this as your normal user (not root / not with sudo)."
    echo "The script calls sudo itself where needed."
    exit 1
fi

MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "unknown")
. /etc/os-release
echo "=== pi-steamlink-kiosk installer ==="
echo "Board: $MODEL"
echo "OS:    $PRETTY_NAME"
echo ""

if [[ "$MODEL" != *"Raspberry Pi 4"* ]]; then
    echo "WARNING: This was tested on a Raspberry Pi 4B only."
fi
if [ "${VERSION_CODENAME:-}" != "trixie" ]; then
    echo "WARNING: This was tested on Raspberry Pi OS Trixie only."
fi
if [ ! -f "$LIGHTDM_CONF" ] || ! command -v labwc >/dev/null; then
    echo "ERROR: lightdm and labwc were not found. Use Raspberry Pi OS (Trixie)"
    echo "       with desktop (not Lite)."
    exit 1
fi

# ------------------------------------------------------------
# 1. System update
# ------------------------------------------------------------
echo "--- 1/6 Updating system packages ---"
sudo apt update
if [ "$UPGRADE" = yes ]; then
    sudo apt upgrade -y
fi

# ------------------------------------------------------------
# 2. Steam Link (stable, from the apt repository)
# ------------------------------------------------------------
echo "--- 2/6 Installing Steam Link ---"
sudo apt install -y steamlink
echo "stable" > "$BRANCH_FILE"

# ------------------------------------------------------------
# 3. Optional: xpadneo (better Xbox controller support over Bluetooth)
# ------------------------------------------------------------
echo "--- 3/6 Xbox controller driver (optional) ---"
if [ "$XPADNEO" = ask ]; then
    read -p "Install xpadneo for Xbox controllers over Bluetooth? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && XPADNEO=yes || XPADNEO=no
fi
if [ "$XPADNEO" = yes ]; then
    # Trixie has no 'raspberrypi-kernel-headers'; the headers package is
    # named after the running kernel.
    sudo apt install -y git dkms "linux-headers-$(uname -r)"
    if [ ! -d "$HOME/xpadneo" ]; then
        git clone https://github.com/atar-axis/xpadneo.git "$HOME/xpadneo"
    fi
    (cd "$HOME/xpadneo" && sudo ./install.sh)
else
    echo "Skipped."
fi

# ------------------------------------------------------------
# 4. Kiosk session: boot straight into Steam Link, no desktop
# ------------------------------------------------------------
echo "--- 4/6 Installing kiosk session ---"
KIOSK_CFG="$HOME/.config/labwc-kiosk"
mkdir -p "$KIOSK_CFG"
cp "$REPO_DIR/kiosk/rc.xml" "$KIOSK_CFG/rc.xml"
# Reuse the keyboard layout configured on the desktop
if [ -f "$HOME/.config/labwc/environment" ]; then
    cp "$HOME/.config/labwc/environment" "$KIOSK_CFG/environment"
fi

sudo install -m 755 "$REPO_DIR/kiosk/steamlink-kiosk"     /usr/local/bin/steamlink-kiosk
sudo install -m 755 "$REPO_DIR/kiosk/steamlink-kiosk-run" /usr/local/bin/steamlink-kiosk-run
sudo install -m 644 "$REPO_DIR/kiosk/steamlink-kiosk.desktop" \
    /usr/share/wayland-sessions/steamlink-kiosk.desktop

# ------------------------------------------------------------
# 5. Auto-login straight into the kiosk session
# ------------------------------------------------------------
echo "--- 5/6 Configuring auto-login ---"
sudo cp -n "$LIGHTDM_CONF" "$LIGHTDM_CONF.bak-steamlink"
grep -q '^\[Seat:\*\]' "$LIGHTDM_CONF" || echo '[Seat:*]' | sudo tee -a "$LIGHTDM_CONF" >/dev/null
sudo sed -i -E \
    -e "s/^#?\s*autologin-user=.*/autologin-user=$USER/" \
    -e 's/^#?\s*autologin-session=.*/autologin-session=steamlink-kiosk/' \
    -e 's/^#?\s*user-session=.*/user-session=steamlink-kiosk/' "$LIGHTDM_CONF"
grep -q '^autologin-user=' "$LIGHTDM_CONF" || \
    sudo sed -i "/^\[Seat:\*\]/a autologin-user=$USER" "$LIGHTDM_CONF"
grep -q '^autologin-session=' "$LIGHTDM_CONF" || \
    sudo sed -i '/^\[Seat:\*\]/a autologin-session=steamlink-kiosk' "$LIGHTDM_CONF"
grep -q '^user-session=' "$LIGHTDM_CONF" || \
    sudo sed -i '/^\[Seat:\*\]/a user-session=steamlink-kiosk' "$LIGHTDM_CONF"

# ------------------------------------------------------------
# 6. Steam Controller polling rate
# ------------------------------------------------------------
# Steam Link opens a terminal and waits for Enter at every launch if the
# polling rate is above 2. usbhid is built into the Pi kernel, so the setting
# has to go on the kernel command line.
echo "--- 6/6 Setting USB polling rate ---"
sudo cp -n "$CMDLINE" "$CMDLINE.bak-steamlink"
grep -q 'usbhid.mousepoll=' "$CMDLINE" || sudo sed -i '1 s/$/ usbhid.mousepoll=2/' "$CMDLINE"

echo ""
echo "=== Installation complete ==="
echo "The Pi will boot straight into Steam Link after a reboot."
echo "To update or switch between stable/beta: ./steamlink-manager.sh"
echo "To undo everything:                      ./uninstall.sh"
echo ""

if [ "$REBOOT" = ask ]; then
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
fi
