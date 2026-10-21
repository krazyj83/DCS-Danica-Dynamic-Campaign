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
  * FIXED CLIENT SLOTS, one per type (in `fixedSlots`, or every type if unset) at
    each depot while its parking lasts; types that fit at no depot get one at the
    side's next airbase with room. These work in single player too.
  * One trigger: MISSION START -> DO SCRIPT (ctld.dontInitialize = true),
    DO SCRIPT FILE vendor/ctld/CTLD.lua, DO SCRIPT FILE dist/dcc_bundle.lua.
    The engine configures and starts CTLD itself (src/dcc_dcs_ctld.lua).
    --no-ctld leaves CTLD out (the engine's own helicopter Cargo menu is used).
  * Options: F10 map in fog-of-war mode, civil traffic off.
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
    """Two invisible FARPs per town (one per coalition) with dynamic spawn and
    an EMPTY helicopter stock. The engine stocks the owner's FARP once players
    have built it (crates), and empties it when the town is lost."""
    made = 0
    for node in theater["nodes"]:
        if node.get("kind") != "town":
            continue
        base = latlon_point(m, node["lat"], node["lon"])
        for i, side in enumerate(("blue", "red")):
            pos = base.point_from_heading(90 + i * 180, 1500)
            g = m.farp(cjtf[side], f"DCC_FARP_{node['id']}_{side}", pos, hidden=True,
                       farp_type=dunit.InvisibleFARP)
            wh = Warehouse()
            wh.coalition = side.upper()
            wh.dynamic_spawn = True
            wh.allow_hot_start = True
            wh.unlimited_aircrafts = False
            wh.unlimited_munitions = armoury != "warehouse"
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
        far = pos.point_from_heading(sh.get("heading", 0), 80000)
        g.add_waypoint(far, 46)
        if sh.get("kind") == "carrier":
            cv = g.units[0]
            g.points[0].tasks.append(dtask.ActivateBeaconCommand(channel=74, modechannel="X", callsign="STN",
                                                                 bearing=True, unit_id=cv.id, aa=False))
            g.points[0].tasks.append(dtask.ActivateICLSCommand(channel=4, unit_id=cv.id))
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


CTLD_DIR = os.path.join(ROOT, "vendor", "ctld")
SCRIPTS_DIR = os.path.join(ROOT, "tools", "mission_scripts")


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
    return d


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

    # Coalitions: only the two CJTF countries.
    blue, red = Coalition("blue"), Coalition("red")
    cjtf = {"blue": blue.add_country(countries.CombinedJointTaskForcesBlue()),
            "red": red.add_country(countries.CombinedJointTaskForcesRed())}
    blue.bullseye, red.bullseye = m.terrain.bullseye_blue, m.terrain.bullseye_red
    m.coalition = {"blue": blue, "red": red}

    types = type_index()
    air = catalog["aircraft"]
    stock = catalog.get("aircraftStock", {"airbase": 4, "depot": 8})
    fixed = catalog.get("fixedSlots")

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

        bases[side].append((0 if node.get("depot") else 1, node["name"], ap))

    # Fixed client slots: one per type at every depot (as far as its parking goes);
    # a type that fits at no depot gets one at the side's first other airbase with room.
    for side in ("blue", "red"):
        wanted = fixed[side] if fixed else all_types(side)
        depots = sorted([b for b in bases[side] if b[0] == 0], key=lambda b: b[1])
        others = sorted([b for b in bases[side] if b[0] == 1], key=lambda b: b[1])

        def place(t, name, ap):
            try:
                g = m.flight_group_from_airport(cjtf[side], f"{side.upper()} {name} {t}", types[t], ap,
                                                start_type=StartType.Cold, group_size=1)
                g.set_client()
                report[side].append(f"{t} @ {name}")
                return True
            except Exception:  # usually: no free parking for this type here
                return False

        homeless = []
        for t in wanted:
            if t not in types:
                continue
            placed = False
            for _, name, ap in depots:
                placed = place(t, name, ap) or placed
            if not placed:
                homeless.append(t)
        for t in homeless:
            if not any(place(t, name, ap) for _, name, ap in others):
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
    m.set_description_text(
        "Danica Dynamic Campaign - persistent war on " + theater_name + ".\n"
        "Fly from any airbase your side owns (multiplayer: dynamic spawn) or from the fixed depot slots.\n"
        "F10 > Other > Campaign > Campaign status for the situation.")

    fix_radio_frequencies(m)
    dtc_files = build_dtcs(m, theater, theater_name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    m.save(out)
    if dtc_files:
        with zipfile.ZipFile(out, "a", compression=zipfile.ZIP_DEFLATED) as z:
            for path, text in dtc_files.items():
                z.writestr(path, text)

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
