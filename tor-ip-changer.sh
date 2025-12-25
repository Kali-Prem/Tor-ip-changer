#!/bin/bash

# ==========================================
# TOR IP CHANGER — Kali-Prem FINAL VERSION
# ==========================================

TOR_SERVICE="tor@default"
TORRC="/etc/tor/torrc"
SOCKS_PORT=9050
CONTROL_PORT=9051
CHECK_IP_URL="https://check.torproject.org/api/ip"

AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"
NEXT_RENEW_FILE="/tmp/tor_next_renew.time"

# ---------- CORE ----------

require_root() {
    [[ $EUID -ne 0 ]] && echo "[!] Run as root" && exit 1
}

tor_status() {
    systemctl is-active --quiet "$TOR_SERVICE" && echo "RUNNING" || echo "STOPPED"
}

get_ip() {
    curl --socks5-hostname 127.0.0.1:$SOCKS_PORT -s "$CHECK_IP_URL" \
        | grep -oE '"IP":"[^"]+' | cut -d'"' -f4
}

get_countdown() {
    [[ ! -f "$NEXT_RENEW_FILE" ]] && echo "N/A" && return
    NOW=$(date +%s)
    NEXT=$(cat "$NEXT_RENEW_FILE")
    (( NEXT <= NOW )) && echo "00:00" && return
    REMAIN=$((NEXT - NOW))
    printf "%02d:%02d" $((REMAIN / 60)) $((REMAIN % 60))
}

notify_ip_change() {
    echo -ne "\a"
    command -v notify-send &>/dev/null && \
        notify-send "Tor IP Changed" "New IP: $1" --icon=network-vpn
}

# ---------- YOUR ORIGINAL BANNER ----------

tor_changer_banner() {
    clear
    echo -e "\e[38;5;51m████████╗ \e[38;5;45m██████╗ \e[38;5;39m██████╗     \e[38;5;33m██████╗ \e[38;5;27m██╗  ██╗ \e[38;5;21m █████╗ \e[38;5;93m███╗   ██╗ \e[38;5;87m███████╗\e[0m"
    echo -e "\e[38;5;51m╚══██╔══╝ \e[38;5;45m██╔═══██╗\e[38;5;39m██╔═══██╗    \e[38;5;33m██╔════╝ \e[38;5;27m██║  ██║ \e[38;5;21m██╔══██╗\e[38;5;93m████╗  ██║ \e[38;5;87m██╔════╝\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m██║   ██║\e[38;5;39m██║   ██║    \e[38;5;33m██║      \e[38;5;27m███████║ \e[38;5;21m███████║\e[38;5;93m██╔██╗ ██║ \e[38;5;87m█████╗\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m██║   ██║\e[38;5;39m██║   ██║    \e[38;5;33m██║      \e[38;5;27m██╔══██║ \e[38;5;21m██╔══██║\e[38;5;93m██║╚██╗██║ \e[38;5;87m██╔══╝\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m╚██████╔╝\e[38;5;39m╚██████╔╝    \e[38;5;33m╚██████╗ \e[38;5;27m██║  ██║ \e[38;5;21m██║  ██║\e[38;5;93m██║ ╚████║ \e[38;5;87m███████╗\e[0m"
    echo -e "\e[38;5;51m   ╚═╝     \e[38;5;45m╚═════╝  \e[38;5;39m╚═════╝     \e[38;5;33m ╚═════╝ \e[38;5;27m╚═╝  ╚═╝ \e[38;5;21m╚═╝  ╚═╝\e[38;5;93m╚═╝  ╚═══╝ \e[38;5;87m╚══════╝\e[0m"
    echo
    echo -e "\e[38;5;118m Tor Changer — Real IP Rotation via Tor ControlPort\e[0m"
    echo -e "\e[38;5;244m Status : $(tor_status) | Tor IP : $(get_ip) | Next : $(get_countdown)\e[0m"
    echo -e "\e[38;5;244m Author:~[Kali-Prem] | Github: https://github.com/Kali-Prem\e[0m"
    echo
}

# ---------- RUNNING STATUS (BELOW MENU) ----------

show_runtime_status() {
    echo "------------------ Running Status ------------------"
    echo "Tor Service     : $(tor_status)"
    echo "Tor IP          : $(get_ip)"
    echo "Tor PID(s)      : $(pgrep -x tor | tr '\n' ' ' || echo None)"
    ss -lnt | grep -q ":$SOCKS_PORT" && echo "SOCKS 9050     : LISTENING" || echo "SOCKS 9050     : NOT LISTENING"
    ss -lnt | grep -q ":$CONTROL_PORT" && echo "Control 9051   : LISTENING" || echo "Control 9051   : NOT LISTENING"
    [[ -f "$AUTO_RENEW_PID" ]] && echo "Auto Renew     : RUNNING" || echo "Auto Renew     : STOPPED"
    echo "----------------------------------------------------"
    echo
}

# ---------- INSTALL ----------

install_all() {
    apt update
    apt install -y tor curl netcat-openbsd iptables libnotify-bin
    cat <<EOF > "$TORRC"
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 1
UseEntryGuards 0
NewCircuitPeriod 10
MaxCircuitDirtiness 10
EOF
    systemctl enable "$TOR_SERVICE"
    systemctl restart "$TOR_SERVICE"
    read -p "Install complete. Press Enter..."
}

# ---------- TOR LOGIC ----------

renew_ip() {
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' | nc 127.0.0.1 $CONTROL_PORT &>/dev/null
    sleep 5
}

force_new_ip() {
    OLD=$(get_ip)
    renew_ip
    NEW=$(get_ip)
    [[ -n "$NEW" && "$OLD" != "$NEW" ]] && notify_ip_change "$NEW"
}

auto_renew() {
    read -p "Interval (minutes): " MIN
    INTERVAL=$((MIN * 60))
    echo $(( $(date +%s) + INTERVAL )) > "$NEXT_RENEW_FILE"
    (
        while true; do
            force_new_ip
            echo $(( $(date +%s) + INTERVAL )) > "$NEXT_RENEW_FILE"
            sleep "$INTERVAL"
        done
    ) & echo $! > "$AUTO_RENEW_PID"
}

stop_auto_renew() {
    [[ -f "$AUTO_RENEW_PID" ]] && kill "$(cat "$AUTO_RENEW_PID")"
    rm -f "$AUTO_RENEW_PID" "$NEXT_RENEW_FILE"
}

update_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null && git pull || echo "Not a git repo"
    read -p "Press Enter..."
}

# ---------- MENU ----------

menu() {
    tor_changer_banner
    echo "1) Install & Setup(Recommended)"
    echo "2) Start Tor"
    echo "3) Stop Tor"
    echo "4) Show Tor IP"
    echo "5) Force New IP"
    echo "6) Auto Renew"
    echo "7) Stop Auto Renew"
    echo "R) Refresh"
    echo "U) Update Repository"
    echo "0) Exit"
    echo

    show_runtime_status

    read -p "Select option: " CHOICE
    case "$CHOICE" in
        1) install_all ;;
        2) systemctl start "$TOR_SERVICE" ;;
        3) systemctl stop "$TOR_SERVICE" ;;
        4) echo "Tor IP: $(get_ip)"; read -p "Press Enter..." ;;
        5) force_new_ip ;;
        6) auto_renew ;;
        7) stop_auto_renew ;;
        R|r) return ;;
        U|u) update_repo ;;
        0) exit 0 ;;
    esac
}

require_root
while true; do menu; done
