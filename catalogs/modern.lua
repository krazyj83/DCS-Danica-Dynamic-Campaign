-- ============================================================================
-- Danica Dynamic Campaign - era catalog: Modern
-- ----------------------------------------------------------------------------
-- The engine thinks in ROLES ("an armour platoon"), never in unit types.
-- This file maps each role to real DCS type names per side. A new era is a new
-- catalog file with the same role names - no engine change.
--
--   roles     : ground platoons. units = what one platoon spawns as,
--               fallback = base-game types used if a listed type is missing
--   convoy    : the trucks of one supply convoy (phase 2)
--   transport : AI cargo aircraft for airlifts (phase 2)
--   aircraft  : PLAYER aircraft per side. Used twice:
--                 1. tools/make_mission.py puts these in every airbase
--                    warehouse (dynamic spawn) and as fixed slots at depots
--                 2. the engine stocks each airbase with its OWNER's list and
--                    sets the enemy's types to 0, so slots follow captures
--               Type names are DCS type names (as in the Mission Editor).
--   fixedSlots: which player types also get a fixed client slot at depots
--               (fixed slots work in single player too; dynamic spawn needs
--               multiplayer)
-- ============================================================================

DCC_CATALOGS = DCC_CATALOGS or {}

DCC_CATALOGS.modern = {
  name = "Modern",

  roles = {
    ARMOR_PLT = {
      blue = { units = { "M-1 Abrams", "M-1 Abrams", "M-2 Bradley", "M-2 Bradley" },
               fallback = { "M-60", "M-60", "M-113", "M-113" } },
      red  = { units = { "T-72B", "T-72B", "BMP-2", "BMP-2" },
               fallback = { "T-55", "T-55", "BMP-1", "BMP-1" } },
    },
    MECH_PLT = {
      blue = { units = { "M1126 Stryker ICV", "M1126 Stryker ICV", "Soldier M4", "Soldier M4", "Soldier M249" },
               fallback = { "M-113", "M-113", "Soldier M4", "Soldier M4", "Soldier M4" } },
      red  = { units = { "BTR-80", "BTR-80", "Infantry AK", "Infantry AK", "Infantry AK" },
               fallback = { "BTR-80", "BTR-80", "Infantry AK", "Infantry AK", "Infantry AK" } },
    },
    SHORAD = {
      blue = { units = { "M1097 Avenger", "M1097 Avenger", "M 818" },
               fallback = { "Vulcan", "Vulcan", "M 818" } },
      red  = { units = { "Strela-10M3", "2S6 Tunguska", "Ural-375" },
               fallback = { "ZSU-23-4 Shilka", "ZSU-23-4 Shilka", "Ural-375" } },
    },
  },

  -- Which roles a platoon is drawn from, by job. Weights need not sum to 1.
  mix = {
    garrison = { MECH_PLT = 5, ARMOR_PLT = 3, SHORAD = 2 },
    assault  = { ARMOR_PLT = 6, MECH_PLT = 4 },
  },

  -- Supply convoy: the trucks spawned for one convoy, plus its escort vehicle.
  convoy = {
    blue = { units = { "M1043 HMMWV Armament", "M 818", "M 818", "M 818", "M 818" },
             fallback = { "Hummer", "M 818", "M 818", "M 818", "M 818" } },
    red  = { units = { "BRDM-2", "Ural-375", "Ural-375", "KAMAZ Truck", "KAMAZ Truck" },
             fallback = { "BRDM-2", "Ural-375", "Ural-375", "Ural-375", "Ural-375" } },
  },

  -- AI cargo aircraft for airlifts between friendly airbases.
  transport = {
    blue = { type = "C-130", fallback = "C-130" },
    red  = { type = "IL-76MD", fallback = "An-26B" },
  },

  -- Player aircraft (dynamic spawn stock per airbase, and fixed depot slots).
  aircraft = {
    blue = {
      planes      = { "FA-18C_hornet", "F-16C_50", "F-15ESE", "A-10C_2", "F-14B", "AV8BNA", "F-4E-45MC", "Su-25T" },
      helicopters = { "AH-64D_BLK_II", "UH-1H", "OH58D", "CH-47Fbl1", "SA342M" },
    },
    red = {
      planes      = { "Su-27", "Su-33", "MiG-29S", "J-11A", "JF-17", "Su-25", "Su-25T", "MiG-21Bis" },
      helicopters = { "Ka-50_3", "Mi-24P", "Mi-8MT" },
    },
  },

  -- Stock of each player type at an airbase. Depots hold more. The supply
  -- system (phase 2) restocks lost aircraft only while the base is supplied.
  aircraftStock = { airbase = 4, depot = 8 },

  -- ---------------------------------------------------------------------------
  -- Phase 3
  -- ---------------------------------------------------------------------------
  -- What each player aircraft can do; filters the mission board.
  --   A2A  CAP, escort        A2G  CAS, BAI, strike     SEAD  SEAD/DEAD
  --   HELO helicopter convoy escort                      LIFT  CSAR, logistics
  --   every aircraft can fly RECON
  capabilities = {
    ["FA-18C_hornet"] = { A2A = true, A2G = true, SEAD = true },
    ["F-16C_50"]      = { A2A = true, A2G = true, SEAD = true },
    ["F-15ESE"]       = { A2A = true, A2G = true },
    ["A-10C_2"]       = { A2G = true },
    ["F-14B"]         = { A2A = true, A2G = true },
    ["AV8BNA"]        = { A2G = true },
    ["F-4E-45MC"]     = { A2A = true, A2G = true, SEAD = true },
    ["Su-25T"]        = { A2G = true, SEAD = true },
    ["Su-27"]         = { A2A = true },
    ["Su-33"]         = { A2A = true, A2G = true },
    ["MiG-29S"]       = { A2A = true },
    ["J-11A"]         = { A2A = true, A2G = true },
    ["JF-17"]         = { A2A = true, A2G = true, SEAD = true },
    ["Su-25"]         = { A2G = true },
    ["MiG-21Bis"]     = { A2A = true, A2G = true },
    ["AH-64D_BLK_II"] = { A2G = true, HELO = true },
    ["Ka-50_3"]       = { A2G = true, HELO = true },
    ["Mi-24P"]        = { A2G = true, HELO = true, LIFT = true },
    ["OH58D"]         = { HELO = true },
    ["SA342M"]        = { HELO = true },
    ["UH-1H"]         = { HELO = true, LIFT = true },
    ["Mi-8MT"]        = { HELO = true, LIFT = true },
    ["CH-47Fbl1"]     = { LIFT = true },
  },

  -- What a transport helicopter carries: supply crates and troop platoons.
  lift = {
    ["UH-1H"]     = { crates = 1, troops = 1 },
    ["Mi-8MT"]    = { crates = 2, troops = 1 },
    ["Mi-24P"]    = { crates = 0, troops = 1 },
    ["CH-47Fbl1"] = { crates = 4, troops = 2 },
  },

  -- AI aircraft. tools/make_mission.py builds a late-activated template group
  -- for each (2-ship) with this loadout; the engine clones the templates.
  -- loadout = { { weapon name contains, max count }, ... } picked per pylon.
  aiAir = {
    blue = {
      fighter = { type = "F-16C_50", loadout = { { "AIM-120C", 4 }, { "AIM-9X", 2 } } },
      attack  = { type = "A-10C",    loadout = { { "AGM-65D", 2 }, { "Mk-82 - 500lb", 6 }, { "LAU-105 - 2 x AIM-9M", 1 } } },
    },
    red = {
      fighter = { type = "MiG-29S",  loadout = { { "R-77", 4 }, { "R-73", 2 } } },
      attack  = { type = "Su-25",    loadout = { { "S-8KOM", 4 }, { "OFAB-250", 4 }, { "R-60M", 2 } } },
    },
  },

  -- Air-defence site at airbases and depots: radars, launchers, support.
  sam = {
    blue = { radars = { "Hawk sr", "Hawk tr" }, launchers = { "Hawk ln", "Hawk ln", "Hawk ln" },
             support = { "Hawk pcp" } },
    red  = { radars = { "SA-11 Buk SR 9S18M1" }, launchers = { "SA-11 Buk LN 9A310M1", "SA-11 Buk LN 9A310M1",
             "SA-11 Buk LN 9A310M1" }, support = { "SA-11 Buk CC 9S470M1" } },
  },

  -- Strike targets at depots and airbases (static objects), in build order.
  -- The first is always the fuel store.
  infra = {
    { type = "Fuel tank",          category = "Fortifications" },
    { type = ".Ammunition depot",  category = "Warehouses" },
    { type = "Warehouse",          category = "Warehouses" },
    { type = "Tank",               category = "Warehouses" },
    { type = "Warehouse",          category = "Warehouses" },
    { type = ".Ammunition depot",  category = "Warehouses" },
  },

  -- Ambush team that hits an escorted convoy (helicopter convoy escort).
  ambush = {
    blue = { "M1043 HMMWV Armament", "Soldier M4", "Soldier M4", "Soldier RPG" },
    red  = { "BRDM-2", "Infantry AK", "Infantry AK", "Paratrooper RPG-16" },
  },

  -- A pilot on the ground waiting for CSAR.
  downedPilot = { blue = "Soldier M4", red = "Infantry AK" },
}
