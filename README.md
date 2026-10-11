# Danica Dynamic Campaign

A perpetual, persistent dynamic campaign for DCS World. One Lua engine runs inside a 24/7 server
mission, the war keeps going whether anyone is online or not, and when one side loses its last
base the server moves on to the next map in the rotation.

**Status: phase 2 of 5 — supply economy, on Caucasus.** Ground forces hold nodes, mass for
assaults and capture bases. Every base runs on supply that trucks and transport aircraft carry
forward, and player aircraft at each airbase follow ownership and stock. The front line is drawn
on the F10 map and the whole war is saved across restarts. A ready-to-fly mission file is
generated for you. Player mission boards, fog of war and map rotation automation come next
(see [Roadmap](#roadmap)).

![Simulated war](docs/sim_war.png)

*A simulated war with nobody online. Players near a front fight it as real DCS units instead.*

---

## Quick start

1. **Server: allow saving** — see [step 1](#1-allow-the-campaign-to-save) below.
2. **Take the mission** `dist/DCC_Caucasus.miz` and put it in the server's mission list (or
   `Saved Games\DCS\Missions` to try it yourself).
3. **Start it as a multiplayer server** (also locally for testing: *Multiplayer → New server*).
   Pick a side and an aircraft at any airbase your side owns.

That's it — the mission already contains the engine, every airbase, and the player aircraft.

---

## How it works (the concepts)

| Concept | What it means |
| --- | --- |
| **Node** | A place that can be owned: an airbase, a town or a **depot**. Depots produce new forces and supply, and can only be attacked once nothing else of that side is within reach. Caucasus depots: Batumi and Tbilisi-Lochini (BLUE), Sochi-Adler, Beslan and Krasnodar-Center (RED). |
| **Edge** | A road between two nodes. All ground movement follows edges. |
| **Platoon** | The unit of force: one DCS group of 3–5 vehicles with a role (armour, mechanised, SHORAD) and a health from 0 to 1. |
| **Tick** | One war step = 5 minutes of mission time. Each tick: depots produce, columns and cargo move, battles resolve, supply is used, each side plans. |
| **Supply (SU)** | One number per node for fuel, ammunition and spares. Every platoon uses a little each tick; an attack costs supply at the node it starts from. |
| **Out of supply** | A node at 0 supply defends without its bonus and its platoons lose strength every tick (~12 h to collapse). A pocket no convoy can reach simply runs dry. |
| **Convoy** | Trucks carrying supply one road at a time toward the front. Near players they are real trucks — destroy them and the cargo never arrives. |
| **Airlift** | A transport aircraft (C-130 / Il-76) carrying supply between friendly airbases. Always a real aircraft, so it can be intercepted anywhere. Keeps cut-off airbases alive. |
| **Main effort** | Each side picks one enemy node to break, piles platoons and supply next to it, then attacks with everything it staged. |
| **Live bubble** | Nodes within 40 km of any player are *live*: their garrisons, columns and convoys are spawned as real DCS groups, and DCS does the fighting. Everywhere else the war runs on dice. |
| **Read-back** | Every 30 s the engine polls spawned groups. Dead vehicles lower a platoon's health or a convoy's cargo; positions become progress along the road. |
| **Warehouse** | Each airbase's DCS warehouse holds the owner's player aircraft (dynamic spawn). Players take aircraft out and bring them back; lost ones are replaced one an hour, paid for in supply — only at a supplied base. |
| **Theater pack** | A data file per map (`theaters/*.lua`): nodes with lat/lon, roads, start owners. No map is named in engine code. |
| **Era catalog** | A data file per era (`catalogs/*.lua`) mapping roles to DCS unit types per side, plus convoy trucks, transports and player aircraft. |

The key design idea: **spawned units are a view of the saved numbers.** Any unit on the map
can be rebuilt from the save file, so a restart, a crash or a map change loses nothing.

```
theaters/  catalogs/             Saved Games\DCS\DCC\<Map>_war.json
     \        /                              ^
  war model (dcc_war.lua + dcc_supply.lua) <-- save/load (dcc_persist.lua)
           ^      |
   read-back      | spawn / despawn, warehouses, F10 drawing
           |      v
  DCS bridge (dcc_dcs.lua + dcc_dcs_supply.lua)  <-->  DCS world + players
```

**Does it matter if I kill a convoy?** Yes, measured: in 8 paired offline wars, destroying the
convoys feeding BLUE's main effort cut the platoons BLUE could send into assaults by 38 % and its
captures from 59 to 43 over one war day (`tools/interdiction.lua`).

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

### 2. The mission

Use the generated **`dist/DCC_Caucasus.miz`**. It contains:

| What | Details |
| --- | --- |
| Coalitions | CJTF Blue vs CJTF Red (either side can use any unit type) |
| Airbase ownership | As in the theater pack (BLUE Georgia, RED north / Abkhazia / South Ossetia) |
| **Dynamic spawn** on all 23 campaign airbases | In multiplayer, players pick any aircraft their side's base holds. The engine removes the enemy's types and stocks the owner's at mission start and after every capture. |
| **Fixed client slots** at the depots | One per aircraft type at Batumi, Tbilisi-Lochini (BLUE) and Sochi-Adler, Beslan, Krasnodar-Center (RED). These also work in single player. |
| One trigger | MISSION START → DO SCRIPT FILE `dcc_bundle.lua` (the engine) |
| Options | F10 map in fog-of-war mode, civil traffic off |

**Player aircraft** (edit `catalogs/modern.lua` → `aircraft` to change):

| Side | Planes | Helicopters |
| --- | --- | --- |
| BLUE | F/A-18C, F-16C, F-15E, A-10C II, F-14B, AV-8B, F-4E, Su-25T | AH-64D, UH-1H, OH-58D, CH-47F, SA342M |
| RED | Su-27, Su-33, MiG-29S, J-11A, JF-17, Su-25, Su-25T, MiG-21bis | Ka-50 III, Mi-24P, Mi-8MTV2 |

Su-25T is on both sides so everyone has a free aircraft to fly. You can only fly modules you own.

**Rebuilding the mission** (after changing the catalog, theater or scripts):

```bash
pip install lupa git+https://github.com/pydcs/dcs.git
python tools/build_bundle.py      # -> dist/dcc_bundle.lua
python tools/make_mission.py      # -> dist/DCC_Caucasus.miz
```

The generator reads the same theater pack and catalog as the engine, so they never disagree.

> **Making the mission by hand instead?** Use CJTF Blue / CJTF Red, add player slots, and one
> MISSION START → DO SCRIPT FILE trigger pointing at `dist/dcc_bundle.lua`. DO SCRIPT FILE copies
> the file into the `.miz`, so re-select it and re-save after every rebuild.

### 3. Development mode (optional)

To edit scripts without regenerating the mission each time:

1. Copy `src/`, `theaters/` and `catalogs/` into `Saved Games\DCS\Scripts\DCC\`.
2. In the mission, point the MISSION START trigger at `src/dcc_loader.lua` instead of the bundle.
3. Edit files in `Saved Games\DCS\Scripts\DCC\` and restart the mission.

### 4. Run it

Start the server. The first start creates a new war; every later start continues it (a phase 1
save is upgraded automatically: supply and aircraft stock are added). Players get an F10 radio
menu **Campaign → Campaign status** with node counts, the main effort, their side's supply,
convoys and airlifts, any bases out of supply, and the latest captures and kills.

Save files live in `Saved Games\DCS\DCC\`:

| File | Purpose |
| --- | --- |
| `Caucasus_war.json` | The live save, written every 5 minutes and at mission end |
| `Caucasus_war_bak0..23.json` | Rotating backups; a corrupt main save falls back to the newest one |
| `Caucasus_war_final_<tick>.json` | A finished war, archived before a new one starts |

To **reset a war**, stop the server and delete `Caucasus_war.json` and the backups.

### 5. When a war ends

The engine announces the winner and the next map, and sets **user flag 9900** to 1. In phase 5,
DCSServerBot will watch that flag and load the next mission in the rotation
(Caucasus → Syria → Persian Gulf → Cold War Germany). Until then, switch the mission by hand.

### 6. First flight test — what to check

The offline tests use a fake DCS API, so these need a real server to confirm:

- [ ] Dynamic spawn lists **only your side's** aircraft at each base, and a captured base switches lists.
- [ ] Fixed depot slots spawn, cold start.
- [ ] Garrisons appear when you fly within 40 km of a front; columns and convoys drive on roads.
- [ ] A transport (C-130 / Il-76) appears when the F10 status reports an airlift, and lands at its destination.
- [ ] Destroying a convoy prints "… convoy … destroyed" and the target base's SU stops rising.
- [ ] `dcs.log` has no `DCC: ERROR` lines.

---

## What players see

- **Front line** — yellow segments across every road whose two ends belong to different sides.
- **Nodes** — circles in the owner's colour (depots larger, dashed outline) with the name for everyone. The owner also sees `platoons | SU`, and `NO SUPPLY` when a base has run dry.
- **Own assaults** — arrows from staging node to target; **own airlifts** — a line origin → destination. Only your side sees them.
- **Messages** — captures, repulsed attacks and destroyed convoys/airlifts for everyone; your side's main effort, assaults, airlifts and out-of-supply warnings for your side.
- **Airbases** — DCS auto-capture is off; the airbase coalition follows the war, and so do the aircraft you can spawn there. Spawning at a base your side does not own removes you with a message.
- **Ground battles and convoys** — within 40 km of a front everything is real: what you destroy is gone from the war.

---

## Tuning

Every number is in `src/dcc_config.lua` with a comment. The ones that matter most:

| Setting | Default | Effect |
| --- | --- | --- |
| `tickSeconds` | 300 | Length of one war step |
| `depotProductionEveryTicks` | 3 | One new platoon per depot every 15 min (before territory bonus) |
| `productionPerNode` | 0.08 | +8 % production (platoons and supply) per node gained since the start, −8 % per node lost |
| `supply.depotPerTick` | 6 | SU a depot produces per tick |
| `supply.upkeepPerPlatoon` | 0.05 | SU each platoon uses per tick |
| `supply.assaultCostPerPlatoon` | 2 | SU an attack costs per platoon |
| `supply.outOfSupplyAttrition` | 0.005 | Health lost per tick at 0 supply (~12 h to collapse) |
| `supply.convoyCapacity` | 30 | SU per convoy |
| `supply.maxAirlifts` | 2 | Transports in the air per side |
| `supply.airRestockTicks` / `airRestockCost` | 12 / 5 | One lost aircraft replaced per hour per base, for 5 SU |
| `liveRadiusKm` | 40 | How close a player must be for units to spawn |
| `maxLivePlatoons` | 120 | Hard cap on spawned platoons (~500 vehicles) — lower it if the server struggles |
| `battleLossRate` | 0.15 | How fast dice battles bleed; higher = faster wars |
| `defenderBonus` | town 1.3, airbase 1.5, depot 2.0 | How hard each node class is to take (only while supplied) |

Player aircraft stock per base is `aircraftStock` in the catalog (4 per type, 8 at depots).
Per-map balance lives in the theater pack: `balance = { blue = 1.0, red = 1.0 }` multiplies each
side's production.

### Balance status (phase 2)

Measured with the offline simulator, no players online:

- **The code is side-neutral.** With the start map mirrored, the Georgia side still won, so any bias comes from geography; red's depots were moved to Beslan and Sochi-Adler to even the start.
- **Wars stay alive.** In 14 wars of 42 days each, the front changed hands 500–800 times per war and swung both ways; starvation is about 8 % of losses, mostly freshly captured towns.
- **AI-only wars do not end on their own.** With supply, the two commanders are evenly matched, so none of the 14 finished. Players decide wars — every convoy, airlift and garrison you kill shifts the balance. If you want wars to end even on an empty server, a "war clock" is easy to add.

---

## Testing offline

Nothing here needs DCS to test. The engine is plain Lua 5.1 (the version DCS uses) and runs
under Python via `lupa`:

```bash
pip install lupa matplotlib

python tools/run_lua.py tests/test_war.lua          # war model + supply: 29 checks
python tools/run_lua.py tests/test_dcs_bridge.lua   # bridge, convoys, airlifts, warehouses: 49 checks

python tools/run_lua.py tools/sim.lua 4320 2026 docs/sim_history.json   # simulate 15 days
python tools/plot_war.py docs/sim_history.json docs/sim_war.png         # plot it
python tools/run_lua.py tools/interdiction.lua 8                         # convoy-kill experiment
```

`tests/dcs_mock.lua` fakes the parts of the DCS scripting API the bridge uses (spawning, groups,
aircraft, airbases and warehouses, F10 drawing, timers, files, player births). It catches wiring
bugs; it does not replace a real test flight.

---

## Project layout

```
src/
  dcc_config.lua      every tunable number
  dcc_util.lua        lat/lon geometry, seeded RNG, helpers
  dcc_json.lua        JSON encode/decode for saves
  dcc_war.lua         the war model (pure Lua, no DCS calls)
  dcc_supply.lua      supply economy: upkeep, convoys, airlifts, aircraft stock
  dcc_front.lua       front-line geometry from ownership
  dcc_persist.lua     save / load / backups (the only file access)
  dcc_dcs.lua         DCS bridge: live bubble, spawning, read-back, F10 drawing, menus
  dcc_dcs_supply.lua  DCS bridge: convoys, airlifts, warehouses, slot guard
  dcc_main.lua        start-up and the 30 s / 5 min loops
  dcc_loader.lua      development loader
theaters/caucasus.lua   Caucasus nodes, roads, start owners
catalogs/modern.lua     Modern era: ground roles, convoys, transports, player aircraft
dist/                   dcc_bundle.lua (the engine) and DCC_Caucasus.miz (the mission)
tests/                  model tests, bridge tests, DCS API mock
tools/                  Lua runner, simulator, plotter, interdiction test, bundle + mission builders
```

---

## Roadmap

| Phase | Scope | Done when |
| --- | --- | --- |
| 1 — Core loop ✓ | Theater pack, nodes and owners, AI assaults, capture, front line, save/load | The front moves on its own overnight and survives a restart |
| **2 — Supply economy ✓ (this)** | Supply per node, real convoys and airlifts, warehouses with dynamic spawn, supply-gated commander, generated mission | Killing a convoy visibly delays the assault it was feeding |
| 3 — Player missions | Mission boards for RED and BLUE: CAP, escort, BAI, CAS, SEAD/DEAD, strike, CTLD, CSAR, helo convoy escort; persistent pilots | Every mission type writes its effect to the save |
| 4 — Fog of war and intel | Detection table, contact aging, recon, Hound ELINT, IADS | Each side's map shows only what it has detected |
| 5 — Rotation and all maps | Victory detection → next map, theater-pack generator, more catalogs | A win on Caucasus loads the next map unattended |

## License

MIT — see [LICENSE](LICENSE).
