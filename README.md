# Danica Dynamic Campaign

A perpetual, persistent dynamic campaign for DCS World. One Lua engine runs inside a 24/7 server
mission, the war keeps going whether anyone is online or not, and when one side loses its last
base the server moves on to the next map in the rotation.

**Status: phase 5 of 5 — all four maps, unattended rotation.** Ground forces hold nodes, mass for
assaults and capture bases. Every base runs on supply that trucks and transport aircraft carry
forward. Each side has a **mission board** — CAS, BAI, strike, SEAD/DEAD, CAP, escort, convoy
escort, recon, CSAR and helicopter logistics — and every mission writes its effect into the war.
AI fighters and attack aircraft fly for both sides, and **pilot records** follow players across
wars and maps. **Territory and the front line** are drawn on the F10 map (and the web map) from
Voronoi cells around every base, and the whole war is saved across restarts.
**Fog of war:** each side's map shows only the enemy it has actually detected — by eye, by AI
sensors, by radar, by ELINT or by recon — and contacts fade and expire. **Early-warning radars and
AWACS** give each side an air picture (and are targets), and **recon brings back photos** of every
enemy platoon. The war runs on **Caucasus → Syria → Persian Gulf → Cold War Germany**: when one side
wins, a server hook loads the next map by itself. Ready-to-fly missions are generated for all four.

![Simulated war](docs/sim_war.png)

*A simulated war with nobody online. Players near a front fight it as real DCS units instead.*

---

## Quick start

**Only access to the missions folder and the server's web UI** (a hosted server)? That works:

1. Upload the four `dist/DCC_*.miz` files.
2. In the server UI, put them in the mission list in this order: Caucasus, Syria, PersianGulf,
   GermanyCW, and switch on looping the list.
3. Start the server. Each war runs for **24 hours** (or until you stop the server); when it is won —
   by conquest or on the clock — the mission ends after two minutes and the server loads the next map.

Without file access the war **cannot be saved**: stopping the server starts that map's war over, and pilot
records last one session. Players are told so at the start. If the host ever enables `io`/`lfs` (step 1
below), saving, the 7-day war clock, persistent pilots and the companion tools switch on by themselves —
nothing to change in the missions.

**Full access to the server PC:**

