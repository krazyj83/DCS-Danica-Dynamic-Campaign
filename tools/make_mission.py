#!/usr/bin/env python3
"""Generate a ready-to-fly campaign mission (.miz) for one theater.

Why this exists: DCS cannot create flyable player aircraft from a script -
player slots must be in the mission file. This tool builds that file from the
same theater pack and era catalog the engine uses, so they never disagree.

What the mission contains:
  * Coalitions: CJTF Blue vs CJTF Red (any unit type can be used by either).
  * Airbase ownership as in the theater pack.
  * DYNAMIC SPAWN on every theater airbase: in multiplayer, players pick any
    aircraft the base's warehouse holds. Both sides' types are listed at
    every base (at least 1 each - a DCS dynamic-spawn quirk); the engine then
    zeroes the enemy's types and stocks the owner's, and repeats that on every
    capture, so the choice always follows ownership.
  * FIXED CLIENT SLOTS: exactly one per type and side (in `fixedSlots`, or every
    type if unset, C-130J included) - on the side's HQ first, then the other depots,
    then the other airbases - each on the smallest stand it fits (the big stands stay free for
    transports). They may take at most `fixedSlotShare` of an airbase's parking (v0.37:
    a full apron left dynamic spawn no free stand, so only one aircraft could
    spawn); `fixedSlotFirst` types (DTC / datalink jets) are placed first. Fixed
    slots work in single player too.
  * One trigger: MISSION START -> DO SCRIPT (ctld.dontInitialize = true),
    DO SCRIPT FILE vendor/ctld/CTLD.lua, DO SCRIPT FILE dist/dcc_bundle.lua.
    The engine configures and starts CTLD itself (src/dcc_dcs_ctld.lua).
    --no-ctld leaves CTLD out (the engine's own helicopter Cargo menu is used).
  * Options: F10 map in fog-of-war mode, civil traffic off.
  * Combined Arms slots per side: 2 Tactical Commander, 2 JTAC, 2 Observer (CA_SLOTS).
  * Kneeboard pages for every aircraft (tools/kneeboard.py): comms, map, reference.
  * DTC cartridges (F-16C, F/A-18C) from the templates in dtc/: radio presets and
    displays as made in the Mission Editor; the Hornet gets every airbase and town
    as a steerpoint. Default cartridge in every client slot of those types.

Needs pydcs:  pip install git+https://github.com/pydcs/dcs.git
              (or clone it and set PYTHONPATH to the clone)

Usage:
    python tools/build_bundle.py
    python tools/make_mission.py                 -> dist/DCC_Caucasus.miz
    python tools/make_mission.py --theater Caucasus --era modern --out my.miz
"""
import argparse
import copy
import glob
import json
import os
import sys
import zipfile

from lupa import lua51

import dcs
from dcs import countries, helicopters, planes
from dcs.action import DoScript, DoScriptFile, EndMission
from dcs.condition import FlagEquals
from dcs.triggers import TriggerOnce
from dcs.coalition import Coalition
from dcs.forcedoptions import ForcedOptions
from dcs.mission import StartType
from dcs.triggers import TriggerStart
from dcs import flyingunit, mapping, ships, task as dtask, unit as dunit
from dcs.terrain.terrain import Warehouse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mod_types import MOD_TYPES  # noqa: E402
import kneeboard  # noqa: E402

WITH_MODS = True

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TERRAINS = {
    "Caucasus": lambda: dcs.terrain.Caucasus(),
    "Syria": lambda: dcs.terrain.Syria(),
    "PersianGulf": lambda: dcs.terrain.PersianGulf(),
    "GermanyCW": lambda: dcs.terrain.Germany(),
}


def lua_to_py(v):
    """Convert a lupa table to plain Python (lists for 1..n tables, else dicts)."""
    if lua51.lua_type(v) != "table":
        return v
    keys = list(v.keys())
    if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [lua_to_py(v[k]) for k in range(1, len(keys) + 1)]
    return {k: lua_to_py(v[k]) for k in keys}


