#!/bin/bash
# Reverts pi-steamlink-kiosk: boots back into the normal Raspberry Pi desktop.
# Steam Link itself stays installed unless you pass --remove-steamlink.
#
# Usage:  ./uninstall.sh [--remove-steamlink] [--no-reboot]

set -euo pipefail

LIGHTDM_CONF=/etc/lightdm/lightdm.conf
CMDLINE=/boot/firmware/cmdline.txt
REMOVE_STEAMLINK=no
REBOOT=ask

for arg in "$@"; do
    case "$arg" in
        --remove-steamlink) REMOVE_STEAMLINK=yes ;;
        --no-reboot)        REBOOT=no ;;
        -h|--help)          sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
    esac
done

if [ "$(id -u)" -eq 0 ]; then
    echo "Please run this as your normal user (not root / not with sudo)."
    exit 1
fi

echo "--- Restoring desktop auto-login ---"
sudo sed -i -E \
    -e 's/^autologin-session=steamlink-kiosk$/autologin-session=rpd-labwc/' \
    -e 's/^user-session=steamlink-kiosk$/user-session=rpd-labwc/' "$LIGHTDM_CONF"

echo "--- Removing kiosk files ---"
sudo rm -f /usr/local/bin/steamlink-kiosk \
           /usr/local/bin/steamlink-kiosk-run \
           /usr/share/wayland-sessions/steamlink-kiosk.desktop
rm -rf "$HOME/.config/labwc-kiosk"

echo "--- Removing USB polling-rate setting ---"
sudo sed -i 's/ usbhid\.mousepoll=2//' "$CMDLINE"

rm -f "$HOME/.steamlink-branch"

if [ "$REMOVE_STEAMLINK" = yes ]; then
    echo "--- Removing Steam Link ---"
    sudo apt remove -y steamlink
fi

echo ""
echo "Done. The Pi will boot into the normal desktop after a reboot."
if [ "$REBOOT" = ask ]; then
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && sudo reboot
fi
exit 0