1. **Server: allow saving** — see [step 1](#1-allow-the-campaign-to-save) below.
2. **Copy the four missions** `dist/DCC_*.miz` to `Saved Games\DCS\Missions\DCC\` and put
   `DCC_Caucasus.miz` in the server's mission list.
3. **Install the rotation hook**: copy `hooks/DCC_rotation_hook.lua` to
   `Saved Games\DCS\Scripts\Hooks\`, and untick *Pause without clients* in the server settings.
4. **Start it as a multiplayer server** (also locally for testing: *Multiplayer → New server*).
   Pick a side and an aircraft at any airbase your side owns.
5. **Optional — web map and Discord:** copy the `server/` folder to the server PC, copy
   `dcc_companion.example.json` to `dcc_companion.json`, fill in your `DCC` folder and Discord
   webhook, and run `start_companion.bat`. See [Web map and Discord](#web-map-and-discord).

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
| **ESCORT** | A2A (supply helicopters: anyone) | Your airlift transport or supply helicopters | They land with you mostly within 15 km | Cargo delivered; enemy AI fighters try to intercept airlifts |
| **CONVOY** | Helicopters | Your convoy to the front | It arrives with you mostly within 3 km | An ambush spawns on its road; an escorted convoy is never ambushed |
| **RECON** | Anyone | Enemy base near the front | You overfly it within 8 km below 4500 m | Its garrison, supply and SAM status appear on your side's map |
| **CSAR** | Transport helicopters | Your downed pilot | Land within 150 m (green smoke), then at a friendly base | Pilot saved, aircraft refunded to that base. After 2 h the pilot is captured |
| **LOGISTICS** | Transport helicopters | Your base short of supply | You unload a supply crate there | +10 SU per crate |
| **RUNWAY** | A2G | Enemy airbase near the front, or a depot | 3 bombs within 60 m of the runway centre line | Airfield closed 4 h: no airlifts, no fixed-wing spawns; repair costs 30 SU |
| **INDUSTRY** | A2G | Enemy factory, power plant or refinery behind the lines | 2 of its 3 buildings destroyed | That side's production −12 % per site until rebuilt (a day, 80 SU) |
| **SNATCH** | Transport helicopters | Enemy pilot or AI crew on the ground | Land within 150 m, then at a friendly base | Prisoner: your side learns his home base; +15 points |
| **COIN** | A2G | Partisan cell near a town you hold (Syria, Gulf) | The cell's group is wiped out | Stops sabotage and ambushes around the town |

**Helicopter cargo is CTLD** (see [Helicopter logistics (CTLD)](#helicopter-logistics-ctld)): crates,
troops, FOBs and AA systems through **F10 → CTLD**, all of it tied to the war.

**AI air.** Each side has a pool of AI fighters and attack aircraft, bought with depot supply.
While anyone is flying, each side keeps a CAP pair over its main effort, sends attack pairs to
battles near players (not into enemy air cover or an active SAM), and now and then tries to
intercept an enemy airlift. Shot-down AI aircraft are gone from the pool.

**Pilot records** (`pilots.json`, kept across wars and maps): sorties, flight time, kills (air,
ground, convoy, SAM, buildings), missions by type, rescues flown and received, ejections, deaths
and captures. Score sets rank, from Lieutenant to General.

**Victory bonus:** when a war ends, every pilot who did enough for the winning side in that war —
**3 sorties or 1 completed mission** for that side (`victoryMinSorties`) — gets **+150 points for a
conquest** (the whole map taken) or **+50 for a war-clock win**. The record shows wars won of each
kind. Switching sides is allowed: do enough for both and you collect whichever side wins.

**War report:** at the end of every war the server shows, and saves as
`Saved Games\DCS\DCC\<Map>_war_report_<tick>.txt` (ready to paste into Discord):

```
=== WAR REPORT - Caucasus ===
RED won on the war clock after 7.0 days.
Bases held at the end:   BLUE 18 / RED 21
Bases captured:          BLUE 56 / RED 52
Platoons lost:           BLUE 786 / RED 685
Supply delivered (SU):   BLUE 15951 / RED 15449
Supply destroyed (SU):   BLUE 658 / RED 408
AI aircraft lost:        BLUE 4 / RED 7
Top pilots (12 flew in this war):
  1. Morten (BLUE) - 356 points, 14 sorties, 6 missions
  ...
Victory bonus (+50 points, war clock) for 5 RED pilots: ...
```

Points in the report are those scored in that war only.

## Air war

| Feature | What happens | Your mission |
| --- | --- | --- |
| **Strike packages** | About every 45 min each side sends a raid at a real target: 2 strikers, 2 escorts, and 2 SEAD aircraft (HARM / Kh-31P) when the target has a SAM. If the strikers get within 6 km, the target is hit: a store burns, the SAM radar or EWR goes down, or the FARP is gone. | **INTERCEPT** (once detected) — kill the strikers before they arrive |
| **Helicopter assaults** | About every 75 min a side flies a platoon in two UH-60 / Mi-8 to a weak enemy base (≤2 platoons) within 70 km. If they land, the troops attack; if they are shot down, the platoon is lost. | **INTERCEPT** — the same mission, on helicopters |
| **Tankers** | BLUE KC-135MPRS (drogue, TACAN 51X), RED IL-78M (52X), orbiting behind the AWACS while anyone is online. | **TANKER** — shoot down the enemy's |
| **Recon drones** | MQ-9 / Wing Loong over the base a side is attacking; it spots ground units within 8 km for its side's map. | Shoot it down to blind them |
| **Forward CAP** | The AI covers its own base the enemy is massing against. | — |
| **Layered air defence** | A SAM site only lights up at 60 km when its side's early-warning radar or AWACS is tracking you; on its own it waits until 25 km. Every site has point defence (Avenger / Tor) that stays on when the main radar goes dark. Kill the EWRs first. | EWR, SEAD |
| **Credit on landing** | Mission points are logged when you land at a friendly base or your carrier. Die or eject on the way home and they are lost (the damage to the enemy still counts). | — |
| **Cooldown** | Two deaths within an hour ground a pilot from fast jets for 15 min. Helicopters are always allowed. | — |

The AI air forces are bigger to carry all of this: 16 fighters and 16 attack aircraft per side to start,
one more bought every hour (max 24).

## Ground war

| Feature | What happens | Your mission |
| --- | --- | --- |
| **Artillery** | 2 batteries per side (M109 / 2S19) move up behind the main effort and next to bases under attack. A battery next to a battle makes the enemy lose 30 % more; near players it is a real battery shelling the fight. Firing gives it away. | **ARTY** — destroy the battery (rebuilt after 6 h) |
| **Front skirmishes** | Small fights (2 vehicles each side) always run on up to 8 front roads, even far from players, so there is always something for CAS. They follow the front and come back 30 min after being wiped out. | CAS anywhere on the front |
| **Fortifications** | A base nobody attacks digs in: one level every 6 h (10 supply), up to 3, +10 % defence each. Bunkers appear when you are near. | **FORT** — destroy bunkers before an assault |
| **Bridges** | Real DCS bridges on the roads are found at mission start. A destroyed bridge closes its road for 6 h: columns on it stop and the AI routes around it. | **BRIDGE** — on enemy supply roads |
| **Morale** | A base out of supply defends at 70 %, one cut off from every depot at 80 %. Cut off, out of supply and down to 2 platoons, it surrenders. | Encircle and starve |

## Radars, AWACS and recon photos

| What | How it works | How to hurt it |
| --- | --- | --- |
| **Early-warning radar (EWR)** | One at every depot (theater packs can add more). Sees enemy aircraft within 180 km — but only above the radar horizon: at 100 km you must be above ~370 m to show up, at 150 km above ~1 km. Terrain blocks it too. Your own coverage is a faint ring on your map. | It always transmits, so enemy aircraft hear it (ELINT, 200 km) and an **EWR** strike mission appears. Destroyed = 6 h and 40 supply to rebuild. Captured = destroyed. |
| **AWACS** (E-3A / A-50) | While anyone is online each side keeps one orbiting 120 km behind its front at 9 km altitude. It sees aircraft out to 350 km. Relieved every 4 h, lands when the server empties. Two per side; a lost one is replaced after 6 h for 40 supply. | Once someone has seen it, the enemy gets an **HVAA** mission (high-value airborne asset). Shoot it down and that side is half blind until a replacement is bought. |
| **Recon photos** | A completed recon mission photographs the base: each platoon with its vehicle types (`[photo] 4x T-72B3`) on your side's map, plus a photo report message to the pilot listing every platoon, the SAM and the radar status. | — |

DCS cannot add pictures to the kneeboard while a mission runs, so the photos are F10 map labels and a
message rather than images.

**Low flying now matters:** below the radar horizon, away from AWACS, nobody on the other side sees you
on their map unless they have eyes on you.

## Map rotation

```
 war won on Caucasus ──► mission writes DCC\rotation.json  { state = "ended", next = "Syria" }
                         sets user flag 9900, announces the winner
        server hook  ──► "[DCC] The war on Caucasus is over. The campaign moves to Syria in 120 seconds."
                     ──► loads Missions\DCC\DCC_Syria.miz
     Syria mission   ──► new war on Syria, rotation.json { current = "Syria", state = "running" }
```

- The rotation is fixed: Caucasus → Syria → Persian Gulf → Cold War Germany → Caucasus.
- **War clock: every war ends after 7 days** of server time, even on an empty server. If nobody has
  conquered the map by then, the side that has **gained more ground since the start** wins (bases held
  now minus bases held at the start — fair on maps where one side starts bigger; a tie goes to the
  stronger army, then to the bigger supply stock). Everyone gets a warning 24 h, 6 h and 1 h before the
  end, naming the side that is ahead; **Campaign status** and the web map show the time left. A win on the clock rotates the
  map exactly like a conquest. A save from before the clock existed gets a fresh 7 days.
- **Pilots carry over** (`pilots.json`); each map keeps its own war save, and a finished war is archived.
- **Restarts are safe:** if the server comes back on the wrong DCC mission (the mission list still starts
  on Caucasus), that mission does not start a war; the hook loads the right map within 10 seconds.
- Missions that are not `DCC_*.miz` are never touched. To pick a map by hand, stop the server and
  delete `Saved Games\DCS\DCC\rotation.json`.
- The hook only needs the `DCC_<map>.miz` files in `Missions\DCC\`; if one is missing it says so in
  chat and in `dcs.log` (`DCC-ROTATION`) and waits.
- Prefer DCSServerBot? Leave the hook out and let it watch user flag 9900 instead.

## The four maps

All four theater packs are generated by `tools/make_theater.py` from short scenario files in
`tools/scenarios/` (Caucasus is hand-made). Square = depot, triangle = airbase, yellow = front at the
start, dashed = sea crossing.

| Map | Scenario | Size |
| --- | --- | --- |
| **Caucasus** | BLUE Georgia vs RED north, Abkhazia, South Ossetia | 39 nodes |
| **Syria** | BLUE Israel, Jordan, south Lebanon vs RED Syria and the Bekaa. Fronts: Golan, Daraa–Irbid, Beirut–Bekaa | 45 nodes |
| **Persian Gulf** | RED has landed on Musandam and the northern Emirates and holds the islands; BLUE holds the rest of the UAE. Islands and the Strait are linked by **sea crossings** | 32 nodes, 11 sea crossings |
| **Cold War Germany** | Modern forces on the old inner-German border, Baltic to the Fulda Gap; BLUE west, RED east | 55 nodes |

| Syria | Persian Gulf | Germany |
| --- | --- | --- |
| ![Syria](docs/theater_syria.png) | ![Persian Gulf](docs/theater_persiangulf.png) | ![Germany](docs/theater_germanycw.png) |

**Sea crossings** are ferries and landing craft: columns and convoys on them run on dice only (they
never spawn and cannot be BAI or ambush targets). Fight them at the ports and islands, and in the air.

**Balance**, measured offline with nobody online, as wins on the 7-day clock (the AI fights alone; with
players, players decide), re-tuned with veterancy, industry and supply helicopters in (v0.11): Caucasus
BLUE 7 of 16, Persian Gulf BLUE 9 of 16 (BLUE production × 1.05), Syria BLUE 18 of 32 (RED × 1.10),
Germany BLUE 18 of 32 (RED × 1.10). Single batches swing a lot.
**Depot placement matters far more than production multipliers:** with BLUE's Caucasus depot at Tbilisi
BLUE gained ground in 11 of 12 wars (now Kutaisi: 5 of 12); with RED's Gulf depot at Ras Al Khaimah
RED won every war (now Khasab).

**Adding a map or changing a scenario:**

```bash
# edit or copy tools/scenarios/syria.py (airbases by DCS name, towns by lat/lon, who owns what)
PYTHONPATH=<pydcs clone> python tools/make_theater.py Syria     # -> theaters/syria.lua + docs/theater_syria.png
python tools/run_lua.py tests/test_theaters.lua                  # connected, depots, war runs
python tools/build_bundle.py && python tools/make_mission.py --theater Syria --out dist/DCC_Syria.miz
```

The generator takes airbase positions from pydcs (the same coordinates DCS uses), builds roads as a
Gabriel graph (two bases are linked when no third base lies inside the circle drawn on the line between
them: short links, no crossings), joins separate pieces with their shortest link and checks the result.

## Web map and Discord

`server/dcc_companion.py` runs next to the DCS server (plain Python 3.8+, nothing to install). It
reads two files the campaign writes every few minutes and does two jobs:

| Job | What it does |
| --- | --- |
| **Live web map** — `http://<server>:8088/` | Front line and base owners on a real map, war clock and who is ahead, weather, the latest captures and kills, top pilots and squadrons. Refreshes every 30 s; works on a phone. Only public information: no garrison sizes, no supply, no enemy positions. |
| **Discord feed** — through a channel webhook | Posts captures, radar / AWACS / SAM / ship kills, convoys destroyed, completed missions, FARPs built, weather changes, war-clock warnings, the victory and the full war report. Each event once, even after restarts; if Discord is down it retries. |

Setup: in Discord, *channel settings → Integrations → Webhooks → New webhook → Copy URL*. Put it and
your `Saved Games\DCS\DCC` folder in `server/dcc_companion.json` (copy the example), then run
`start_companion.bat`. Open port 8088 in the Windows firewall to share the map. Other modes:
`--once` (post and exit, for Task Scheduler), `--static <dir>` (write `index.html` + `public.json` for
any web host), `--no-web`, `--no-discord`. **DCSServerBot** users can run it alongside; nothing clashes.

## Squadrons

Put a tag in your DCS name — `[VKG] Morten`, `VKG | Morten`, `-=VKG=- Morten` or `Morten [VKG]` (2–8
letters or digits) — and you fly for that squadron. **F10 → Missions → Squadron leaderboard** adds up
the members' scores and war wins; the war report lists the top squadrons of that war, and the web map
shows the board.

## Weather, night and the AI's memory

**Weather** changes every 6 hours (clear → overcast → rain → storm and back, saved with the war):

| | Ground columns | Dice battles | Eyes | Helicopter missions | AI attack aircraft |
| --- | --- | --- | --- | --- | --- |
| Overcast | — | — | 90 % | yes | yes |
| Rain | 80 % speed | slower | 60 % | yes | yes |
| Storm | 60 % speed | slower | 40 % | **none offered** | **grounded** |

Rain and storms show up as fog in DCS (DCS 2.9.10+). Clouds and rain themselves cannot be changed while
a mission runs. **Night** (20:00–06:00 mission time) halves what eyes can see and grounds AI attack
sorties; fighters and AWACS still fly. The time of day restarts with the mission file after a server
restart — DCSServerBot can start missions at the real time if you want the day/night cycle to continue.

**The AI remembers where it is hurt.** Every column killed raises that road's *threat* for the side that
lost it (halving every 3 hours). At threat 2 the AI tells its side, sends its convoys on that road with
an **air-defence escort** (Avenger / Vulcan or Strela / Shilka driving with the trucks) and prefers
another road when one exists; at threat 3 it puts a **CAP pair over the road**. Status shows each side
its most dangerous road. Measured offline, killing convoys still cuts the enemy's assaults by 43 %:
the AI makes hunting harder, not pointless.

## JTAC

Take a **CAS** mission and a JTAC team (an invisible, immortal light vehicle) moves up 4 km from the
battle on your side. It lases the nearest enemy vehicle with **code 1688** and an IR pointer for
night-vision goggles, follows it, and switches when it dies. **F10 → Missions → JTAC**: *Report target*
(type, MGRS, code, how many hostiles), *Mark with smoke* (red), *Next target*. The team packs up when
the mission ends.

## Helicopter logistics (CTLD)

The missions include **[VEAF CTLD](https://github.com/VEAF/CTLD) v2** (MIT, by Ciribob, Zip and
the VEAF team), started and configured by the engine. Every helicopter type CTLD knows can lift
(UH-1H, Mi-8, CH-47, Mi-24, ...): **F10 → CTLD**. What CTLD does now counts in the war:

| In CTLD | In the war |
| --- | --- |
| Every own base is a CTLD **pickup and logistic zone** (1.5 km round an airbase, 600 m round a town) | Captured base: its zones change sides |
| **Request a crate** at a base | The base pays **10 SU per crate**; a dry base says no |
| **Supply crate** unloaded (or para-dropped) within 3 km of an own base | **+10 SU** there, completes LOGISTICS, builds towards a FARP |
| **Load troops** at a base | **1 platoon per 10 soldiers** leaves the garrison (never the last one) |
| Troops unloaded at an own base | They join that garrison |
| Troops unloaded at an **enemy** base | **Air assault**: they attack it at once |
| Troops unloaded in the field | Still yours; killed there = lost; pick them up again with CTLD |
| Helicopter shot down with troops | Platoons lost. Leave the slot with troops on board: they walk home |
| **FOB** built within 5 km of an own town | The town is a **FARP** (destroyed FOB = FARP gone) |
| **AA system** set up within 3 km of an own base | Base digs in one level (max 3) |
| **Light vehicle** flown in whole (Chinook, Mi-8: BLUE Humvee / MG Humvee / TOW Humvee, RED UAZ-469 — BRDM-2, Tigr, APCs and tanks are too heavy and come in crates) and set down within 3 km of an **enemy** base | It joins the **air assault** on that base (with any troops landed there — one assault, not several) and fights where it stands |
| **Vehicle** unpacked (or flown in whole and set down) within 3 km of an own base | Joins the garrison as a platoon, at the strength its crates paid for (crates × 10 SU ÷ 60: an Abrams, 4 crates, = 0.67 platoon). After a minute it leaves the map — the base spawns it with the garrison from then on |
| **Howitzer / MLRS** unpacked at an own base | An artillery battery there (a destroyed one is rebuilt first; at most 2 extra per side) |
| **Ammo / fuel truck** unpacked at an own base | Its load becomes supply (crates × 10 SU) |

Vehicles unpacked out in the field stay real CTLD units where you put them. CTLD's own
JTAC (crates, drones, JTAC teams) is switched off — the [campaign JTAC](#jtac) does CAS. Troops come
from base garrisons only (no free troops at CTLD FOBs). Without CTLD in the mission
(`make_mission.py --no-ctld`) the engine's own simple **F10 → Missions → Cargo** menu comes back.

## AI supply helicopters

Both sides fly **supply helicopters** (UH-60A / Mi-8MT pairs, 10 SU) on short hops to the front —
towns too — from a base 15–120 km behind it, **in emergencies only**: a base that is cut off, or whose
road in is under attack (so interdiction still bites — but now the helicopters are worth hunting too). They are real aircraft, low and slow: **ESCORT** them (any aircraft, helicopters
included — the mission is on the board while they fly), or hunt the enemy's: once your side has
detected them (radar, AWACS, eyes) you get an **INTERCEPT** mission on them — any aircraft, attack
helicopters too. Enemy fixed-wing airlifts get an INTERCEPT (air-to-air) the same way. Shot down = the supply is
lost. On landing they set their crates down, wait a few minutes and fly home. At most 1 per side at once,
one run to the same base every 2 h, none in a storm.

## Armoury: weapons follow supply

What a base can arm you with depends on its supply (share of its supply cap):

| Base supply | Weapons | Cost when you take off |
| --- | --- | --- |
| under 30 % | guns, rockets, unguided bombs | free |
| 30–60 % | + guided: IR missiles, laser / TV missiles and bombs (Hellfire, Maverick, GBU-12) | 0.5 SU each |
| over 60 % | + advanced: radar missiles (AMRAAM, R-77), anti-radiation, GPS bombs, anti-ship, cruise | 1 SU each |

You are told the base's armoury when you spawn (and **F10 → Support → Armoury at this base**). Taxi
out with more than the base can supply and you get a warning; take off with it anyway and you are
**recalled** (the aircraft is removed). `ext.armoury.enforce = false` makes it a charge only.

## Support on call and ranks

**F10 → Support** — put a mark on the F10 map (your coalition), then:

| Command | Rank | What happens |
| --- | --- | --- |
| Artillery on my map mark | Captain | Your nearest artillery battery within 35 km fires 12 rounds (10 SU from its base; every 10 min per side) |
| CAS pair on my map mark | Major | An AI attack pair flies to the mark (20 SU, from the air pool; every 20 min per side) |
| AWACS picture | Colonel | The 5 nearest enemy aircraft your side's sensors hold, as bearing / range / altitude |
| Armoury at this base | anyone | What the base can arm you with |

**Lieutenant Colonel** and up may spawn helicopters at FARPs. Ranks come from your score
(Captain 100, Major 300, Lt Col 700, Colonel 1500).

## More air war

* **Shoot and scoot** — point defence (Avenger, Tor) drives 1.5–4 km to a new spot after it fires or a
  HARM comes in; the SA-11 site does too (the Hawk is fixed). The enemy's fix on it goes stale by that
  distance, and the site respawns where it went.
* **AI aircrews** eject (70 %): CSAR for their side — rescued, the aircraft goes back into the AI pool —
  and **SNATCH** for the other. Enemy player pilots can be snatched too (they get a "captured").
* **Scaling** — the side with fewer players online takes up to 15 % fewer losses in battle and its AI flies
  more strike packages (5 % and +25 % per player of difference). Keeps PvE fair when players switch sides.

## More ground war

* **Engineers** — CTLD **Bridge kit** crates: 2 unpacked within 1.5 km of a destroyed bridge reopen the road
  at once (otherwise 6 h).
* **Minefields** — a CTLD minefield laid within 1.5 km of a road mines it for 24 h: the other side's columns
  on it move at half speed and lose 15 % once.
* **Veterancy** — platoons at a base that is held or taken gain experience: **veteran** (2) fights 10 %
  harder, **elite** (5) 20 %, and they spawn with better crews.
* **Industry** — 3 sites per side behind the lines (factory, power plant, refinery), always on the map,
  ruins while destroyed. See INDUSTRY.
* **Partisans** (Syria, Persian Gulf) — cells rise in towns held by the side that took them, away from the
  front: they sabotage supply and ambush columns. A garrison breaks them up now and then; COIN does it now.
* **Persistent wrecks** — destroyed vehicles stay as wrecks through restarts (3 days, at most 300), and
  destroyed buildings stay destroyed.

## FARPs

Every town can become a FARP. Fly **3 supply crates** (30 SU) to a friendly town — or build a CTLD
**FOB** next to it — the **FARP** mission
on the board points you at towns right behind the front — and it becomes a FARP: fuel and ammo trucks
arrive, it shows on everyone's map, and your side's helicopters can **spawn there** (2 of each type,
dynamic spawn). A captured town loses its FARP. Behind the scenes each town has two invisible FARPs in
the mission (one per side) with empty stock; the engine stocks the right one.

## Carrier (Persian Gulf)

BLUE has **CVN-74 John C. Stennis** with three escorts in the Gulf of Oman: TACAN **74X**, ICLS **4**,
client slots for 2 F/A-18C and 2 F-14B. It sails into the wind and turns back every leg. RED's radars,
AWACS and pilots can find it; once found, RED gets an **ANTISHIP** mission and its AI sends Su-34s with
Kh-31A now and then. **Sunk = gone for the rest of the war**, with its air wing — the carrier stays
sunk after a restart. Theater packs can add more ships (`naval` in the scenario file).

## Fog of war and intel

You only see the enemy your side has found. Every side keeps a **contact table** in the save;
the F10 map and the mission board read that table, never the true positions.

| How a contact is made | What it gives |
| --- | --- |
| **Radar** — your early-warning sites and AWACS | Enemy aircraft above the radar horizon (see above) |
| **Eyes** — a player aircraft within 6 km of enemy ground units or 10 km of aircraft, with terrain not in the way | Column positions, garrison vehicle counts, SAM sites with a precise fix |
| **AI sensors** — your SAM radars, AI fighters and ground platoons report what they detect | Enemy aircraft and ground units near them |
| **ELINT** — any of your aircraft above 800 m within 110 km of an enemy SAM radar that is switched on | The site's position with an error circle: ±6 km at first, narrowing with every observation down to 300 m. Keep listening to sharpen it |
| **Recon mission** | The whole base: garrison size and SAM status, plus every column on its roads. Valid 6 h |
| **Troops in contact** — every base sees enemy columns within 8 km on its roads and anything attacking it | BAI targets on columns about to hit you |
| **Front estimate** — always on | Enemy bases on the front show *est. light / medium / heavy* |

**Age.** A contact is *fresh* for 30 minutes (solid, can be tasked), then *stale* (faded, "last
seen 1.5 h ago", not tasked), and forgotten after 3 hours. Enemy aircraft stay on the map for
2 minutes after the last sighting. Columns are drawn **where they were seen**, not where they are.

**Missions follow intel.** BAI is only offered on columns your side has seen in the last 30 minutes,
and SEAD only on SAM sites you know — so recon and ELINT come first. With nobody flying, the board
shows about 0.3 BAI and no SEAD (versus 3 and 2 with full knowledge); fly a recon or a SEAD
patrol to find targets. STRIKE, CAS, CAP, RECON, CSAR and logistics are against fixed or own
positions and stay offered.

**SAM radars (EMCON).** A SAM site keeps its radar off until enemy aircraft come within 60 km,
then switches to alarm state red — that is when ELINT can hear it. Fire an anti-radiation missile
(HARM, Kh-58, Kh-25MP …) at it and it goes dark for 1–2 minutes: it survives, but it cannot shoot
or be heard. Kill the radar while it is lit, or use the window to get close.

**What is not fogged:** who owns each base (circles and names are public), the front line, and
the AI commanders' own plans — the AI still plans with full knowledge, fog applies to players.
Spectators see only the front line and who owns each base.

---

## How it works (the concepts)

| Concept | What it means |
| --- | --- |
| **Node** | A place that can be owned: an airbase, a town or a **depot**. Depots produce new forces and supply, and can only be attacked once nothing else of that side is within reach. Caucasus depots: Batumi and Kutaisi (BLUE), Sochi-Adler, Beslan and Krasnodar-Center (RED). |
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
| **Contact** | Something one side has detected: key, kind, where, how (visual / sensor / ELINT / recon), how precise, when. Saved; ages from fresh to stale to forgotten. |
| **EWR / AWACS** | Each side's radars as model state: EWR sites per node (up / destroyed), the AWACS pool and whether one is on station. |
| **Sea crossing** | A link between landmasses (ferries, landing craft). Moves on it run on dice only. |
| **Rotation file** | `DCC\rotation.json`: which map the campaign is on, and the next one after a win. Read by the server hook. |
| **Threat** | Per side, per road: how much that side has lost there recently. Drives AI escorts, re-routing and CAP. |
| **FARP** | A town where players delivered 3 crates: helicopter spawn, rearm, refuel. |
| **public.json / feed.jsonl** | Public status and the event feed for the web map and Discord (written by the mission, read by `server/dcc_companion.py`). |
| **Territory** | The ground each base holds: its Voronoi cell (closer to it than to any other base, at most 75 km). A side's territory is the union of its cells; the front is where BLUE and RED cells meet. |
| **Theater pack** | A data file per map (`theaters/*.lua`): nodes with lat/lon, roads, start owners. No map is named in engine code. |
| **Era catalog** | A data file per era (`catalogs/*.lua`) mapping roles to DCS unit types per side, plus convoy trucks, transports and player aircraft. |

The key design idea: **spawned units are a view of the saved numbers.** Any unit on the map
can be rebuilt from the save file, so a restart, a crash or a map change loses nothing.

```
theaters/  catalogs/             Saved Games\DCS\DCC\<Map>_war.json
     \        /                              ^
  war model (dcc_war + supply + ops + missions + intel + radar) <-- save/load
           ^      |
   read-back      | spawn / despawn, warehouses, F10 drawing
           |      v
  DCS bridge (dcc_dcs + _supply + _ops + _intel + _radar)  <-->  DCS world + players
           ^
  hooks/DCC_rotation_hook.lua  <-- DCC\rotation.json -->  loads the next map
```

**Does it matter if I kill a convoy?** Yes, measured: in 8 paired offline wars, destroying the
convoys feeding BLUE's main effort cut the platoons BLUE could send into assaults by 31 % and its
captures from 55 to 46 over one war day; 7 of 8 wars were hit (`tools/interdiction.lua`). Every
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

Use the generated **`dist/DCC_<map>.miz`** (Caucasus, Syria, PersianGulf, GermanyCW). Each contains:

| What | Details |
| --- | --- |
| Coalitions | CJTF Blue vs CJTF Red (either side can use any unit type) |
| Airbase ownership | As in the theater pack (BLUE Georgia, RED north / Abkhazia / South Ossetia) |
| **Dynamic spawn** on all 23 campaign airbases | In multiplayer, players pick any aircraft their side's base holds. The engine removes the enemy's types and stocks the owner's at mission start and after every capture. |
| **Fixed client slots** at the depots | One per aircraft type at Batumi, Kutaisi (BLUE) and Sochi-Adler, Beslan, Krasnodar-Center (RED). These also work in single player. |
| AI templates | Late-activated groups: 2-ships `DCC_TPL_blue_fighter` F-16C, `_blue_attack` A-10C, `_red_fighter` MiG-29S, `_red_attack` Su-25 with loadouts, and single `DCC_TPL_blue_awacs` E-3A / `_red_awacs` A-50. The engine copies them for AI sorties — change a template's loadout in the Mission Editor if you like. |
| One trigger | MISSION START → DO SCRIPT `ctld.dontInitialize = true` → DO SCRIPT FILE `CTLD.lua` → DO SCRIPT FILE `dcc_bundle.lua` (the engine, which sets up and starts CTLD) |
| Options | F10 map view **Allies only** (enemies appear only through the campaign's intel layer), civil traffic off |

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
for m in Syria PersianGulf GermanyCW; do python tools/make_mission.py --theater $m --out dist/DCC_$m.miz; done
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
| `rotation.json` | Which map the campaign is on (written by the mission, read by the rotation hook) |

To **reset a war**, stop the server and delete `Caucasus_war.json` and the backups.

### 5. When a war ends

The engine announces the winner and the next map, sets **user flag 9900** to 1 and writes
`DCC\rotation.json`. The rotation hook loads the next map two minutes later — see
[Map rotation](#map-rotation).

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
- [ ] **Rotation:** on a test server, delete all but one RED node from the save (or set `garrisonStart` tiny), let BLUE win, and watch the hook load `DCC_Syria.miz` after the chat warning. Check `dcs.log` for `DCC-ROTATION` lines.
- [ ] The E-3A / A-50 appear ("Command: … AWACS on station") and fly a race-track behind the front.
- [ ] An EWR unit (FPS-117 / 1L13) stands near each depot when you fly within 80 km; destroying it reports "early-warning radar … destroyed".
- [ ] Flying high toward an enemy depot puts you on *their* map (ask someone on the other side); flying low at 100 km does not.
- [ ] A recon pass gives the photo report message and `[photo]` labels per platoon.
- [ ] Syria, Persian Gulf and Germany missions start a war, set airbase owners and spawn units (each map once).
- [ ] **Mission Editor → Options → F10 view** reads *Allies only* (the generator writes `optview_onlyallies`; if your DCS shows a different name, pick *Allies only* by hand). Enemy units must not appear on the F10 map by themselves.
- [ ] Flying at 6000 m toward an enemy airbase: within 60 km a red SAM ring with an error circle appears on your map, and the circle shrinks over a few minutes.
- [ ] Firing a HARM at a lit SAM makes it stop guiding (dark) for 1–2 minutes.
- [ ] A low pass over an enemy base puts "N vehicles seen" there; a hill between you and it does not.
- [ ] Spectators see only the front line and base owners (intel is per coalition).
- [ ] **FARP:** deliver 3 crates to a friendly town; the trucks appear, and the town's FARP offers your side's helicopters in the slot list (dynamic spawn on script-stocked invisible FARPs is the least-tested DCS feature here).
- [ ] **JTAC:** take a CAS mission, *Report target*, and check the laser on 1688 in your targeting pod.
- [ ] **Carrier (Gulf):** the F/A-18C / F-14B slots spawn on the deck; TACAN 74X and ICLS 4 work; the group turns around at the end of its leg.
- [ ] **Weather:** in a storm (status says so) fog closes in (DCS 2.9.10+).
- [ ] **Companion:** the web map shows the front; a capture shows up in Discord within a minute.
- [ ] **Hosted server without file access:** the start message says the war cannot be saved; after a win the mission ends after 2 min and the next mission in the list loads.
- [ ] A RED strike package ("Command: RED STRIKE sortie airborne") shows up as INTERCEPT on BLUE's board.
- [ ] Tanker: TACAN 51X, refuelling from the KC-135MPRS works (drogue).
- [ ] Near a battle, the artillery battery fires (shell splashes at the base).
- [ ] Skirmishes: vehicles fighting on the front roads far from any player.
- [ ] Destroying a bridge on a road between two bases reports "Bridge on the road … destroyed".
- [ ] `dcs.log` has no `DCC: ERROR` lines (errors now include a stack traceback).

---

## What players see

- **Territory and front line** — each side's ground is shaded in its colour and the front is a continuous
  yellow line between them, pockets and enclaves included. Every base owns the ground closer to it than
  to any other base (its *Voronoi cell*, capped at 75 km so territory does not run out over the sea); the
  front is wherever a BLUE cell meets a RED cell. Redrawn when a base changes hands. The idea comes from
  [rurounijones/frontline](https://github.com/rurounijones/frontline) (C#, AGPL); this is an independent
  Lua implementation that runs inside the mission (`src/dcc_territory.lua`).
- **Nodes** — circles in the owner's colour (depots larger, dashed outline) with the name for everyone. The owner also sees `platoons | SU`, and `NO SUPPLY` when a base has run dry.
- **Enemy contacts** (fog of war) — SAM threat rings (with an ELINT error circle when the fix is rough), columns where they were seen, garrisons seen at bases, recon reports, *est. light/medium/heavy* on enemy front bases, enemy aircraft seen in the last 2 minutes. Faded = stale. Refreshed every minute. F10 → status also lists how many fresh contacts your side holds.
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
| `warClockDays` | 7 | A war ends after this many days of server time; most ground gained wins. 0 = no clock |
| `warClockDaysNoSave` | 1 | The same on a server that cannot save (hosted without file access) |
| `air.*`, `ground.*` | | Package and assault rates, tanker/drone pools, IADS cue range, credit on landing, cooldown; artillery, fortification, morale, bridge and skirmish settings |
| `victoryMinSorties` | 3 | Sorties for the winner needed for the victory bonus (or one completed mission) |
| `world.*` | | Weather effects, night hours, fog, AI threat levels, FARP size, AI anti-ship rate |
| `jtac.laserCode` | 1688 | JTAC laser code |
| `defenderBonus` | town 1.3, airbase 1.5, depot 2.0 | How hard each node class is to take (only while supplied) |

Phase 3 settings are in `ops` (SAM repair times and costs, structures, AI air pools, air
cover, ambush chance, CSAR timeout, crate size) and `missions` (board size per type, CAP time,
recon and escort distances).

Phase 4 settings are in `intel`: `enabled` (set false for a god's-eye board and map),
contact aging (`staleTicks`, `expireTicks`), visual ranges, ELINT range, height and error
(`elintKm`, `elintMinAglM`, `elintBaseErrM`, `elintMinErrM`, `elintShrink`), SAM wake distance,
dark time after an anti-radiation missile, troops-in-contact distance and redraw interval.

Player aircraft stock per base is `aircraftStock` in the catalog (4 per type, 8 at depots).
Per-map balance lives in the theater pack: `balance = { blue = 1.0, red = 1.0 }` multiplies each
side's production.

### Balance status (phase 2)

Measured with the offline simulator, no players online:

- **The code is side-neutral.** With the start map mirrored, the Georgia side still won, so any bias comes from geography; red's depots were moved to Beslan and Sochi-Adler to even the start.
- **Wars stay alive.** In 14 wars of 42 days each, the front changed hands 500–800 times per war and swung both ways; starvation is about 8 % of losses, mostly freshly captured towns.
- **AI-only wars rarely end on their own** — hence the 7-day war clock. With supply, the two commanders are evenly matched, so none of the 14 finished. Players decide wars — every convoy, airlift and garrison you kill shifts the balance.

---

## Testing offline

Nothing here needs DCS to test. The engine is plain Lua 5.1 (the version DCS uses) and runs
under Python via `lupa`:

```bash
pip install lupa matplotlib

python tools/run_lua.py tests/test_war.lua          # war model, supply, war clock: 38 checks
python tools/run_lua.py tests/test_ops.lua          # every mission type and every war rule: 150 checks
python tools/run_lua.py tests/test_dcs_bridge.lua   # bridge, convoys, airlifts, warehouses: 51 checks
python tools/run_lua.py tests/test_dcs_ops.lua      # flying every mission type against a fake DCS: 61 checks
python tools/run_lua.py tests/test_dcs_intel.lua    # fog of war: each map shows only what that side detected: 40 checks
python tools/run_lua.py tests/test_dcs_radar.lua    # EWR, AWACS, HVAA, recon photos: 34 checks
python tools/run_lua.py tests/test_theaters.lua     # all four maps: connected, depots, war runs, territory and front: 44 checks
python tools/run_lua.py tests/test_dcs_airground.lua # packages, tankers, drones, IADS, cooldown, artillery, skirmishes, forts, bridges, supply helicopters and intercepting them: 47 checks
python tools/run_lua.py tests/test_dcs_world.lua    # weather, night, AI escorts and CAP, FARPs, JTAC, carrier, public files: 46 checks
python tests/test_companion.py                      # web map and Discord feed (with a fake Discord): 7 tests
python tools/run_lua.py tests/test_rotation.lua     # a win (conquest or clock) loads the next map unattended, bonus and report: 40 checks
python tools/run_lua.py tests/test_ext.lua          # armoury, runways, SAM moves, crews, support, mines, veterancy, industry, partisans, scaling, wrecks: 67 checks
python tools/run_lua.py tests/test_ctld.lua         # the real CTLD.lua on the fake DCS: zones, crates, troops, FOB, AA, vehicles joining bases or assaults, light-vehicle loads, bridge kits, minefields: 60 checks

python tools/run_lua.py tools/sim.lua 4320 2026 docs/sim_history.json   # simulate 15 days
DCC_THEATER=Syria python tools/run_lua.py tools/sim.lua 4320               # ...on another map
python tools/plot_war.py docs/sim_history.json docs/sim_war.png         # plot it
python tools/run_lua.py tools/interdiction.lua 8                         # convoy-kill experiment
```

`tests/dcs_mock.lua` fakes the parts of the DCS scripting API the bridge uses (spawning, groups,
aircraft, airbases and warehouses, F10 drawing, timers, files, player births, line of sight,
AI detections, alarm states, weapon shots). It catches wiring
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
  dcc_intel.lua       contacts per side: aging, troops in contact, front estimates, SAM knowledge
  dcc_radar.lua       EWR sites, AWACS pool, EWR and HVAA missions, recon photos
  dcc_world.lua       weather, night, road threat (AI adaptation), FARPs, ships, ANTISHIP and FARP missions
  dcc_air.lua         tankers, drones, strike packages and helicopter assaults, INTERCEPT and TANKER missions
  dcc_ground.lua      artillery, fortifications, bridges and closed roads, morale and surrender
  dcc_ext.lua         armoury, runways, crews, support, engineers, mines, veterancy, industry, partisans, scaling, wrecks
  dcc_front.lua       front crossings on contested roads (kept for the AI and tests)
  dcc_territory.lua   territory and front line from Voronoi cells (drawn on F10 and the web map)
  dcc_persist.lua     save / load / backups (the only file access)
  dcc_dcs.lua         DCS bridge: live bubble, spawning, read-back, F10 drawing, menus
  dcc_dcs_supply.lua  DCS bridge: convoys, airlifts, warehouses, slot guard
  dcc_dcs_ops.lua     DCS bridge: menus, briefings, detection, SAMs, statics, AI air, CSAR, cargo
  dcc_dcs_intel.lua   DCS bridge: eyes, AI sensors, ELINT, SAM EMCON/HARM, the per-side intel map layer
  dcc_dcs_radar.lua   DCS bridge: EWR units, AWACS orbits, radar-horizon air picture, photo reports
  dcc_dcs_world.lua   DCS bridge: night, fog, convoy escorts, road CAP, FARP stock and crews, ships
  dcc_dcs_jtac.lua    DCS bridge: JTAC teams, laser and IR pointer, smoke, menu
  dcc_dcs_public.lua  DCS bridge: public.json and feed.jsonl for the companion
  dcc_dcs_air.lua     DCS bridge: tankers, drones, packages, IADS cueing, point defence, forward CAP, credit, cooldown
  dcc_dcs_ground.lua  DCS bridge: artillery fire, front skirmishes, bunkers, bridge discovery
  dcc_dcs_ctld.lua    DCS bridge: CTLD set-up, base zones, crate costs, troops, FOBs and AA into the war
  dcc_dcs_ext_air.lua DCS bridge: armoury, runway bombs, shoot and scoot, AI crews, prisoners, Support menu, ranks, wrecks
  dcc_dcs_ext_ground.lua DCS bridge: bridge kits, minefields, industry sites, partisan cells
  dcc_main.lua        start-up and the 30 s / 5 min loops
  dcc_loader.lua      development loader
theaters/*.lua          Caucasus (hand-made), Syria, Persian Gulf, Cold War Germany (generated)
hooks/DCC_rotation_hook.lua   server hook: loads the next map after a win
vendor/ctld/            CTLD.lua (VEAF CTLD v2, built by tools/build_ctld.py), beacon sounds, credits
server/                 dcc_companion.py (web map + Discord), example config, start_companion.bat
catalogs/modern.lua     Modern era: ground roles, convoys, transports, player aircraft, capabilities,
                        AI air loadouts, SAM sites, strike buildings, ambush teams
dist/                   dcc_bundle.lua (the engine) and DCC_Caucasus.miz (the mission)
tests/                  model tests, bridge tests, DCS API mock
tools/                  Lua runner, simulator, plotter, interdiction test, bundle + mission builders,
                        theater generator (make_theater.py) and its scenarios (tools/scenarios/)
```

---

## Roadmap

| Phase | Scope | Done when |
| --- | --- | --- |
| 1 — Core loop ✓ | Theater pack, nodes and owners, AI assaults, capture, front line, save/load | The front moves on its own overnight and survives a restart |
| 2 — Supply economy ✓ | Supply per node, real convoys and airlifts, warehouses with dynamic spawn, supply-gated commander, generated mission | Killing a convoy visibly delays the assault it was feeding |
| 3 — Player missions ✓ | Mission boards for RED and BLUE: CAS, BAI, strike, SEAD/DEAD, CAP, escort, convoy escort, recon, CSAR, helicopter logistics and air assault; AI air; persistent pilots | Every mission type writes its effect to the save |
| 4 — Fog of war and intel ✓ | Contact table with aging, eyes / AI sensors / ELINT / recon / troops in contact, SAM EMCON and HARM shutdown, intel-gated BAI and SEAD, per-side intel map layer (own ELINT instead of the Hound library — no extra dependency) | Each side's map shows only what it has detected |
| **5 — Rotation and all maps ✓ (this)** | Rotation hook and rotation file, Syria / Persian Gulf / Cold War Germany packs from a generator, sea crossings, EWR sites, AWACS, HVAA and EWR missions, recon photos | A win on Caucasus loads the next map unattended |

**After phase 5 ✓:** war clock (7 days, ground gained wins), victory bonus and war report, squadrons,
web map and Discord feed, weather and night, AI that adapts to interdiction, JTAC, player-built FARPs,
carrier operations in the Gulf, VEAF CTLD as the helicopter logistics layer, AI supply helicopters,
armoury, runway strikes, shoot and scoot, prisoners, support on call, engineers, minefields, veterancy,
industry, partisans, player-count scaling, rank unlocks, persistent wrecks.

**Ideas, not started:** fog for the AI commanders too, a Cold War era catalog (if wanted later),
player-requested AI support (artillery, CAS on call), more ships (a RED surface group in the Gulf).

## License

MIT — see [LICENSE](LICENSE).
