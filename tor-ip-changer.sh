#!/bin/bash

# ==========================================
# TOR IP CHANGER — FULL FEATURED (KALI)
# ==========================================

TOR_SERVICE="tor@default"
TORRC="/etc/tor/torrc"
SOCKS_PORT=9050
CONTROL_PORT=9051
CHECK_IP_URL="https://check.torproject.org/api/ip"
NYM_WAIT=15
AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"

# ---------- CORE UTILS ----------

require_root() {
    [[ $EUID -ne 0 ]] && echo "[!] Run as root" && exit 1
}

tor_status() {
    systemctl is-active --quiet "$TOR_SERVICE" && echo "RUNNING" || echo "STOPPED"
}

get_ip() {
    curl --socks5-hostname 127.0.0.1:$SOCKS_PORT \
         -H "Connection: close" -s "$CHECK_IP_URL" \
         | grep -oE '"IP":"[^"]+' | cut -d'"' -f4
}

# ---------- BANNER ----------

tor_changer_banner() {
    clear
    STATUS=$(tor_status)
    IP=$(get_ip)
    [[ -z "$IP" ]] && IP="N/A"

    echo -e "\e[38;5;51m████████╗ \e[38;5;45m██████╗ \e[38;5;39m██████╗     \e[38;5;33m██████╗ \e[38;5;27m██╗  ██╗ \e[38;5;21m █████╗ \e[38;5;93m███╗   ██╗ \e[38;5;87m███████╗\e[0m"
    echo -e "\e[38;5;51m╚══██╔══╝ \e[38;5;45m██╔═══██╗\e[38;5;39m██╔═══██╗    \e[38;5;33m██╔════╝ \e[38;5;27m██║  ██║ \e[38;5;21m██╔══██╗\e[38;5;93m████╗  ██║ \e[38;5;87m██╔════╝\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m██║   ██║\e[38;5;39m██║   ██║    \e[38;5;33m██║      \e[38;5;27m███████║ \e[38;5;21m███████║\e[38;5;93m██╔██╗ ██║ \e[38;5;87m█████╗\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m██║   ██║\e[38;5;39m██║   ██║    \e[38;5;33m██║      \e[38;5;27m██╔══██║ \e[38;5;21m██╔══██║\e[38;5;93m██║╚██╗██║ \e[38;5;87m██╔══╝\e[0m"
    echo -e "\e[38;5;51m   ██║    \e[38;5;45m╚██████╔╝\e[38;5;39m╚██████╔╝    \e[38;5;33m╚██████╗ \e[38;5;27m██║  ██║ \e[38;5;21m██║  ██║\e[38;5;93m██║ ╚████║ \e[38;5;87m███████╗\e[0m"
    echo -e "\e[38;5;51m   ╚═╝     \e[38;5;45m╚═════╝  \e[38;5;39m╚═════╝     \e[38;5;33m ╚═════╝ \e[38;5;27m╚═╝  ╚═╝ \e[38;5;21m╚═╝  ╚═╝\e[38;5;93m╚═╝  ╚═══╝ \e[38;5;87m╚══════╝\e[0m"
    echo
    echo -e "\e[38;5;118m Tor Changer — Real IP Rotation via Tor ControlPort\e[0m"
    echo -e "\e[38;5;244m Status : $STATUS   |   Tor IP : $IP\e[0m"
    echo -e "\e[38;5;244m Author : Kali-Prem | Platform : Kali Linux\e[0m"
    echo
}

# ---------- RUNTIME STATUS ----------

show_runtime_status() {
    echo "------------------ Runtime Status ------------------"

    systemctl is-active --quiet "$TOR_SERVICE" \
        && echo "[Tor Service]      : RUNNING" \
        || echo "[Tor Service]      : STOPPED"

    TOR_PIDS=$(pgrep -x tor | tr '\n' ' ')
    [[ -z "$TOR_PIDS" ]] && TOR_PIDS="None"
    echo "[Tor PID(s)]       : $TOR_PIDS"

    ss -tulnp | grep -q ":$SOCKS_PORT" \
        && echo "[SOCKS 9050]       : LISTENING" \
        || echo "[SOCKS 9050]       : NOT LISTENING"

    ss -tulnp | grep -q ":$CONTROL_PORT" \
        && echo "[Control 9051]     : LISTENING" \
        || echo "[Control 9051]     : NOT LISTENING"

    if [[ -f "$AUTO_RENEW_PID" ]] && ps -p "$(cat $AUTO_RENEW_PID)" &>/dev/null; then
        echo "[Auto Renew]       : RUNNING (PID $(cat $AUTO_RENEW_PID))"
    else
        echo "[Auto Renew]       : STOPPED"
    fi

    IP=$(get_ip)
    [[ -z "$IP" ]] && IP="N/A"
    echo "[Current Tor IP]   : $IP"

    echo "----------------------------------------------------"
    echo
}

# ---------- TOR LOGIC ----------

install_all() {
    apt update
    apt install -y tor curl netcat-openbsd iptables

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
    sleep 5
}

start_tor() { systemctl start "$TOR_SERVICE"; sleep 5; }
stop_tor()  { systemctl stop "$TOR_SERVICE"; }

renew_ip() {
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' | nc 127.0.0.1 $CONTROL_PORT >/dev/null 2>&1
    sleep $NYM_WAIT
}

force_new_ip() {
    OLD_IP=$(get_ip)
    for _ in {1..6}; do
        renew_ip
        NEW_IP=$(get_ip)
        [[ "$NEW_IP" != "$OLD_IP" && -n "$NEW_IP" ]] && break
    done
}

auto_renew() {
    read -p "Auto renew interval (minutes): " MIN
    (
        while true; do
            force_new_ip
            sleep $((MIN * 60))
        done
    ) & echo $! > "$AUTO_RENEW_PID"
}

stop_auto_renew() {
    [[ -f "$AUTO_RENEW_PID" ]] && kill "$(cat "$AUTO_RENEW_PID")" && rm -f "$AUTO_RENEW_PID"
}

pause() { read -p "Press Enter to continue..."; }

# ---------- MENU ----------

menu() {
    tor_changer_banner
    echo "1) Install & Setup(recommended)"
    echo "2) Start Tor"
    echo "3) Stop Tor"
    echo "4) Show Tor IP"
    echo "5) Force New IP"
    echo "6) Auto Renew"
    echo "7) Stop Auto Renew"
    echo "0) Exit"
    echo "======================================"

    show_runtime_status

    read -p "Select option: " CHOICE
    case "$CHOICE" in
        1) install_all ;;
        2) start_tor ;;
        3) stop_tor ;;
        4) echo "Tor IP: $(get_ip)" ;;
        5) force_new_ip ;;
        6) auto_renew ;;
        7) stop_auto_renew ;;
        0) exit 0 ;;
    esac
    pause
}

require_root
while true; do menu; done
