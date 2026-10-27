#!/usr/bin/env python3
"""Generate a theater pack (theaters/<map>.lua) from a short scenario file.

Why: hand-writing 40 nodes and 70 roads per map is slow and error-prone. A
scenario only says WHICH airbases and towns take part and who owns them at the
start; this tool does the rest:

  * Airbase positions come from pydcs (the same coordinates DCS uses), so the
    engine always snaps to the right airfield, and misspelled names are caught.
  * Roads are generated as a Gabriel graph: two nodes get a road when no third
    node lies inside the circle whose diameter is the line between them. That
    gives short links to real neighbours, no crossing roads, and a connected
    network. Links longer than `maxEdgeKm` are dropped; components are then
    stitched together with their shortest link.
  * Separate landmasses (`group` per node) are only linked by the sea crossings
    you list in `seaEdges` - those are abstract (ferries / landing craft) and
    never spawn ground units.
  * Checks: every node reachable, both sides have a depot, every airbase name
    exists on the map. Writes docs/theater_<map>.png for a visual check.

Scenario files live in tools/scenarios/<map>.py and define SCENARIO (see
syria.py for a commented example).

Usage:
    PYTHONPATH=<pydcs clone> python tools/make_theater.py Syria
    python tools/make_theater.py --all
"""
import argparse
import importlib.util
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCEN_DIR = os.path.join(ROOT, "tools", "scenarios")


