Berikut adalah versi yang sudah dipercantik dengan berbagai peningkatan visual dan fungsional:

```bash
#!/bin/bash
#!/usr/bin/env bash

########################################################################
#                                                                      #
#            🦕 Pterodactyl Installer, Updater, Remover and More       #
#            Copyright 2025, Malthe K, <me@malthe.cc>                  # 
#  https://github.com/NavitaBurhan/ptrodactyl-installer/blob/main/LICENSE #
#                                                                      #
#  This script is not associated with the official Pterodactyl Panel.  #
#  You may not remove this line                                        #
#                                                                      #
########################################################################

### VARIABLES ###
dist="$(. /etc/os-release && echo "$ID")"
version="$(. /etc/os-release && echo "$VERSION_ID")"
USERPASSWORD=""
WINGSNOQUESTIONS=false

### COLORS ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

### FANCY OUTPUTS ###
function print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}                    🦕 PTERODACTYL INSTALLER v3.0                    ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                      ║${NC}"
    echo -e "${CYAN}║${YELLOW}                    Copyright 2025, Malthe K                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${BLUE}                    Enhanced & Beautified Version                   ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

function print_step() {
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${WHITE} $1${BLUE}$(printf "%*s" $((67 - ${#1})) "")│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

function success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function error() {
    echo -e "${RED}❌ $1${NC}"
}

function info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

function loading_animation() {
    local text="$1"
    local duration=${2:-3}
    
    echo -ne "${YELLOW}$text "
    for i in $(seq 1 $duration); do
        echo -ne "."
        sleep 0.5
    done
    echo -e " ${GREEN}Done!${NC}"
}

function progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r${CYAN}Progress: [${NC}"
    printf "%*s" $completed | tr ' ' '█'
    printf "%*s" $((width - completed)) | tr ' ' '░'
    printf "${CYAN}] %d%% (%d/%d)${NC}" $percentage $current $total
}

function trap_ctrlc() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${WHITE}                           👋 Goodbye!                               ${RED}║${NC}"
    echo -e "${RED}║${YELLOW}                    Installation cancelled by user                   ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    exit 2
}
trap "trap_ctrlc" 2

### ENHANCED CHECKS ###
function check_requirements() {
    print_step "🔍 Checking System Requirements"
    
    local requirements=("curl" "dig")
    local missing=()
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root!"
        echo -e "${YELLOW}💡 Try running: ${WHITE}sudo su${NC}"
        exit 1
    fi
    
    # Check required commands
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required packages: ${missing[*]}"
        echo -e "${YELLOW}💡 Install them with: ${WHITE}apt install ${missing[*]}${NC}"
        exit 1
    fi
    
    success "All requirements satisfied!"
    echo ""
}

### ENHANCED PTERODACTYL PANEL INSTALLATION ###
function send_summary() {
    clear
    print_banner
    
    if [ -d "/var/www/pterodactyl" ]; then
        warning "Pterodactyl is already installed. This script may fail!"
        echo ""
    fi
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                           📋 INSTALLATION SUMMARY                    ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Panel URL:${NC}      ${GREEN}${FQDN:-'Not set'}${NC}$(printf "%*s" $((50 - ${#FQDN})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Webserver:${NC}      ${GREEN}${WEBSERVER:-'Not selected'}${NC}$(printf "%*s" $((46 - ${#WEBSERVER})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Email:${NC}          ${GREEN}${EMAIL:-'Not set'}${NC}$(printf "%*s" $((51 - ${#EMAIL})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}SSL:${NC}            ${GREEN}${SSLSTATUS:-'Not configured'}${NC}$(printf "%*s" $((44 - ${#SSLSTATUS})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Custom SSL:${NC}     ${GREEN}${CUSTOMSSL:-'Not configured'}${NC}$(printf "%*s" $((44 - ${#CUSTOMSSL})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Username:${NC}       ${GREEN}${USERNAME:-'Not set'}${NC}$(printf "%*s" $((48 - ${#USERNAME})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}First name:${NC}     ${GREEN}${FIRSTNAME:-'Not set'}${NC}$(printf "%*s" $((47 - ${#FIRSTNAME})) "") ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Last name:${NC}      ${GREEN}${LASTNAME:-'Not set'}${NC}$(printf "%*s" $((48 - ${#LASTNAME})) "") ${CYAN}║${NC}"
    if [ -n "$USERPASSWORD" ]; then
        local masked_password=$(printf "%0.s*" $(seq 1 ${#USERPASSWORD}))
        echo -e "${CYAN}║${NC} ${BOLD}Password:${NC}       ${GREEN}${masked_password}${NC}$(printf "%*s" $((49 - ${#masked_password})) "") ${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${NC} ${BOLD}Password:${NC}       ${YELLOW}Not set${NC}$(printf "%*s" $((49)) "") ${CYAN}║${NC}"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

function panel() {
    print_banner
    print_step "🚀 Starting Pterodactyl Panel Installation"
    info "Before installation, we need some information."
    echo ""
    panel_webserver
}

function panel_webserver() {
    send_summary
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                          🌐 SELECT WEBSERVER                         ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} ${BOLD}NGINX${NC} ${YELLOW}(recommended)${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[2]${NC} ${BOLD}Apache${NC}                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}👉 Enter your choice (1-2): ${NC}"
    read -r option
    
    case $option in
        1)
            WEBSERVER="NGINX"
            success "NGINX selected!"
            panel_fqdn
            ;;
        2)
            WEBSERVER="Apache"
            success "Apache selected!"
            panel_fqdn
            ;;
        *)
            error "Invalid option! Please enter 1 or 2."
            sleep 2
            panel_webserver
            ;;
    esac
}

function panel_fqdn() {
    send_summary
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                            🌍 DOMAIN SETUP                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    info "Please enter your FQDN (Fully Qualified Domain Name)"
    echo -e "${YELLOW}💡 Example: panel.yourdomain.com${NC}"
    echo ""
    echo -ne "${YELLOW}👉 Enter FQDN: ${NC}"
    read -r FQDN
    
    if [ -z "$FQDN" ]; then
        error "FQDN cannot be empty!"
        sleep 2
        panel_fqdn
        return
    fi

    echo ""
    loading_animation "🔍 Fetching public IP information" 3
    
    IP_CHECK=$(curl -s ipinfo.io/ip -4 2>/dev/null)
    IPV6_CHECK=$(curl -s v6.ipinfo.io/ip -6 2>/dev/null)

    if [ -z "$IP_CHECK" ] && [ -z "$IPV6_CHECK" ]; then
        error "Failed to retrieve public IP address!"
        return 1
    fi
    
    success "Detected Public IPv4: ${IP_CHECK}"
    [ -n "$IPV6_CHECK" ] && success "Detected Public IPv6: ${IPV6_CHECK}"
    
    loading_animation "🔍 Resolving domain" 2
    DOMAIN_PANELCHECK=$(dig +short "$FQDN" | head -n 1)

    if [ -z "$DOMAIN_PANELCHECK" ]; then
        warning "Could not resolve $FQDN to an IP address"
        warning "If you're running this locally, you can ignore this warning"
        echo -e "${YELLOW}⏳ Proceeding in 10 seconds... Press CTRL+C to cancel${NC}"
        sleep 10
    else
        success "$FQDN resolves to: $DOMAIN_PANELCHECK"
    fi

    loading_animation "🔍 Checking Cloudflare status" 2
    ORG_CHECK=$(curl -s "https://ipinfo.io/$DOMAIN_PANELCHECK/json" 2>/dev/null | grep -o '"org":.*' | cut -d '"' -f4)

    if [[ "$ORG_CHECK" == *"Cloudflare"* ]]; then
        warning "Your FQDN is behind Cloudflare Proxy"
        info "This is fine if you know what you're doing"
        warning "If using Cloudflare Flexible SSL, set TRUSTED_PROXIES in .env after installation"
        echo -e "${YELLOW}⏳ Proceeding in 10 seconds... Press CTRL+C to cancel${NC}"
        sleep 10
    else
        success "Your FQDN is NOT behind Cloudflare"
    fi

    panel_ssl
}

function panel_ssl() {
    send_summary
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                            🔒 SSL CONFIGURATION                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}🔐 Do you want to enable SSL for your Panel? ${GREEN}(Recommended)${NC}"
    echo ""
    echo -ne "${YELLOW}👉 Enable SSL? (Y/N): ${NC}"
    
    while :; do
        read -r SSL_CONFIRM
        case "${SSL_CONFIRM,,}" in
            y|yes)
                SSLSTATUS=true
                success "SSL enabled!"
                panel_ssltype
                break
                ;;
            n|no)
                SSLSTATUS=false
                warning "SSL disabled - your panel will be less secure!"
                panel_email
                break
                ;;
            *)
                error "Invalid input! Please enter Y or N."
                echo -ne "${YELLOW}👉 Enable SSL? (Y/N): ${NC}"
                ;;
        esac
    done
}

function panel_ssltype() {
    send_summary
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                           🔐 SSL TYPE SELECTION                       ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} ${BOLD}Let's Encrypt${NC} ${YELLOW}(recommended)${NC}                              ${CYAN}║${NC}"
    echo -e "${
