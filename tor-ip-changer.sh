#!/bin/bash

# ===============================
# TOR IP CHANGER - KALI LINUX
# PATCHED: REAL IP ROTATION
# ===============================

TORRC="/etc/tor/torrc"
CONTROL_PORT=9051
SOCKS_PORT=9050
CHECK_IP_URL="https://check.torproject.org/api/ip"
AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"
TOR_SERVICE="tor@default"
NYM_WAIT=12   # Tor-required cooldown

require_root() {
    [[ $EUID -ne 0 ]] && echo "[!] Run as root" && exit 1
}

install_all() {
    echo "[+] Installing requirements..."
    apt update
    apt install -y tor curl netcat-openbsd iptables

    mkdir -p /etc/tor
    touch "$TORRC"
    chmod 644 "$TORRC"

    sed -i '/^ControlPort/d;/^CookieAuthentication/d;/^MaxCircuitDirtiness/d;/^NewCircuitPeriod/d' "$TORRC"

    cat <<EOF >> "$TORRC"
ControlPort 9051
CookieAuthentication 1
MaxCircuitDirtiness 15
NewCircuitPeriod 15
EOF

    systemctl enable "$TOR_SERVICE"
    systemctl restart "$TOR_SERVICE"
    sleep 5

    systemctl is-active --quiet "$TOR_SERVICE" \
        && echo "[✓] Tor ready" \
        || echo "[!] Tor failed"
}

start_tor() {
    systemctl start "$TOR_SERVICE"
    sleep 5
    echo "[✓] Tor started"
}

stop_tor() {
    systemctl stop "$TOR_SERVICE"
    echo "[✓] Tor stopped"
}

get_ip() {
    curl --socks5-hostname 127.0.0.1:$SOCKS_PORT \
         -H "Connection: close" \
         -s "$CHECK_IP_URL" | grep -oE '"IP":"[^"]+' | cut -d'"' -f4
}

renew_ip() {
    echo "[*] Sending NEWNYM..."
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' \
        | nc 127.0.0.1 $CONTROL_PORT >/dev/null 2>&1

    echo "[*] Waiting Tor cooldown..."
    sleep $NYM_WAIT
}

force_new_ip() {
    OLD_IP=$(get_ip)
    echo "[*] Current IP: $OLD_IP"

    for ATTEMPT in {1..5}; do
        renew_ip
        NEW_IP=$(get_ip)

        if [[ -n "$NEW_IP" && "$NEW_IP" != "$OLD_IP" ]]; then
            echo "[✓] New Tor IP: $NEW_IP"
            return
        fi

        echo "[-] Exit reused, retrying..."
        sleep 10
    done

    echo "[!] Tor reused exit node (normal Tor behavior)"
}

auto_renew() {
    read -p "Enter renew interval (minutes, >=1): " MIN
    [[ ! "$MIN" =~ ^[0-9]+$ || "$MIN" -lt 1 ]] && echo "Invalid" && return

    (
        while true; do
            force_new_ip
            sleep $((MIN * 60))
        done
    ) &

    echo $! > "$AUTO_RENEW_PID"
    echo "[✓] Auto renew enabled"
}

stop_auto_renew() {
    [[ -f "$AUTO_RENEW_PID" ]] && kill "$(cat "$AUTO_RENEW_PID")" && rm -f "$AUTO_RENEW_PID" \
        && echo "[✓] Auto renew stopped" || echo "[!] Not running"
}

set_country() {
    read -p "Exit country code (US, DE, FR, NL): " COUNTRY
    sed -i '/^ExitNodes/d;/^StrictNodes/d' "$TORRC"
    echo "ExitNodes {$COUNTRY}" >> "$TORRC"
    echo "StrictNodes 1" >> "$TORRC"
    systemctl restart "$TOR_SERVICE"
    sleep 5
    echo "[✓] Exit country set"
}

kill_switch_on() {
    TOR_UID=$(id -u debian-tor)
    iptables -F
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -m owner --uid-owner "$TOR_UID" -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $SOCKS_PORT -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $CONTROL_PORT -j ACCEPT
    echo "[✓] Kill switch enabled"
}

kill_switch_off() {
    iptables -F
    iptables -P OUTPUT ACCEPT
    echo "[✓] Kill switch disabled"
}

pause() { read -p "Press Enter to continue..."; }

menu() {
    clear
    echo "======================================"
    echo " TOR IP CHANGER - REAL ROTATION FIXED "
    echo "======================================"
    echo "1) Install & Setup"
    echo "2) Start Tor"
    echo "3) Stop Tor"
    echo "4) Show Tor IP"
    echo "5) Force New IP (Verified)"
    echo "6) Auto Renew"
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
        4) get_ip ;;
        5) force_new_ip ;;
        6) auto_renew ;;
        7) stop_auto_renew ;;
        8) set_country ;;
        9) kill_switch_on ;;
        10) kill_switch_off ;;
        0) exit 0 ;;
        *) echo "Invalid" ;;
    esac
    pause
}

require_root
while true; do menu; done
