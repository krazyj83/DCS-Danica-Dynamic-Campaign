"""pydcs types for community mods that pydcs does not know.

Only what tools/make_mission.py needs: the DCS type name, size (parking), fuel
and the default radio. Every server and player needs the mod installed:
    A-4E-C  - Community A-4E Skyhawk  (https://github.com/Community-A-4E/community-a4e-c)
    UH-60L  - UH-60L Black Hawk by Kinkkujuustovoileipa
            (https://github.com/Kinkkujuustovoileipa/uh-60l)
"""
from dcs import task
from dcs.helicopters import HelicopterType
from dcs.planes import PlaneType


class A_4E_C(PlaneType):
    id = "A-4E-C"
    flyable = True
    height = 4.57
    width = 8.38
    length = 12.22
    fuel_max = 2467
    max_speed = 1083.6
    chaff = 30
    flare = 30
    charge_total = 60
    chaff_charge_size = 1
    flare_charge_size = 1
    radio_frequency = 251
    pylons = set()
    tasks = [task.CAS, task.CAP, task.GroundAttack]
    task_default = task.CAS
    name = "A-4E-C"


class UH_60L(HelicopterType):
    id = "UH-60L"
    flyable = True
    height = 5.13
    width = 16.36
    length = 19.76
    fuel_max = 1362
    max_speed = 296
    radio_frequency = 251
    pylons = set()
    tasks = [task.Transport]
    task_default = task.Transport
    name = "UH-60L"


MOD_TYPES = [A_4E_C, UH_60L]
