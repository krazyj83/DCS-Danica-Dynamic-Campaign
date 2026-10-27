# Changelog

Every change to Danica Dynamic Campaign, newest first. The version is `version` in
`src/dcc_config.lua`; it is also printed in `dcs.log` and in the start-up message.
Each entry: **Added** (new), **Changed** (works differently), **Fixed** (was broken).

---

## 0.37.0 — 2026-10-27 (bugs from the 9-player test)

**Fixed**
- **Only one aircraft could spawn at several bases:** fixed client slots filled the whole apron at Kutaisi, Batumi
  and Beslan, so dynamic spawn had no free stand. Fixed slots now take at most 25 % of an airbase's parking
  (`fixedSlotShare` in the catalog); DTC / datalink jets get theirs first (`fixedSlotFirst`).
- **Air-to-air missiles missing from the shelf:** advanced weapons (AMRAAM, R-77, AIM-54, ...) left the shelf as soon as
  a base dipped under 45 % supply. Every weapon type is now always on the shelf at 100 (`ext.armoury.tiers = false`);
  guided / advanced weapons still cost supply when taken. `tiers = true` brings the supply tiers back.
- **No way to make supply crates:** CTLD's Supply category was buried pages deep in *Request Equipment*. Every CTLD
  transport now has **F10 → Missions → Supply crate (10 SU)**: the same CTLD crate beside the aircraft.
- **No dynamic spawn on carriers:** every carrier gets its own warehouse with dynamic spawn (20 of each slot type,
  unlimited munitions and fuel).
- **C-130J did not load:** fixed slots took the big stands first (pydcs picks by stand name), so a C-130J found none.
  Fixed slots now go on the smallest stand the type fits; the big stands stay free for transports.
- **Tanks on the runway:** every script-spawned ground unit and its waypoints are moved at least 60 m off runways,
  taxiways and aprons (`runwayClearM`); garrison spots at airbases avoid them too.

**Changed**
- DCS test plan: P-101, P-301, P-603, P-701, P-801 set to RETEST with the feedback and the fix; new P-107 (C-130J).

## 0.36.0 — 2026-10-26 (feedback from the beta test)

**Changed**
- **Armoury: 100 of every weapon type** at every airbase and FARP from the start of the war (was 500 basic / 60 guided /
  30 advanced, double at depots). `ext.armoury.stock`, new `depotStock` (1 = depots like any base).
- **20 aircraft of each type** at every airbase for dynamic spawn (was 4, 8 at depots; `aircraftStock`), and 20 of
  each helicopter type at a FARP (was 2; `world.farpHelos`).

**Added**
- **BLUE can fly allied eastern types:** MiG-29A/S/G, MiG-29 Fulcrum, JF-17, Su-27, MiG-21bis, Su-25, L-39ZA/C, Mi-24P and
  Mi-8MTV2 are on both sides' lists (dynamic spawn at BLUE bases, fixed slots at BLUE depots).
- DCS test plan: P-106 (allied types for BLUE); P-101, P-603 and P-702 set to RETEST.

## 0.35.0 — 2026-10-25

**Added**
- **Minelayer ships:** harbour mines are now laid by a real ship sailing the lane — BLUE **Castle class**, RED
  **Vasily Bykov** (Currenthill mod; falls back to the core Molniya corvette if the server lacks it). Spotted by coastal
  radar at 30 % of the lane or by an enemy pilot within 20 km; the port's side then gets a **MINELAYER** mission (sink
  it, any A2G aircraft) and a map mark. Sunk = no mines; at 85 % it lays them and heads home.

## 0.34.0 — 2026-10-25

**Added**
- **Bogey dope** (F10 → Support, every aircraft): BRAA and aspect of the nearest enemy aircraft your side has seen in
  the last minute, within 100 nm. No rank needed.
- **Sortie debrief** on landing at a friendly base, FARP or own carrier: flight time, kills by kind, finished missions
  with their effect on the war, points and promotions.
