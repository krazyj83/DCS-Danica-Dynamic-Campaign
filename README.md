# Danica Dynamic Campaign

A perpetual, persistent dynamic campaign for DCS World. One Lua engine runs inside a 24/7 server
mission, the war keeps going whether anyone is online or not, and when one side loses its last
base the server moves on to the next map in the rotation.

**Status: phase 3 of 5 — player missions, on Caucasus.** Ground forces hold nodes, mass for
assaults and capture bases. Every base runs on supply that trucks and transport aircraft carry
forward. Each side has a **mission board** — CAS, BAI, strike, SEAD/DEAD, CAP, escort, convoy
escort, recon, CSAR and helicopter logistics — and every mission writes its effect into the war.
AI fighters and attack aircraft fly for both sides, and **pilot records** follow players across
wars and maps. The front line is drawn on the F10 map and the whole war is saved across restarts.
A ready-to-fly mission file is generated for you. Fog of war and map rotation automation come next
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

That's it — the mission already contains the engine, every airbase, the player aircraft and
the AI aircraft templates.

---

## Flying missions

In the cockpit: **F10 → Other → Missions**. The board shows only what your aircraft can fly,
one submenu per mission type. Pick one and you get a briefing (target, coordinates, bearing
and range, what success does) and a mark on your F10 map. **My mission** repeats the briefing,
**Abandon mission** frees you, **My pilot record** and **Leaderboard** show the persistent stats.

| Mission | Who | Target | Success when | Effect in the war |
| --- | --- | --- | --- | --- |
| **CAS** | A2G | A base under attack (ours or theirs) | The battle goes your side's way | Who holds the base; every kill is permanent |
| **BAI** | A2G | Enemy convoy or column on a road | It is destroyed | Its cargo or platoons never arrive |
| **STRIKE** | A2G | Fuel, ammo and warehouse buildings at an enemy depot/airbase | A building is destroyed | Each one burns 25 SU and cuts the base's output (all gone = 30 %); one rebuilt every 3 h |
| **SEAD/DEAD** | SEAD | Enemy SAM site (Hawk / SA-11) | Radar or whole site killed | Radar: site offline ~2 h. Radar + launchers: destroyed, rebuilt in ~6 h for 60 SU |
| **CAP** | A2A | Your main-effort area | 20 min on station, or an air kill there | 1 h of air superiority: enemy AI attack sorties stay away |
| **ESCORT** | A2A | Your airlift transport | It lands with you mostly within 15 km | Cargo delivered; enemy AI fighters try to intercept airlifts |
| **CONVOY** | Helicopters | Your convoy to the front | It arrives with you mostly within 3 km | An ambush spawns on its road; an escorted convoy is never ambushed |
| **RECON** | Anyone | Enemy base near the front | You overfly it within 8 km below 4500 m | Its garrison, supply and SAM status appear on your side's map |
| **CSAR** | Transport helicopters | Your downed pilot | Land within 150 m (green smoke), then at a friendly base | Pilot saved, aircraft refunded to that base. After 2 h the pilot is captured |
| **LOGISTICS** | Transport helicopters | Your base short of supply | You unload a crate there | +10 SU per crate |

**Helicopter cargo** (UH-1H, Mi-8, CH-47, Mi-24): **F10 → Missions → Cargo**. Land at a friendly
base to *Load supply crate* or *Load troops* (one platoon from its garrison), land elsewhere and
*Unload*. Troops unloaded at an **enemy** base attack it at once — an empty enemy base is simply
taken. Crash with troops on board and they are lost; leave the slot and they walk home.

**AI air.** Each side has a pool of AI fighters and attack aircraft, bought with depot supply.
While anyone is flying, each side keeps a CAP pair over its main effort, sends attack pairs to
battles near players (not into enemy air cover or an active SAM), and now and then tries to
intercept an enemy airlift. Shot-down AI aircraft are gone from the pool.

**Pilot records** (`pilots.json`, kept across wars and maps): sorties, flight time, kills (air,
ground, convoy, SAM, buildings), missions by type, rescues flown and received, ejections, deaths
and captures. Score sets rank, from Lieutenant to General.

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
| **Mission board** | Player missions generated from the live war for each side. Each points at something real in the save; its effect happens in the model itself. |
| **SAM site** | Airbases and depots have an air-defence site (BLUE Hawk, RED SA-11), spawned when a player is within 80 km. Up → suppressed (radar dead) → destroyed. Captured sites are destroyed; the new owner builds its own. |
| **Structures** | Fuel, ammo and warehouse buildings at depots (6) and airbases (4) — strike targets that cut output and supply when destroyed. |
| **Air pool** | Each side's AI fighters and attack aircraft as numbers; sorties draw from it, losses are permanent, depots buy replacements. |
| **Theater pack** | A data file per map (`theaters/*.lua`): nodes with lat/lon, roads, start owners. No map is named in engine code. |
| **Era catalog** | A data file per era (`catalogs/*.lua`) mapping roles to DCS unit types per side, plus convoy trucks, transports and player aircraft. |

