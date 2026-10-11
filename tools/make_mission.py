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
  * FIXED CLIENT SLOTS at each side's depots (one per type in `fixedSlots`,
    or every type if unset). These work in single player too.
  * One trigger: MISSION START -> DO SCRIPT FILE dist/dcc_bundle.lua.
  * Options: F10 map in fog-of-war mode, civil traffic off.

Needs pydcs:  pip install git+https://github.com/pydcs/dcs.git
              (or clone it and set PYTHONPATH to the clone)

Usage:
    python tools/build_bundle.py
    python tools/make_mission.py                 -> dist/DCC_Caucasus.miz
    python tools/make_mission.py --theater Caucasus --era modern --out my.miz
"""
import argparse
import os
import sys

from lupa import lua51

import dcs
from dcs import countries, helicopters, planes
from dcs.action import DoScriptFile
from dcs.coalition import Coalition
from dcs.forcedoptions import ForcedOptions
from dcs.mission import StartType
from dcs.triggers import TriggerStart

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


def build(theater_name, era, out, bundle):
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
        ap.unlimited_munitions = True
        ap.unlimited_fuel = True
        own = stock["depot"] if node.get("depot") else stock["airbase"]
        warehouse = {"planes": {}, "helicopters": {}}
        for s in ("blue", "red"):
            n = own if s == side else 1
            for kind in ("planes", "helicopters"):
                for t in air[s].get(kind, []):
                    warehouse[kind][t] = {"initialAmount": max(n, warehouse[kind].get(t, {}).get("initialAmount", 0))}
        ap.aircrafts = warehouse

        # Fixed client slots at depots.
        if node.get("depot"):
            wanted = fixed[side] if fixed else all_types(side)
            for t in wanted:
                cls = types.get(t)
                if cls is None:
                    continue
                gname = f"{side.upper()} {node['name']} {t}"
                try:
                    g = m.flight_group_from_airport(cjtf[side], gname, cls, ap,
                                                    start_type=StartType.Cold, group_size=1)
                    g.set_client()
                    report[side].append(f"{t} @ {node['name']}")
                except Exception as exc:  # usually: no free parking for this type
                    print(f"  no slot for {t} at {node['name']}: {exc}")

    # AI aircraft templates (phase 3): late-activated, never fly themselves.
    # The engine clones them for CAP, CAS and intercept sorties.
    templates = build_ai_templates(m, catalog, cjtf, theater)
    print(f"  AI templates: {', '.join(templates)}")

    # The single trigger: load the campaign engine.
    if not os.path.exists(bundle):
        sys.exit(f"{bundle} not found - run tools/build_bundle.py first")
    key = m.map_resource.add_resource_file(bundle)
    trig = TriggerStart(comment="DCC start")
    trig.add_action(DoScriptFile(key))
    m.triggerrules.triggers.append(trig)

    # Options.
    # "Allies only": the F10 map shows own units only; enemies appear only through the
    # campaign's intel layer (dcc_dcs_intel.lua), which draws what each side has detected.
    m.forced_options.options_view = ForcedOptions.Views.OnlyAllies
    m.forced_options.civil_traffic = ForcedOptions.CivilTraffic.Off
    m.set_description_text(
        "Danica Dynamic Campaign - persistent war on " + theater_name + ".\n"
        "Fly from any airbase your side owns (multiplayer: dynamic spawn) or from the fixed depot slots.\n"
        "F10 > Other > Campaign > Campaign status for the situation.")

    os.makedirs(os.path.dirname(out), exist_ok=True)
    m.save(out)

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
    a = ap.parse_args()
    out = a.out or os.path.join(ROOT, "dist", f"DCC_{a.theater}.miz")
    build(a.theater, a.era, out, a.bundle)


if __name__ == "__main__":
    main()
