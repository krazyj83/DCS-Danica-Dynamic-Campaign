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
}