The key design idea: **spawned units are a view of the saved numbers.** Any unit on the map
can be rebuilt from the save file, so a restart, a crash or a map change loses nothing.

```
theaters/  catalogs/             Saved Games\DCS\DCC\<Map>_war.json
     \        /                              ^
  war model (dcc_war + dcc_supply + dcc_ops + dcc_missions) <-- save/load (dcc_persist.lua)
           ^      |
   read-back      | spawn / despawn, warehouses, F10 drawing
           |      v
  DCS bridge (dcc_dcs + dcc_dcs_supply + dcc_dcs_ops)  <-->  DCS world + players
```

**Does it matter if I kill a convoy?** Yes, measured: in 8 paired offline wars, destroying the
convoys feeding BLUE's main effort cut the platoons BLUE could send into assaults by 26 % and its
captures from 51 to 45 over one war day; 6 of 8 wars were hit (`tools/interdiction.lua`). Every
mission type has a test that checks its effect lands in the save (`tests/test_ops.lua`).

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
| AI templates | Four late-activated 2-ships (`DCC_TPL_blue_fighter` F-16C, `_blue_attack` A-10C, `_red_fighter` MiG-29S, `_red_attack` Su-25) with loadouts. The engine copies them for AI sorties — change a template's loadout in the Mission Editor if you like. |
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
| `pilots.json` | Pilot records for every theater — never reset by a new war |

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
- [ ] **F10 → Other → Missions** shows mission types your aircraft can fly; taking one gives a briefing and a map mark.
- [ ] A SAM site appears within 80 km of an enemy airbase or depot; killing its radar reports "radar … knocked out".
- [ ] Strike buildings sit near (not on) the airfield; destroying one reports "… destroyed (1 of N)".
- [ ] AI pairs appear ("Command: … CAP sortie airborne") and actually orbit / attack.
- [ ] Ejecting creates a downed pilot; a Huey landing next to them and then at a friendly base rescues them.
- [ ] Huey *Load supply crate* / *Unload* changes the base's SU on your map.
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

Phase 3 settings are in `ops` (SAM repair times and costs, structures, AI air pools, air
cover, ambush chance, CSAR timeout, crate size) and `missions` (board size per type, CAP time,
recon and escort distances).

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
python tools/run_lua.py tests/test_ops.lua          # every mission type writes its effect: 51 checks
python tools/run_lua.py tests/test_dcs_bridge.lua   # bridge, convoys, airlifts, warehouses: 49 checks
python tools/run_lua.py tests/test_dcs_ops.lua      # flying every mission type against a fake DCS: 60 checks

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
  dcc_ops.lua         SAM sites, structures, AI air pools, intel, carried troops, downed pilots
  dcc_missions.lua    mission board: generate, take, judge, credit
  dcc_pilots.lua      persistent pilot records, score and rank
  dcc_front.lua       front-line geometry from ownership
  dcc_persist.lua     save / load / backups (the only file access)
  dcc_dcs.lua         DCS bridge: live bubble, spawning, read-back, F10 drawing, menus
  dcc_dcs_supply.lua  DCS bridge: convoys, airlifts, warehouses, slot guard
  dcc_dcs_ops.lua     DCS bridge: menus, briefings, detection, SAMs, statics, AI air, CSAR, cargo
  dcc_main.lua        start-up and the 30 s / 5 min loops
  dcc_loader.lua      development loader
theaters/caucasus.lua   Caucasus nodes, roads, start owners
catalogs/modern.lua     Modern era: ground roles, convoys, transports, player aircraft, capabilities,
                        AI air loadouts, SAM sites, strike buildings, ambush teams
dist/                   dcc_bundle.lua (the engine) and DCC_Caucasus.miz (the mission)
tests/                  model tests, bridge tests, DCS API mock
tools/                  Lua runner, simulator, plotter, interdiction test, bundle + mission builders
```

---

## Roadmap

| Phase | Scope | Done when |
| --- | --- | --- |
| 1 — Core loop ✓ | Theater pack, nodes and owners, AI assaults, capture, front line, save/load | The front moves on its own overnight and survives a restart |
| 2 — Supply economy ✓ | Supply per node, real convoys and airlifts, warehouses with dynamic spawn, supply-gated commander, generated mission | Killing a convoy visibly delays the assault it was feeding |
| **3 — Player missions ✓ (this)** | Mission boards for RED and BLUE: CAS, BAI, strike, SEAD/DEAD, CAP, escort, convoy escort, recon, CSAR, helicopter logistics and air assault; AI air; persistent pilots | Every mission type writes its effect to the save |
| 4 — Fog of war and intel | Detection table, contact aging, recon, Hound ELINT, IADS | Each side's map shows only what it has detected |
| 5 — Rotation and all maps | Victory detection → next map, theater-pack generator, more catalogs | A win on Caucasus loads the next map unattended |

## License

MIT — see [LICENSE](LICENSE).
