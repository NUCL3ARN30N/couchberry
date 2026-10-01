#!/bin/bash
# Steam Link version manager: show the installed version, update it, or switch
# between the stable (apt) and beta (direct download) builds.
#
# Use the beta build if you see dropped frames on stable.

set -u

BRANCH_FILE="$HOME/.steamlink-branch"
BETA_URL="https://media.steampowered.com/steamlink/rpi/latest/steamlink.deb"
BETA_DEB="/tmp/steamlink-beta.deb"

get_installed_version() {
    dpkg-query -W -f='${Version}' steamlink 2>/dev/null || echo "not installed"
}

get_branch() {
    if [ -f "$BRANCH_FILE" ]; then cat "$BRANCH_FILE"; else echo "unknown"; fi
}

install_beta() {
    echo "Downloading latest Steam Link beta build..."
    if wget -q -O "$BETA_DEB" "$BETA_URL"; then
        echo "Installing beta build..."
        sudo dpkg -i "$BETA_DEB" || sudo apt --fix-broken install -y
        rm -f "$BETA_DEB"
        echo "beta" > "$BRANCH_FILE"
        echo "Beta build installed."
    else
        echo "ERROR: Could not download the beta build."
        echo "Manual download: https://steamcommunity.com/app/353380/discussions/6/"
        return 1
    fi
}

install_stable() {
    echo "Installing stable Steam Link from the apt repository..."
    sudo apt update
    local version
    version=$(apt-cache policy steamlink | awk '/Candidate:/ {print $2}')
    if [ -z "$version" ]; then
        echo "ERROR: Could not determine the apt candidate version."
        return 1
    fi
    echo "Repository candidate version: $version"
    sudo apt install -y --allow-downgrades --reinstall steamlink="$version"
    echo "stable" > "$BRANCH_FILE"
    echo "Stable version installed."
}

update_current_branch() {
    case "$(get_branch)" in
        beta)
            echo "Updating beta branch (re-downloading latest beta build)..."
            install_beta
            ;;
        stable)
            echo "Updating stable branch..."
            sudo apt update
            sudo apt install --only-upgrade -y steamlink
            echo "Stable branch is up to date."
            ;;
        *)
            echo "Branch is unknown. Please choose 'Switch to stable' or 'Switch to beta'."
            ;;
    esac
}

while true; do
    echo ""
    echo "=== Steam Link Version Manager ==="
    echo "Installed version: $(get_installed_version)"
    echo "Current branch:    $(get_branch)"
    echo ""
    echo "  1) Update current branch"
    echo "  2) Switch to stable"
    echo "  3) Switch to beta"
    echo "  4) Exit"
    echo ""
    read -p "Choose an option [1-4]: " -n 1 -r
    echo ""

    case "$REPLY" in
        1) update_current_branch || true ;;
        2) install_stable || true ;;
        3) install_beta || true ;;
        4) echo "Exiting."; exit 0 ;;
        *) echo "Invalid option. Please choose 1-4."; continue ;;
    esac

    echo ""
    read -p "Reboot now to apply? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
done
