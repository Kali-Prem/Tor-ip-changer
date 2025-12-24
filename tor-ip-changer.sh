#!/bin/bash

# ==========================================
# TOR IP CHANGER — FINAL FIX (KALI LINUX)
# ==========================================

TOR_SERVICE="tor@default"
TORRC="/etc/tor/torrc"
SOCKS_PORT=9050
CONTROL_PORT=9051
CHECK_IP_URL="https://check.torproject.org/api/ip"
NYM_WAIT=15
AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"

require_root() {
    [[ $EUID -ne 0 ]] && echo "[!] Run as root" && exit 1
}

install_all() {
    echo "[+] Installing requirements..."
    apt update
    apt install -y tor curl netcat-openbsd iptables

    echo "[+] Writing hardened torrc..."
    cat <<EOF > "$TORRC"
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 1

UseEntryGuards 0
NewCircuitPeriod 10
MaxCircuitDirtiness 10
CircuitBuildTimeout 5

ClientOnly 1
AvoidDiskWrites 1
EOF

    systemctl enable "$TOR_SERVICE"
    systemctl restart "$TOR_SERVICE"

    echo "[+] Waiting for Tor bootstrap..."
    sleep 8
    journalctl -u "$TOR_SERVICE" -n 5 --no-pager
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
         -s "$CHECK_IP_URL" \
         | grep -oE '"IP":"[^"]+' | cut -d'"' -f4
}

renew_ip() {
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' \
        | nc 127.0.0.1 $CONTROL_PORT >/dev/null 2>&1
    sleep $NYM_WAIT
}

force_new_ip() {
    OLD_IP=$(get_ip)
    echo "[*] Current IP: $OLD_IP"

    for i in {1..6}; do
        echo "[*] Requesting new circuit..."
        renew_ip
        NEW_IP=$(get_ip)

        if [[ -n "$NEW_IP" && "$NEW_IP" != "$OLD_IP" ]]; then
            echo "[✓] IP CHANGED: $NEW_IP"
            return
        fi

        echo "[-] Exit reused, retrying..."
        sleep 10
    done

    echo "[!] Tor reused exit node (normal Tor behavior)"
}

auto_renew() {
    read -p "Auto renew interval (minutes ≥1): " MIN
    [[ ! "$MIN" =~ ^[0-9]+$ || "$MIN" -lt 1 ]] && echo "Invalid interval" && return

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

pause() { read -p "Press Enter to continue..."; }

menu() {
    clear
    echo "======================================"
    echo " TOR IP CHANGER — FINAL FIXED VERSION "
    echo "======================================"
    echo "1) Install & Setup (RECOMMENDED)"
    echo "2) Start Tor"
    echo "3) Stop Tor"
    echo "4) Show Tor IP"
    echo "5) Force New IP (Verified)"
    echo "6) Auto Renew"
    echo "7) Stop Auto Renew"
    echo "0) Exit"
    echo "======================================"
    read -p "Select option: " CHOICE

    case "$CHOICE" in
        1) install_all ;;
        2) start_tor ;;
        3) stop_tor ;;
        4) echo "[+] Tor IP: $(get_ip)" ;;
        5) force_new_ip ;;
        6) auto_renew ;;
        7) stop_auto_renew ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    pause
}

require_root
while true; do menu; done
