-- ============================================================================
-- Danica Dynamic Campaign - configuration
-- ----------------------------------------------------------------------------
-- Every tunable number lives here. Values are starting points for phase 1
-- testing, not balanced results: tune them after watching a few nights of war.
-- ============================================================================

DCC = DCC or {}

DCC.config = {
  version         = "0.65.0",

  -- Which theater pack and era catalog to run. "auto" picks the theater from
  -- env.mission.theatre (the map the mission was built on).
  theater         = "auto",
  era             = "modern",

  -- Time ------------------------------------------------------------------
  tickSeconds      = 300,   -- one war step = 5 minutes of mission time
  liveCheckSeconds = 30,    -- how often live (spawned) units are polled
  messageSeconds   = 10,    -- every message stays on screen at least this long (CTLD's too)

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
    startFraction    = 0.5,   -- every node starts half full ...
    startSU          = 50,    -- ... but with at least this much (v0.38: 50 SU at every base; depots 150)
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
    heliliftCapacity = 10,    -- SU per helicopter supply run (real AI helicopters, escortable)
    heliliftSpeedKmh = 200,
    heliliftMinKm    = 15,    -- short hops to the front, towns included
    heliliftMaxKm    = 120,
    maxHelilifts     = 1,     -- per side at once
    heliliftEveryTicks = 24,  -- at most one run to the same base every 2 h
                              -- ...and only for bases cut off or behind a road under attack
    heliCargoMinutes = 15,    -- the crates a supply helicopter sets down stay on the ground this long
    captureShare     = 0.5,   -- share of a captured node's stores the attacker keeps
    airRestockTicks  = 12,    -- every hour each airbase may replace one lost aircraft...
    airRestockCost   = 5,     -- ...for this much supply
    airMinStock      = 2,     -- v0.38: never fewer than this of any own type at an own airbase (free)
  },

  -- Operations (phase 3): what players can hit or help.
  ops = {
    samAt            = { airbase = true, depot = true }, -- node classes with an air-defence site
    samRepairTicks   = 48,  samRepairCost  = 10,  -- radar knocked out: back after 4 h for 10 SU (v0.62: was 2 h)
    samRebuildTicks  = 96,  samRebuildCost = 60,  -- site destroyed: rebuilt after 8 h for 60 SU (v0.62: was 6 h)
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
    perType = { CAS = 2, BAI = 3, STRIKE = 2, SEAD = 2, CAP = 1, ESCORT = 3,
                CONVOY = 2, RECON = 2, CSAR = 4, LOGISTICS = 2, EWR = 1, HVAA = 1, ANTISHIP = 1, FARP = 2,
                FARPSUP = 2, INTERCEPT = 3, HVAESCORT = 2, PKGESCORT = 2, MEDEVAC = 2, POW = 2,
                AMPHIB = 1, SHIPSTRIKE = 2, SHIPESCORT = 2, SCUD = 2, POPUP = 3, TANKER = 1, ARTY = 2, FORT = 2, BRIDGE = 2,
                RUNWAY = 1, SNATCH = 2, INDUSTRY = 1, COIN = 2,
                ASSAULT = 4, HOLD = 4, GCONVOY = 3, MINESWEEP = 2, MINELAYER = 2, AIRASSAULT = 2 },   -- ground missions (CA players), mine sweeping
    heloRangeKm     = 110,    -- helicopters only see missions within ~60 nm of their spawn
    slowRangeKm     = 222,    -- slow movers (slowTypes) within ~120 nm
    slowTypes       = { "A-10A", "A-10C", "A-10C_2", "Su-25", "Su-25T", "L-39ZA", "C-101CC", "MB-339A",
                        "MB-339APAN", "OV-10A", "Yak-52", "Hawk", "L-39C",
                        "C-101EB", "Christen Eagle II", "P-51D", "P-51D-30-NA", "TF-51D", "P-47D-30",
                        "P-47D-30bl1", "P-47D-40", "SpitfireLFMkIX", "SpitfireLFMkIXCW", "MosquitoFBMkVI",
                        "F4U-1D", "Bf-109K-4", "FW-190D9", "FW-190A8", "I-16", "La-7" },
    hubSupplyBelow  = 0.7,    -- local supply runs go to own bases below this share of their cap
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
    weatherFrontTicks = { 24, 72 },  -- a new weather front every 2-6 h...
    weatherDrift   = 0.02,    -- ...and the sky turns toward it this much per tick (5 min):
                              --   clear -> rain takes ~3 h, rain -> storm ~1.5 h
    speedFactor    = { rain = 0.8, storm = 0.6 },      -- ground columns
    battleFactor   = { rain = 0.85, storm = 0.7 },     -- dice battles bleed slower
    visualFactor   = { overcast = 0.9, rain = 0.6, storm = 0.4 },
    nightVisual    = 0.5,     -- eyes at night (NVGs help, but not that much)
    nightStartHour = 20,  nightEndHour = 6,             -- mission clock
    fog            = { rain = { 4000, 400 }, storm = { 1500, 900 } },  -- DCS fog: visibility m, thickness m
    fogFromSev     = 0.45,    -- fog starts this far toward rain (light haze, 10 km), thickens from there
    escortThreat   = 2,       -- road threat that gets convoys an air-defence escort
    rerouteThreat  = 2,       -- ...and makes the AI prefer another road
    reroutePenalty = 400,     -- (planning cost per threat point; one step nearer the front = 1000)
    capThreat      = 3,       -- ...and gets AI CAP over it
    threatDecayTicks = 36,    -- threat halves every 3 h
    farpBuildSU    = 30,      -- crates (10 SU each) to turn a town into a FARP
    farpStock      = 40,      -- SU a FARP holds itself (a FARP kit or 4 crates fills it)
    farpUsePerTick = 40 / 576, -- ...used per tick (5 min): full to dry in 48 h of play (v0.64: was 0.25, ~13 h)
    farpLowShare   = 0.5,     -- below this a FARPSUP mission is posted
    farpHelos      = 10,      -- helicopters of each own type a FARP can spawn (v0.44: was 20)
    farpWeapons    = 50,      -- v0.44: of each helicopter weapon on a FARP's shelf (airbases: ext.armoury.stock)
    -- v0.45: which weapons a FARP stocks: a DCS resource name (lower case) containing any of these. Everything
    -- else stays at airbases. Covers the launchers and pods the weapons hang on, so they are listed too.
    farpWeaponMatch = {
      "agm_114", "agm-114", "hellfire", "m299", "m310",                     -- Hellfire K and L, launchers (AH-64D, OH-58D)
      "agr_20", "agr-20", "apkws",                                           -- APKWS, all types
      "hydra", "lau_61", "lau-61", "lau_68", "lau-68", "lau_131", "lau-131", "m261", "m260", "m257", "m274",  -- Hydra, all
      "fim_92", "fim-92", "stinger", "atas",                                 -- Stinger (OH-58D, AH-64D)
      "m240", "m134", "m60",                                                 -- door guns (CH-47F, UH-1H, UH-60L)
      "vikhr", "9m127", "9m114", "9m120", "shturm", "ataka", "hot3", "hot_3", "mistral",  -- Ka-50, Mi-24P, Gazelle
      "nurs.s-8", "nurs.c_8", "nurs.s_8", "nurs.s-13", "nurs.c_13", "nurs.s_5", "nurs.c_5", ".b_8", ".b-8", ".ub_32", ".ub-32",
      ".b_13", ".b-13", ".ub_16", ".ub-16", "upk_23", "gun pod", "gunpod", "fuel_tank_230",   -- rockets, pods, AH-64 tank
    },
    farpFuel       = 1000,    -- v0.44: fuel (tons, Mission Editor warehouse) at every FARP pad from mission start
    farpAtStart    = true,    -- v0.44: every town a side holds starts as a stocked FARP (also added once to an
                              --   older save); captured towns still need building
    farpPads       = 2,       -- helipads per FARP (v0.38: one invisible pad let only one helicopter spawn);
                              --   make_mission.py builds DCC_FARP_<town>_<side>, ..._2, ...
    antishipChance = 0.4,     -- chance per hour of an AI strike on a known enemy ship
    -- v0.56: the missions' winds (make_mission.py; DCS cannot change wind while a mission runs). Prevailing
    -- direction per map (degrees FROM), varied by up to fromSpread; speeds in m/s at ground / 2000 m / 8000 m.
    missionWind = { from = { Caucasus = 250, Syria = 290, PersianGulf = 320, GermanyCW = 260 }, fromSpread = 40,
                    ground = { 2, 7 }, at2000 = { 6, 14 }, at8000 = { 12, 28 }, turbulence = { 3, 12 } },
    -- v0.60: DCS dynamic weather (Mission Editor > Weather > Dynamic) in every built mission: pressure systems
    -- that move during the mission, so wind, QNH and rain change across the map and through the day. Uses DCS's
    -- older cloud system (few clouds, no cloud presets). false = static weather with missionWind above.
    dynamicWeather = {
      enabled  = true,
      variants = 4,                         -- v0.61: weather versions per map (DCC_<map>.miz, _wx2 .. _wx4): the
                                            -- daily restart loads the next one, so the sky changes every day
      cyclones = { 2, 4 },                  -- pressure systems per mission (random in this range per build)
      -- share of the variants (or chance per build with one variant) that gets a high (anticyclone: settled, light winds) instead of a low
      -- (cyclone: wind, cloud and rain)
      highChance = { Caucasus = 0.5, Syria = 0.65, PersianGulf = 0.8, GermanyCW = 0.35 },
      -- the campaign's own weather (fog, column speed, eyes, storms) heads this way at mission start:
      -- severity 0 clear - 0.33 overcast - 0.66 rain - 1 storm
      campaignTarget = { high = 0.1, low = 0.6 },
    },
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
    bridgeLb       = 2000,   -- v0.54: this many lb of bombs on the span bring a bridge down (the campaign counts,
    bridgeHitM     = 40,     --   not DCS damage): a bomb this close to the bridge counts
    skirmishes     = true,   -- small fights always running on the front (for CAS)
    skirmishPerSide = 2,     -- vehicles per side per skirmish
    skirmishMax    = 8,      -- most skirmishes at once
  },
  public = { events = 40, everySeconds = 60,      -- DCC\public.json for the web map / Discord
             pilots = 100,                        -- v0.51: pilots listed (leaderboard, pilot pages)...
             sorties = 20,                        -- ...latest sorties of everyone...
             sortiesPerPilot = 5 },               -- ...and per pilot (kept in pilots.json)

  -- Live bubble (what gets spawned as real DCS units) -----------------------
  liveRadiusKm     = 25,    -- nodes within this distance of a player are live (v0.57: was 40, network load)
  maxLivePlatoons  = 60,    -- hard cap on spawned platoons (~250 vehicles; v0.57: was 120)
  liveHysteresisKm = 10,    -- a live node stays live until players are this much further out
  liveStallTicks   = 6,     -- a live battle with no progress gets one dice round every 30 min
  captureRadiusKm  = 3,     -- attackers must be this close to take a node
  spawnSpreadM     = 1200,  -- garrison platoons are scattered within this radius
  aiSkill          = "Excellent", -- v0.41: every AI unit the engine (or CTLD) spawns: "Average" (Rookie), "Good"
                                  --   (Trained), "High" (Veteran), "Excellent" (Ace), "Random"; nil = as spawned
  aiEcm            = "never", -- v0.42: AI aircraft jamming (ECM pods): "never", "lock" (only when locked),
                              --   "detected", "always"; nil = DCS default. Jamming strobes swamped the F-16s.
  runwayClearM     = 60,    -- ground units and their waypoints stay this far off runways, taxiways, aprons (v0.37)
  landCacheMax     = 4000,  -- good spots remembered for respawns (v0.65); the memory is cleared when this full

  -- Persistence ---------------------------------------------------------------
  saveFolder       = "DCC", -- under Saved Games\DCS\ (lfs.writedir())
  -- (v0.40's fresh-war switch is gone since v0.47: a Game Master types "-dcc freshwar yes" instead)
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
    fillHoles = true,   -- ...except inside the area spanned by all bases: no gaps between far-apart bases
    capSides  = 24,     -- polygon used for that limit
    fillAlpha = 0.35,   -- territory shading on the F10 map (0 = none, 1 = solid)
    lineWidth = 3,      -- front line thickness style
  },

  -- More air and ground war (dcc_ext.lua / dcc_dcs_ext_*.lua)
  ext = {
    -- weapons a base can arm aircraft with, by its supply (share of its cap)
    armoury = { guidedAt = 0.2, advancedAt = 0.45, guidedSU = 0.25, advancedSU = 0.5,
                                       -- bases start at 0.5 supply, so every tier is on the shelf
                                       --   until the enemy cuts the supply lines
                mode = "warehouse",    -- "warehouse": limited munitions, the re-arm menu only offers what
                                       --   is on the shelf (tested on a server, Oct 2026)
                                       -- "takeoff": unlimited munitions, warn when taxiing, recall at
                                       --   take-off (missions built with --armoury takeoff)
                enforce = true,        -- takeoff mode: false = charge only, never recall
                stock = { basic = 100, guided = 100, advanced = 100 },  -- per weapon type, every base and FARP
                tiers = false,         -- v0.37: false = every tier always on the shelf (guided / advanced
                                       --   still cost supply when taken); true = tiers follow supply
                                       --   (guided from guidedAt, advanced from advancedAt)
                depotStock = 1,        -- depots hold this many times the stock (v0.36: 1 = same as any base)
                testMenu = false },    -- F10 > Armoury test (on in the test mission)
    runwayLb = 6000, runwayTicks = 48, runwayRepairSU = 30,  -- v0.54: 6000 lb of bombs close an airfield for 4 h
    runwayHitM = 60,             -- a bomb this close to the runway centre line counts
    -- v0.54: bomb weight in lb by DCS weapon name (first match, lower case); anything else: bombLbDefault
    bombLb = { { "mk_84", 2000 }, { "mk_83", 1000 }, { "mk_82", 500 }, { "mk_81", 250 }, { "mk_20", 500 },
               { "gbu_10", 2000 }, { "gbu_24", 2000 }, { "gbu_31", 2000 }, { "gbu_16", 1000 }, { "gbu_32", 1000 },
               { "gbu_12", 500 }, { "gbu_38", 500 }, { "gbu_54", 500 }, { "gbu_39", 250 },
               { "cbu_97", 1000 }, { "cbu_87", 1000 }, { "cbu_99", 500 }, { "cbu_103", 1000 }, { "cbu_105", 1000 },
               { "agm_154", 1000 }, { "bdu_", 0 }, { "sab_", 0 },
               { "fab_1500", 3300 }, { "kab_1500", 3300 }, { "fab_500", 1100 }, { "kab_500", 1100 }, { "betab_500", 1100 },
               { "rbk_500", 1100 }, { "fab_250", 550 }, { "rbk_250", 550 }, { "ofab", 250 }, { "fab_100", 220 },
               { "ls_6", 1100 }, { "gb_6", 1100 }, { "lb_", 500 } },
    bombLbDefault = 500,
    samMoveKm = { 1.5, 4 }, samMoveCooldown = 900,            -- shoot and scoot (seconds between moves)
    aiCrewChance = 0.7,          -- share of AI crews that eject alive
    support = {
      artySU = 10, artyRangeKm = 35, artyRounds = 6, artyCooldownMin = 10,   -- v0.57: 6 rounds (was 12)
      casSU = 20, casCooldownMin = 20,
      markMinutes = 15,          -- a map mark is good for this long
    },
    farpKit = { types = { "CH-47Fbl1", "Mi-8MT", "Mi-8MTV2" },   -- who can lift it
                weight = 3000.01,   -- kg (a Huey or Mi-24 can't sling it)
                su = 30,            -- supply it costs at the base it is loaded at
                km = 3 },           -- set down this close to a friendly town
    bridgeKitKm = 1.5, bridgeKitCrates = 2,
    mineTicks = 288, mineSpeed = 0.5, mineLoss = 0.15, mineRoadKm = 1.5,
    veterancy = { vetXp = 2, eliteXp = 5, vetBonus = 0.1, eliteBonus = 0.2 },
    industryPerSide = 3, industryFactor = 0.12, industryRebuildTicks = 288, industryRebuildSU = 80,
    partisans = { maps = { Syria = true, PersianGulf = true }, chance = 0.004, max = 4, lifeTicks = 576,
                  sabotageSU = 1, sweepPerPlatoon = 0.004, ambush = 0.25 },
    scaling = { perPlayer = 0.05, max = 0.15, airPerPlayer = 0.25, airMax = 2 },
    ranks = { arty = "Captain", cas = "Major", farp = nil, picture = "Colonel" },  -- farp: rank for FARP spawns; nil = anyone (v0.46, was "Lieutenant Colonel")
    wrecks = { max = 100, days = 3, scenery = true },   -- v0.57: newest 100 per map (was 300)
  },

  -- CTLD (VEAF CTLD v2, built into the missions): helicopter logistics
  -- Self-check, "Where can I spawn?" and admin chat commands (v0.47, dcc_dcs_admin.lua)
  admin = {
    selfCheckDelay       = 30,    -- s after mission start: the self-check runs (dcs.log, DCC\selfcheck.txt)
    selfCheckShowSeconds = 60,    -- warnings stay this long on screen
    templates   = { "fighter", "tanker", "awacs", "attack", "sead", "airmobile", "drone", "gunship" },  -- AI templates checked
    spawnListTypes = 8,           -- "Where can I spawn?": types named per list (then "+n more")
    spawnLowStock  = 3,           -- ...a type with this many or fewer is listed as low
    spawnListRows  = 15,          -- ...and bases / FARPs listed
    reloadDelay    = 15,          -- s between "-dcc restart" / "-dcc freshwar yes" and the reload (server hook)
  },

  -- SRS voice (v0.50, dcc_dcs_srs.lua): the mission queues lines, the server hook speaks them through
  -- SRS (DCS-SR-ExternalAudio.exe; its install folder is set in hooks/DCC_rotation_hook.lua, srs.dir).
  srs = {
    enabled     = true,
    freqs       = { awacs   = { blue = 238.0, red = 238.0 },    -- MHz, AM; SRS keeps the coalitions apart; no airfield on any map uses these
                    command = { blue = 239.0, red = 239.0 },
                    info    = { blue = 240.0, red = 240.0 } },
    modulation  = "AM",
    names       = { awacs = "Overlord", command = "Command", info = "Information" },
    gender      = { awacs = "male", command = "female", info = "female" },
    culture     = "en-GB",
    infoEveryMin = 15,     -- airfield information for one base at most this often...
    infoKm      = 6,       -- ...when a player sits on the ground this close to it
    maxQueue    = 20,      -- lines kept when no hook collects them
  },

  ctld = {
    enabled          = true,   -- use CTLD when the mission loads it (else our own Cargo menu)
    crateSU          = 10,     -- every crate requested at a base costs that base this much supply
    supplyCrateSU    = 10,     -- a supply crate unloaded at a friendly base adds this much
    supplyWeight     = 500.01, -- kg; also CTLD's id for the supply crate
    zoneRadiusAirbaseM = 1500, -- pickup / logistic zone around an airbase
    zoneRadiusM      = 600,    -- around a town or carrier
    farpZoneRadiusM  = 300,    -- v0.56: around a town's own FARP pads (troops and crates of that town)
    dropKm           = 3,      -- troops or crates this close to a base count as delivered there
    fobFarpKm        = 5,      -- a CTLD FOB this close to a town makes the town a FARP
    fobChargeKm      = 40,     -- crates at a FOB are paid by the nearest own base this close
    aaDefenceKm      = 3,      -- an AA system this close to an own base digs it in one level
    platoonSU        = 60,     -- vehicles unpacked at an own base join it as a platoon of
                               -- health (crates x crateSU) / platoonSU (an Abrams, 4 crates: 0.67)
    joinDelay        = 60,     -- seconds before the unpacked vehicle leaves the map (it is in the garrison)
    maxExtraBatteries = 2,     -- artillery crates can add this many batteries per side
    -- whole vehicles a helicopter (Chinook, Mi-8) or transport aircraft may carry: light vehicles
    -- only (BRDM-2 and Tigr are ~7 t: crates only)
    wholeVehicles = {
      blue = { "Hummer", "M1043 HMMWV Armament", "M1045 HMMWV TOW" },
      red  = { "UAZ-469" },
    },
    -- kg, for CTLD's load checks (Mi-8 3 t, Chinook 11 t)
    vehicleWeights = { ["UAZ-469"] = 1600, ["Tigr_233036"] = 7200 },
  },

  -- More air and ground war (v0.18, src/dcc_ext2.lua + dcc_dcs_ext2.lua) ---------
  ext2 = {
    -- 2. tankers and AWACS: escorted by players, hunted by the enemy
    hvaDownTicks    = 24,      -- a lost tanker / AWACS: none for 2 h
    hvaEscortKm     = 40,      -- HVAESCORT: stay this close...
    hvaEscortMin    = 20,      -- ...for this many minutes
    huntMinutes     = 90,      -- mean time between enemy fighter sweeps at an HVA (when players are on)
    huntWarnKm      = 150,     -- the HVA's side is warned when the hunters launch
    -- 3. strike packages
    pkgEscortKm     = 25,      -- PKGESCORT: be this close to the target while the strike goes in
    pkgTypes        = { STRIKE = true, INDUSTRY = true, EWR = true, RUNWAY = true },
    -- 4. enemy reacts to aces
    aceKills        = 3,       -- air kills in one sortie that get a player hunted
    aceCooldownMin  = 30,
    -- 5. artillery duels
    harassSU        = 0.4,     -- supply a shelled base loses per tick (5 min)
    harassLogTicks  = 12,      -- "is shelling" message at most once an hour per battery
    shellKm         = 15,      -- impacts are only shown when a player is this close
    -- 6. convoys
    secondAmbushAt  = 0.3,     -- a second ambush this much further along the road
    liveAmbushChance = 0.3,    -- a live, unescorted front convoy near players: chance of an ambush
    -- 7 + 9. prisoners and wounded (helicopter pick-ups)
    powPerSurrender = 6, powPerCapture = 3, powTicks = 36,
    medevacPerBattle = 4, medevacTicks = 18, medevacHeal = 0.1,
    maxPickups      = 4,       -- open pick-ups per side
    pickupLandM     = 250,     -- land this close to pick up
    -- 8. heavy sling loads (Chinook / Mi-8)
    heavyTypes      = { "CH-47Fbl1", "Mi-8MT", "Mi-8MTV2" },
    generatorBoost  = 0.25, generatorTicks = 288,   -- +25 % supply cap for 24 h
    heavyKm         = 3,
    -- 10. CSAR under fire
    searchAfterMin  = 10,      -- an enemy search party sets out after this long...
    searchKm        = 30,      -- ...from the nearest enemy base within this range
    searchSpeed     = 4,       -- m/s (on foot / light vehicle, cross country)
    searchCatchM    = 120,     -- this close to the pilot: captured
  },

  -- Naval and hidden-threat war (v0.25, src/dcc_ext3.lua + dcc_dcs_ext3.lua) -------
  ext3 = {
    -- 1. amphibious assault (ships with amphib = true in the theater pack)
    amphib = { platoons = 2, maxDefenders = 4, cooldownTicks = 144,   -- one landing per ship per 12 h at most
               rangeKm = 70,             -- beaches this close to the ship
               minutes = 120,            -- mean time between landings while players are on
               escortKm = 20 },          -- AMPHIB escort: be this close to the helicopters
    -- 2. shipping lanes (theater pack: shipping = { { port, start, dock } })
    shipping = { everyTicks = 36, maxPerSide = 1, su = 40, speedKmh = 20, belowShare = 0.8,
                 escortKm = 20, aiStrikeChance = 0.08, ships = { blue = "Dry-cargo ship-1", red = "Dry-cargo ship-2" } },
    -- 3. carrier air wing: recovery tanker and CAP over the carrier
    carrier = { tankerTacan = 76, tankerCall = "SHL", respawnMin = 30, lifeMin = 120, retaskKm = 15,
                capAltM = 6000, tankerAltM = 1800 },
    -- 4. SCUDs (RED)
    scud = { side = "red", launchers = 2, everyTicks = 30, rangeKm = 300, damageSU = 15, runwayChance = 0.35,
             depth = { 2, 4 }, scootTicks = 3, rebuildTicks = 144, rebuildSU = 60, impactKm = 30 },
    -- 7. pop-up threats near the front
    popup = { chance = 0.05, max = 3, lifeTicks = 18, manpadsShare = 0.6, spawnKm = 40, despawnKm = 60,
              seeKm = 8 },
    -- 10. night illumination: flares over night battles near players, and on call
    illum = { autoKm = 25, everySec = 300, heightM = 650, power = 1000000,    -- v0.57: a flare every 5 min (was 2)
              callSU = 2, callKm = 30, callFlares = 4, callEverySec = 300, callCooldownMin = 5 },  -- called: 1 per 5 min
  },

  -- v0.27: Combined Arms, QRA, engineers, performance guard ----------------------
  ext4 = {
    -- 6. Combined Arms: campaign ground groups a CA commander / JTAC can drive
    --    (platoons, supply convoys, artillery, skirmishes). Slots: make_mission.py.
    ca = { playerCanDrive = true,
           patterns = { "^DCC_p%d+$", "^DCC_c%d+$", "^DCC_ARTY_", "^DCC_SKIRM_" } },
    -- 7. Quick reaction alert: grounded fighters are scrambled onto new INTERCEPTs
    qra = { minutes = 5, km = 150 },
    -- 6b. ground missions (ASSAULT, HOLD, GCONVOY) for players in ground vehicles:
    --     shown within rangeKm, credit after presenceMin minutes within presenceKm
    ground = { rangeKm = 60, presenceKm = 5, presenceMin = 5,
               artyKm = 6, dangerCloseM = 300,     -- Support > Artillery for ground players (v0.29)
               -- Support > Smoke screen ahead (v0.30): 5 smoke rounds across the heading
               smokeSU = 2, smokeAheadM = 500, smokeWidthM = 400, smokeRounds = 5,
               smokeMinutes = 3, smokeCooldownMin = 5, smokePreset = 6 },
    -- AI attacks lay smoke when their lead vehicles are within withinKm of the base (v0.30)
    -- ...and live garrisons screen themselves (smoke grenades, free) against an attack
    -- within defendKm or a low enemy aircraft within airKm (v0.32)
    aiSmoke = { enabled = true, withinKm = 2, everyMin = 20,     -- v0.57: 20 min (was 10), network load
                defend = true, defendKm = 2, airKm = 6, airMaxAltM = 2500, defendEveryMin = 20, defendOffsetM = 300,
                shotSec = 60, diveMps = 15 },   -- aircraft only when attacking: fired in 60 s, or diving at the base
    -- 8. harbour mines (v0.34): every everyTicks each side mines an enemy lane port with
    --    chance; they last lifeTicks; a ship past strikeAt of its lane hits them; a
    --    helicopter clears them flying sweepMin minutes below sweepAglM within sweepKm
    mines = { everyTicks = 72, chance = 0.4, lifeTicks = 288, strikeAt = 0.85,
              sweepMin = 5, sweepAglM = 150, sweepKm = 3,
              -- v0.35: laid by a real minelayer ship sailing the lane; spotted at detectAt
              -- (coastal radar) or by an enemy aircraft within spotKm; first type that spawns
              layerSpeedKmh = 30, detectAt = 0.3, spotKm = 20,
              layerShips = { blue = { "CastleClass_01" },
                             red = { "CHAP_Project22160", "MOLNIYA" } } },   -- Bykov is the Currenthill mod
    -- 1. Support > Bogey dope: nearest enemy aircraft your side has seen in the last staleSec
    bogey = { staleSec = 60, maxNm = 100 },
    -- 15. Engineer repair kit (CTLD > Engineering, any lift helicopter)
    repair = { weight = 1000.01, charge = 2, km = 3 },    -- charge x crateSU = 20 SU
    -- 16. Performance guard: fewer live units when DCS carries many ground units
    perf = { everySec = 60, restore = 0.85, minRadiusKm = 20,
             levels = { { units = 550, scale = 0.7 }, { units = 800, scale = 0.45 } } },   -- v0.57: was 700 / 1000
  },

  -- v0.49: air assault missions (dcc_ext5.lua) and their AI gunship escort (dcc_dcs_ext5.lua)
  ext5 = {
    airAssault = {
      maxDefenders = 3,      -- enemy bases with this many platoons or fewer are targets (not depots)
      minTroops    = 2,      -- the own base the troops come from needs this many platoons
      rangeKm      = 60,     -- target within this distance of that base
      altM         = 60,     -- gunships fly this low (m above ground)...
      speedMs      = 55,     -- ...at this speed (about 105 kt)
      standoffKm   = 4,      -- they hold this far short of the target first...
      zoneKm       = 3,      -- ...then attack ground units within this radius of it
      lifeSeconds  = 2700,   -- and go home after 45 min (survivors return to the attack pool)
    },
    -- v0.56: AI-vs-AI fire control against multiplayer desync. Campaign ground groups (platoons, convoys,
    -- artillery, skirmishes, ambushes) hold fire unless a player is within fireKm; battles further out are
    -- fought on the dice even when their units are on the map.
    fireControl = {
      enabled  = true,
      fireKm   = 15,
      prefixes = { "^DCC_p%d", "^DCC_c%d", "^DCC_ARTY_", "^DCC_SKIRM_", "^DCC_AMB_", "^DCC_AMBL_" },
      -- v0.57: AI switched off for standing campaign groups with no player this close (they stay visible;
      -- moving groups, SAM sites and radars keep their AI)
      idleKm   = 50,
      idlePrefixes = { "^DCC_p%d", "^DCC_ARTY_", "^DCC_FARPCREW_", "^DCC_SKIRM_" },
      -- v0.57: road columns and supply convoys are only spawned within convoyKm of a player (dice further out;
      -- they still arrive and resupply bases), and kept until convoyKm + convoyHysteresisKm
      convoyKm = 20, convoyHysteresisKm = 5,
    },
  },

  -- v0.58: player slots (dynamic spawns, multicrew) -------------------------------
  slots = {
    removeCheckSec = 5,     -- a player sent to spectators who is still in the aircraft after this: it is destroyed
    sweepSec       = 30,    -- every so often, players DCS reports in an aircraft but the campaign does not know get
                            -- their menus (a dynamic spawn whose birth came before the player, a crew seat change)
    groundEjectKm  = 6,     -- an ejection on the ground this close to an own base is a way out of the slot, not a
                            -- downed pilot: no CSAR mission
    logPlayers     = true,  -- write every player entering and leaving an aircraft to dcs.log
  },

  -- v0.59: weapons stock pages (F10 > Support > Weapons stock here / Where is ...) ------------
  stock = {
    lowShare  = 0.25,       -- a family below this share of a full shelf is LOW (0 = OUT)
    whereMax  = 6,          -- Where is ...: this many own bases, nearest first
    onSpawn   = true,       -- the spawn message names what is low or out at the base
    showSec   = 30,         -- how long the stock page stays on screen
  },

  -- Drawing (F10 map) -----------------------------------------------------------
  markIdBase       = 7000000,  -- F10 mark ids used by the engine start here
  colours = {
    blue  = { 0.137, 0.451, 0.957, 1.0 },   -- #2373F4
    red   = { 0.875, 0.188, 0.110, 1.0 },   -- #DF301C
    front = { 1.00, 0.85, 0.10, 1.0 },
  },

  debug = false,
}
