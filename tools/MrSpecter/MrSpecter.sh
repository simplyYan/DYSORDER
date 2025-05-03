#!/bin/bash

# MrSpecter - OSINT Recon Tool
# Author: @simplyYan
# License: GNU

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Dependencies required
DEPENDENCIES=("curl" "whois")

# Detect package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt-get"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        echo ""
    fi
}

# Check and install missing dependencies
install_dependencies() {
    local pkg_mgr
    pkg_mgr=$(detect_package_manager)

    if [[ -z "$pkg_mgr" ]]; then
        echo "❌ Unsupported Linux distribution. Please install dependencies manually: ${DEPENDENCIES[*]}"
        exit 1
    fi

    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "🔧 Installing missing dependency: $dep"
            case "$pkg_mgr" in
                apt-get) sudo apt-get update && sudo apt-get install -y "$dep" ;;
                dnf) sudo dnf install -y "$dep" ;;
                pacman) sudo pacman -Sy --noconfirm "$dep" ;;
                zypper) sudo zypper install -y "$dep" ;;
                apk) sudo apk add "$dep" ;;
            esac

            # Re-check after install
            if ! command -v "$dep" &>/dev/null; then
                echo "❌ Failed to install $dep. Please install it manually."
                exit 1
            fi
        fi
    done
}

# Run installation check
install_dependencies

# Platforms config for username scan
PLATFORMS=(
  "https://github.com/%s"
  "https://twitter.com/%s"
  "https://www.reddit.com/user/%s"
  "https://www.instagram.com/%s"
  "https://www.tiktok.com/@%s"
  "https://www.pinterest.com/%s"
  "https://medium.com/@%s"
  "https://%s.tumblr.com"
  "https://www.facebook.com/%s"
  "https://www.linkedin.com/in/%s"
  "https://www.snapchat.com/add/%s"
  "https://www.youtube.com/%s"
  "https://www.flickr.com/people/%s"
  "https://www.quora.com/profile/%s"
  "https://www.deviantart.com/%s"
  "https://www.vimeo.com/%s"
  "https://soundcloud.com/%s"
  "https://www.behance.net/%s"
  "https://www.dribbble.com/%s"
  "https://www.goodreads.com/%s"
  "https://www.producthunt.com/@%s"
  "https://www.slideshare.net/%s"
  "https://www.about.me/%s"
  "https://www.discogs.com/user/%s"
  "https://www.last.fm/user/%s"
  "https://www.bandcamp.com/%s"
  "https://www.mixcloud.com/%s"
  "https://www.okcupid.com/profile/%s"
  "https://www.badoo.com/en/%s"
  "https://www.twitch.tv/%s"
  "https://www.couchsurfing.com/people/%s"
  "https://www.tripadvisor.com/members/%s"
  "https://www.airbnb.com/users/show/%s"
  "https://www.foursquare.com/%s"
  "https://www.weibo.com/%s"
  "https://www.vk.com/%s"
  "https://www.xing.com/profile/%s"
  "https://www.meetup.com/members/%s"
  "https://www.stackoverflow.com/users/%s"
  "https://www.bitbucket.org/%s"
  "https://www.gitlab.com/%s"
  "https://www.codepen.io/%s"
  "https://www.reverbnation.com/%s"
  "https://www.patreon.com/%s"
  "https://www.kickstarter.com/profile/%s"
  "https://www.indiegogo.com/individuals/%s"
  "https://www.depop.com/%s"
  "https://www.etsy.com/shop/%s"
  "https://www.zillow.com/profile/%s"
  "https://www.trulia.com/profile/%s"
  "https://www.houzz.com/user/%s"
  "https://www.cargocollective.com/%s"
  "https://www.creativemarket.com/%s"
  "https://www.500px.com/%s"
  "https://www.ello.co/%s"
  "https://www.angel.co/%s"
  "https://www.crunchbase.com/person/%s"
  "https://www.instapaper.com/p/%s"
  "https://www.pastebin.com/u/%s"
  "https://www.scribd.com/%s"
  "https://www.academia.edu/%s"
  "https://www.researchgate.net/profile/%s"
  "https://www.dailymotion.com/%s"
  "https://www.metacafe.com/channels/%s"
  "https://www.livejournal.com/users/%s"
  "https://www.periscope.tv/%s"
  "https://www.ustream.tv/%s"
  "https://www.break.com/user/%s"
  "https://www.newgrounds.com/%s"
  "https://www.gaiaonline.com/profiles/%s"
  "https://www.hackerone.com/%s"
  "https://www.bugcrowd.com/%s"
  "https://www.keybase.io/%s"
  "https://www.openstreetmap.org/user/%s"
  "https://www.wikimedia.org/wiki/User:%s"
  "https://www.wikipedia.org/wiki/User:%s"
  "https://www.stackexchange.com/users/%s"
  "https://www.superuser.com/users/%s"
  "https://www.askubuntu.com/users/%s"
  "https://www.mathoverflow.net/users/%s"
  "https://www.serverfault.com/users/%s"
  "https://www.guru.com/freelancers/%s"
  "https://www.peopleperhour.com/freelancer/%s"
  "https://www.freelancer.com/u/%s"
  "https://www.upwork.com/freelancers/~%s"
  "https://www.fiverr.com/%s"
  "https://www.behance.net/%s"
  "https://www.coroflot.com/%s"
  "https://www.artstation.com/%s"
  "https://www.stage32.com/%s"
  "https://www.modelmayhem.com/%s"
  "https://www.soundclick.com/%s"
  "https://www.mixcrate.com/%s"
  "https://www.looperman.com/users/profile/%s"
  "https://www.spreaker.com/user/%s"
  "https://www.podbean.com/user-%s"
  "https://www.anchor.fm/%s"
  "https://www.tunein.com/user/%s"
  "https://www.8tracks.com/users/%s"
  "https://www.jango.com/music/%s"
  "https://www.napster.com/artist/%s"
  "https://www.shazam.com/artist/%s"
  "https://www.audiomack.com/%s"
  "https://www.datpiff.com/profile/%s"
  "https://www.spinrilla.com/profile/%s"
  "https://www.musicxray.com/%s"
  "https://www.reverbnation.com/%s"
  "https://www.bandmix.com/%s"
  "https://www.soundclick.com/%s"
  "https://www.noisetrade.com/%s"
)