def slug(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    return s


def load_scenario(name):
    path = os.path.join(SCEN_DIR, f"{name.lower()}.py")
    if not os.path.exists(path):
        sys.exit(f"no scenario file {path}")
    spec = importlib.util.spec_from_file_location(f"scen_{name}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.SCENARIO


def terrain_for(name):
    import dcs.terrain as t
    return {"Caucasus": t.Caucasus, "Syria": t.Syria, "PersianGulf": t.PersianGulf,
            "GermanyCW": t.Germany}[name]()


def km_between(a, b):
    lat = math.radians((a["lat"] + b["lat"]) / 2)
    dx = (b["lon"] - a["lon"]) * 111.32 * math.cos(lat)
    dy = (b["lat"] - a["lat"]) * 110.57
    return math.hypot(dx, dy)


def gabriel(nodes, max_km):
    """Gabriel graph per group, limited to max_km."""
    edges = set()
    for i, a in enumerate(nodes):
        for j in range(i + 1, len(nodes)):
            b = nodes[j]
            if a["group"] != b["group"]:
                continue
            dab = km_between(a, b)
            if dab > max_km:
                continue
            ok = True
            for c in nodes:
                if c is a or c is b or c["group"] != a["group"]:
                    continue
                if km_between(a, c) ** 2 + km_between(b, c) ** 2 < dab ** 2:
                    ok = False
                    break
            if ok:
                edges.add(tuple(sorted((a["id"], b["id"]))))
    return edges


def components(ids, edges):
    nb = {i: set() for i in ids}
    for a, b in edges:
        nb[a].add(b)
        nb[b].add(a)
    seen, comps = set(), []
    for i in ids:
        if i in seen:
            continue
        stack, comp = [i], set()
        while stack:
            x = stack.pop()
            if x in comp:
                continue
            comp.add(x)
            stack.extend(nb[x] - comp)
        seen |= comp
        comps.append(comp)
    return comps


def stitch(nodes, edges):
    """Join the components of each group with their shortest link."""
    by_id = {n["id"]: n for n in nodes}
    added = []
    for group in sorted({n["group"] for n in nodes}):
        ids = [n["id"] for n in nodes if n["group"] == group]
        while True:
            comps = components(ids, {e for e in edges if e[0] in ids and e[1] in ids})
            if len(comps) <= 1:
                break
            best = None
            for x in comps[0]:
                for other in comps[1:]:
                    for y in other:
                        d = km_between(by_id[x], by_id[y])
                        if best is None or d < best[0]:
                            best = (d, tuple(sorted((x, y))))
            edges.add(best[1])
            added.append(best)
    return added


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def build(name, plot=True):
    sc = load_scenario(name)
    terrain = terrain_for(sc["theater"])
    nodes, problems = [], []

    def add(node):
        if any(n["id"] == node["id"] for n in nodes):
            problems.append(f"duplicate node id {node['id']}")
        nodes.append(node)

    for entry in sc["airbases"]:
        ab, side, opts = entry[0], entry[1], (entry[2] if len(entry) > 2 else {})
        ap = terrain.airports.get(ab)
        if ap is None:
            problems.append(f"airbase '{ab}' not on the {sc['theater']} map")
            continue
        ll = ap.position.latlng()
        add({"id": opts.get("id", slug(ab)), "name": opts.get("name", ab), "kind": "airbase", "side": side,
             "lat": round(ll.lat, 4), "lon": round(ll.lng, 4), "airbase": ab,
             "depot": bool(opts.get("depot")), "ewr": bool(opts.get("ewr")),
             "group": opts.get("group", "main")})
    for entry in sc.get("towns", []):
        tname, side, lat, lon = entry[0], entry[1], entry[2], entry[3]
        opts = entry[4] if len(entry) > 4 else {}
        add({"id": opts.get("id", slug(tname)), "name": tname, "kind": "town", "side": side,
             "lat": lat, "lon": lon, "airbase": None, "depot": bool(opts.get("depot")),
             "ewr": bool(opts.get("ewr")), "group": opts.get("group", "main")})

    ids = {n["id"] for n in nodes}
    edges = gabriel(nodes, sc.get("maxEdgeKm", 150))
    for a, b in sc.get("noEdges", []):
        edges.discard(tuple(sorted((a, b))))
    for a, b in sc.get("extraEdges", []):
        edges.add(tuple(sorted((a, b))))
    stitched = stitch(nodes, edges)
    sea = set()
    for a, b in sc.get("seaEdges", []):
        sea.add(tuple(sorted((a, b))))
    for a, b in list(edges) + list(sea):
        for x in (a, b):
            if x not in ids:
                problems.append(f"edge {a}-{b}: unknown node {x}")

    # checks
    all_edges = edges | sea
    comps = components(sorted(ids), all_edges)
    if len(comps) > 1:
        problems.append(f"network not connected: {[sorted(c) for c in comps]}")
    for side in ("blue", "red"):
        if not any(n["depot"] and n["side"] == side for n in nodes):
            problems.append(f"{side} has no depot")
    front = [e for e in all_edges if next(n for n in nodes if n["id"] == e[0])["side"]
             != next(n for n in nodes if n["id"] == e[1])["side"]]
    if not front:
        problems.append("no front: no road links the two sides")
    if problems:
        for p in problems:
            print("  PROBLEM:", p)
        sys.exit(1)

    # write the pack
    by_id = {n["id"]: n for n in nodes}
    out = []
    out.append("-- " + "=" * 76)
    out.append(f"-- Danica Dynamic Campaign - theater pack: {sc['theater']}")
    out.append("-- " + "-" * 76)
    out.append("-- GENERATED by tools/make_theater.py from tools/scenarios/" + name.lower() + ".py.")
    out.append("-- Edit the scenario and regenerate rather than editing this file.")
    out.append("--")
    for line in sc.get("description", "").strip().splitlines():
        out.append("-- " + line.strip())
    out.append("--")
    out.append(f"-- {len(nodes)} nodes, {len(edges)} roads, {len(sea)} sea crossings, {len(front)} front links.")
    out.append("-- " + "=" * 76)
    out.append("")
    out.append("DCC_THEATERS = DCC_THEATERS or {}")
    out.append("")
    out.append(f"DCC_THEATERS.{sc['theater']} = {{")
    out.append(f"  name    = {lua_str(sc['theater'])},")
    out.append('  era     = "modern",')
    out.append('  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },')
    bal = sc.get("balance", {"blue": 1.0, "red": 1.0})
    out.append(f"  balance = {{ blue = {bal['blue']}, red = {bal['red']} }},")
    if sc.get("main"):
        out.append(f"  main    = {{ blue = {lua_str(sc['main']['blue'])}, red = {lua_str(sc['main']['red'])} }},"
                   "   -- each side's HQ (a depot): the star on the map")
    out.append("")
    out.append("  nodes = {")
    for side in ("blue", "red"):
        out.append(f"    -- ---------------- {side.upper()} ----------------")
        for n in sorted((n for n in nodes if n["side"] == side), key=lambda n: (-n["lat"], n["lon"])):
            parts = [f"id = {lua_str(n['id'])}", f"name = {lua_str(n['name'])}", f"kind = {lua_str(n['kind'])}",
                     f"side = {lua_str(side)}", f"lat = {n['lat']:.4f}", f"lon = {n['lon']:.4f}"]
            if n["airbase"]:
                parts.append(f"airbase = {lua_str(n['airbase'])}")
            if n["depot"]:
                parts.append("depot = true")
            if n["ewr"]:
                parts.append("ewr = true")
            out.append("    { " + ", ".join(parts) + " },")
    out.append("  },")
    out.append("")
    out.append("  edges = {")
    for a, b in sorted(edges):
        out.append(f"    {{ {lua_str(a)}, {lua_str(b)} }},   -- {km_between(by_id[a], by_id[b]):.0f} km")
    for a, b in sorted(sea):
        out.append(f"    {{ {lua_str(a)}, {lua_str(b)}, sea = true }},   -- sea crossing, "
                   f"{km_between(by_id[a], by_id[b]):.0f} km")
    out.append("  },")
    if sc.get("naval"):
        out.append("")
        out.append("  -- Naval groups: placed by tools/make_mission.py (with client slots on carriers);")
        out.append("  -- the engine tracks them and offers ANTISHIP missions against them.")
        out.append("  naval = {")
        for sh in sc["naval"]:
            out.append("    { " + ", ".join([f"id = {lua_str(sh['id'])}", f"side = {lua_str(sh['side'])}",
                f"name = {lua_str(sh['name'])}", f"kind = {lua_str(sh.get('kind', 'carrier'))}",
                f"lat = {sh['lat']:.4f}", f"lon = {sh['lon']:.4f}", f"heading = {sh.get('heading', 0)}",
                f"ship = {lua_str(sh['ship'])}",
                "escorts = { " + ", ".join(lua_str(e) for e in sh.get("escorts", [])) + " }",
                "slots = { " + ", ".join(lua_str(e) for e in sh.get("slots", [])) + " }"]) + " },")
        out.append("  },")
    out.append("}")
    path = os.path.join(ROOT, "theaters", f"{name.lower()}.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"Wrote {path}: {len(nodes)} nodes, {len(edges)} roads, {len(sea)} sea crossings, "
          f"{len(front)} front links" + (f", {len(stitched)} stitched" if stitched else ""))

    if plot:
        try:
            plot_pack(sc["theater"], nodes, edges, sea)
        except ImportError:
            print("  (matplotlib not installed - no picture)")


def plot_pack(name, nodes, edges, sea):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    by_id = {n["id"]: n for n in nodes}
    fig, ax = plt.subplots(figsize=(10, 9))
    col = {"blue": "#2a6fdb", "red": "#d93a2b"}
    for a, b in edges:
        A, B = by_id[a], by_id[b]
        front = A["side"] != B["side"]
        ax.plot([A["lon"], B["lon"]], [A["lat"], B["lat"]], color="#e0b000" if front else "#999999",
                lw=2.5 if front else 1, zorder=1)
    for a, b in sea:
        A, B = by_id[a], by_id[b]
        ax.plot([A["lon"], B["lon"]], [A["lat"], B["lat"]], color="#3fa7c9", lw=1.2, ls="--", zorder=1)
    for n in nodes:
        marker = "s" if n["depot"] else ("^" if n["kind"] == "airbase" else "o")
        ax.scatter(n["lon"], n["lat"], c=col[n["side"]], marker=marker, s=90 if n["depot"] else 45,
                   edgecolors="black", linewidths=0.5, zorder=2)
        ax.annotate(n["name"], (n["lon"], n["lat"]), fontsize=6.5, xytext=(3, 3), textcoords="offset points")
    lat0 = sum(n["lat"] for n in nodes) / len(nodes)
    ax.set_aspect(1 / math.cos(math.radians(lat0)))
    ax.set_title(f"{name} - start of the war (square = depot, triangle = airbase, "
                 "yellow = front, dashed = sea crossing)", fontsize=9)
    ax.grid(alpha=0.2)
    out = os.path.join(ROOT, "docs", f"theater_{name.lower()}.png")
    fig.tight_layout()
    fig.savefig(out, dpi=110)
    plt.close(fig)
    print(f"  picture: {out}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("map", nargs="?")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--no-plot", action="store_true")
    a = ap.parse_args()
    names = [f[:-3] for f in sorted(os.listdir(SCEN_DIR)) if f.endswith(".py")] if a.all else [a.map]
    if not names or names == [None]:
        sys.exit(__doc__)
    for n in names:
        build(n, plot=not a.no_plot)


if __name__ == "__main__":
    main()
