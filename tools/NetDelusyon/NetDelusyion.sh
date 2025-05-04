#!/bin/bash

# NetDelusyon - Network Recon & Sniffing Tool
# Author: simplyYan
# License: GNU General Public License v3.0

# Colors
red='\033[0;31m'; green='\033[0;32m'; blue='\033[1;34m'; reset='\033[0m'

# Check dependencies
deps=("ping" "ip" "awk" "grep" "tcpdump" "curl" "nmap" "arp-scan" "macchanger" "whois" "dig")
for dep in "${deps[@]}"; do
    if ! command -v $dep &> /dev/null; then
        echo -e "${blue}[INFO] Installing missing dependency: $dep${reset}"
        sudo apt-get install -y $dep
    fi
done

# Settings
export_results=false
silent_mode=false
auto_iface=true

# Menu
main_menu() {
    clear
    echo -e "${blue}NetDelusyon - Enhanced Network Recon & Sniffing Tool${reset}"
    echo "<< Part of the DYSØRDER project >>"
    echo ""
    echo "1) Host Discovery (Ping Sweep)"
    echo "2) Port Scan"
    echo "3) Packet Sniffer"
    echo "4) WHOIS Lookup"
    echo "5) Interface Info"
    echo "6) MAC Address Scan & Manufacturer"
    echo "7) OS Detection (OS Fingerprinting)"
    echo "8) DNS Enumeration"
    echo "9) Geolocate IP"
    echo "10) Export Results (Toggle: $export_results)"
    echo "11) Silent Mode (Toggle: $silent_mode)"
    echo "12) Auto Interface Detection (Toggle: $auto_iface)"
    echo "0) Exit"
    echo ""
    read -p "Select an option: " option
    case $option in
        1) host_discovery ;;
        2) port_scan ;;
        3) packet_sniffer ;;
        4) whois_lookup ;;
        5) show_interfaces ;;
        6) mac_scan ;;
        7) os_detection ;;
        8) dns_enumeration ;;
        9) geolocate_ip ;;
        10) toggle_export_results ;;
        11) toggle_silent_mode ;;
        12) toggle_auto_iface ;;
        0) exit ;;
        *) echo "Invalid option"; sleep 1; main_menu ;;
    esac
}

# Toggle for export results
toggle_export_results() {
    export_results=$((export_results + 1)) # Toggle between 0 and 1
    if [ $export_results -eq 1 ]; then
        echo -e "${green}Export Results: Enabled${reset}"
    else
        echo -e "${red}Export Results: Disabled${reset}"
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# Toggle for silent mode
toggle_silent_mode() {
    silent_mode=$((silent_mode + 1)) # Toggle between 0 and 1
    if [ $silent_mode -eq 1 ]; then
        echo -e "${green}Silent Mode: Enabled${reset}"
    else
        echo -e "${red}Silent Mode: Disabled${reset}"
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# Toggle for auto interface detection
toggle_auto_iface() {
    auto_iface=$((auto_iface + 1)) # Toggle between 0 and 1
    if [ $auto_iface -eq 1 ]; then
        echo -e "${green}Auto Interface Detection: Enabled${reset}"
    else
        echo -e "${red}Auto Interface Detection: Disabled${reset}"
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 1. Ping Sweep (Host Discovery)
host_discovery() {
    read -p "Enter network (e.g., 192.168.1): " net
    echo -e "${green}Scanning live hosts on ${net}.0/24...${reset}"
    for i in {1..254}; do
        (ping -c 1 -W 1 $net.$i &> /dev/null && echo -e "${green}[+] Host alive: $net.$i${reset}") &
    done
    wait
    if [ "$export_results" -eq 1 ]; then
        echo "Live hosts found in $net.0/24" >> results.txt
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 2. Port Scan
port_scan() {
    read -p "Enter target IP: " ip
    read -p "Enter port range (e.g., 20-80): " range
    echo -e "${green}Scanning ports on $ip...${reset}"
    for port in $(seq $(echo $range | cut -d'-' -f1) $(echo $range | cut -d'-' -f2)); do
        if [ "$silent_mode" -eq 0 ]; then
            (echo > /dev/tcp/$ip/$port) &>/dev/null && echo -e "${blue}[*] Port $port open on $ip${reset}"
        else
            (echo > /dev/tcp/$ip/$port) &>/dev/null
        fi
    done
    if [ "$export_results" -eq 1 ]; then
        echo "Port scan for $ip: $range" >> results.txt
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 3. Packet Sniffer
packet_sniffer() {
    read -p "Enter interface (e.g., wlan0): " iface
    read -p "Enter filter (e.g., port 80, tcp, udp, or leave empty): " filter
    echo -e "${green}Sniffing on $iface (press Ctrl+C to stop)...${reset}"
    if [ "$export_results" -eq 1 ]; then
        sudo tcpdump -i $iface $filter -w capture.pcap
    else
        sudo tcpdump -i $iface $filter
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 4. WHOIS Lookup
whois_lookup() {
    read -p "Enter IP or domain: " target
    echo -e "${green}Fetching WHOIS data for $target...${reset}"
    curl -s "https://whois.domaintools.com/$target" | grep -E "Registrar|Registrant|Name Server|IP Location|WHOIS Server" | head -n 20
    if [ "$export_results" -eq 1 ]; then
        echo "WHOIS data for $target" >> results.txt
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 5. Show Network Interfaces
show_interfaces() {
    echo -e "${green}Available network interfaces:${reset}"
    ip -brief addr
    read -p "Press enter to return to menu..."
    main_menu
}

# 6. MAC Address Scan & Manufacturer
mac_scan() {
    read -p "Enter target IP range (e.g., 192.168.1.0/24): " target
    echo -e "${green}Scanning for MAC addresses in $target...${reset}"
    sudo arp-scan $target --interface=$(ip route show default | awk '{print $5}')
    read -p "Press enter to return to menu..."
    main_menu
}

# 7. OS Detection (OS Fingerprinting)
os_detection() {
    read -p "Enter target IP: " ip
    echo -e "${green}Attempting to detect OS of $ip...${reset}"
    nmap -O $ip
    if [ "$export_results" -eq 1 ]; then
        echo "OS detection for $ip" >> results.txt
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 8. DNS Enumeration
dns_enumeration() {
    read -p "Enter domain for DNS enumeration: " domain
    echo -e "${green}Enumerating DNS records for $domain...${reset}"
    dig +short $domain ANY
    if [ "$export_results" -eq 1 ]; then
        echo "DNS enumeration for $domain" >> results.txt
    fi
    read -p "Press enter to return to menu..."
    main_menu
}

# 9. Geolocate IP
geolocate_ip() {
    read -p "Enter IP to geolocate: " ip
    echo -e "${green}Geolocating IP $ip...${reset}"
    curl -s "https://ipinfo.io/$ip" | jq
    read -p "Press enter to return to menu..."
    main_menu
}

main_menu
