# AirVolt ⚡

**Universal wireless peripheral battery monitor for macOS Menu Bar.**  
*Native, ultra-lightweight macOS alternative to [Wireless-Device-Battery-Monitor](https://github.com/krisgfx9/Wireless-Device-Battery-Monitor).*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Release](https://img.shields.io/badge/Release-v1.0.0-green.svg)](https://github.com/skywhyfinder/AirVolt/releases)

---

## ✨ Features

- **⚡ Universal Device Support (No Vendor Bloatware Required):**
  - **Mice & Keyboards:** Logitech (Lightspeed HID++), Razer (HyperSpeed), SteelSeries, Corsair, Keychron, Attack Shark (X3/X6/R1), Darmoshark, VGN/VXE, Delux, Ajazz, Mchose, Apple Magic Mouse/Keyboard, and any standard Bluetooth / 2.4G HID peripheral.
  - **Gamepads & Controllers:** Native macOS GameController integration. Supports **Flydigi** (Vader 3/4 Pro, Apex 3/4), **8BitDo**, **GameSir**, **Machenike**, **Sony DualSense / DualShock 4**, **Xbox Series / One**, **Nintendo Switch**, and generic Chinese/MFi gamepads.
  - **Headsets & Earbuds:** Apple AirPods, AirPods Max, Beats, Sony, JBL, Samsung Galaxy Buds, and headsets reporting battery via Bluetooth or USB receivers.
- **🖥️ Sits in the macOS Menu Bar:**
  - Shows dynamic device icons and live battery percentages (e.g. `🖱 88%  🎧 100%  ⚡`).
  - Customizable view modes: *All devices (up to 3)*, *Lowest battery only*, or *Icon-only*.
- **📊 Elegant Dropdown Dashboard:**
  - One-click popover in macOS Sequoia / Sonoma style.
  - Shows exact percentage, colorful battery bar, charging status (⚡), connection type (Bluetooth, 2.4G Wireless, USB), and brand name.
- **🔔 Low Battery Notifications:**
  - Native macOS alerts when any device drops below your chosen threshold (e.g. 20%, 15%, 10%).
- **🚀 Launch at Login:**
  - Seamless auto-start via macOS `SMAppService`.
  - Runs as a menu bar accessory app without cluttering your Dock.
- **🧪 Demo Mode:**
  - Built-in preview switch (✨) to test UI states and device cards anytime without needing hardware connected.
- **🪶 Ultra Lightweight:**
  - 100% Native Swift + SwiftUI / AppKit.
  - ~5 MB binary size, ~20 MB RAM, and near 0.0% CPU when idle.

---

## 📥 Installation

### Option 1: Download Pre-built Release
1. Go to the [Releases](https://github.com/skywhyfinder/AirVolt/releases) page.
2. Download `AirVolt-macOS-v1.0.0.zip`.
3. Unzip and drag `AirVolt.app` to your `Applications` folder.
4. Launch AirVolt!

### Option 2: Build from Source
```bash
git clone https://github.com/skywhyfinder/AirVolt.git
cd AirVolt
./Scripts/build_app.sh
open build/AirVolt.app
```

Or run via Swift CLI:
```bash
swift run
```

---

## 🛠️ How It Works Under the Hood

AirVolt leverages multiple native macOS driver layers:
1. **`GameController.framework` (`GCController`):** Real-time battery reporting for all controllers (Flydigi, 8BitDo, Xbox, DualSense, Nintendo, etc.).
2. **`IOKit.hid` (`IOHIDManager`):** Directly reads reports from 2.4 GHz USB dongles (Logitech HID++, Razer, CompX/Telink Chinese mouse receivers) and standard HID Battery Strength elements.
3. **`IOBluetooth` / System Profiler:** Fetches battery state for connected Bluetooth audio and peripherals.
4. **`IOKit.ps` (Power Sources):** Monitors Apple accessories and recognized power sources.

---

## 📜 License & Credits

Distributed under the **GNU General Public License v3.0 (GPL-3.0)**.  
Inspired by [Wireless-Device-Battery-Monitor](https://github.com/krisgfx9/Wireless-Device-Battery-Monitor) by `@krisgfx9`.
