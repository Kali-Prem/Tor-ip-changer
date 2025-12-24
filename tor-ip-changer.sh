#!/usr/bin/env python3

import os
import sys
import time
import socket
import subprocess
import requests

TOR_CONTROL_PORT = 9051
TOR_SOCKS_PORT = 9050
CHECK_IP_URL = "https://httpbin.org/ip"
TOR_SERVICE = "tor@default"

PROXY = {
    "http": "socks5h://127.0.0.1:9050",
    "https": "socks5h://127.0.0.1:9050",
}

# =========================
# UTILITIES
# =========================

def require_root():
    if os.geteuid() != 0:
        sys.exit("\033[1;91m[!] Run this script as root.\033[0m")

def clear():
    os.system("clear")

def banner():
    print("\033[1;92m")
    print(" TOR IP CHANGER - CONTROLPORT EDITION ")
    print(" Author : isPique (Reviewed & Fixed)")
    print(" Version: 2.1")
    print("\033[0m")

# =========================
# TOR FUNCTIONS
# =========================

def tor_running():
    result = subprocess.run(
        ["systemctl", "is-active", TOR_SERVICE],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )
    return result.stdout.strip() == "active"

def start_tor():
    if not tor_running():
        subprocess.run(["systemctl", "start", TOR_SERVICE], check=False)
        time.sleep(5)

def stop_tor():
    subprocess.run(["systemctl", "stop", TOR_SERVICE], check=False)

def wait_for_tor():
    for _ in range(30):
        try:
            requests.get(CHECK_IP_URL, proxies=PROXY, timeout=5)
            return True
        except:
            time.sleep(1)
    return False

def renew_ip():
    try:
        with socket.create_connection(("127.0.0.1", TOR_CONTROL_PORT), timeout=5) as s:
            s.sendall(b'AUTHENTICATE ""\r\n')
            s.sendall(b'SIGNAL NEWNYM\r\n')
            s.sendall(b'QUIT\r\n')
    except Exception as e:
        print(f"\033[1;91m[-] ControlPort error: {e}\033[0m")

# =========================
# IP FUNCTIONS
# =========================

def get_ip(use_tor=False):
    try:
        r = requests.get(
            CHECK_IP_URL,
            proxies=PROXY if use_tor else None,
            timeout=10
        )
        return r.json().get("origin", "Unknown")
    except:
        return "Unavailable"

# =========================
# MAIN
# =========================

def main():
    require_root()
    clear()
    banner()

    print("\033[1;34m[*] Checking Tor installation...\033[0m")
    if subprocess.run(["which", "tor"], stdout=subprocess.DEVNULL).returncode != 0:
        sys.exit("\033[1;91m[-] Tor is not installed.\033[0m")

    start_tor()

    if not wait_for_tor():
        sys.exit("\033[1;91m[-] Tor failed to start.\033[0m")

    print(f"\033[1;92m[+] Current IP (Normal): {get_ip()}\033[0m")
    print(f"\033[1;92m[+] Current IP (Tor):    {get_ip(True)}\033[0m")

    try:
        interval = int(input("\n\033[1;93m[>] Change IP every (seconds): \033[0m"))
        if interval < 10:
            raise ValueError
    except:
        sys.exit("\033[1;91m[-] Interval must be >= 10 seconds.\033[0m")

    print("\033[1;91m[!] Press CTRL+C to stop.\033[0m\n")

    while True:
        renew_ip()
        time.sleep(10)  # Tor cooldown
        new_ip = get_ip(True)
        print(f"\033[1;92m[+] New Tor IP: {new_ip}\033[0m")
        time.sleep(interval)

# =========================
# ENTRY
# =========================

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\033[1;93m[!] Exiting...\033[0m")
        stop_tor()
