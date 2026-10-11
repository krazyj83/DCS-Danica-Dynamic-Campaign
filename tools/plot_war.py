#!/usr/bin/env python3
"""Plot a simulated war: four map snapshots plus territory over time.

    python tools/run_lua.py tools/sim.lua 15000 2026 docs/sim_history.json
    python tools/plot_war.py docs/sim_history.json docs/sim_war.png
"""
import json
import math
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

BLUE = "#2f6fdb"
RED = "#d6453d"
INK = "#2b2b2b"
MUTED = "#8a8a8a"
GRID = "#e6e6e6"


def draw_map(ax, hist, snap, title):
    nodes = {n["id"]: n for n in hist["nodes"]}
    k = math.cos(math.radians(43))  # keep the map's aspect honest
    owners = snap["owners"]
    for a, b in hist["edges"]:
        na, nb = nodes[a], nodes[b]
        contested = owners[a] != owners[b]
        ax.plot([na["lon"] * k, nb["lon"] * k], [na["lat"], nb["lat"]],
                color="#f2b705" if contested else "#cfcfcf",
                lw=2.4 if contested else 1.0, zorder=1, solid_capstyle="round")
    for nid, n in nodes.items():
        col = BLUE if owners[nid] == "blue" else RED
        size = 30 + 6 * snap["garrisons"][nid]
        ax.scatter(n["lon"] * k, n["lat"], s=size, color=col, zorder=3,
                   marker="s" if n.get("depot") else "o",
                   edgecolors="white", linewidths=1.2)
    ax.set_title(title, fontsize=10, color=INK, loc="left")
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    for s in ax.spines.values():
        s.set_visible(False)


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else "docs/sim_history.json"
    out = sys.argv[2] if len(sys.argv) > 2 else "docs/sim_war.png"
    hist = json.load(open(src))
    snaps = hist["snapshots"]
    minutes = hist.get("tickMinutes", 5)

    def day(s):
        return s["tick"] * minutes / 1440

    picks = [snaps[0], snaps[len(snaps) // 3], snaps[2 * len(snaps) // 3], snaps[-1]]

    fig = plt.figure(figsize=(13, 7.2), dpi=110)
    gs = fig.add_gridspec(2, 4, height_ratios=[0.75, 1], hspace=0.12, wspace=0.05)
    for i, s in enumerate(picks):
        ax = fig.add_subplot(gs[0, i])
        draw_map(ax, hist, s, f"Day {day(s):.1f} - BLUE {s['blueNodes']}, RED {s['redNodes']}")

    ax = fig.add_subplot(gs[1, :])
    days = [day(s) for s in snaps]
    blue = [s["blueNodes"] for s in snaps]
    red = [s["redNodes"] for s in snaps]
    ax.plot(days, blue, color=BLUE, lw=2)
    ax.plot(days, red, color=RED, lw=2)
    ax.text(days[-1], blue[-1], "  BLUE", color=INK, va="center", fontsize=10)
    ax.text(days[-1], red[-1], "  RED", color=INK, va="center", fontsize=10)
    for ev in hist.get("events", []):
        if ev["kind"] == "victory":
            d = ev["tick"] * minutes / 1440
            ax.axvline(d, color=MUTED, lw=1, ls="--")
            ax.text(d, max(blue + red) + 1.5, f"{ev['side'].upper()} wins, day {d:.1f}  ", color=INK, fontsize=9, va="bottom", ha="right")
    ax.set_xlabel("War day (no players online - every battle resolved by dice)", color=INK)
    ax.set_ylabel("Nodes held", color=INK)
    ax.grid(axis="y", color=GRID)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["left"].set_color(MUTED)
    ax.spines["bottom"].set_color(MUTED)
    ax.tick_params(colors=MUTED)
    ax.set_xlim(0, days[-1] * 1.07)

    fig.suptitle(f"Simulated Caucasus war (seed {hist['seed']}), nobody online: the front keeps moving both ways",
                 x=0.02, ha="left", fontsize=13, color=INK, fontweight="bold")
    fig.text(0.02, 0.925, "Circles = towns and airbases, squares = depots, size = garrison. "
             "Yellow roads = the front line.", fontsize=9.5, color=MUTED)
    fig.savefig(out, bbox_inches="tight", facecolor="white")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