- **Harbour mines:** every 6 h each side may mine an enemy lane port (40 %). Mined: orange MINES circle on the map, no
  supply ships sail for it, a ship on the approach strikes a mine. **MINESWEEP** mission for helicopters: 5 min below
  150 m within 3 km of the harbour. Mines clear by themselves after 24 h (`ext4.mines`).
- Kneeboard quick reference: bogey dope, MINESWEEP.

## 0.33.0 — 2026-10-24

**Changed**
- **Defender smoke only against attacking aircraft:** an aircraft must have fired in the last 60 s or be diving at
  the base (sinking > 15 m/s, heading within ~45° of it). Strike packages passing over no longer set it off.

## 0.32.0 — 2026-10-24

**Added**
- **Defender smoke:** live garrisons pop smoke grenades (free) when an enemy attack's lead vehicles are within
  2 km or an enemy aircraft is within 6 km and below 2500 m — a curtain 300 m out toward the threat, at most every
  10 min per base (`ext4.aiSmoke.defend`).

## 0.31.0 — 2026-10-24

**Added**
- **AI smoke:** live AI attacks lay a smoke curtain halfway between their lead vehicles and the base once within
  2 km (a battery of the attacking side in range, 2 SU), again every 10 min (`ext4.aiSmoke`).

## 0.30.0 — 2026-10-24

