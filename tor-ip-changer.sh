#!/bin/bash

# ===============================
# TOR IP CHANGER - KALI LINUX
# Fixed & Hardened
# ===============================

TORRC="/etc/tor/torrc"
CONTROL_PORT=9051
SOCKS_PORT=9050
CHECK_IP_URL="https://ifconfig.me"
AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"
TOR_SERVICE="tor@default"

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "[!] Run as root: sudo ./tor-ip-changer.sh"
        exit 1
    fi
}

install_all() {
    echo "[+] Installing Tor & requirements..."
    apt update
    apt install -y tor curl netcat-openbsd iptables

    echo "[+] Preparing torrc..."
    mkdir -p /etc/tor
    touch "$TORRC"
    chmod 644 "$TORRC"

    sed -i '/^ControlPort/d' "$TORRC"
    sed -i '/^CookieAuthentication/d' "$TORRC"
    sed -i '/^ExitNodes/d' "$TORRC"
    sed -i '/^StrictNodes/d' "$TORRC"

    cat <<EOF >> "$TORRC"
ControlPort 9051
CookieAuthentication 1
EOF

    echo "[+] Enabling Tor service..."
    systemctl enable "$TOR_SERVICE"
    systemctl restart "$TOR_SERVICE"

    sleep 2
    systemctl is-active --quiet "$TOR_SERVICE" \
        && echo "[✓] Tor installed and running" \
        || echo "[!] Tor failed to start"
}

start_tor() {
    systemctl start "$TOR_SERVICE"
    echo "[✓] Tor started"
}

stop_tor() {
    systemctl stop "$TOR_SERVICE"
    echo "[✓] Tor stopped"
}

get_ip() {
    curl --socks5 127.0.0.1:$SOCKS_PORT -s "$CHECK_IP_URL" || echo "Tor not running"
}

renew_ip() {
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' \
        | nc 127.0.0.1 $CONTROL_PORT >/dev/null 2>&1

    echo "[✓] IP Renew requested"
}

auto_renew() {
    read -p "Enter renew interval (minutes): " MIN
    [[ ! "$MIN" =~ ^[0-9]+$ ]] && echo "Invalid number" && return

    (
        while true; do
            sleep $((MIN * 60))
            renew_ip
        done
    ) &

    echo $! > "$AUTO_RENEW_PID"
    echo "[✓] Auto renew every $MIN minutes"
}

stop_auto_renew() {
    if [[ -f "$AUTO_RENEW_PID" ]]; then
        kill "$(cat "$AUTO_RENEW_PID")" 2>/dev/null
        rm -f "$AUTO_RENEW_PID"
        echo "[✓] Auto renew stopped"
    else
        echo "[!] Auto renew not running"
    fi
}

set_country() {
    read -p "Enter exit country code (US, DE, FR, NL): " COUNTRY
    COUNTRY=$(echo "$COUNTRY" | tr -d '{}')

    sed -i '/^ExitNodes/d' "$TORRC"
    sed -i '/^StrictNodes/d' "$TORRC"

    echo "ExitNodes {$COUNTRY}" >> "$TORRC"
    echo "StrictNodes 1" >> "$TORRC"

    systemctl restart "$TOR_SERVICE"
    echo "[✓] Exit country set to $COUNTRY"
}

kill_switch_on() {
    TOR_UID=$(id -u debian-tor 2>/dev/null)
    [[ -z "$TOR_UID" ]] && echo "[!] Tor user not found" && return

    iptables -F
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -m owner --uid-owner "$TOR_UID" -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $SOCKS_PORT -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $CONTROL_PORT -j ACCEPT

    echo "[✓] Kill switch ENABLED"
}

kill_switch_off() {
    iptables -F
    iptables -P OUTPUT ACCEPT
    echo "[✓] Kill switch DISABLED"
}

pause() {
    read -p "Press Enter to continue..."
}

menu() {
    clear
    echo "======================================"
    echo "      TOR IP CHANGER - KALI LINUX"
    echo "======================================"
    echo "1) Install & Setup Everything"
    echo "2) Start Tor"
    echo "3) Stop Tor"
    echo "4) Show Current Tor IP"
    echo "5) Renew IP (NEWNYM)"
    echo "6) Auto Renew Every X Minutes"
    echo "7) Stop Auto Renew"
    echo "8) Set Exit Country"
    echo "9) Enable Kill Switch"
    echo "10) Disable Kill Switch"
    echo "0) Exit"
    echo "======================================"
    read -p "Select option: " CHOICE

    case "$CHOICE" in
        1) install_all ;;
        2) start_tor ;;
        3) stop_tor ;;
        4) echo "[+] Current Tor IP:" && get_ip ;;
        5) renew_ip && sleep 5 && get_ip ;;
        6) auto_renew ;;
        7) stop_auto_renew ;;
        8) set_country ;;
        9) kill_switch_on ;;
        10) kill_switch_off ;;
        0) exit 0 ;;
        *) echo "[!] Invalid option" ;;
    esac

    pause
}

require_root
while true; do menu; done
