# 🔐 Tor IP Changer – Kali Linux

**Short tagline:**

> Simple, secure Tor-based IP rotation with an interactive CLI for Kali Linux.

---

## 🛡️ Badges

![Platform](https://img.shields.io/badge/platform-Kali%20Linux-blue)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey)
![Tor](https://img.shields.io/badge/network-Tor-purple)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-active-success)

---

## 📌 Overview

**Tor IP Changer** is an **all‑in‑one Bash tool for Kali Linux** that automates Tor installation, configuration, and **IP rotation** using **Tor‑approved methods**. It provides a clean **interactive CLI menu** to manage Tor circuits, rotate IPs, set exit countries, enable a firewall kill switch, and schedule automatic renewals.

Built for **privacy‑focused users, penetration testers, and security researchers**.

---

## ✨ Features

* 🚀 One‑command install & setup
* 📟 Interactive CLI menu
* 🔄 Instant IP renew using `SIGNAL NEWNYM`
* ⏱ Auto IP rotation every X minutes
* 🌍 Exit country selector
* 🧱 Firewall kill switch (prevents IP leaks)
* 🔐 Tor ControlPort support
* ⚙️ Auto‑start Tor service
* 🐧 Optimized for Kali Linux

---

## 🛠️ How It Works

* Routes traffic through the **Tor network**
* Requests new circuits using **Tor ControlPort**
* Blocks traffic leaks with **iptables kill switch**
* Uses **official Tor packages** (no spoofing, no custom crypto)

---

## 📦 Installation

```bash
git clone https://github.com/Kali-Prem/tor-ip-changer
cd tor-ip-changer
chmod +x tor-ip-changer.sh
sudo ./tor-ip-changer.sh
```

---

## ▶ Usage

Launch the interactive menu:

```bash
sudo ./tor-ip-changer.sh
```

Route applications through Tor:

```bash
proxychains firefox
proxychains curl ifconfig.me
```

---

## 🖼️ Screenshots

> *(Add real screenshots here)*

### Main Menu

![Main Menu](screenshots/menu.png)

### Exit Country Selection

![Country Selector](screenshots/country.png)

### IP Rotation & Status

![IP Check](screenshots/ip-check.png)

---

## ⚠️ Disclaimer

This project is intended for **educational and privacy‑enhancing purposes only**.

* Does **not** guarantee anonymity
* Does **not** bypass laws, bans, or restrictions
* Users are responsible for their own actions

---

## 📄 License

MIT License — free to use, modify, and learn responsibly.

---

## 🤝 Contributing

Pull requests are welcome. Suggestions, issues, and improvements are appreciated.