**Added**
- **Smoke screen ahead** (F10 → Support for ground players): 5 smoke rounds from a battery within 35 km build a
  400 m wide curtain 500 m in front of the vehicle, across its heading, 20 s after the call, for 3 min.
  2 SU; own 5 min reload per player (the side's artillery cooldown is not used).

## 0.29.0 — 2026-10-24

**Added**
- **Fire support for ground players:** a Combined Arms player in a vehicle gets his own F10 → Support menu —
  *Artillery on the nearest enemy in sight* (within 6 km, line of sight), *Artillery on my objective* (the ground
  mission's base or convoy), *Artillery / CAS pair / Illumination on my map mark*.
- Same batteries, cost (10 SU), 12 rounds and 10 min cooldown per side as the pilots' artillery; no rank needed
  for tank crews; targets within 300 m are refused (danger close).

## 0.28.0 — 2026-10-24

**Added**
- **Ground missions for Combined Arms players:** **ASSAULT** (your attack on an enemy base: take it),
  **HOLD** (your base under attack: repulse it), **GCONVOY** (escort your supply convoy by road). A player in a
  vehicle gets an F10 → Missions board with these only, within 60 km. Credit for everyone on the mission who
  was within 5 km of the target for 5 min; mission points, team bonus and ground kills go into the pilot record.
- A platoon a CA player is driving stays spawned wherever he takes it.
- CA players who take over an existing vehicle (no birth event) are picked up too.

**Changed**
- QRA scramble range 250 → **150 km**.
- Ground players get the Missions menu (ground missions only) instead of no menu.

## 0.27.0 — 2026-10-24

**Added**
- **Combined Arms slots:** per side 2 Tactical Commander, 2 JTAC and 2 Observer slots in every mission.
  Campaign platoons, supply convoys, artillery and front skirmish groups spawn **player-drivable**
  (`ext4.ca`); SAM, EWR and JTAC teams stay AI. A player in a vehicle is not slot-guarded and gets no
  pilot menus.
- **QRA scramble:** a new INTERCEPT alerts that side's grounded A2A pilots within 250 km with the threat,
  intercept heading and range. Airborne within **5 min** = the INTERCEPT is taken automatically;
  **+10 QRA bonus** (pilot field `qra`) when it is done.
- **Engineer repair kit:** CTLD → Engineering → *Repair kit* (any lift helicopter, 1 t, 20 SU). Within
  3 km of a friendly base it repairs at once a destroyed building, else the SAM, else the EWR.
- **Performance guard:** counts the ground units in DCS every minute; from 700 / 1000 units the live
  radius, live platoons, skirmishes and pop-ups shrink (scale 0.7 / 0.45), back at 15 % below; announced
  to everyone.
- Kneeboard quick reference: QRA, repair kit, Combined Arms.
- New modules `src/dcc_ext4.lua`, `src/dcc_dcs_ext4.lua`; `tests/test_ext4.lua`.

## 0.26.1 — 2026-10-24

**Fixed**
- **Gap in RED's territory on Caucasus** (between Maykop, Armavir and Cherkessk): territory cells were
  capped at 75 km around each base, leaving holes where bases are far apart. Cells now share one cap —
  the area spanned by all bases plus 75 km around it — so every side's territory is solid on all four
  maps; the outer edge still stops 75 km beyond the outermost bases.

**Added**
- Test: every point along every road on all four maps belongs to exactly one side's territory.

## 0.26.0 — 2026-10-23

**Added**
- **Night illumination:** at night every battle with a player within 25 km is lit by a flare
  (650 m up) every 2 min.
- **F10 → Support → Illumination on my map mark:** 4 flares over the mark, one a minute, from an
  own base within 30 km (2 SU, 5 min reload per side).
- **Kneeboard pages** in every mission (all aircraft, `tools/kneeboard.py`):
  1. Comms & nav — every airbase's tower VHF / UHF and owner at the start, ship TACAN / ICLS and
     slots, tankers (51X, 52X, 76X).
  2. Campaign map at the start — bases, roads, sea crossings, sea lanes, ships.
  3. Quick reference — menus, mission types, how bases fall, armoury, night and weather.
- DejaVu fonts in `tools/fonts/` (free licence) for the kneeboard.

**Changed**
- README brought up to date with everything up to this version; this changelog added.

## 0.25.0 — 2026-10-23

**Added**
- **Amphibious assaults:** the Tarawa (BLUE) and Kuznetsov (RED) land 2 marine platoons by helicopter
  on the weakest enemy coastal town within 70 km (≤ 4 platoons; 12 h between landings).
  Missions: **AMPHIB** escort for the own side, **INTERCEPT** for the enemy.
- **Shipping lanes:** 5–8 sea lanes per map; a supply ship (40 SU, 10 kn) sails to a side's lowest
  port every 3 h. Missions **SHIPSTRIKE** and **SHIPESCORT**; AI anti-ship strikes on cargo ships.
- **Carrier air wing:** AI CAP over every carrier (Hornets / Su-33s) and a BLUE S-3B recovery
  tanker on **TACAN 76X**, both following the ship.
- **SCUD hunt (RED):** 2 launchers in the rear hit BLUE depots and airbases every ~2.5 h (−15 SU,
  35 % chance of a closed runway); the launch reveals them, they move on after 15 min; **SCUD**
  missions; impacts shown to players within 30 km.
- **Pop-up threats:** MANPADS teams and mobile SAMs near the front, real units when enemy aircraft
  come within 40 km, on the board (**POPUP**) only once seen or after firing.
- New modules `src/dcc_ext3.lua`, `src/dcc_dcs_ext3.lua`; `tests/test_ext3.lua`.

## 0.24.1 — 2026-10-22

**Added**
- BLUE AI anti-ship strikes use **F/A-18C with 4× AGM-84D Harpoon**, 2× AIM-9X, 2× AIM-120C.

## 0.24.0 — 2026-10-22

**Added**
- Carriers on **every map**: Stennis and Tarawa (BLUE), Kuznetsov (RED) on Syria, Persian Gulf and
  Germany (Germany: Stennis only for BLUE).
- `legKm` per ship: shorter legs in narrow seas.

**Changed**
- BLUE now also gets **ANTISHIP** missions (against the Kuznetsov).
- Gulf Stennis slots: + F-14B(U), F-14A.

## 0.23.0 — 2026-10-22

**Added**
- **Caucasus carriers:** CVN-74 Stennis (TACAN 74X, ICLS 4; Hornets, Tomcats) and LHA-1 Tarawa
  (75X, ICLS 5; Harriers, Huey, Apache, Gazelle) off Poti / Batumi; Admiral Kuznetsov (Su-33,
  Ka-50) off Novorossiysk.

**Changed**
- TACAN and ICLS channels per ship from the theater pack (two carriers never share a beacon).

## 0.22.0 — 2026-10-22

**Changed**
- **Weather drifts gradually:** a severity that moves toward the next front (a new one every 2–6 h);
  clear → rain takes ~3 h; column speed, battles, eyes and fog follow it smoothly.
- Fog eased by DCS over each 5-min step (`setFogAnimation`); light haze before rain.

**Added**
- "Met office" forecasts and changes for everyone; trend in Campaign status.

## 0.21.1 — 2026-10-21

**Fixed**
- **Datalink:** script-spawned aircraft (AWACS, tankers, AI fighters, CTLD) had EPLRS off, so the
  AWACS shared nothing — now on for every aircraft group.
- Fixed client slots had no Link 16 STN or datalink block — now unique STNs, voice callsigns and
  the Mission Editor's blocks (Link 16 F/A-18C, F-16C, F-15E; SADL A-10C II; IDM AH-64D).

## 0.21.0 — 2026-10-21

**Added**
- Community mods **A-4E-C** (BLUE, A2A / A2G) and **UH-60L** (BLUE, helicopter missions, CTLD lifter);
  `make_mission.py --no-mods` leaves them out.

**Changed**
- Fixed slots: one per type at every depot while parking lasts, the rest at the side's next airbase
  with room (every type now has a fixed slot).

## 0.20.2 — 2026-10-21

**Added**
- F-14B(U) for BLUE.

## 0.20.1 — 2026-10-21

**Added**
- Every flyable aircraft of every era: WWII Allies BLUE (P-51, P-47, Spitfire, Mosquito, Corsair …),
  Axis and Soviet RED (Bf-109, Fw-190, I-16, La-7), Korea (F-86, MiG-15), trainers, F-100D.

## 0.20.0 — 2026-10-21 (feedback from the 6-player test)

**Fixed**
- **F10 menu overfilled** (F11 / F12 paging did not work): Missions → Join a flight | Mission board
  (9 types per page + *More missions*) | My mission | Pilot records | Cargo — never more than 10
  items per level.
- **Units spawned in water:** every ground group and static spawned by any script is moved to the
  nearest dry land, waypoints too.
- **Messages vanished too fast:** every message stays at least 10 s (`messageSeconds`), CTLD's too.

**Changed**
- All modern types for each side (BLUE western, RED eastern); Su-25T is RED only.

## 0.19.0 — 2026-10-20

**Added**
- **Flying together:** the board shows who is on a mission, *Join a flight* lists missions your side
  is flying, the flight is told when someone joins or leaves, the brief lists the flight, every pilot
  is credited and gets a **+5 team bonus** with 2+ pilots.

## 0.18.1 — 2026-10-19 (no version bump)

**Added**
- **DTC cartridges** for the F-16C and F/A-18C in every mission (templates in `dtc/`); the Hornet's
  holds every airbase and town as a named steerpoint; default in every fixed slot of the type.

## 0.18.0 — 2026-10-19

**Added**
- **HVA:** a lost tanker / AWACS is gone for 2 h; enemy fighters hunt them; **HVAESCORT** missions.
- **Strike packages:** **PKGESCORT** with every strike-type mission; package bonus (+10).
- **Aces:** 3 air kills in a sortie and the enemy vectors fighters onto you.
- **Artillery duels:** idle batteries shell the nearest enemy base (supply loss, reveals the battery).
- **Convoys:** a second ambush on escorted convoys; ambushes on live unescorted front convoys.
- **POW** and **MEDEVAC** helicopter pick-ups after captures, surrenders and battles.
- **Heavy lift** (Chinook / Mi-8): Generator (+25 % supply cap for 24 h), Runway repair kit.
- **CSAR under fire:** enemy search parties walk to downed pilots and capture them.

## 0.17.0 — 2026-10-18

**Added**
- **FARP resupply:** FARPs hold their own stock (40 SU, ~13 h); **FARPSUP** missions; a dry FARP has
  no spawns and empty shelves; a FARP kit refills it.
- Mission brief: coordinates in degrees/minutes/seconds and **target elevation**.

## 0.16.0 — 2026-10-18

**Added**
- **FARP kit:** CTLD → Engineering, 3 t, Chinook / Mi-8 only, 30 SU — set down near a friendly town
  and it is a FARP at once.

## 0.15.0 — 2026-10-18

**Added**
- Missions are **created near** helicopters and slow aircraft when they spawn (supply runs, convoy
  escort, FARPs); slow movers see missions within 120 nm.

## 0.14.0 — 2026-10-18 (feedback from the first player test)

**Changed**
- F10 view **Fog of war** (was *Allies only*).
- Armoury stock 500 / 60 / 30 per type (was 100 / 16 / 8); guided from 20 %, advanced from 45 %
  supply; cheaper (0.25 / 0.5 SU).
- Helicopters only see missions within 60 nm of their spawn, nearest first.

## 0.13.0 — 2026-10-16

**Changed**
- **Warehouse armoury** in all campaign missions: limited munitions, shelves follow base supply.
- Armoury tiers by DCS weapon category first; test-mission buttons set every base of the side.
- Territory colours #2373F4 / #DF301C, fill 0.35.

**Fixed**
- Aircraft groups on their type's own radio frequency (UH-1H mission would not save).
- Mission start scripts are files (DO SCRIPT text was run as a dictionary key: CTLD started with
  defaults and the test mode never switched on).

## 0.12.0 — 2026-10-15

**Added**
- Warehouse armoury (test mission): weapon names from DCS, tiers, shelves, F10 → Armoury test.

## 0.11.0 — 2026-10-14

**Added**
- Armoury by supply (take-off variant), RUNWAY missions, shoot and scoot, AI crews eject (CSAR /
  SNATCH), F10 Support (artillery, CAS, AWACS picture, armoury), bridge kits, minefields, veterancy,
  INDUSTRY, partisans and COIN, player-count scaling, rank unlocks, persistent wrecks.

**Changed**
- Supply helicopters emergency-only; balance re-tuned.

## 0.10.1 — 2026-10-14

**Changed**
- Whole-vehicle helicopter loads: light vehicles only, real weights.

## 0.10.0 — 2026-10-14

**Added**
- INTERCEPT on supply helicopters and airlifts; recon vehicles join air assaults.

## 0.9.0 — 2026-10-14

**Added**
- CTLD vehicles join garrisons (or become batteries / supply); AI supply helicopters.

## 0.8.0 — 2026-10-14

**Added**
- **VEAF CTLD v2** as the helicopter logistics layer, tied to the war (zones, crate costs, troops,
  FOB → FARP, AA → fortification).

## 0.7.0 — 2026-10-13

**Added**
- Hosted-server mode (no file access: 24 h wars, rotation through the server's mission list).
- Strike packages, helicopter assaults, tankers, drones, forward CAP, layered air defence, credit on
  landing, cooldown; artillery, skirmishes, fortifications, bridges, morale and surrender.

## 0.6.1 — 2026-10-13

**Added**
- Territory and front line from Voronoi cells (F10 and web map).
- `extras/respawn.lua`: standalone respawn script.

## 0.6.0 — 2026-10-11

**Added**
- Web map and Discord feed (`server/dcc_companion.py`), squadrons, weather and night, adaptive AI
  (road threat), JTAC, player-built FARPs, Gulf carrier.

**Changed**
- War clock decided by ground gained; Caucasus BLUE depot moved to Kutaisi.

## 0.5.x — 2026-10-11

**Added**
- Phase 5: all four maps, map rotation hook, theater generator, EWR, AWACS, recon photos.
- War clock (7 days), victory bonus, end-of-war report.

## 0.4.0 — 2026-10-11

**Added**
- Phase 4: fog of war and intel (contacts, eyes, AI sensors, ELINT, SAM EMCON, recon).

## 0.3.0 — 2026-10-11

**Added**
- Phase 3: mission boards, AI air, persistent pilot records.

## 0.2.0 — 2026-10-11

**Added**
- Phase 2: supply economy (convoys, airlifts, aircraft stock) and the generated mission.

## 0.1.0 — 2026-10-11

**Added**
- Phase 1: the core war loop on Caucasus (nodes, platoons, assaults, captures, live bubble, saves).
