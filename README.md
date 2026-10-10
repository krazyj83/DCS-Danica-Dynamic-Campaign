# Danica Dynamic Campaign

A perpetual, persistent dynamic campaign for DCS World. One Lua engine runs inside a 24/7 server
mission, the war keeps going whether anyone is online or not, and when one side loses its last
base the server moves on to the next map in the rotation.

**Status: phase 1 of 5 — the core loop on Caucasus.** Ground forces hold nodes, mass for
assaults, capture bases, the front line is drawn on the F10 map, and the whole war is saved and
restored across restarts. Player mission boards, supply convoys, fog of war and map rotation
automation come in later phases (see [Roadmap](#roadmap)).

![Simulated war](docs/sim_war.png)

*A simulated war with nobody online. Players near a front fight it as real DCS units instead.*

---

## How it works (the concepts)

| Concept | What it means |
| --- | --- |
| **Node** | A place that can be owned: an airbase, a town or a **depot**. Depots produce new forces and can only be attacked once nothing else of that side is within reach. Caucasus depots: Batumi and Tbilisi-Lochini (BLUE), Sochi-Adler, Beslan and Krasnodar-Center (RED). |
| **Edge** | A road between two nodes. All movement follows edges. |
| **Platoon** | The unit of force: one DCS group of 3–5 vehicles with a role (armour, mechanised, SHORAD) and a health from 0 to 1. |
| **Tick** | One war step = 5 minutes of mission time. Each tick: depots produce, columns move, battles resolve, each side plans. |
| **Encirclement** | A node cut off by road from every friendly depot gets no reinforcements and slowly loses strength until relieved. |
| **Main effort** | Each side picks one enemy node to break and piles reinforcements next to it beyond the normal cap, then attacks with everything it staged. This is what moves a front built of chains of towns. |
| **Live bubble** | Nodes within 40 km of any player are *live*: their garrisons and road columns are spawned as real DCS groups, and DCS does the fighting. Everywhere else the war runs on dice. |
| **Read-back** | Every 30 s the engine polls spawned groups. Dead vehicles lower the platoon's health; a column's position becomes its progress along the road. |
| **Theater pack** | A data file per map (`theaters/*.lua`): nodes with lat/lon, roads, start owners. No map is named in engine code. |
| **Era catalog** | A data file per era (`catalogs/*.lua`) mapping roles to DCS unit types per side, with fallbacks if a type is missing. |

The key design idea: **spawned units are a view of the saved numbers.** Any unit on the map
can be rebuilt from the save file, so a restart, a crash or a map change loses nothing.

```
theaters/  catalogs/             Saved Games\DCS\DCC\<Map>_war.json
     \        /                              ^
      war model (dcc_war.lua)  <-- save/load (dcc_persist.lua)
           ^      |
   read-back      | spawn / despawn, F10 drawing
           |      v
      DCS bridge (dcc_dcs.lua)  <-->  DCS world + players
```

---

## Server setup (step by step)

### 1. Allow the campaign to save

DCS blocks file access from missions by default. On the **server** machine, edit
`<DCS install>\Scripts\MissionScripting.lua` and comment out the two lines for `io` and `lfs`:

```lua
do
	sanitizeModule('os')
	--sanitizeModule('io')
	--sanitizeModule('lfs')
	_G['require'] = nil
	_G['loadlib'] = nil
	_G['package'] = nil
end
```

DCS updates overwrite this file — re-apply it after every update (DCSServerBot can do it for you).
Without it the campaign still runs but forgets everything on restart; `dcs.log` says
`persistence OFF` when that happens.

### 2. Build the bundle

```bash
python tools/build_bundle.py
```

This writes `dist/dcc_bundle.lua` — the engine plus every theater pack and catalog in one file.

### 3. Make the mission (once per map)

1. Open the **Mission Editor**, create a new mission on **Caucasus**.
2. Coalitions: put **CJTF Blue** on BLUE and **CJTF Red** on RED (the engine spawns units under these countries).
3. Add the player aircraft and helicopter slots you want, for both sides, at friendly airbases from the start map (BLUE in Georgia, RED in the north). Nothing else needs placing — no ground units, no zones.
4. **Options**: set the F10 map view to your fog-of-war preference (e.g. *Fog of war* or *Map only*), and turn off *External views* if you want realism.
5. **Triggers** — exactly one trigger:
   - Type **MISSION START**, name `DCC start`
   - Action **DO SCRIPT FILE** → `dist/dcc_bundle.lua`
6. Save the mission (e.g. `DCC_Caucasus.miz`) and put it in the server's mission list.

That single trigger is deliberate: editor triggers poll every condition once per second and
only react to ten event types, which does not scale to a war with dozens of bases. Everything
else runs in Lua timers that cost nothing while idle.

> **Re-save after updating the scripts.** DO SCRIPT FILE copies the file into the `.miz`. After
> rebuilding the bundle, re-open the trigger, re-select the file and save the mission.

### 4. Development mode (optional)

To edit scripts without re-saving the mission each time:

1. Copy `src/`, `theaters/` and `catalogs/` into `Saved Games\DCS\Scripts\DCC\`.
2. Point the MISSION START trigger at `src/dcc_loader.lua` instead of the bundle.
3. Edit files in `Saved Games\DCS\Scripts\DCC\` and restart the mission.

### 5. Run it

Start the server. The first start creates a new war; every later start continues it. Players
get an F10 radio menu **Campaign → Campaign status** with node counts, their side's main effort
and the latest captures.

Save files live in `Saved Games\DCS\DCC\`:

| File | Purpose |
| --- | --- |
| `Caucasus_war.json` | The live save, written every 5 minutes and at mission end |
| `Caucasus_war_bak0..23.json` | Rotating backups; a corrupt main save falls back to the newest one |
| `Caucasus_war_final_<tick>.json` | A finished war, archived before a new one starts |

To **reset a war**, stop the server and delete `Caucasus_war.json` and the backups.

### 6. When a war ends

The engine announces the winner and the next map, and sets **user flag 9900** to 1. In phase 5,
DCSServerBot will watch that flag and load the next mission in the rotation
(Caucasus → Syria → Persian Gulf → Cold War Germany). Until then, switch the mission by hand.

---

## What players see

- **Front line** — yellow segments across every road whose two ends belong to different sides.
- **Nodes** — circles in the owner's colour (depots larger, dashed outline) with the name for everyone, and the garrison size for the owner only.
- **Own assaults** — arrows from staging node to target, visible only to the attacking side.
- **Messages** — captures and repulsed attacks for everyone; your side's main-effort and assault orders for your side only.
- **Airbases** — DCS auto-capture is off; airbase coalition follows the war, so slots and ATC switch sides when a base falls.
- **Ground battles** — fly within 40 km of a front and the units are real: anything you destroy is gone from the war.

---

## Tuning

Every number is in `src/dcc_config.lua` with a comment. The ones that matter most:

| Setting | Default | Effect |
| --- | --- | --- |
| `tickSeconds` | 300 | Length of one war step |
| `depotProductionEveryTicks` | 3 | One new platoon per depot every 15 min (before territory bonus) |
| `productionPerNode` | 0.08 | +8 % production per node gained since the start (−8 % per node lost); gives momentum |
| `isolationAttrition` | 0.01 | Health lost per tick by garrisons cut off from every friendly depot (~6 h to collapse) |
| `liveRadiusKm` | 40 | How close a player must be for units to spawn |
| `maxLivePlatoons` | 120 | Hard cap on spawned platoons (~500 vehicles) — lower it if the server struggles |
| `battleLossRate` | 0.15 | How fast dice battles bleed; higher = faster wars |
| `defenderBonus` | town 1.3, airbase 1.5, depot 2.0 | How hard each node class is to take |

Per-map balance lives in the theater pack: `balance = { blue = 1.0, red = 1.0 }` multiplies each
side's production.

### Balance status (phase 1)

Measured with the offline simulator, no players online:

- **The code is side-neutral.** With the start map mirrored (red in Georgia) the Georgia side won 9 of 10, so any bias comes from geography, not the engine.
- **The map was not.** Georgia is compact with depots right behind its front. Moving red's northern depot from Mozdok to Beslan and adding a red depot at Sochi-Adler brought the start close to even.
- **AI-only wars see-saw.** The front changes hands many times a day and never freezes, but most AI-only wars were still running after 6 weeks; about 1 in 7 ended (blue, around day 16–32). Players near the front tip that balance, and phase 2's supply lines (convoys you can cut) are meant to make breakthroughs decisive. Expect to tune `productionPerNode` and `battleLossRate` after watching the first real nights.

---

## Testing offline

Nothing here needs DCS to test. The engine is plain Lua 5.1 (the version DCS uses) and runs
under Python via `lupa`:

```bash
pip install lupa matplotlib

python tools/run_lua.py tests/test_war.lua          # war model: 20 checks incl. exact save/restore
python tools/run_lua.py tests/test_dcs_bridge.lua   # bridge + main loop against a fake DCS API

python tools/run_lua.py tools/sim.lua 15000 2026 docs/sim_history.json   # simulate a war
python tools/plot_war.py docs/sim_history.json docs/sim_war.png          # plot it
```

`tests/dcs_mock.lua` fakes the parts of the DCS scripting API the bridge uses (spawning, groups,
airbases, F10 drawing, timers, files). It catches wiring bugs; it does not replace a real test
flight.

---

## Project layout

```
src/
  dcc_config.lua    every tunable number
  dcc_util.lua      lat/lon geometry, seeded RNG, helpers
  dcc_json.lua      JSON encode/decode for saves
  dcc_war.lua       the war model (pure Lua, no DCS calls)
  dcc_front.lua     front-line geometry from ownership
  dcc_persist.lua   save / load / backups (the only file access)
  dcc_dcs.lua       DCS bridge: live bubble, spawning, read-back, F10 drawing, menus
  dcc_main.lua      start-up and the 30 s / 5 min loops
  dcc_loader.lua    development loader
theaters/caucasus.lua   Caucasus nodes, roads, start owners
catalogs/modern.lua     Modern era role -> unit types
tests/                  model tests, bridge tests, DCS API mock
tools/                  Lua runner, simulator, plotter, bundle builder
```

---

## Roadmap

| Phase | Scope | Done when |
| --- | --- | --- |
| **1 — Core loop (this)** | Theater pack, nodes and owners, AI assaults, capture, front line, save/load | The front moves on its own overnight and survives a restart |
| 2 — Supply economy | Warehouses, real convoys and cargo flights, budget-driven commander | Killing a convoy visibly delays the assault it was feeding |
| 3 — Player missions | Mission boards for RED and BLUE: CAP, escort, BAI, CAS, SEAD/DEAD, strike, CTLD, CSAR, helo convoy escort; persistent pilots | Every mission type writes its effect to the save |
| 4 — Fog of war and intel | Detection table, contact aging, recon, Hound ELINT, IADS | Each side's map shows only what it has detected |
| 5 — Rotation and all maps | Victory detection → next map, theater-pack generator, more catalogs | A win on Caucasus loads the next map unattended |

## License

MIT — see [LICENSE](LICENSE).
