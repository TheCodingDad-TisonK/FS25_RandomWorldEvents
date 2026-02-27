# 🌍 FS25 Random World Events

![Downloads](https://img.shields.io/github/downloads/TheCodingDad-TisonK/FS25_RandomWorldEvents/total?style=for-the-badge)
![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/FS25_RandomWorldEvents?style=for-the-badge)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-red?style=for-the-badge)

Adds **43+ dynamic random events**, a physics overhaul, and a full in-game settings screen to **Farming Simulator 25** — making every playthrough feel different.

[Download Latest Release](https://github.com/TheCodingDad-TisonK/FS25_RandomWorldEvents/releases/latest) •
[Report Bug](https://github.com/TheCodingDad-TisonK/FS25_RandomWorldEvents/issues) •
[FS22 Version](https://github.com/TheCodingDad-TisonK/FS22_RandomWorldEvents)

---

> ℹ️ **Info**
>
> This mod is actively developed and supported on GitHub.
> Any uploads to other platforms not listed in the Availability section may not be authorized.

---

## 📌 Overview

**Random World Events** is the full FS25 rewrite of the FS22 original. It introduces a
probabilistic event engine that fires timed world events during gameplay, affecting your
economy, vehicles, fields, and more. Each event has configurable intensity, duration,
and cooldown. A separate physics layer applies terrain-aware wheel grip and suspension
tuning to the vehicle you're driving, every frame.

All settings save per-savegame, so each farm can have its own configuration.

---

## ✨ Features

### 🌍 Random Event System
- **43+ unique events** across 4 active categories
- Configurable **frequency** (1–10), **intensity** (1–5), and **cooldown** (1–240 min)
- Events trigger automatically on a probability timer during gameplay
- Manual trigger via **F9** or the `rweTest` console command
- Per-category enable/disable toggles (economic, vehicle, field, special)
- In-game HUD notifications and warnings when events start and end
- Single active event at a time — a cooldown prevents event spam

### 💰 Economic Events (15 events)
Government subsidies, market booms and crashes, tax refunds, loan interest, seed/fuel/fertilizer/equipment discounts, insurance payouts, export opportunities, economic crises, and more.

### 🚜 Vehicle Events (8 events)
Speed boosts, free fuel refills, fuel leaks, minor accidents, fleet repair bills, visual upgrades, vehicle cleaning, and engine trouble.

### 🌾 Field Events (10 events)
Crop yield bonuses and penalties, fertilizer effectiveness changes, seed growth speed adjustments, harvest modifiers, and field sale price shifts.

### ⚡ Special Events (10 events)
Time acceleration, time slowdown, XP bonuses and penalties, money multipliers, equipment durability changes, trade price bonuses, and town festivals.

### 🔧 Physics Overhaul
- **Terrain-aware wheel grip** — asphalt, dirt, field, grass, and snow each have distinct friction values
- **Suspension stiffness** multiplier applied per-wheel every frame
- All physics values are tunable from the in-game settings screen
- Debug mode logs per-wheel grip data to the console

### 🖥️ In-Game Settings Screen
Full tabbed GUI accessible from the game's menu:
- **Events Tab** — toggle categories, set frequency/intensity/cooldown, enable notifications
- **Physics Tab** — tune wheel grip, suspension stiffness, articulation damping, center-of-mass strength

### 💾 Per-Savegame Persistence
Settings are stored alongside each savegame — different farms can have different configurations without touching the mod files.

---

## 🛠️ Installation

1. Download `FS25_RandomWorldEvents.zip` from the [latest release](https://github.com/TheCodingDad-TisonK/FS25_RandomWorldEvents/releases/latest).
2. Place the zip in your FS25 mods folder:
   - **Windows:** `Documents\My Games\FarmingSimulator2025\mods\`
3. Launch Farming Simulator 25.
4. When starting or loading a savegame, enable **Random World Events** in the mod selection screen.
5. Load into your farm — you'll see a confirmation notification when the mod initializes.

---

## 🎛️ Default Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| `enabled` | `true` | — | Master on/off switch |
| `frequency` | `5` | 1–10 | Event trigger probability |
| `intensity` | `2` | 1–5 | Event magnitude |
| `cooldown` | `30` | 1–240 min | Minimum time between events |
| `showNotifications` | `true` | — | HUD notices when events start/end |
| `showWarnings` | `true` | — | Warning-level notifications |
| `economicEvents` | `true` | — | Enable economic category |
| `vehicleEvents` | `true` | — | Enable vehicle category |
| `fieldEvents` | `true` | — | Enable field category |
| `specialEvents` | `true` | — | Enable special category |

### Physics Defaults

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| `wheelGripMultiplier` | `1.0` | 0.1–5.0 | Base wheel friction scale |
| `suspensionStiffness` | `1.0` | 0.1–5.0 | Spring force multiplier |
| `articulationDamping` | `0.5` | 0.1–5.0 | Articulation damping factor |
| `comStrength` | `1.0` | 0.1–5.0 | Center-of-mass strength |

---

## 🖥️ Console Commands

Open the in-game console (`` ` `` key) and type any of these:

| Command | Description |
|---------|-------------|
| `rwe` | Show all available commands |
| `rweStatus` | Show current status — enabled state, active event, cooldown |
| `rweTest` | Force-trigger a random event immediately |
| `rweEnd` | Forcibly end the currently active event |
| `rweDebug on\|off` | Toggle debug mode (verbose logging) |
| `rweList [category]` | List all registered events, optionally filtered by category |

### Key Bindings

| Key | Action |
|-----|--------|
| **F9** | Force-trigger a random event |
| **F3** | Open settings screen *(coming soon)* |

---

## 🌐 Availability

| Platform | Status |
|----------|--------|
| **GitHub** | ✅ [Official Source](https://github.com/TheCodingDad-TisonK/FS25_RandomWorldEvents) |
| **ModHub** | 🔄 Pending |
| **KingMods** | 🔄 Pending |

---

## 📖 Version History

| Version | Date | Notes |
|---------|------|-------|
| **v2.0.0.0** | 2026-02 | Full FS25 rewrite — new event engine, physics layer, tabbed GUI, per-savegame settings |

---

## ⚠️ Known Limitations

- **Wildlife/animal events** — category toggle exists but events are not yet implemented
- **Weather events** — category toggle exists but events are not yet implemented
- **Multiplayer** — declared as supported but money/physics changes are local-only; proper network sync is not yet implemented
- **Physics values** — `articulationDamping` and `comStrength` are configurable but not yet wired to an FS25 physics API call

---

## 🚧 Planned Features

- Complete wildlife/animal event category
- Complete weather event category
- Multiplayer-safe money synchronization
- Full F3 settings screen keybind
- Event history log viewable in-game
- Weighted event selection (rare vs. common events)

---

## ⬆️ Upgrading from FS22

This is a ground-up rewrite for FS25. FS22 savegame settings will not transfer — configure the mod fresh in each savegame. The event catalog has been expanded and the physics system is new in v2.

---

## 🤝 Credits

- **Author**: TisonK
- **Special Thanks**: FS25 modding community and everyone who reported bugs on the FS22 version

---

## 📬 Support

Found a bug or have a feature request?
Open an issue on GitHub:

👉 https://github.com/TheCodingDad-TisonK/FS25_RandomWorldEvents/issues

---

## ⚖️ License

**All rights reserved.**

Unauthorized redistribution, modification, reuploading, or claiming this mod as your own is **strictly prohibited**.

Original author: TisonK

---

*Enjoy a more unpredictable farming experience!* 🌾
