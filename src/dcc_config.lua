-- ============================================================================
-- Danica Dynamic Campaign - configuration
-- ----------------------------------------------------------------------------
-- Every tunable number lives here. Values are starting points for phase 1
-- testing, not balanced results: tune them after watching a few nights of war.
-- ============================================================================

DCC = DCC or {}

DCC.config = {
  version         = "0.7.0",

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

  -- Operations (phase 3): what players can hit or help.
  ops = {
    samAt            = { airbase = true, depot = true }, -- node classes with an air-defence site
    samRepairTicks   = 24,  samRepairCost  = 10,  -- radar knocked out: back after 2 h for 10 SU
    samRebuildTicks  = 72,  samRebuildCost = 60,  -- site destroyed: rebuilt after 6 h for 60 SU
    samLiveRadiusKm  = 80,    -- SAM sites spawn when a player is this close
    infraPerNode     = { airbase = 4, depot = 6 }, -- strike targets per node
    infraSupplyHit   = 25,    -- SU burned with each destroyed building
    infraRepairTicks = 36,  infraRepairCost = 15, -- one building repaired every 3 h
    airPoolStart     = { fighter = 16, attack = 16 },  -- packages, CAPs and escorts all draw on these
    airPoolMax       = { fighter = 24, attack = 24 },
    airPoolRestockTicks = 12, airPoolRestockCost = 10, -- one AI aircraft bought every hour
    airCoverTicks    = 12,    -- CAP gives 1 h of air superiority over its area
    intelFreshTicks  = 72,    -- recon older than 6 h is stale
    convoyAmbushChance = 0.15, convoyAmbushLoss = 0.5, -- unescorted last leg to the front
    csarTimeoutTicks = 24,    -- a downed pilot is captured after 2 h
    crateSU          = 10,    -- supply in one helicopter crate
  },

  -- Mission board (phase 3)
  missions = {
    perType = { CAS = 2, BAI = 3, STRIKE = 2, SEAD = 2, CAP = 1, ESCORT = 2,
                CONVOY = 2, RECON = 2, CSAR = 4, LOGISTICS = 2, EWR = 1, HVAA = 1, ANTISHIP = 1, FARP = 2,
                INTERCEPT = 3, TANKER = 1, ARTY = 2, FORT = 2, BRIDGE = 2 },
    capMinutes      = 20,     -- CAP: time on station that completes the mission
    capRadiusKm     = 40,
    reconRadiusKm   = 8,      -- recon: overfly within this distance...
    reconMaxAglM    = 4500,   -- ...below this height
    escortRadiusKm  = 15,     -- escort: stay this close to the transport...
    convoyEscortKm  = 3,      -- ...or the convoy (helicopters)
    escortShare     = 0.5,    -- ...for at least this share of the time
  },

  pilotsFile = "pilots.json", -- persistent pilot records (kept across maps)

  -- Intel and fog of war (phase 4)
  intel = {
    enabled        = true,   -- missions and map use only what each side has detected
    staleTicks     = 6,      -- contacts older than 30 min are drawn faded and cannot be tasked
    expireTicks    = 36,     -- contacts older than 3 h are forgotten
    groundObsKm    = 8,      -- every base sees enemy columns on its roads this close (troops in contact)
    visualKmAir    = 10,     -- players see aircraft this far (with line of sight)...
    visualKmGround = 6,      -- ...and ground units this far
    elintKm        = 110,    -- airborne aircraft hear an emitting radar this far
    elintMinAglM   = 800,    -- ...when at least this high
    elintBaseErrM  = 6000,   -- first ELINT fix is this rough...
    elintMinErrM   = 300,    -- ...and narrows with every observation down to this
    samWakeKm      = 60,     -- SAM radars switch on when enemy aircraft are this close
    harmDarkSeconds = { 60, 120 }, -- a SAM goes dark this long when an anti-radiation missile is fired at it
    drawEverySeconds = 60,   -- the intel map layer is redrawn this often
    scanSeconds    = 10,     -- how often players, AI sensors and ELINT are checked
    airContactSeconds = 120, -- enemy aircraft stay on the map this long after the last sighting
    elintShrink    = 0.6,    -- each new ELINT observation multiplies the error by this
  },

  -- Radar stations and AWACS (phase 5)
  radar = {
    ewrAt            = { depot = true }, -- node classes with an early-warning radar (packs can add ewr = true)
    ewrRebuildTicks  = 72,  ewrRebuildCost = 40,  -- destroyed: back after 6 h for 40 SU
    ewrKm            = 180,   -- EWR range...
    ewrAntennaM      = 25,    -- ...and antenna height (sets the radar horizon: low flyers hide)
    ewrElintKm       = 200,   -- an EWR always transmits: enemy aircraft hear it this far
    awacsKm          = 350,   -- AWACS range (radar horizon from awacsAltM)
    awacsAltM        = 9000,
    awacsStandoffKm  = 120,   -- orbit this far behind the own front
    awacsLifeSeconds = 14400, -- on station 4 h, then a relief takes over
    awacsPoolStart   = 2,  awacsPoolMax = 2,
    awacsRestockTicks = 72, awacsRestockCost = 40,  -- one AWACS bought every 6 h at most
  },

  -- Weather, night, AI adaptation, FARPs, ships, JTAC, public feed (after phase 5)
  world = {
    weatherTicks   = 72,      -- the weather may change every 6 h
    speedFactor    = { rain = 0.8, storm = 0.6 },      -- ground columns
    battleFactor   = { rain = 0.85, storm = 0.7 },     -- dice battles bleed slower
    visualFactor   = { overcast = 0.9, rain = 0.6, storm = 0.4 },
    nightVisual    = 0.5,     -- eyes at night (NVGs help, but not that much)
    nightStartHour = 20,  nightEndHour = 6,             -- mission clock
    fog            = { rain = { 4000, 400 }, storm = { 1500, 900 } },  -- DCS fog: visibility m, thickness m
    escortThreat   = 2,       -- road threat that gets convoys an air-defence escort
    rerouteThreat  = 2,       -- ...and makes the AI prefer another road
    reroutePenalty = 400,     -- (planning cost per threat point; one step nearer the front = 1000)
    capThreat      = 3,       -- ...and gets AI CAP over it
    threatDecayTicks = 36,    -- threat halves every 3 h
    farpBuildSU    = 30,      -- crates (10 SU each) to turn a town into a FARP
    farpHelos      = 2,       -- helicopters of each own type a FARP can spawn
    antishipChance = 0.4,     -- chance per hour of an AI strike on a known enemy ship
  },
  jtac = { laserCode = 1688, searchKm = 6, standoffKm = 4 },

  -- Air war additions
  air = {
    assetPoolStart    = { tanker = 2, drone = 2 },
    assetPoolMax      = { tanker = 2, drone = 3 },
    assetRestockTicks = { tanker = 72, drone = 24 },   -- one bought every 6 h / 2 h at most
    assetRestockCost  = { tanker = 30, drone = 10 },
    packageMinutes    = 45,     -- each side launches a strike package about this often (players online)
    airAssaultMinutes = 75,     -- ...and an AI helicopter assault about this often
    airAssaultKm      = 70,     -- helicopter assault range
    airAssaultMaxDefenders = 2, -- only bases this weak are targets
    forwardCap        = true,   -- CAP over the own base the enemy is about to attack
    creditOnLanding   = true,   -- mission points count once the pilot lands at a friendly base
    cooldownDeaths    = 2,      -- pilot deaths...
    cooldownWindowMin = 60,     -- ...within this many minutes...
    cooldownMin       = 15,     -- ...ground the pilot from fast jets this long (helicopters still OK)
    samCueKm          = 25,     -- a SAM without radar cueing (EWR/AWACS) only wakes up this close
  },

  -- Ground war additions
  ground = {
    batteries      = 2,      -- artillery batteries per side
    artyFactor     = 1.3,    -- a supporting battery makes the enemy lose 30 % more per round
    batteryRebuildTicks = 72, batteryRebuildCost = 30,
    fortMax = 3, fortTicks = 72, fortCost = 10, fortBonus = 0.1,  -- dig in: +10 % per level every 6 h
    moraleNoSupply = 0.7, moraleCutOff = 0.8, surrenderAt = 2,
    bridgeTicks    = 72,     -- a destroyed bridge closes its road for 6 h
    skirmishes     = true,   -- small fights always running on the front (for CAS)
    skirmishPerSide = 2,     -- vehicles per side per skirmish
    skirmishMax    = 8,      -- most skirmishes at once
  },
  public = { events = 40, everySeconds = 60 },   -- DCC\public.json for the web map / Discord

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
  victoryMinSorties = 3,    -- victory bonus needs this many sorties for the winner (or one completed mission)
  warClockDays     = 7,
  warClockDaysNoSave = 1,   -- on a server that cannot save (io/lfs off) a war lasts this long instead
  endMissionFlag   = 9901,  -- set 2 min after a win: the mission's END MISSION trigger fires and the
                            -- server loads the next mission in its list (map rotation without hooks)     -- a war ends after this many days of server time; most ground gained wins (0 = off)
  campaignOverFlag = 9900,  -- user flag set to 1 when a war ends (DCSServerBot watches it)
  rotation         = { "Caucasus", "Syria", "PersianGulf", "GermanyCW" }, -- fixed map order
  rotationEnforce  = true,  -- a mission for the wrong map waits for the hook instead of starting a war
                            -- (delete Saved Games\DCS\DCC\rotation.json to pick a map by hand)

  -- Territory and front line (Voronoi cells around every base)
  territory = {
    reachKm   = 75,     -- a base claims ground at most this far (keeps territory off open sea)
    capSides  = 24,     -- polygon used for that limit
    fillAlpha = 0.12,   -- territory shading on the F10 map
    lineWidth = 3,      -- front line thickness style
  },

  -- Drawing (F10 map) -----------------------------------------------------------
  markIdBase       = 7000000,  -- F10 mark ids used by the engine start here
  colours = {
    blue  = { 0.15, 0.45, 1.00, 1.0 },
    red   = { 1.00, 0.20, 0.15, 1.0 },
    front = { 1.00, 0.85, 0.10, 1.0 },
  },

  debug = false,
}
