#!/usr/bin/env python3
"""Run a Lua script under Lua 5.1 (the version DCS uses) without DCS.

Uses the `lupa` package (pip install lupa), which bundles Lua 5.1.
The engine's pure modules are loaded first, so test and tool scripts can use
DCC.War, DCC.front, DCC.json and the theater/catalog data directly.

Usage:
    python tools/run_lua.py tests/test_war.lua
    python tools/run_lua.py tools/sim.lua --ticks 2000
"""
import os
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PURE_MODULES = [
    "src/dcc_config.lua",
    "src/dcc_util.lua",
    "src/dcc_json.lua",
    "src/dcc_war.lua",
    "src/dcc_supply.lua",
    "src/dcc_ops.lua",
    "src/dcc_missions.lua",
    "src/dcc_pilots.lua",
    "src/dcc_intel.lua",
    "src/dcc_radar.lua",
    "src/dcc_world.lua",
    "src/dcc_air.lua",
    "src/dcc_ground.lua",
    "src/dcc_front.lua",
    "src/dcc_territory.lua",
    "catalogs/modern.lua",
    "theaters/caucasus.lua",
    "theaters/syria.lua",
    "theaters/persiangulf.lua",
    "theaters/germanycw.lua",
]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    script = sys.argv[1]
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.DCC_ROOT = ROOT
    g.arg = lua.table_from(sys.argv[2:])
    for rel in PURE_MODULES:
        lua.execute(open(os.path.join(ROOT, rel), encoding="utf-8").read())
    lua.execute(open(script, encoding="utf-8").read())
    result = g.DCC_EXIT_CODE
    return int(result) if result is not None else 0


if __name__ == "__main__":
    sys.exit(main())
