#!/bin/bash

# ===============================
# TOR IP CHANGER - ALL IN ONE
# Kali Linux
# ===============================


                                                                                                                                                                                                           
                                                                                                                                                                                                           
echo "TTTTTTTTTTTTTTTTTTTTTTT                                                    CCCCCCCCCCCCChhhhhhh"                                                                                                            
echo "T:::::::::::::::::::::T                                                 CCC::::::::::::Ch:::::h"                                                                                                            
echo "T:::::::::::::::::::::T                                               CC:::::::::::::::Ch:::::h"                                                                                                            
echo "T:::::TT:::::::TT:::::T                                              C:::::CCCCCCCC::::Ch:::::h"                                                                                                            
echo "TTTTTT  T:::::T  TTTTTTooooooooooo   rrrrr   rrrrrrrrr              C:::::C       CCCCCC h::::h hhhhh         aaaaaaaaaaaaa  nnnn  nnnnnnnn       ggggggggg   ggggg    eeeeeeeeeeee    rrrrr   rrrrrrrrr"   
echo "        T:::::T      oo:::::::::::oo r::::rrr:::::::::r            C:::::C               h::::hh:::::hhh      a::::::::::::a n:::nn::::::::nn    g:::::::::ggg::::g  ee::::::::::::ee  r::::rrr:::::::::r"  
echo "        T:::::T     o:::::::::::::::or:::::::::::::::::r           C:::::C               h::::::::::::::hh    aaaaaaaaa:::::an::::::::::::::nn  g:::::::::::::::::g e::::::eeeee:::::eer:::::::::::::::::r" 
echo "        T:::::T     o:::::ooooo:::::orr::::::rrrrr::::::r          C:::::C               h:::::::hhh::::::h            a::::ann:::::::::::::::ng::::::ggggg::::::gge::::::e     e:::::err::::::rrrrr::::::r"
echo "        T:::::T     o::::o     o::::o r:::::r     r:::::r          C:::::C               h::::::h   h::::::h    aaaaaaa:::::a  n:::::nnnn:::::ng:::::g     g:::::g e:::::::eeeee::::::e r:::::r     r:::::r"
echo "        T:::::T     o::::o     o::::o r:::::r     rrrrrrr          C:::::C               h:::::h     h:::::h  aa::::::::::::a  n::::n    n::::ng:::::g     g:::::g e:::::::::::::::::e  r:::::r     rrrrrrr"
echo "        T:::::T     o::::o     o::::o r:::::r                      C:::::C               h:::::h     h:::::h a::::aaaa::::::a  n::::n    n::::ng:::::g     g:::::g e::::::eeeeeeeeeee   r:::::r"            
echo "        T:::::T     o::::o     o::::o r:::::r                       C:::::C       CCCCCC h:::::h     h:::::ha::::a    a:::::a  n::::n    n::::ng::::::g    g:::::g e:::::::e            r:::::r"            
echo "      TT:::::::TT   o:::::ooooo:::::o r:::::r                        C:::::CCCCCCCC::::C h:::::h     h:::::ha::::a    a:::::a  n::::n    n::::ng:::::::ggggg:::::g e::::::::e           r:::::r"            
echo "      T:::::::::T   o:::::::::::::::o r:::::r                         CC:::::::::::::::C h:::::h     h:::::ha:::::aaaa::::::a  n::::n    n::::n g::::::::::::::::g  e::::::::eeeeeeee   r:::::r"            
echo "      T:::::::::T    oo:::::::::::oo  r:::::r                           CCC::::::::::::C h:::::h     h:::::h a::::::::::aa:::a n::::n    n::::n  gg::::::::::::::g   ee:::::::::::::e   r:::::r"            
echo "      TTTTTTTTTTT      ooooooooooo    rrrrrrr                              CCCCCCCCCCCCC hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa nnnnnn    nnnnnn    gggggggg::::::g     eeeeeeeeeeeeee   rrrrrrr"            
echo "                                                                                                                                                           g:::::g"                                         
echo "                                                                                                                                               gggggg      g:::::g"                                         
echo "                                                                                                                                               g:::::gg   gg:::::g"                                         
echo "                                                                                                                                                g::::::ggg:::::::g "                                        
echo "                                                                                                                                                 gg:::::::::::::g"                                          
echo "                                                                                                                                                   ggg::::::ggg"                                            
echo "                                                                                                                                                      gggggg"                                               

echo "Created by: Kali-Prem"
echo "GitHub:- https://github.com/Kali-Prem"

echo "Version: 1.0.0"







TORRC="/etc/tor/torrc"
CONTROL_PORT=9051
CHECK_IP_URL="https://ifconfig.me"
AUTO_RENEW_PID="/tmp/tor_auto_renew.pid"

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "[!] Run as root: sudo ./tor-ip-changer.sh"
        exit 1
    fi
}

install_all() {
    echo "[+] Installing Tor & requirements..."
    apt update -y
    apt install -y tor proxychains4 curl netcat iptables

    echo "[+] Configuring Tor ControlPort..."
    sed -i '/ControlPort/d' $TORRC
    sed -i '/CookieAuthentication/d' $TORRC
    echo "ControlPort 9051" >> $TORRC
    echo "CookieAuthentication 1" >> $TORRC

    systemctl enable tor
    systemctl restart tor

    echo "[✓] Installation complete"
}

get_ip() {
    proxychains -q curl -s $CHECK_IP_URL
}

renew_ip() {
    echo -e 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT' \
    | nc 127.0.0.1 $CONTROL_PORT > /dev/null
}

auto_renew() {
    read -p "Enter renew interval (minutes): " MIN
    echo "[+] Auto renew every $MIN minutes"

    (
        while true; do
            sleep $(($MIN * 60))
            renew_ip
        done
    ) &

    echo $! > $AUTO_RENEW_PID
    echo "[✓] Auto renew started"
}

stop_auto_renew() {
    if [[ -f $AUTO_RENEW_PID ]]; then
        kill "$(cat $AUTO_RENEW_PID)" 2>/dev/null
        rm -f $AUTO_RENEW_PID
        echo "[✓] Auto renew stopped"
    else
        echo "[!] Auto renew not running"
    fi
}

set_country() {
    read -p "Enter exit country code (US, DE, FR, NL): " COUNTRY
    sed -i '/ExitNodes/d' $TORRC
    sed -i '/StrictNodes/d' $TORRC
    echo "ExitNodes {$COUNTRY}" >> $TORRC
    echo "StrictNodes 1" >> $TORRC
    systemctl restart tor
    echo "[✓] Exit country set to $COUNTRY"
}

kill_switch_on() {
    TOR_UID=$(id -u debian-tor)

    iptables -F
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 9051 -j ACCEPT

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

    case $CHOICE in
        1) install_all ;;
        2) systemctl start tor && echo "[✓] Tor started" ;;
        3) systemctl stop tor && echo "[✓] Tor stopped" ;;
        4) echo "[+] Current IP:" && get_ip ;;
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
