# VEAF CTLD v2 (vendored)

`CTLD.lua` is **CTLD — Combined Transport and Logistics Dispatcher**, version **2.0.0-rc13**,
from <https://github.com/VEAF/CTLD> (tag `published-v2.0.0-rc13`). Originally created by Ciribob,
maintained by Zip and the VEAF team. MIT licence. Credit to them for everything CTLD does.

It is built from CTLD's sources with `tools/build_ctld.py` (the same steps as CTLD's own
`tools/build/merge_CTLD.ps1`: the default `CTLD_config.yaml` embedded as `ctld.configDefault`,
then the files of `tools/build/listToMerge.txt` in order). It is **not modified**: the campaign
changes its settings and wraps a few of its functions at run time (`src/dcc_dcs_ctld.lua`).

`beacon.ogg` and `beaconsilent.ogg` are CTLD's radio beacon sounds, added to every mission.

To update CTLD:

```bash
git clone https://github.com/VEAF/CTLD /tmp/ctld
git -C /tmp/ctld checkout <tag>
python tools/build_ctld.py /tmp/ctld
python tools/run_lua.py tests/test_ctld.lua      # the integration still holds?
```