# Banner
banner() {
cat << "EOF"
___  ___     _____                 _            
|  \/  |    /  ___|               | |           
| .  . |_ __\ `--. _ __   ___  ___| |_ ___ _ __ 
| |\/| | '__|`--. \ '_ \ / _ \/ __| __/ _ \ '__|
| |  | | |  /\__/ / |_) |  __/ (__| ||  __/ |   
\_|  |_/_|  \____/| .__/ \___|\___|\__\___|_|   
                  | |                           
                  |_|                           



MrSpecter - OSINT Recon Tool
<< Part of the DYSØRDER project >>
EOF
}

# Whois Function
run_whois() {
    local target="$1"
    echo -e "${YELLOW}[*] Performing WHOIS lookup for: $target${NC}"
    whois "$target" | sed '/^$/d'
}

# Username search
check_user() {
    local user="$1"
    echo -e "${YELLOW}[*] Searching for username: $user${NC}"
    for url_template in "${PLATFORMS[@]}"; do
        url=$(printf "$url_template" "$user")
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
        if [[ "$response" == "200" ]]; then
            echo -e "${GREEN}[+] Found: $url${NC}"
        elif [[ "$response" == "301" || "$response" == "302" ]]; then
            echo -e "${YELLOW}[~] Redirected: $url${NC}"
        else
            echo -e "${RED}[-] Not Found: $url${NC}"
        fi
    done
}

# Help
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 <mode> <target>"
    echo "Modes:"
    echo "  whois <domain|ip>       Run WHOIS lookup"
    echo "  user <username>         Search username across platforms"
    echo
    echo "Examples:"
    echo "  $0 whois google.com"
    echo "  $0 user johndoe"
}

# Main
main() {
    banner
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    mode="$1"
    target="$2"

    case "$mode" in
        whois)
            run_whois "$target"
            ;;
        user)
            check_user "$target"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
