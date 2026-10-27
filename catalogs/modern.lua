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
    -- every flyable type in DCS, any era, by who flew it in real life (WWII Allies BLUE, Axis
    -- and Soviet RED). Types this DCS install does not have are skipped when the mission is built.
    blue = {
      planes      = { "FA-18C_hornet", "F-16C_50", "F-15ESE", "F-15C", "F-14B", "F-14BU", "F-14A-135-GR", "F-14A-135-GR-Early",
                      "F-14A-95-GR", "F-4E-45MC", "A-10C_2", "A-10C", "A-10A", "AV8BNA", "M-2000C", "Mirage-F1EE",
                      "Mirage-F1CE", "Mirage-F1BE", "F-5E-3", "F-5E-3_FC", "AJS37", "F-100D", "F-86F Sabre", "F-86F_FC",
                      "C-101CC", "C-101EB", "MB-339A", "MB-339APAN", "Hawk", "C-130J-30", "Christen Eagle II",
                      "P-51D", "P-51D-30-NA", "TF-51D", "P-47D-30", "P-47D-30bl1", "P-47D-40", "SpitfireLFMkIX",
                      "SpitfireLFMkIXCW", "MosquitoFBMkVI", "F4U-1D",
                      "A-4E-C",                                    -- mod: Community A-4E
                      -- v0.36: eastern types flown by allied air forces (Germany, Poland, Slovakia, Bulgaria,
                      -- Croatia, Pakistan, Georgia, Ukraine ...) - BLUE may fly them too
                      "MiG-29A", "MiG-29S", "MiG-29G", "MiG-29 Fulcrum", "JF-17", "MiG-21Bis", "Su-25", "Su-27",
                      "L-39ZA", "L-39C" },
      helicopters = { "AH-64D_BLK_II", "UH-1H", "OH58D", "CH-47Fbl1", "SA342M", "SA342L", "SA342Mistral",
                      "SA342Minigun", "UH-60L",                    -- mod: UH-60L Black Hawk
                      "Mi-24P", "Mi-8MT" },                        -- v0.36: allied eastern helicopters
    },
    red = {
      planes      = { "Su-27", "Su-33", "MiG-29S", "MiG-29A", "MiG-29G", "MiG-29 Fulcrum", "J-11A", "JF-17",
                      "Su-25T", "Su-25", "MiG-21Bis", "MiG-19P", "MiG-15bis", "MiG-15bis_FC", "L-39ZA", "L-39C",
                      "Yak-52", "Bf-109K-4", "FW-190D9", "FW-190A8", "I-16", "La-7" },
      helicopters = { "Ka-50_3", "Ka-50", "Mi-24P", "Mi-8MT" },
    },
  },

  -- Stock of each player type at an airbase. Depots hold more. The supply
  -- system (phase 2) restocks lost aircraft only while the base is supplied.
  aircraftStock = { airbase = 20, depot = 20 },
  -- Fixed client slots (make_mission.py) take at most this share of an airbase's parking: the rest stays
  -- free for dynamic spawn (v0.37 - a full apron let only one aircraft spawn). These types go first
  -- (DTC cartridges, Link 16 / SADL / IDM datalink are set on fixed slots only).
  fixedSlotShare = 0.25,
  fixedSlotFirst = { "FA-18C_hornet", "F-16C_50", "F-15ESE", "A-10C_2", "AH-64D_BLK_II", "F-14B", "AV8BNA",
                     "Su-27", "MiG-29S", "Ka-50_3", "JF-17" },     -- v0.36: 20 of each type everywhere (was 4 / 8)

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
    ["F-15C"]         = { A2A = true },
    ["F-14A-135-GR"]  = { A2A = true, A2G = true },
    ["A-10C"]         = { A2G = true },
    ["A-10A"]         = { A2G = true },
    ["M-2000C"]       = { A2A = true, A2G = true },
    ["Mirage-F1EE"]   = { A2A = true, A2G = true },
    ["Mirage-F1CE"]   = { A2A = true, A2G = true },
    ["F-5E-3"]        = { A2A = true, A2G = true },
    ["AJS37"]         = { A2G = true },
    ["C-101CC"]       = { A2G = true },
    ["MB-339A"]       = { A2G = true },
    ["Hawk"]          = { A2G = true },
    ["C-130J-30"]     = {},                       -- recon only (it flies CTLD cargo)
    ["SA342L"]        = { A2G = true, HELO = true },
    ["SA342Mistral"]  = { HELO = true },
    ["SA342Minigun"]  = { HELO = true },
    ["MiG-29A"]       = { A2A = true },
    ["MiG-29G"]       = { A2A = true },
    ["MiG-29 Fulcrum"] = { A2A = true, A2G = true },
    ["MiG-19P"]       = { A2A = true },
    ["L-39ZA"]        = { A2G = true },
    ["L-39C"]         = {},
    ["Yak-52"]        = {},
    ["Ka-50"]         = { A2G = true, HELO = true },
    ["F-14BU"]        = { A2A = true, A2G = true },
    ["A-4E-C"]        = { A2A = true, A2G = true },           -- mod
    ["UH-60L"]        = { HELO = true, LIFT = true },         -- mod
    ["F-14A-135-GR-Early"] = { A2A = true, A2G = true },
    ["F-14A-95-GR"]   = { A2A = true, A2G = true },
    ["Mirage-F1BE"]   = { A2A = true, A2G = true },
    ["F-5E-3_FC"]     = { A2A = true, A2G = true },
    ["F-100D"]        = { A2G = true },
    ["F-86F Sabre"]   = { A2A = true, A2G = true },
    ["F-86F_FC"]      = { A2A = true, A2G = true },
    ["C-101EB"]       = {},
    ["MB-339APAN"]    = { A2G = true },
    ["Christen Eagle II"] = {},
    ["P-51D"]         = { A2A = true, A2G = true },
    ["P-51D-30-NA"]   = { A2A = true, A2G = true },
    ["TF-51D"]        = {},
    ["P-47D-30"]      = { A2A = true, A2G = true },
    ["P-47D-30bl1"]   = { A2A = true, A2G = true },
    ["P-47D-40"]      = { A2A = true, A2G = true },
    ["SpitfireLFMkIX"]   = { A2A = true, A2G = true },
    ["SpitfireLFMkIXCW"] = { A2A = true, A2G = true },
    ["MosquitoFBMkVI"] = { A2G = true },
    ["F4U-1D"]        = { A2A = true, A2G = true },
    ["MiG-15bis"]     = { A2A = true },
    ["MiG-15bis_FC"]  = { A2A = true },
    ["Bf-109K-4"]     = { A2A = true },
    ["FW-190D9"]      = { A2A = true, A2G = true },
    ["FW-190A8"]      = { A2A = true, A2G = true },
    ["I-16"]          = { A2A = true },
    ["La-7"]          = { A2A = true },
  },

  -- What a transport helicopter carries: supply crates and troop platoons.
  lift = {
    ["UH-1H"]     = { crates = 1, troops = 1 },
    ["Mi-8MT"]    = { crates = 2, troops = 1 },
    ["Mi-24P"]    = { crates = 0, troops = 1 },
    ["CH-47Fbl1"] = { crates = 4, troops = 2 },
    ["UH-60L"]    = { crates = 1, troops = 1 },
  },

  -- AI aircraft. tools/make_mission.py builds a late-activated template group
  -- for each (2-ship) with this loadout; the engine clones the templates.
  -- loadout = { { weapon name contains, max count }, ... } picked per pylon.
  aiAir = {
    blue = {
      fighter = { type = "F-16C_50", loadout = { { "AIM-120C", 4 }, { "AIM-9X", 2 } } },
      attack  = { type = "A-10C",    loadout = { { "AGM-65D", 2 }, { "Mk-82 - 500lb", 6 }, { "LAU-105 - 2 x AIM-9M", 1 } } },
      awacs   = { type = "E-3A",     loadout = {}, size = 1 },
      sead    = { type = "F-16C_50", loadout = { { "AGM-88C", 2 }, { "AIM-120C", 2 } } },
      tanker  = { type = "KC135MPRS", loadout = {}, size = 1 },   -- drogue: F/A-18, F-14, AV-8B
      drone   = { type = "MQ-9 Reaper", loadout = {}, size = 1 },
      airmobile = { type = "UH-60A", loadout = {}, size = 2, helicopter = true },
      antiship = { type = "FA-18C_hornet", loadout = { { "AGM-84D", 4 }, { "AIM-9X", 2 }, { "AIM-120C", 2 } } },  -- only used against ships
      carriertanker = { type = "S-3B Tanker", loadout = {}, size = 1 },     -- recovery tanker over the carrier
      carriercap = { type = "FA-18C_hornet", loadout = { { "AIM-120C", 4 }, { "AIM-9X", 2 } } },
    },
    red = {
      fighter = { type = "MiG-29S",  loadout = { { "R-77", 4 }, { "R-73", 2 } } },
      attack  = { type = "Su-25",    loadout = { { "S-8KOM", 4 }, { "OFAB-250", 4 }, { "R-60M", 2 } } },
      awacs   = { type = "A-50",     loadout = {}, size = 1 },
      sead    = { type = "Su-24M",   loadout = { { "Kh-31P", 2 }, { "R-60M", 2 } } },
      tanker  = { type = "IL-78M",   loadout = {}, size = 1 },
      drone   = { type = "WingLoong-I", loadout = {}, size = 1 },
      airmobile = { type = "Mi-8MT", loadout = {}, size = 2, helicopter = true },
      antiship = { type = "Su-34",   loadout = { { "Kh-31A", 4 }, { "R-73", 2 } } },  -- only used against ships
      carriercap = { type = "Su-33",  loadout = { { "R-27ER", 4 }, { "R-73", 2 } } },
    },
  },

  -- After phase 5: convoy air-defence escorts (AI adaptation), JTAC vehicles,
  -- FARP ground crew (fuel and ammo trucks so the FARP can rearm and refuel).
  escortAD = { blue = { "M1097 Avenger", "Vulcan" }, red = { "Strela-10M3", "ZSU-23-4 Shilka" } },
  jtac     = { blue = { "Hummer", "M1043 HMMWV Armament" }, red = { "UAZ-469", "Tigr_233036" } },
  artillery = { blue = { "M-109", "M-109", "M 818" }, red = { "SAU Msta", "SAU Msta", "Ural-375" } },
  fortifications = { "Sandbox", "Bunker", "Sandbox" },   -- static types, one per fortification level
  farpCrew = { blue = { "M978 HEMTT Tanker", "M 818", "Hummer" }, red = { "ATZ-10", "Ural-375", "UAZ-469" } },

  -- Early-warning radar sites (phase 5). The first type that exists in this DCS install is used.
  ewr = {
    blue = { "FPS-117", "55G6 EWR" },
    red  = { "1L13 EWR", "55G6 EWR" },
  },

  -- Air-defence site at airbases and depots: radars, launchers, support.
  sam = {
    blue = { radars = { "Hawk sr", "Hawk tr" }, launchers = { "Hawk ln", "Hawk ln", "Hawk ln" },
             support = { "Hawk pcp" }, pointDefence = { "M1097 Avenger", "M1097 Avenger" } },   -- Hawk: fixed; its Avengers move
    red  = { radars = { "SA-11 Buk SR 9S18M1" }, launchers = { "SA-11 Buk LN 9A310M1", "SA-11 Buk LN 9A310M1",
             "SA-11 Buk LN 9A310M1" }, support = { "SA-11 Buk CC 9S470M1" },
             pointDefence = { "Tor 9A331" }, mobile = true },   -- SA-11 shoots and scoots
  },

  -- Armoury (warehouse mode): weapon resource names to try when DCS itself does not list
  -- them (Warehouse.getResourceMap). Best-effort spellings: only names DCS accepts are used,
  -- and F10 > Armoury test in the test mission shows which ones were.
  weapons = {
    names = {
      "weapons.missiles.AIM_120C", "weapons.missiles.AIM_120", "weapons.missiles.AIM_7", "weapons.missiles.AIM_7M",
      "weapons.missiles.AIM_7MH", "weapons.missiles.AIM_7P", "weapons.missiles.AIM_54A_Mk60", "weapons.missiles.AIM_54C_Mk47",
      "weapons.missiles.AIM_9", "weapons.missiles.AIM_9X", "weapons.missiles.AIM_9M", "weapons.missiles.AIM_9P5",
      "weapons.missiles.AIM-9L", "weapons.missiles.R_77", "weapons.missiles.R_27ER", "weapons.missiles.R_27R",
      "weapons.missiles.R_27T", "weapons.missiles.R_27ET", "weapons.missiles.R_73", "weapons.missiles.R_60M",
      "weapons.missiles.R_3S", "weapons.missiles.R_13M", "weapons.missiles.SD-10", "weapons.missiles.PL-5EII",
      "weapons.missiles.PL-8B", "weapons.missiles.AGM_88", "weapons.missiles.AGM_88C", "weapons.missiles.Kh-58U",
      "weapons.missiles.X_58", "weapons.missiles.Kh-25MPU", "weapons.missiles.X_25MP", "weapons.missiles.Kh-31P",
      "weapons.missiles.X_31P", "weapons.missiles.Kh-31A", "weapons.missiles.X_31A", "weapons.missiles.AGM_84D",
      "weapons.missiles.AGM_84E", "weapons.missiles.AGM_84H", "weapons.missiles.AGM_154C", "weapons.missiles.AGM_154A",
      "weapons.missiles.C_802AK", "weapons.missiles.LS_6_500", "weapons.missiles.AGM_65D", "weapons.missiles.AGM_65E",
      "weapons.missiles.AGM_65F", "weapons.missiles.AGM_65G", "weapons.missiles.AGM_65H", "weapons.missiles.AGM_65K",
      "weapons.missiles.AGM_114K", "weapons.missiles.AGM_114L", "weapons.missiles.Vikhr_M", "weapons.missiles.9M127-1",
      "weapons.missiles.X_25ML", "weapons.missiles.Kh-25ML", "weapons.missiles.X_29L", "weapons.missiles.X_29T",
      "weapons.missiles.Kh-29L", "weapons.missiles.Kh-29T", "weapons.missiles.9M114", "weapons.missiles.9M120",
      "weapons.missiles.C_701T", "weapons.missiles.C_705", "weapons.missiles.HOT3", "weapons.missiles.Mistral",
      "weapons.missiles.FIM_92", "weapons.missiles.AGR_20A", "weapons.missiles.AGR_20_M282", "weapons.missiles.AGM_62",
      "weapons.missiles.BK90_MJ1", "weapons.bombs.GBU_10", "weapons.bombs.GBU_12", "weapons.bombs.GBU_16",
      "weapons.bombs.GBU_24", "weapons.bombs.GBU_31", "weapons.bombs.GBU_31_V_3B", "weapons.bombs.GBU_32_V_2B",
      "weapons.bombs.GBU_38", "weapons.bombs.GBU_54_V_1B", "weapons.bombs.KAB_500L", "weapons.bombs.KAB_1500L",
      "weapons.bombs.KAB_500KR", "weapons.bombs.KAB_500S", "weapons.bombs.LS_6", "weapons.bombs.Mk_82",
      "weapons.bombs.Mk_83", "weapons.bombs.Mk_84", "weapons.bombs.Mk_82Y", "weapons.bombs.Mk_82AIR",
      "weapons.bombs.CBU_97", "weapons.bombs.CBU_87", "weapons.bombs.CBU_99", "weapons.bombs.Mk_20",
      "weapons.bombs.FAB_100", "weapons.bombs.FAB_250", "weapons.bombs.FAB_500", "weapons.bombs.FAB_1500",
      "weapons.bombs.RBK_250", "weapons.bombs.RBK_500AO", "weapons.bombs.BetAB_500", "weapons.bombs.OFAB-100-120",
      "weapons.bombs.SAB_100", "weapons.bombs.BDU_50LD", "weapons.bombs.BDU_33", "weapons.nurs.HYDRA_70_M151",
      "weapons.nurs.HYDRA_70_M156", "weapons.nurs.HYDRA_70_M274", "weapons.nurs.HYDRA_70_MK5", "weapons.nurs.Zuni_127",
      "weapons.nurs.S-8KOM", "weapons.nurs.C_8", "weapons.nurs.S-8OFP2", "weapons.nurs.C_8OFP2",
      "weapons.nurs.S-13OF", "weapons.nurs.C_13", "weapons.nurs.S-24B", "weapons.nurs.C_24",
      "weapons.nurs.S-25L", "weapons.nurs.C_25", "weapons.nurs.S_5M", "weapons.nurs.C_5",
      "weapons.droptanks.FuelTank_150L", "weapons.droptanks.FuelTank_350L", "weapons.droptanks.PTB_800_MIG21", "weapons.droptanks.fuel_tank_230",
      "weapons.droptanks.F-16-PTB-N1", "weapons.droptanks.FPU_8A", "weapons.droptanks.PTB-1500", "weapons.droptanks.PTB-800",
      "weapons.droptanks.PTB-1150", "weapons.droptanks.PTB_490C_MIG21", "weapons.droptanks.FT600", "weapons.droptanks.800L",
      "weapons.containers.AN_AAQ_28_LITENING", "weapons.containers.ALQ-184", "weapons.containers.AN_ASQ_228", "weapons.containers.Fantasmagoria",
      "weapons.containers.KINGAL", "weapons.containers.SKY_SHADOW", "weapons.containers.TANGAZH", "weapons.containers.L005",
      "weapons.containers.U22", "weapons.containers.F-15E_AAQ-13_LANTIRN", "weapons.containers.F-15E_AAQ-14_LANTIRN", "weapons.containers.AN_AAQ_33",
      "weapons.containers.WMD7", "weapons.containers.KG-600",
    },
  },

  -- Partisan cells (both sides use the same irregulars; the coalition decides)
  partisans = { units = { "HL_DSHK", "Infantry AK Ins", "Infantry AK Ins", "Infantry AK Ins" },
                fallback = { "Infantry AK", "Infantry AK", "Infantry AK" } },

  -- Industry sites behind the lines (static objects): { type, category } x 3
  industry = {
    factory          = { { "Workshop A", "Fortifications" }, { "Tech combine", "Fortifications" }, { "Workshop A", "Fortifications" } },
    ["power plant"]  = { { "Tech combine", "Fortifications" }, { "Chemical tank A", "Fortifications" }, { "Chemical tank A", "Fortifications" } },
    refinery         = { { "Fuel tank", "Fortifications" }, { "Fuel tank", "Fortifications" }, { "Chemical tank A", "Fortifications" } },
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

  -- Pop-up threats near the front (dcc_ext3.lua) and RED's SCUD launchers.
  popups = {
    manpads = { blue = { "Soldier stinger", "Stinger comm" }, red = { "SA-18 Igla manpad", "SA-18 Igla comm" } },
    shorad  = { blue = { "M1097 Avenger" }, red = { "Strela-10M3" } },
  },
  scud = { "Scud_B", "Ural-375" },

  -- A pilot on the ground waiting for CSAR.
  downedPilot = { blue = "Soldier M4", red = "Infantry AK" },
}
