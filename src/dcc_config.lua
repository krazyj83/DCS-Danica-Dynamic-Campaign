-- ============================================================================
-- Danica Dynamic Campaign - configuration
-- ----------------------------------------------------------------------------
-- Every tunable number lives here. Values are starting points for phase 1
-- testing, not balanced results: tune them after watching a few nights of war.
-- ============================================================================

DCC = DCC or {}

DCC.config = {
  version         = "0.2.0-phase2",

  -- Which theater pack and era catalog to run. "auto" picks the theater from
  -- env.mission.theatre (the map the mission was built on).
  theater         = "auto",
  era             = "modern",

  -- Time ------------------------------------------------------------------
  tickSeconds      = 300,   -- one war step = 5 minutes of mission time
  liveCheckSeconds = 30,    -- how often live (spawned) units are polled

  -- Movement ----------------------------------------------------------------
  groundSpeedKmh   = 30,    -- average road speed for abstract (unspawned) moves
  liveSpeedMps     = 12,    -- speed ordered to spawned assault groups (~43 km/h)

  -- Forces (counted in platoons; one platoon = one DCS group of 3-5 vehicles)
  garrisonStart    = { airbase = 4, town = 3, depot = 6 },
  garrisonMax      = { airbase = 8, town = 6, depot = 12 },
  depotProductionEveryTicks = 3,   -- base: each depot adds 1 platoon per 3 ticks (15 min)
  productionPerNode   = 0.08,      -- +8 % production per node gained since the start (-8 % per node lost)
  productionMinFactor = 0.5,
  productionMaxFactor = 2.0,
  frontKeep        = 2,     -- platoons a front node keeps when it attacks
  frontStaging     = 3,     -- extra platoons a front node may hold beyond its max
  stagingCapFactor = 3,     -- nodes facing the main effort may hold max x this
  focusTicks       = 144,   -- re-pick the main effort after 12 h without a capture
  focusPatienceTicks = 36,  -- after 3 h building up, the main effort attacks at stalled odds
  rearKeep         = 1,     -- platoons a rear node keeps when it reinforces
  reinforceColumnMax = 3,   -- most platoons one node sends per tick
  assaultMin       = 3,     -- smallest assault worth launching
  assaultMax       = 12,    -- largest assault one node can send
  assaultOdds      = 1.15,  -- attack power must beat defence power x this
  assaultOddsStalled = 0.6, -- main effort attacks at these odds once staging is full or patience runs out

  -- Combat (abstract resolution, used when no player is near) ---------------
  defenderBonus    = { airbase = 1.5, town = 1.3, depot = 2.0 },
  battleLossRate   = 0.15,  -- share of enemy power taken as damage per tick
  destroyedBelow   = 0.25,  -- platoon health below this = platoon destroyed

  -- Supply (phase 2). One supply unit (SU) = fuel, ammo and spares together.
  supply = {
    cap              = { town = 60, airbase = 80, depot = 300 }, -- normal stock limit per node
    overfillFactor   = 2.5,   -- deliveries may fill a node up to cap x this (staging areas)
    startFraction    = 0.5,   -- every node starts half full
    depotPerTick     = 6,     -- SU a depot produces per tick (x the same factor as platoons)
    upkeepPerPlatoon = 0.05,  -- SU each platoon uses per tick (an 18-platoon town: ~11 SU/h)
    outOfSupplyAttrition = 0.005, -- health lost per tick at 0 supply (~12 h to collapse)
    assaultCostPerPlatoon = 2, -- SU paid at the start node for each attacking platoon
    assaultCarryShare = 0.5,  -- share of that cost the attackers carry into a captured node
    keepHours        = 3,     -- every node wants at least this many hours of upkeep in stock
    stagingFactor    = 2,     -- nodes facing the main effort want cap x this
    depotReserve     = 40,    -- SU a depot keeps before sending convoys
    rearKeep         = 10,    -- SU a rear node keeps before passing supply on
    convoyCapacity   = 30,    -- SU per truck convoy
    convoyMin        = 8,     -- smallest load worth sending
    convoysPerNode   = 3,     -- convoys a node may have on the road at once
    airliftCapacity  = 30,    -- SU per airlift
    airliftSpeedKmh  = 350,
    airliftMinKm     = 80,    -- airlifts only for longer hops (or cut-off airbases)
    maxAirlifts      = 2,     -- per side at once
    captureShare     = 0.5,   -- share of a captured node's stores the attacker keeps
    airRestockTicks  = 12,    -- every hour each airbase may replace one lost aircraft...
    airRestockCost   = 5,     -- ...for this much supply
  },

  -- Live bubble (what gets spawned as real DCS units) -----------------------
  liveRadiusKm     = 40,    -- nodes within this distance of a player are live
  maxLivePlatoons  = 120,   -- hard cap on spawned platoons (~500 vehicles)
  liveHysteresisKm = 10,    -- a live node stays live until players are this much further out
  liveStallTicks   = 6,     -- a live battle with no progress gets one dice round every 30 min
  captureRadiusKm  = 3,     -- attackers must be this close to take a node
  spawnSpreadM     = 1200,  -- garrison platoons are scattered within this radius

  -- Persistence ---------------------------------------------------------------
  saveFolder       = "DCC", -- under Saved Games\DCS\ (lfs.writedir())
  saveSlots        = 24,    -- rotating backups kept
  campaignOverFlag = 9900,  -- user flag set to 1 when a war ends (DCSServerBot watches it)
  rotation         = { "Caucasus", "Syria", "PersianGulf", "GermanyCW" }, -- fixed map order

  -- Drawing (F10 map) -----------------------------------------------------------
  markIdBase       = 7000000,  -- F10 mark ids used by the engine start here
  colours = {
    blue  = { 0.15, 0.45, 1.00, 1.0 },
    red   = { 1.00, 0.20, 0.15, 1.0 },
    front = { 1.00, 0.85, 0.10, 1.0 },
  },

  debug = false,
}
