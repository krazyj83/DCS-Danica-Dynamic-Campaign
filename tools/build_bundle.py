#!/usr/bin/env python3
"""Concatenate the engine, catalogs and theater packs into one Lua file.

The bundle is what a server mission embeds with its single
MISSION START -> DO SCRIPT FILE trigger. It needs no file access to load
(only to save the war), and every map's theater pack is inside, so the same
bundle works in every mission of the rotation.

Usage:
    python tools/build_bundle.py            -> dist/dcc_bundle.lua
"""
import glob
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ENGINE = [
    "src/dcc_config.lua",
    "src/dcc_util.lua",
    "src/dcc_json.lua",
    "src/dcc_war.lua",
    "src/dcc_supply.lua",
    "src/dcc_ops.lua",
    "src/dcc_missions.lua",
    "src/dcc_pilots.lua",
    "src/dcc_front.lua",
    "src/dcc_persist.lua",
    "src/dcc_dcs.lua",
    "src/dcc_dcs_supply.lua",
    "src/dcc_dcs_ops.lua",
    "src/dcc_main.lua",
]


def main() -> None:
    parts = sorted(glob.glob(os.path.join(ROOT, "catalogs", "*.lua"))) + \
        sorted(glob.glob(os.path.join(ROOT, "theaters", "*.lua")))
    files = [os.path.join(ROOT, f) for f in ENGINE] + parts
    version = "unknown"
    for line in open(os.path.join(ROOT, "src/dcc_config.lua"), encoding="utf-8"):
        if "version" in line and "=" in line:
            version = line.split('"')[1]
            break

    out = [f"-- Danica Dynamic Campaign bundle {version} (generated - edit the sources, not this file)\n"]
    for f in files:
        rel = os.path.relpath(f, ROOT).replace("\\", "/")
        out.append(f"\n-- >>> {rel}\n")
        # Each file runs in its own function scope, like it does with dofile().
        out.append("do\n" + open(f, encoding="utf-8").read() + "\nend\n")
    out.append("\nDCC.start()\n")

    os.makedirs(os.path.join(ROOT, "dist"), exist_ok=True)
    target = os.path.join(ROOT, "dist", "dcc_bundle.lua")
    with open(target, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(out))
    print(f"Wrote {target} ({len(files)} files)")


if __name__ == "__main__":
    main()
