"""Build vendor/ctld/CTLD.lua from a checkout of https://github.com/VEAF/CTLD (MIT).

Same steps as CTLD's own tools/build/merge_CTLD.ps1, in Python, so no PowerShell or
poetry is needed:
  1. wrap src/CTLD_config.yaml verbatim as `ctld.configDefault = [[...]]`
  2. concatenate src/ files in the order of tools/build/listToMerge.txt

    python tools/build_ctld.py <path-to-CTLD-checkout> [out.lua]
"""
import re
import sys
from pathlib import Path


def bracket(text):
    eq = ""
    while f"]{eq}]" in text:
        eq += "="
    return eq


def build(root: Path, out: Path):
    src = root / "src"
    yaml_text = (src / "CTLD_config.yaml").read_text(encoding="utf-8")
    eq = bracket(yaml_text)
    embedded = ("-- GENERATED - verbatim embed of CTLD_config.yaml\nctld = ctld or {}\n"
                f"ctld.configDefault = [{eq}[\n{yaml_text}]{eq}]\n")
    cfg = (src / "CTLD_config.lua").read_text(encoding="utf-8")
    m = re.search(r'ctld\.VERSION\s*=\s*"([^"]+)"', cfg)
    version = m.group(1) if m else "unknown"
    parts = ["--[[\n    CTLD.lua - Combined Transport and Logistics Dispatcher for DCS World\n"
             f"    Version : {version}\n    Source  : https://github.com/VEAF/CTLD\n"
             "    Licence : MIT (see LICENSE next to this file)\n"
             "    Built by tools/build_ctld.py for the Danica Dynamic Campaign. DO NOT EDIT.\n]]\n"]
    n = 0
    for line in (root / "tools/build/listToMerge.txt").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("--"):
            continue
        text = embedded if line == "CTLD_config_default_yaml.lua" else (src / line).read_text(encoding="utf-8")
        parts.append(f"-- {'=' * 100}\n-- Start : {line}\n{text}\n-- End : {line}\n")
        n += 1
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("".join(parts), encoding="utf-8", newline="\n")
    print(f"CTLD {version}: {n} files -> {out} ({out.stat().st_size} bytes)")
    return version


if __name__ == "__main__":
    root = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).resolve().parent.parent / "vendor/ctld/CTLD.lua"
    build(root, out)