def load_data(theater, era):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    for rel in (f"catalogs/{era}.lua", f"theaters/{theater.lower()}.lua"):
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            sys.exit(f"missing {rel}")
        lua.execute(open(path, encoding="utf-8").read())
    g = lua.globals()
    return lua_to_py(g.DCC_THEATERS[theater]), lua_to_py(g.DCC_CATALOGS[era])


def load_config():
    """DCC.config from src/dcc_config.lua (the same numbers the engine reads)."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(open(os.path.join(ROOT, "src", "dcc_config.lua"), encoding="utf-8").read())
    return lua_to_py(lua.globals().DCC.config)


def type_index():
    """DCS type name -> pydcs class, for planes and helicopters."""
    idx = {}
    for mod in (planes, helicopters):
        for name in dir(mod):
            cls = getattr(mod, name)
            if isinstance(cls, type) and hasattr(cls, "id") and hasattr(cls, "flyable"):
                idx[cls.id] = cls
    if WITH_MODS:
        for cls in MOD_TYPES:            # community mods (tools/mod_types.py)
            idx[cls.id] = cls
    return idx


def find_airport(terrain, name):
    if name in terrain.airports:
        return terrain.airports[name]
    low = name.lower().replace(" ", "").replace("-", "")
    for key, ap in terrain.airports.items():
        if key.lower().replace(" ", "").replace("-", "") == low:
            return ap
    return None


def pylon_weapons(cls):
    """{pylon number: [(name, (pylon, weapon dict)), ...]} for a pydcs aircraft type."""
    out = {}
    for i in range(1, 30):
        P = getattr(cls, f"Pylon{i}", None)
        if P is None:
            continue
        out[i] = [(v[1]["name"], v) for v in vars(P).values()
                  if isinstance(v, tuple) and len(v) == 2 and isinstance(v[1], dict) and "clsid" in v[1]]
    return out


def pick_loadout(cls, wishes):
    """Fill pylons from a wish list [(name contains, max count), ...], in order."""
    left = {w: n for w, n in wishes}
    chosen = []
    for pylon, weapons in sorted(pylon_weapons(cls).items()):
        for wish, _ in wishes:
            if left[wish] <= 0:
                continue
            match = [w for name, w in weapons if wish.lower() in name.lower()]
            if match:
                chosen.append(match[0])
                left[wish] -= 1
                break
    return chosen


CA_SLOTS = {"commander": 2, "jtac": 2, "observer": 2}


def build_ai_templates(m, catalog, cjtf, theater):
    types = type_index()
    made = []
    for side in ("blue", "red"):
        # Park the templates (late activation = invisible) over the side's first depot.
        depot = next((n for n in theater["nodes"] if n["side"] == side and n.get("depot")), theater["nodes"][0])
        ap = find_airport(m.terrain, depot.get("airbase", "")) if depot.get("airbase") else None
        pos = ap.position if ap else m.terrain.bullseye_blue
        for role, spec in catalog.get("aiAir", {}).get(side, {}).items():
            cls = types.get(spec["type"])
            if cls is None:
                print(f"  warning: AI type {spec['type']} unknown to pydcs")
                continue
            name = f"DCC_TPL_{side}_{role}"
            g = m.flight_group_inflight(cjtf[side], name, cls, pos.point_from_heading(90, 20000 + len(made) * 3000),
                                        altitude=9000 if role == "awacs" else 6000, speed=600,
                                        group_size=spec.get("size", 2))
            g.late_activation = True
            for unit in g.units:
                unit.pylons.clear()
                for w in pick_loadout(cls, [tuple(x) for x in spec["loadout"]]):
                    unit.load_pylon(w)
            made.append(f"{name} ({spec['type']}, {len(g.units[0].pylons)} pylons)")
    return made


def latlon_point(m, lat, lon):
    return mapping.Point.from_latlng(mapping.LatLng(lat, lon), m.terrain)


def build_farps(m, theater, catalog, cjtf, armoury="warehouse"):
    """Invisible FARPs per town (FARP_PADS pads per coalition) with dynamic spawn and
    an EMPTY helicopter stock. The engine stocks the owner's FARP (helicopters and
    weapons) while it is open, and empties it when the town is lost. Fuel is set
    here: config world.farpFuel tons at every pad (v0.44)."""
    fuel = load_config()["world"]["farpFuel"]
    made = 0
    for node in theater["nodes"]:
        if node.get("kind") != "town":
            continue
        base = latlon_point(m, node["lat"], node["lon"])
        for i, side in enumerate(("blue", "red")):
            centre = base.point_from_heading(90 + i * 180, 1500)
            # FARP_PADS helipads side by side (v0.38: one invisible pad = one helicopter at a time)
            for k in range(1, FARP_PADS + 1):
                pos = centre.point_from_heading(0, (k - 1) * 60)
                suffix = "" if k == 1 else f"_{k}"
                g = m.farp(cjtf[side], f"DCC_FARP_{node['id']}_{side}{suffix}", pos, hidden=True,
                           farp_type=dunit.InvisibleFARP)
                wh = Warehouse()
                wh.coalition = side.upper()
                wh.dynamic_spawn = True
                wh.allow_hot_start = True
                wh.unlimited_aircrafts = False
                wh.unlimited_munitions = armoury != "warehouse"
                wh.unlimited_fuel = False
                wh.jet_init = wh.gasoline_init = wh.diesel_init = wh.methanol_mixture_init = fuel
                wh.aircrafts = {"planes": {}, "helicopters": {t: {"initialAmount": 1}
                                                             for t in catalog["aircraft"][side].get("helicopters", [])}}
                m.warehouses.warehouses[int(g.units[0].id)] = wh.dict()
            made += 1
    return made


def build_naval(m, theater, cjtf, types):
    """Ship groups from the theater pack; carriers get TACAN/ICLS and client slots."""
    report = []
    for sh in theater.get("naval", []) or []:
        side = sh["side"]
        cls = ships.ship_map.get(sh["ship"])
        if cls is None:
            print(f"  warning: ship type {sh['ship']} unknown to pydcs")
            continue
        pos = latlon_point(m, sh["lat"], sh["lon"])
        g = m.ship_group(cjtf[side], f"DCC_NAVAL_{sh['id']}", cls, pos, heading=sh.get("heading", 0))
        for i, et in enumerate(sh.get("escorts", []) or []):
            ecls = ships.ship_map.get(et)
            if ecls:
                e = m.ship(f"DCC_NAVAL_{sh['id']} escort {i + 1}", ecls)
                p = pos.point_from_heading((sh.get("heading", 0) + 90 + i * 120) % 360, 2500)
                e.position.x, e.position.y = p.x, p.y
                e.heading = sh.get("heading", 0)
                g.add_unit(e)
        # sail into the wind at 25 kn; the engine turns the group around at the end
        far = pos.point_from_heading(sh.get("heading", 0), (sh.get("legKm") or 80) * 1000)
        g.add_waypoint(far, 46)
        if sh.get("kind") == "carrier":
            cv = g.units[0]
            # beacons per ship (theater pack), so two carriers on one map do not share a channel
            tacan = sh.get("tacan", 74)
            if tacan:
                g.points[0].tasks.append(dtask.ActivateBeaconCommand(channel=tacan, modechannel="X",
                                                                     callsign=sh.get("tacanCall", "STN"),
                                                                     bearing=True, unit_id=cv.id, aa=False))
            icls = sh.get("icls", 4)
            if icls:
                g.points[0].tasks.append(dtask.ActivateICLSCommand(channel=icls, unit_id=cv.id))
            # Dynamic spawn on the ship (v0.37): every slot type, 20 of each, unlimited munitions
            # and fuel (the fleet resupplies itself; the armoury follows land bases only).
            wh = Warehouse()
            wh.coalition = side.upper()
            wh.dynamic_spawn = True
            wh.allow_hot_start = True
            wh.unlimited_aircrafts = False
            wh.unlimited_munitions = True
            wh.unlimited_fuel = True
            stock_n = sh.get("dynamicStock", CARRIER_STOCK)
            ac = {"planes": {}, "helicopters": {}}
            for t in sh.get("slots", []) or []:
                if t in types:
                    kind = "helicopters" if t in helicopters.helicopter_map else "planes"
                    ac[kind][t] = {"initialAmount": stock_n}
            wh.aircrafts = ac
            m.warehouses.warehouses[int(cv.id)] = wh.dict()
            for n, t in enumerate(sh.get("slots", []) or []):
                cls_a = types.get(t)
                if cls_a is None:
                    continue
                try:
                    fg = m.flight_group_from_unit(cjtf[side], f"{side.upper()} {sh['name']} {t} {n + 1}", cls_a, g,
                                                  start_type=StartType.Cold, group_size=1)
                    fg.set_client()
                    report.append(f"{t} @ {sh['name']}")
                except Exception as exc:
                    print(f"  no carrier slot for {t}: {exc}")
    return report


FARP_PADS = 2            # helipads per FARP and side (config world.farpPads must match, v0.38)
CARRIER_STOCK = 20       # aircraft of each slot type a carrier holds for dynamic spawn (v0.37)

CTLD_DIR = os.path.join(ROOT, "vendor", "ctld")
SCRIPTS_DIR = os.path.join(ROOT, "tools", "mission_scripts")


AI_SKILL = dunit.Skill.Excellent   # v0.41: every AI unit in the mission is Ace (the engine's own spawns: config aiSkill)


def set_ai_skill(m):
    """Every AI unit in the mission (ships, AI aircraft templates, ground) at AI_SKILL; client slots untouched."""
    n = 0
    for coal in m.coalition.values():
        for country in coal.countries.values():
            for g in (list(country.vehicle_group) + list(country.ship_group) + list(country.plane_group)
                      + list(country.helicopter_group)):
                for u in g.units:
                    if getattr(u, "skill", None) not in (None, dunit.Skill.Client, dunit.Skill.Player):
                        u.skill = AI_SKILL
                        n += 1
    print(f"  AI skill: {n} units set to {AI_SKILL.value}")


def fix_radio_frequencies(m):
    """Every aircraft group on its type's own default radio frequency.

    pydcs gives helicopter groups 127.5 MHz, which some types cannot tune (the UH-1H's
    radio stops below it) and the Mission Editor then refuses to save the mission."""
    fixed = 0
    for coal in m.coalition.values():
        for country in coal.countries.values():
            for g in list(country.plane_group) + list(country.helicopter_group):
                utype = g.units[0].unit_type if g.units else None
                freq = getattr(utype, "radio_frequency", None)
                if freq and g.frequency != freq:
                    g.frequency = freq
                    fixed += 1
    if fixed:
        print(f"  radio: {fixed} aircraft groups set to their type's default frequency")


# ---------------------------------------------------------------------------
# DTC (Data Transfer Cartridge): one cartridge per DTC-capable type, built from
# the templates in dtc/ (made in the Mission Editor, exported as .dtc). The
# map's airbases and towns become the Hornet's steerpoints; every client slot of
# that type gets the cartridge as its default. pydcs has no DTC support, so the
# unit's dict() is extended and the files are added to the .miz after saving.
# ---------------------------------------------------------------------------
DTC_DIR = os.path.join(ROOT, "dtc")

_base_unit_dict = flyingunit.FlyingUnit.dict


def _unit_dict_with_dtc(self):
    d = _base_unit_dict(self)
    name = getattr(self, "dcc_dtc", None)
    if name:
        d["DTC"] = {"Cartridges": {1: {"name": name, "default": True}}}
    links = getattr(self, "dcc_datalinks", None)
    if links:
        d["datalinks"] = links
    return d


# ---------------------------------------------------------------------------
# Datalinks. pydcs leaves a client slot without a Link 16 STN and without the
# "datalinks" block the Mission Editor writes, so the jet joins no network and
# sees no AWACS / flight tracks. tools/datalinks.json holds the Mission Editor's
# own blocks per type (Link 16: F/A-18C, F-16C; SADL: A-10C II; IDM: AH-64D);
# every client slot gets one, with its own unit as team member, plus a unique
# STN and voice callsign like the Mission Editor gives.
# ---------------------------------------------------------------------------
DATALINKS = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "datalinks.json"),
                           encoding="utf-8"))
DATALINKS.setdefault("F-15ESE", DATALINKS.get("F-16C_50"))      # Link 16, same block


def _own_ids(v, uid):
    """Every missionUnitId in a Mission Editor datalink block -> this unit; lists -> Lua tables."""
    if isinstance(v, dict):
        return {k: (uid if k == "missionUnitId" else _own_ids(x, uid)) for k, x in v.items()}
    if isinstance(v, list):
        return {i + 1: _own_ids(x, uid) for i, x in enumerate(v)}
    return v


def assign_datalinks(m):
    stn, n = 0o201, 0
    for coal in m.coalition.values():
        for country in coal.countries.values():
            for g in list(country.plane_group) + list(country.helicopter_group):
                for u in g.units:
                    if u.skill not in (dunit.Skill.Client, dunit.Skill.Player):
                        continue
                    t = u.unit_type
                    props = getattr(t, "property_defaults", None) or {}
                    if "STN_L16" in props:
                        u.set_property("STN_L16", f"{stn:05o}")
                        stn += 1
                    if "VoiceCallsignLabel" in props:
                        cs = getattr(u, "callsign_dict", None) or {}
                        letters = "".join(ch for ch in str(cs.get("name", "Enfield")) if ch.isalpha()) or "Enfield"
                        u.set_property("VoiceCallsignLabel", (letters[0] + letters[-1]).upper())
                        u.set_property("VoiceCallsignNumber", f"{cs.get(2, 1)}{cs.get(3, 1)}")
                    tpl = DATALINKS.get(t.id)
                    if tpl:
                        links = _own_ids(copy.deepcopy(tpl), u.id)
                        for link in links.values():
                            net = link.get("network")
                            if isinstance(net, dict) and "teamMembers" in net:
                                net["teamMembers"] = {i + 1: {"missionUnitId": x.id} for i, x in enumerate(g.units)}
                                net["donors"] = {}
                        u.dcc_datalinks = links
                        n += 1
    print(f"  datalinks: {n} client slots on a network, {stn - 0o201} Link 16 STNs")


flyingunit.FlyingUnit.dict = _unit_dict_with_dtc


def build_dtcs(m, theater, theater_name):
    """Returns {path in the .miz: json text} and gives client slots their cartridge."""
    files, names = {}, {}
    nodes = sorted(theater["nodes"], key=lambda n: (n.get("kind") != "airbase", n["name"]))
    for fn in sorted(glob.glob(os.path.join(DTC_DIR, "*.dtc"))):
        d = json.load(open(fn, encoding="utf-8"))
        typ = d["type"]
        name = f"DCC {theater_name} {typ}"
        d["name"] = name
        data = d["data"]
        data["name"], data["terrain"], data["type"] = name, theater_name, typ
        wy = data.get("WYPT")
        if wy and wy.get("NAV_PTS"):
            proto = wy["NAV_PTS"][0]
            pts = []
            limit = (wy.get("NAV_SETTINGS", {}).get("AA_Waypoint", {}).get("AA_WP_Number") or 60) - 1
            for i, n in enumerate(nodes[:limit], start=1):
                p = latlon_point(m, n["lat"], n["lon"])
                pt = copy.deepcopy(proto)
                pt.update({"id": f"STPT{i}", "idOA": f"OA{i}", "idOA_Line": f"OA{i}Line", "wypt_num": i,
                           "x": p.x, "y": p.y, "alt": 0, "note": "", "text_note": n["name"]})
                pts.append(pt)
            wy["NAV_PTS"] = pts
            wy["NAV_ROUTE"] = [[], [], []]
            wy["terrain"] = theater_name
        files[f"DTC/{name}.dtc"] = json.dumps(d, indent=1)
        names[typ] = name
    slots = 0
    for coal in m.coalition.values():
        for country in coal.countries.values():
            for g in list(country.plane_group) + list(country.helicopter_group):
                for u in g.units:
                    if u.unit_type.id in names and u.skill in (dunit.Skill.Client, dunit.Skill.Player):
                        u.dcc_dtc = names[u.unit_type.id]
                        slots += 1
    if files:
        print(f"  DTC: {', '.join(sorted(names))} cartridges, default in {slots} client slots")
    return files


def build(theater_name, era, out, bundle, use_ctld=True, armoury="warehouse", test=False):
    theater, catalog = load_data(theater_name, era)
    if theater_name not in TERRAINS:
        sys.exit(f"no pydcs terrain mapping for {theater_name}")
    m = dcs.Mission(TERRAINS[theater_name]())

    # Coalitions: the two CJTF countries carry every unit. BLUE also lists the USA (empty): DCS only gives a
    # coalition GPS when the USA is in it, and without GPS the F-16's Link 16 never syncs (NET STATUS, GPS TIME ON:
    # SYNC stays blank, no datalink tracks) and GPS weapons fly on INS only (v0.43).
    blue, red = Coalition("blue"), Coalition("red")
    cjtf = {"blue": blue.add_country(countries.CombinedJointTaskForcesBlue()),
            "red": red.add_country(countries.CombinedJointTaskForcesRed())}
    blue.add_country(countries.USA())
    blue.bullseye, red.bullseye = m.terrain.bullseye_blue, m.terrain.bullseye_red
    m.coalition = {"blue": blue, "red": red}

    types = type_index()
    air = catalog["aircraft"]
    stock = catalog.get("aircraftStock", {"airbase": 4, "depot": 8})
    fixed = catalog.get("fixedSlots")
    share = catalog.get("fixedSlotShare", 0.25)      # most of every apron stays free for dynamic spawn
    first = catalog.get("fixedSlotFirst", [])
    used = {}

    # Warehouse entry for one aircraft type (keyed by DCS type name).
    def all_types(side):
        return air[side].get("planes", []) + air[side].get("helicopters", [])

    for side in ("blue", "red"):
        for t in all_types(side):
            if t not in types:
                print(f"  warning: {side} aircraft '{t}' unknown to pydcs - it may be misspelled")

    report = {"blue": [], "red": []}
    missing_airports = []
    bases = {"blue": [], "red": []}

    for node in theater["nodes"]:
        if node.get("kind") != "airbase" or not node.get("airbase"):
            continue
        ap = find_airport(m.terrain, node["airbase"])
        if ap is None:
            missing_airports.append(node["airbase"])
            continue
        side = node["side"]
        ap.set_coalition(side)

        # Dynamic spawn: both sides listed, owner's types at full stock,
        # enemy's at 1 (the engine sets them to 0 at mission start).
        ap.dynamic_spawn = True
        ap.allow_hot_start = True
        ap.unlimited_aircrafts = False
        ap.unlimited_munitions = armoury != "warehouse"   # warehouse: the engine stocks the shelves
        ap.unlimited_fuel = True
        own = stock["depot"] if node.get("depot") else stock["airbase"]
        warehouse = {"planes": {}, "helicopters": {}}
        for s in ("blue", "red"):
            n = own if s == side else 1
            for kind in ("planes", "helicopters"):
                for t in air[s].get(kind, []):
                    if t not in types:
                        continue                 # unknown to pydcs, or a mod left out (--no-mods)
                    warehouse[kind][t] = {"initialAmount": max(n, warehouse[kind].get(t, {}).get("initialAmount", 0))}
        ap.aircrafts = warehouse

        hq = (theater.get("main") or {}).get(side) == node["id"]
        bases[side].append((0 if hq else (1 if node.get("depot") else 2), node["name"], ap))

    # Fixed client slots (v0.39): exactly ONE per type and side - C-130J included - on the HQ first,
    # then the other depots, then the other airbases. Each base keeps most of its apron for dynamic
    # spawn (fixedSlotShare); only a type that fits nowhere else may go past that.
    for side in ("blue", "red"):
        wanted = list(fixed[side] if fixed else all_types(side))
        wanted.sort(key=lambda t: (first.index(t) if t in first else len(first)))   # stable: DTC jets first
        ordered = sorted(bases[side], key=lambda b: (b[0], b[1]))

        def place(t, name, ap, capped=True):
            if capped and used.get(ap.id, 0) >= int(len(ap.parking_slots) * share):
                return False                              # keep the rest of the apron for dynamic spawn
            # the smallest stand the type fits (pydcs takes the first by name, so fighters sat on the
            # big stands and a C-130J found none left - v0.37: "the Hercules does not load")
            fits = ap.free_parking_slots(types[t])
            if not fits:
                return False
            stand = min(fits, key=lambda x: ((x.width or 0) * (x.length or 0), x.slot_name))
            try:
                g = m.flight_group_from_airport(cjtf[side], f"{side.upper()} {name} {t}", types[t], ap,
                                                start_type=StartType.Cold, group_size=1, parking_slots=[stand])
                g.set_client()
                used[ap.id] = used.get(ap.id, 0) + 1
                report[side].append(f"{t} @ {name}")
                return True
            except Exception:  # usually: no free parking for this type here
                return False

        for t in wanted:
            if t not in types:
                continue
            if not any(place(t, name, ap) for _, name, ap in ordered) and \
               not any(place(t, name, ap, capped=False) for _, name, ap in ordered):
                print(f"  no fixed slot for {t} ({side}): no parking left - dynamic spawn only")

    # AI aircraft templates (phase 3): late-activated, never fly themselves.
    # The engine clones them for CAP, CAS and intercept sorties.
    templates = build_ai_templates(m, catalog, cjtf, theater)
    print(f"  AI templates: {', '.join(templates)}")

    # FARPs players can build at towns, and ships (carrier in the Gulf).
    farps = build_farps(m, theater, catalog, cjtf, armoury)
    naval = build_naval(m, theater, cjtf, types)
    print(f"  FARP sites: {farps}  naval slots: {len(naval)}")

    # The single trigger: load the campaign engine.
    if not os.path.exists(bundle):
        sys.exit(f"{bundle} not found - run tools/build_bundle.py first")
    trig = TriggerStart(comment="DCC start")
    ctld_lua = os.path.join(CTLD_DIR, "CTLD.lua")
    if use_ctld and os.path.exists(ctld_lua):
        # CTLD loads first but does not start: the engine sets it up for the war, then starts it.
        # (a script file, not DO SCRIPT text: DCS ran the text's dictionary key instead of the text)
        trig.add_action(DoScriptFile(m.map_resource.add_resource_file(os.path.join(SCRIPTS_DIR, "dcc_ctld_wait.lua"))))
        trig.add_action(DoScriptFile(m.map_resource.add_resource_file(ctld_lua)))
        for snd in ("beacon.ogg", "beaconsilent.ogg"):      # CTLD radio beacons
            if os.path.exists(os.path.join(CTLD_DIR, snd)):
                m.map_resource.add_resource_file(os.path.join(CTLD_DIR, snd))
        print("  CTLD: included")
    if armoury == "takeoff":
        trig.add_action(DoScriptFile(m.map_resource.add_resource_file(os.path.join(SCRIPTS_DIR, "dcc_armoury_takeoff.lua"))))
    if test:
        # test mission: its own saves, no rotation, F10 > Armoury test
        trig.add_action(DoScriptFile(m.map_resource.add_resource_file(os.path.join(SCRIPTS_DIR, "dcc_test_mode.lua"))))
        print("  TEST MISSION (own saves, F10 > Armoury test)")
    print(f"  armoury: {armoury}")
    key = m.map_resource.add_resource_file(bundle)
    trig.add_action(DoScriptFile(key))
    m.triggerrules.triggers.append(trig)

    # Map rotation without hooks: 2 min after a win the engine sets flag 9901;
    # this ends the mission and the server loads the next mission in its list.
    end = TriggerOnce(comment="DCC war over - next map")
    end.add_condition(FlagEquals(9901, 1))
    end.add_action(EndMission(text=m.string("The war is over - loading the next map.")))
    m.triggerrules.triggers.append(end)

    # Options.
    # F10 view "Fog of war" (optview_allies): own units, plus enemy units only while a
    # friendly unit can see them. The campaign's intel layer (dcc_dcs_intel.lua) adds
    # the last-known enemy positions on top. ("Allies only" = optview_onlyallies.)
    m.forced_options.options_view = ForcedOptions.Views.Allies
    m.forced_options.civil_traffic = ForcedOptions.CivilTraffic.Off
    m.forced_options.unrestricted_satnav = True    # v0.43: GPS for both sides (RED too: JF-17 GPS bombs, EGI)

    # Combined Arms slots (v0.27): per side 2 tactical commanders, 2 JTACs and
    # 2 observers. The campaign's own platoons, convoys, artillery and skirmish
    # groups are spawned player-drivable (config ext4.ca). Needs the CA module.
    gc = m.groundControl
    for side in ("blue", "red"):
        setattr(gc, f"{side}_tactical_commander", CA_SLOTS["commander"])
        setattr(gc, f"{side}_jtac", CA_SLOTS["jtac"])
        setattr(gc, f"{side}_observer", CA_SLOTS["observer"])
    gc.pilot_can_control_vehicles = False
    m.set_description_text(
        "Danica Dynamic Campaign - persistent war on " + theater_name + ".\n"
        "Fly from any airbase your side owns (multiplayer: dynamic spawn) or from the fixed depot slots.\n"
        "F10 > Other > Campaign > Campaign status for the situation.")

    set_ai_skill(m)
    fix_radio_frequencies(m)
    assign_datalinks(m)
    dtc_files = build_dtcs(m, theater, theater_name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    m.save(out)
    # kneeboard pages: comms, map, quick reference (tools/kneeboard.py)
    airports = []
    for node in theater["nodes"]:
        if node.get("kind") == "airbase" and node.get("airbase"):
            ap = find_airport(m.terrain, node["airbase"])
            airports.append((node["name"], node["side"], getattr(ap, "atc_radio", None) if ap else None))
    tankers = [("blue", "KC-135MPRS (BLUE tanker)    TACAN 51X TKR   boom"),
               ("red", "IL-78M (RED tanker)         TACAN 52X TKS   drogue")]
    if any(s.get("side") == "blue" and s.get("kind") == "carrier" and s.get("ship") != "LHA_Tarawa"
           for s in theater.get("naval", []) or []):
        tankers.append(("blue", "S-3B (carrier recovery)     TACAN 76X SHL   drogue"))
    knee_files = kneeboard.build(theater, theater_name, airports, tankers)
    with zipfile.ZipFile(out, "a", compression=zipfile.ZIP_DEFLATED) as z:
        for path, text in dtc_files.items():
            z.writestr(path, text)
        for path, data in knee_files.items():
            z.writestr(path, data)
    print(f"  kneeboard: {len(knee_files)} pages")

    print(f"Wrote {out}")
    for side in ("blue", "red"):
        print(f"  {side.upper()}: {len(report[side])} fixed client slots")
    if missing_airports:
        print("  airbases not found in pydcs terrain: " + ", ".join(missing_airports))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--theater", default="Caucasus")
    ap.add_argument("--era", default="modern")
    ap.add_argument("--bundle", default=os.path.join(ROOT, "dist", "dcc_bundle.lua"))
    ap.add_argument("--out", default=None)
    ap.add_argument("--no-ctld", action="store_true", help="leave CTLD out of the mission")
    ap.add_argument("--armoury", choices=["takeoff", "warehouse"], default="warehouse",
                    help="warehouse (default): limited munitions, shelves stocked by base supply; "
                         "takeoff: unlimited munitions, recall at take-off")
    ap.add_argument("--no-mods", action="store_true",
                    help="leave the community mod aircraft (A-4E-C, UH-60L) out")
    ap.add_argument("--test", action="store_true",
                    help="armoury test mission: own saves (DCC_test), no rotation, F10 > Armoury test")
    a = ap.parse_args()
    global WITH_MODS
    WITH_MODS = not a.no_mods
    suffix = "_ArmouryTest" if a.test else ""
    out = a.out or os.path.join(ROOT, "dist", f"DCC_{a.theater}{suffix}.miz")
    build(a.theater, a.era, out, a.bundle, use_ctld=not a.no_ctld, armoury=a.armoury, test=a.test)


if __name__ == "__main__":
    main()
