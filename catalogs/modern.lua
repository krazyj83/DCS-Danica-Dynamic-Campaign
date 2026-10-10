-- ============================================================================
-- Danica Dynamic Campaign - era catalog: Modern
-- ----------------------------------------------------------------------------
-- The engine thinks in ROLES ("an armour platoon"), never in unit types.
-- This file maps each role to real DCS type names per side. A new era is a new
-- catalog file with the same role names - no engine change.
--
--   units    : the vehicles one platoon of that role spawns as
--   fallback : base-game types used if a listed type is missing (mods)
--
-- Phase 1 uses ground roles only. Air, logistics and IADS roles arrive in
-- later phases.
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
}
