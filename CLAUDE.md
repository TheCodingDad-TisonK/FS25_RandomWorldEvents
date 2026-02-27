# FS25_RandomWorldEvents — Claude Code Project Instructions

## Project Overview

**FS25_RandomWorldEvents** is a Farming Simulator 25 mod (v2.0.0.0) that introduces a
random-event system and a physics override layer to the base game. Events fire on a
probabilistic timer during gameplay and can affect the economy, vehicles, fields, animals,
and special game-state variables. All settings persist per-savegame via an XML file.

Author: TisonK | License: All rights reserved.

---

## Repository Layout

```
FS25_RandomWorldEvents/
├── RandomWorldEvents.lua          # Core manager + FS25 lifecycle hooks
├── modDesc.xml                    # Mod metadata, l10n strings, source file list
├── guiProfiles.xml                # GUI style profiles
├── icon.dds                       # Mod icon
├── icons/
│   ├── events.dds                 # Tab icon — Events page
│   └── settings.dds               # Tab icon — Settings page
├── gui/
│   ├── RandomWorldEventsScreen.lua  # TabbedMenuWithDetails screen wrapper
│   ├── RandomWorldEventsFrame.lua   # Events/settings frame (tab 1)
│   └── RandomWorldDebugFrame.lua    # Physics/debug frame (tab 2)
├── xml/
│   ├── RandomWorldEventsScreen.xml
│   ├── RandomWorldEventsFrame.xml
│   └── RandomWorldDebugFrame.xml
└── utils/
    ├── economicEvents.lua           # 15 economic events
    ├── vehicleEvents.lua            # 8 vehicle events
    ├── fieldEvents.lua              # 10 field events
    ├── animalEvents.lua             # BUG: currently duplicates specialEvents.lua
    ├── specialEvents.lua            # 10 special events (time, XP, money, trade)
    └── PhysicsUtils.lua             # Terrain-aware physics override layer
```

---

## Architecture

### Singleton Pattern
There is exactly one runtime instance of `RandomWorldEvents`, exposed globally as
`g_RandomWorldEvents`. It is created inside `Mission00.load` and torn down in
`FSBaseMission.delete`.

### Lifecycle Hooks
```
Mission00.load        → creates g_RandomWorldEvents, loads modules + GUI
FSBaseMission.update  → drives the event timer and active-event tick
FSBaseMission.delete  → saves settings, clears g_RandomWorldEvents
FSBaseMission.keyEvent → F3 (settings screen, stub), F9 (force trigger)
```

### Deferred Module Registration
Event modules load before `g_RandomWorldEvents` is guaranteed to exist (FS25 loads
all `extraSourceFiles` in order). Each module checks for `g_RandomWorldEvents` at
load time; if absent it pushes a closure into `RandomWorldEvents.pendingRegistrations`.
The core then drains that list inside `loadEventModules()` after the singleton is
ready.

### Settings Persistence
Settings are stored at:
```
<savegameDirectory>/<MOD_NAME>.xml
```
The `settingsManager` embedded in `RandomWorldEvents:new()` handles load/save via
FS25's `XMLFile` API. On first run (no file), defaults are deep-copied from
`manager.defaultConfig`.

### EVENT_STATE
`RandomWorldEvents.EVENT_STATE` is a **class-level table** (not per-instance). It
stores the active event ID, start time, duration, cooldown timestamp, and all
transient effect flags (e.g. `marketBonus`, `yieldBonus`, `vehicleSpeedBoost`).
Only one event can be active at a time.

---

## Known Bugs & Issues

| # | Location | Issue |
|---|----------|-------|
| 1 | `utils/animalEvents.lua` | File contains `specialEvents` code verbatim — animal/wildlife events are **not implemented**. The `wildlifeEvents` toggle controls nothing. |
| 2 | `modDesc.xml:90` | `<filename>` tag uses the attribute name `filename` twice: `<filename name="RandomWorldEventsScreen" filename="gui/..."/>`. The second attribute should be `filename` but the first should likely be `name`. Some parsers may reject this. |
| 3 | `modDesc.xml` | Version field says `1.0.0.0` but Lua headers say `2.0.0.0`. |
| 4 | `economicEvents.lua:242` + `vehicleEvents.lua:420` | Both modules monkey-patch `g_RandomWorldEvents:update` via `originalUpdate` chaining. If both run, the second module overwrites the first module's override, **silently dropping** the first module's per-tick effects. This pattern is fragile. |
| 5 | `RandomWorldEventsScreen.lua:45–50` | Tab icons are swapped: the Events frame gets `settings.dds` and the Debug frame gets `events.dds`. |
| 6 | `RandomWorldEvents.lua:664–673` | `keyEvent` has a redundant inner `if rweManager then` check (the outer guard already confirms it). Minor but misleading. |
| 7 | `PhysicsUtils.lua:140–158` | `PhysicsUtils` is self-clobbered: `PhysicsUtils = PhysicsUtils:new()`. If the pending-registration path runs AND `loadEventModules` also instantiates it, there is a double-init. Both produce the same result but log confusingly. |
| 8 | `fieldEvents.lua:99–104` | `canTrigger` checks `fieldController.fields` exists and `#fields > 0`. FS25 uses a `g_fieldManager` API, not `g_currentMission.fieldController` — this guard may never pass, causing field events to silently not fire on many maps. |

---

## Coding Conventions

- **Logging prefix**: always `[RWE]` for the core, `[EconomicEvents]`, `[VehicleEvents]`,
  etc. for modules. Use `Logging.info`, `Logging.warning`, `Logging.error`.
- **Guard patterns**: every module function that touches `g_RandomWorldEvents` or
  `g_currentMission` begins with a nil-check.
- **Event registration**: call `g_RandomWorldEvents:registerEvent({ ... })`. See
  `DEVELOPMENT.md` for the full event schema.
- **No globals**: use `local` for all module-internal tables. Only `g_RandomWorldEvents`
  is intentionally global.
- **FS25 API**: prefer `vehicle:method()` over direct field access. Do not assume
  `getFillUnitInformation`, `getMotor`, `addDamageAmount` exist — guard with `if vehicle.method`.
- **Settings**: never write settings directly to disk except via `g_RandomWorldEvents:saveSettings()`.

---

## Build & Deploy

```bash
# From Mods Base Directory
bash build.sh --deploy
```

Deploys zip to:
```
C:\Users\tison\Documents\My Games\FarmingSimulator2025\mods
```

After deploying, tail the game log for the `[RandomWorldEvents]` / `[RWE]` prefix:
```
C:\Users\tison\Documents\My Games\FarmingSimulator2025\log.txt
```

---

## Console Commands (in-game)

| Command | Description |
|---------|-------------|
| `rwe` | Print help |
| `rweStatus` | Show enabled state, active event, cooldown |
| `rweTest` | Force-trigger a random event |
| `rweEnd` | Forcibly end the active event |
| `rweDebug on\|off` | Toggle debug mode |
| `rweList [category]` | List registered events |

Hotkeys: **F9** — force trigger event.
