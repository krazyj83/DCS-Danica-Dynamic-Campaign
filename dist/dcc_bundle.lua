-- Danica Dynamic Campaign bundle 0.43.0 (generated - edit the sources, not this file)

-- >>> src/dcc_config.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - configuration
-- ----------------------------------------------------------------------------
-- Every tunable number lives here. Values are starting points for phase 1
-- testing, not balanced results: tune them after watching a few nights of war.
-- ============================================================================

DCC = DCC or {}

DCC.config = {
  version         = "0.43.0",

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
    perType = { CAS = 2, BAI = 3, STRIKE = 2, SEAD = 2, CAP = 1, ESCORT = 3,
                CONVOY = 2, RECON = 2, CSAR = 4, LOGISTICS = 2, EWR = 1, HVAA = 1, ANTISHIP = 1, FARP = 2,
                FARPSUP = 2, INTERCEPT = 3, HVAESCORT = 2, PKGESCORT = 2, MEDEVAC = 2, POW = 2,
                AMPHIB = 1, SHIPSTRIKE = 2, SHIPESCORT = 2, SCUD = 2, POPUP = 3, TANKER = 1, ARTY = 2, FORT = 2, BRIDGE = 2,
                RUNWAY = 1, SNATCH = 2, INDUSTRY = 1, COIN = 2,
                ASSAULT = 4, HOLD = 4, GCONVOY = 3, MINESWEEP = 2, MINELAYER = 2 },   -- ground missions (CA players), mine sweeping
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
    farpUsePerTick = 0.25,    -- ...used per tick (5 min): full to dry in ~13 h
    farpLowShare   = 0.5,     -- below this a FARPSUP mission is posted
    farpHelos      = 20,      -- helicopters of each own type a FARP can spawn (v0.36: was 2)
    farpPads       = 2,       -- helipads per FARP (v0.38: one invisible pad let only one helicopter spawn);
                              --   make_mission.py builds DCC_FARP_<town>_<side>, ..._2, ...
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
  aiSkill          = "Excellent", -- v0.41: every AI unit the engine (or CTLD) spawns: "Average" (Rookie), "Good"
                                  --   (Trained), "High" (Veteran), "Excellent" (Ace), "Random"; nil = as spawned
  aiEcm            = "never", -- v0.42: AI aircraft jamming (ECM pods): "never", "lock" (only when locked),
                              --   "detected", "always"; nil = DCS default. Jamming strobes swamped the F-16s.
  runwayClearM     = 60,    -- ground units and their waypoints stay this far off runways, taxiways, aprons (v0.37)

  -- Persistence ---------------------------------------------------------------
  saveFolder       = "DCC", -- under Saved Games\DCS\ (lfs.writedir())
  -- Fresh-war switch (v0.40, for troubleshooting): when this token differs from the one in the save,
  -- the saved war is archived and a new war starts - once; restarts then continue the new war.
  -- Change the token to force another fresh start; false = never (normal running).
  freshWar         = "2026-10-28a",
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
    runwayHits = 3, runwayTicks = 48, runwayRepairSU = 30,   -- 3 bomb hits close an airfield for 4 h
    runwayHitM = 60,             -- a bomb this close to the runway centre line counts
    samMoveKm = { 1.5, 4 }, samMoveCooldown = 900,            -- shoot and scoot (seconds between moves)
    aiCrewChance = 0.7,          -- share of AI crews that eject alive
    support = {
      artySU = 10, artyRangeKm = 35, artyRounds = 12, artyCooldownMin = 10,
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
    ranks = { arty = "Captain", cas = "Major", farp = "Lieutenant Colonel", picture = "Colonel" },
    wrecks = { max = 300, days = 3, scenery = true },
  },

  -- CTLD (VEAF CTLD v2, built into the missions): helicopter logistics
  ctld = {
    enabled          = true,   -- use CTLD when the mission loads it (else our own Cargo menu)
    crateSU          = 10,     -- every crate requested at a base costs that base this much supply
    supplyCrateSU    = 10,     -- a supply crate unloaded at a friendly base adds this much
    supplyWeight     = 500.01, -- kg; also CTLD's id for the supply crate
    zoneRadiusAirbaseM = 1500, -- pickup / logistic zone around an airbase
    zoneRadiusM      = 600,    -- around a town or carrier
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
    illum = { autoKm = 25, everySec = 120, heightM = 650, power = 1000000,
              callSU = 2, callKm = 30, callFlares = 4, callCooldownMin = 5 },
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
    aiSmoke = { enabled = true, withinKm = 2, everyMin = 10,
                defend = true, defendKm = 2, airKm = 6, airMaxAltM = 2500, defendEveryMin = 10, defendOffsetM = 300,
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
             levels = { { units = 700, scale = 0.7 }, { units = 1000, scale = 0.45 } } },
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

end

-- >>> src/dcc_util.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - utilities (pure Lua 5.1, no DCS calls)
-- ----------------------------------------------------------------------------
-- Geography on lat/lon, a seeded random generator and table helpers.
-- Nothing here touches DCS, so it runs in offline tests too.
-- ============================================================================

DCC = DCC or {}
local U = {}
DCC.util = U

local rad, deg = math.rad, math.deg
local sin, cos, atan2, asin, sqrt = math.sin, math.cos, math.atan2, math.asin, math.sqrt
local EARTH_KM = 6371.0

-- Great-circle distance in km between two {lat, lon} points.
function U.distKm(a, b)
  local dLat = rad(b.lat - a.lat)
  local dLon = rad(b.lon - a.lon)
  local h = sin(dLat / 2) ^ 2 + cos(rad(a.lat)) * cos(rad(b.lat)) * sin(dLon / 2) ^ 2
  return 2 * EARTH_KM * asin(math.min(1, sqrt(h)))
end

-- Initial bearing in degrees from a to b.
function U.bearing(a, b)
  local p1, p2 = rad(a.lat), rad(b.lat)
  local dLon = rad(b.lon - a.lon)
  local y = sin(dLon) * cos(p2)
  local x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dLon)
  return (deg(atan2(y, x)) + 360) % 360
end

-- Point reached travelling `km` from p on bearing `brg` (degrees).
function U.destination(p, brg, km)
  local d = km / EARTH_KM
  local b = rad(brg)
  local p1, l1 = rad(p.lat), rad(p.lon)
  local p2 = asin(sin(p1) * cos(d) + cos(p1) * sin(d) * cos(b))
  local l2 = l1 + atan2(sin(b) * sin(d) * cos(p1), cos(d) - sin(p1) * sin(p2))
  return { lat = deg(p2), lon = deg(l2) }
end

-- Straight-line interpolation (fine for the short distances between nodes).
function U.lerp(a, b, t)
  return { lat = a.lat + (b.lat - a.lat) * t, lon = a.lon + (b.lon - a.lon) * t }
end

function U.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- ----------------------------------------------------------------------------
-- Seeded random generator (Park-Miller). The state is a plain number, so it is
-- saved with the campaign and a restored war continues the same sequence.
-- ----------------------------------------------------------------------------
local RNG = {}
RNG.__index = RNG

function U.rng(seed)
  local s = math.floor(tonumber(seed) or 12345) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  return setmetatable({ state = s }, RNG)
end

-- Uniform float in [0, 1).
function RNG:next()
  self.state = (self.state * 16807) % 2147483647
  return (self.state - 1) / 2147483646
end

-- Uniform float in [lo, hi).
function RNG:range(lo, hi)
  return lo + (hi - lo) * self:next()
end

-- Integer in [1, n].
function RNG:int(n)
  return math.floor(self:next() * n) + 1
end

-- Pick a key from a { key = weight } table.
function RNG:weighted(weights)
  local keys, total = {}, 0
  for k, w in pairs(weights) do keys[#keys + 1] = k; total = total + w end
  table.sort(keys) -- pairs() order is not stable; sorting keeps runs reproducible
  local r = self:next() * total
  for _, k in ipairs(keys) do
    r = r - weights[k]
    if r < 0 then return k end
  end
  return keys[#keys]
end

-- ----------------------------------------------------------------------------
-- Table helpers
-- ----------------------------------------------------------------------------
function U.copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = U.copy(v) end
  return c
end

function U.removeValue(list, value)
  for i = #list, 1, -1 do
    if list[i] == value then table.remove(list, i); return true end
  end
  return false
end

function U.sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys
end

function U.otherSide(side)
  return side == "blue" and "red" or "blue"
end

-- Logging goes to dcs.log inside DCS, to stdout offline.
function U.log(fmt, ...)
  local msg = "DCC: " .. string.format(fmt, ...)
  if env and env.info then env.info(msg) else print(msg) end
end

function U.debug(fmt, ...)
  if DCC.config and DCC.config.debug then U.log(fmt, ...) end
end

end

-- >>> src/dcc_json.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - minimal JSON encoder/decoder (pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- DCS has net.lua2json, but its availability in the mission sandbox has
-- changed between versions. A small local encoder keeps saves working on any
-- DCS build and in offline tests.
--
-- Rules: a table whose keys are exactly 1..n is a JSON array; any other table
-- is an object and its keys are written as strings. Empty tables become {}.
-- ============================================================================

DCC = DCC or {}
local J = {}
DCC.json = J

local escapes = { ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
                  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

local function escapeStr(s)
  return '"' .. s:gsub('[%c"\\]', function(c)
    return escapes[c] or string.format("\\u%04x", c:byte())
  end) .. '"'
end

local function isArray(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  if n == 0 then return false end
  for i = 1, n do if t[i] == nil then return false end end
  return true
end

local function encode(v, out, indent, depth)
  local tv = type(v)
  if tv == "nil" then out[#out + 1] = "null"
  elseif tv == "boolean" then out[#out + 1] = tostring(v)
  elseif tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "null"
    elseif v == math.floor(v) and math.abs(v) < 1e15 then out[#out + 1] = string.format("%d", v)
    else out[#out + 1] = string.format("%.17g", v) end -- 17 digits: exact round trip
  elseif tv == "string" then out[#out + 1] = escapeStr(v)
  elseif tv == "table" then
    local nl = indent and ("\n" .. string.rep(indent, depth + 1)) or ""
    local close = indent and ("\n" .. string.rep(indent, depth)) or ""
    if isArray(v) then
      out[#out + 1] = "["
      for i = 1, #v do
        if i > 1 then out[#out + 1] = "," end
        out[#out + 1] = nl
        encode(v[i], out, indent, depth + 1)
      end
      out[#out + 1] = close .. "]"
    else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      out[#out + 1] = "{"
      for i, k in ipairs(keys) do
        if i > 1 then out[#out + 1] = "," end
        local val = v[k]
        if val == nil then val = v[tonumber(k)] end
        out[#out + 1] = nl .. escapeStr(k) .. (indent and ": " or ":")
        encode(val, out, indent, depth + 1)
      end
      out[#out + 1] = (#keys > 0 and close or "") .. "}"
    end
  else
    error("dcc_json: cannot encode type " .. tv)
  end
end

function J.encode(v, pretty)
  local out = {}
  encode(v, out, pretty and "  " or nil, 0)
  return table.concat(out)
end

-- ---------------------------------------------------------------------------
-- Decoder (recursive descent)
-- ---------------------------------------------------------------------------
local function skip(s, i)
  local _, e = s:find("^[ \n\r\t]*", i)
  return e + 1
end

local decodeValue

local function decodeString(s, i)
  local out, j = {}, i + 1
  while true do
    local c = s:sub(j, j)
    if c == "" then error("dcc_json: unterminated string") end
    if c == '"' then return table.concat(out), j + 1 end
    if c == "\\" then
      local n = s:sub(j + 1, j + 1)
      local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
      if n == "u" then
        local code = tonumber(s:sub(j + 2, j + 5), 16)
        out[#out + 1] = code < 128 and string.char(code) or "?"
        j = j + 6
      else
        out[#out + 1] = map[n] or n
        j = j + 2
      end
    else
      out[#out + 1] = c
      j = j + 1
    end
  end
end

function decodeValue(s, i)
  i = skip(s, i)
  local c = s:sub(i, i)
  if c == "{" then
    local obj = {}
    i = skip(s, i + 1)
    if s:sub(i, i) == "}" then return obj, i + 1 end
    while true do
      local key
      key, i = decodeString(s, skip(s, i))
      i = skip(s, i)
      if s:sub(i, i) ~= ":" then error("dcc_json: expected ':' at " .. i) end
      obj[key], i = decodeValue(s, i + 1)
      i = skip(s, i)
      local d = s:sub(i, i)
      if d == "}" then return obj, i + 1 end
      if d ~= "," then error("dcc_json: expected ',' or '}' at " .. i) end
      i = i + 1
    end
  elseif c == "[" then
    local arr = {}
    i = skip(s, i + 1)
    if s:sub(i, i) == "]" then return arr, i + 1 end
    while true do
      arr[#arr + 1], i = decodeValue(s, i)
      i = skip(s, i)
      local d = s:sub(i, i)
      if d == "]" then return arr, i + 1 end
      if d ~= "," then error("dcc_json: expected ',' or ']' at " .. i) end
      i = i + 1
    end
  elseif c == '"' then
    return decodeString(s, i)
  elseif s:sub(i, i + 3) == "true" then return true, i + 4
  elseif s:sub(i, i + 4) == "false" then return false, i + 5
  elseif s:sub(i, i + 3) == "null" then return nil, i + 4
  else
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if not num or num == "" then error("dcc_json: unexpected character at " .. i) end
    return tonumber(num), i + #num
  end
end

function J.decode(s)
  local v = decodeValue(s, 1)
  return v
end

end

-- >>> src/dcc_war.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - war model (pure Lua 5.1, no DCS calls)
-- ----------------------------------------------------------------------------
-- This is the whole war as numbers. It knows nodes, roads, platoons, moves and
-- battles, and it advances one "tick" (5 minutes) at a time.
--
-- The DCS bridge sits on top: it spawns the platoons that are near players as
-- real units, and reports back what happened to them. Battles nobody can see
-- are resolved here with dice, so the war keeps moving on an empty server.
--
-- Key concepts
--   node     : a place that can be owned (airbase, town, depot)
--   platoon  : the unit of force; has a side, a role and a health 0..1
--   garrison : the platoons sitting in a node
--   move     : something travelling. kind = "reinforce" (platoons to a
--              friendly node), "assault" (platoons to an enemy node),
--              "convoy" (supply by road) or "airlift" (supply by air).
--              Supply lives in dcc_supply.lua, which adds methods to War.
--   battle   : an assault that has arrived; status = "fighting"
--   live     : a node or move the bridge has spawned as DCS units. The model
--              does not roll dice for live fights - DCS does the fighting.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local War = {}
War.__index = War
DCC.War = War

local SIDES = { "blue", "red" }
local ROLE_ORDER = { ARMOR_PLT = 1, MECH_PLT = 2, SHORAD = 3 } -- assault preference

-- ---------------------------------------------------------------------------
-- Theater index: static data the model looks up (positions, road lengths).
-- ---------------------------------------------------------------------------
local function indexTheater(theater)
  local T = { name = theater.name, nodes = {}, order = {}, edges = {}, sea = {} }
  for _, n in ipairs(theater.nodes) do
    assert(n.id and n.lat and n.lon and n.side, "theater node needs id, lat, lon, side")
    T.nodes[n.id] = {
      id = n.id, name = n.name or n.id, kind = n.kind or "town",
      depot = n.depot and true or false,
      lat = n.lat, lon = n.lon, airbase = n.airbase, ewr = n.ewr,
      startSide = n.side, nb = {},
    }
    T.order[#T.order + 1] = n.id
  end
  table.sort(T.order)
  for _, e in ipairs(theater.edges) do
    local a, b = T.nodes[e[1]], T.nodes[e[2]]
    if a and b then
      local km = U.distKm(a, b)
      a.nb[b.id], b.nb[a.id] = km, km
      T.edges[#T.edges + 1] = { a = a.id, b = b.id, km = km, sea = e.sea }
      -- sea crossings (ferries, landing craft): abstract only, never spawned
      if e.sea then T.sea[a.id .. "|" .. b.id], T.sea[b.id .. "|" .. a.id] = true, true end
    else
      U.log("theater %s: edge %s-%s skipped (unknown node)", theater.name, tostring(e[1]), tostring(e[2]))
    end
  end
  return T
end

-- Node class decides garrison size and defender bonus.
local function classOf(tn)
  if tn.depot then return "depot" end
  return tn.kind == "airbase" and "airbase" or "town"
end

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------
local function base(theater, catalog, cfg)
  return setmetatable({
    T = indexTheater(theater), theater = theater, cat = catalog, cfg = cfg,
    fogOfWar = cfg.intel and cfg.intel.enabled,   -- phase 4: board and map use contacts only
    balance = theater.balance or {},   -- e.g. { red = 1.2 }: production multiplier per side
    liveFn = nil,          -- set by the bridge: function(nodeId) -> bool
    newEvents = {},
  }, War)
end

-- A fresh war from the theater's start positions.
function War.new(theater, catalog, cfg, seed)
  local self = base(theater, catalog, cfg)
  self.rng = U.rng(seed or 12345)
  self.state = {
    version = 1, theater = theater.name, tick = 0, nextId = 1,
    nodes = {}, platoons = {}, moves = {}, events = {},
    stats = { captures = { blue = 0, red = 0 }, lost = { blue = 0, red = 0 },
              produced = { blue = 0, red = 0 } },
  }
  for _, id in ipairs(self.T.order) do
    local tn = self.T.nodes[id]
    self.state.nodes[id] = { side = tn.startSide, platoons = {} }
    for _ = 1, cfg.garrisonStart[classOf(tn)] do
      self:newPlatoon(tn.startSide, self:pickRole("garrison"), id)
    end
  end
  self:initAllSupply()
  if self.initOps then self:initOps() end
  if self.initIntel then self:initIntel() end
  self:log("start", nil, "War begins on " .. theater.name)
  return self
end

-- A war restored from a saved state table.
function War.restore(theater, catalog, cfg, state)
  local self = base(theater, catalog, cfg)
  self.state = state
  self.rng = U.rng(state.rng or 12345)
  state.moves = state.moves or {}
  state.platoons = state.platoons or {}
  state.events = state.events or {}
  -- New nodes added to the theater pack since the save: start them as defined.
  for _, id in ipairs(self.T.order) do
    if not state.nodes[id] then
      state.nodes[id] = { side = self.T.nodes[id].startSide, platoons = {} }
      U.log("restore: new node %s added with no garrison", id)
    end
    state.nodes[id].platoons = state.nodes[id].platoons or {}
  end
  -- Nodes removed from the theater pack: drop them and their platoons.
  for id, ns in pairs(state.nodes) do
    if not self.T.nodes[id] then
      for _, pid in ipairs(ns.platoons) do state.platoons[pid] = nil end
      state.nodes[id] = nil
      U.log("restore: node %s no longer in theater, removed", id)
    end
  end
  for mid, mv in pairs(state.moves) do
    mv.platoons = mv.platoons or {}
    if not (self.T.nodes[mv.from] and self.T.nodes[mv.to]) then
      for _, pid in ipairs(mv.platoons) do state.platoons[pid] = nil end
      state.moves[mid] = nil
    end
  end
  self:initAllSupply()   -- a phase-1 save gets supply and aircraft stock added
  if self.initOps then
    self:initOps()        -- an older save gets SAM sites, structures and air pools added
    self:returnAllCarried() -- a restart lands every helicopter: troops go home
  end
  if self.initIntel then self:initIntel() end
  return self
end

-- The state to save. The RNG position is stored so dice continue after a restart.
function War:snapshot()
  self.state.rng = self.rng.state
  return self.state
end

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------
function War:log(kind, side, text, extra)
  local ev = { tick = self.state.tick, kind = kind, side = side, text = text }
  if extra then for k, v in pairs(extra) do ev[k] = v end end
  local evs = self.state.events
  evs[#evs + 1] = ev
  while #evs > 100 do table.remove(evs, 1) end
  self.newEvents[#self.newEvents + 1] = ev
  U.debug("[%d] %s", self.state.tick, text)
end

function War:pickRole(job)
  return self.rng:weighted(self.cat.mix[job])
end

function War:newId(prefix)
  local n = self.state.nextId
  self.state.nextId = n + 1
  return prefix .. n
end

function War:newPlatoon(side, role, nodeId)
  local pid = self:newId("p")
  self.state.platoons[pid] = { id = pid, side = side, role = role, health = 1, node = nodeId }
  local ns = self.state.nodes[nodeId]
  ns.platoons[#ns.platoons + 1] = pid
  return pid
end

function War:power(pids)
  local p = 0
  for _, pid in ipairs(pids) do
    local pl = self.state.platoons[pid]
    if pl then p = p + pl.health end
  end
  return p
end

function War:nodeName(id) return self.T.nodes[id].name end
function War:classOf(id) return classOf(self.T.nodes[id]) end

function War:countNodes(side)
  local n = 0
  for _, ns in pairs(self.state.nodes) do if ns.side == side then n = n + 1 end end
  return n
end

-- Depots are the backbone of a side. They can only be attacked once the
-- attacker has no other enemy node within reach of its supplied territory:
-- either the enemy holds nothing else, or what it holds sits behind its depots.
function War:depotsOpen(attacker)
  local enemy = U.otherSide(attacker)
  local supplied = self:supplied(attacker)
  for id, ns in pairs(self.state.nodes) do
    if ns.side == enemy and not self.T.nodes[id].depot then
      for nb in pairs(self.T.nodes[id].nb) do
        -- Only counts if our supply can reach the node we would attack from.
        if self.state.nodes[nb].side == attacker and supplied[nb] then return false end
      end
    end
  end
  return true
end

function War:isNodeLive(id) return self.liveFn ~= nil and self.liveFn(id) == true end
-- A ground move across a sea edge (ships / landing craft): runs on dice only.
function War:onSea(mv)
  return mv.kind ~= "airlift" and self.T.sea[mv.from .. "|" .. mv.to] == true
end

function War:isMoveLive(mv)
  if mv.kind == "airlift" then return self.airLive == true end
  if self:onSea(mv) then return false end
  if self.forcedMoveFn and self.forcedMoveFn(mv.id) then return true end   -- a mission target
  return self:isNodeLive(mv.from) or self:isNodeLive(mv.to)
end

-- Steps from each node to the nearest enemy-held node (breadth-first search
-- over the road graph). 1 = on the front, 2 = one step behind, and so on.
function War:frontDistance(side)
  local dist, queue, head = {}, {}, 1
  for id, ns in pairs(self.state.nodes) do
    if ns.side ~= side then dist[id] = 0; queue[#queue + 1] = id end
  end
  table.sort(queue)
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if dist[nb] == nil then dist[nb] = dist[id] + 1; queue[#queue + 1] = nb end
    end
  end
  return dist
end

function War:movesFrom(id, kind)
  local list = {}
  for _, mv in pairs(self.state.moves) do
    if mv.from == id and (kind == nil or mv.kind == kind) then list[#list + 1] = mv end
  end
  return list
end

function War:movesTo(id, side, kind)
  local list = {}
  for _, mv in pairs(self.state.moves) do
    if mv.to == id and mv.side == side and (kind == nil or mv.kind == kind) then list[#list + 1] = mv end
  end
  return list
end

-- ---------------------------------------------------------------------------
-- Platoon lifecycle
-- ---------------------------------------------------------------------------
function War:destroyPlatoon(pid)
  local pl = self.state.platoons[pid]
  if not pl then return end
  if pl.node then U.removeValue(self.state.nodes[pl.node].platoons, pid) end
  if pl.move and self.state.moves[pl.move] then U.removeValue(self.state.moves[pl.move].platoons, pid) end
  self.state.stats.lost[pl.side] = self.state.stats.lost[pl.side] + 1
  self.state.platoons[pid] = nil
end

-- Spread `loss` (in platoon-health units) over a list in 0.25 chunks.
-- `pids` may be a garrison/move list or a combined copy; destroyed platoons
-- are removed from it either way.
function War:damage(pids, loss)
  local guard = 0
  while loss > 1e-6 and #pids > 0 and guard < 200 do
    guard = guard + 1
    local pid = pids[self.rng:int(#pids)]
    local pl = self.state.platoons[pid]
    local d = math.min(0.25, loss)
    pl.health = pl.health - d
    loss = loss - d
    if pl.health < self.cfg.destroyedBelow then
      self:destroyPlatoon(pid)
      U.removeValue(pids, pid)
    end
  end
end

function War:startMove(kind, side, from, to, pids)
  local mid = self:newId("m")
  local mv = { id = mid, kind = kind, side = side, from = from, to = to,
               platoons = {}, progress = 0, km = self.T.nodes[from].nb[to], status = "moving" }
  for _, pid in ipairs(pids) do
    U.removeValue(self.state.nodes[from].platoons, pid)
    local pl = self.state.platoons[pid]
    pl.node, pl.move = nil, mid
    mv.platoons[#mv.platoons + 1] = pid
  end
  self.state.moves[mid] = mv
  return mv
end

-- Platoons of a move settle into a node's garrison.
function War:joinGarrison(mv)
  local ns = self.state.nodes[mv.to]
  for _, pid in ipairs(mv.platoons) do
    local pl = self.state.platoons[pid]
    pl.move, pl.node = nil, mv.to
    ns.platoons[#ns.platoons + 1] = pid
  end
  self.state.moves[mv.id] = nil
end

-- Remember moves destroyed on the road (for BAI missions), for one hour.
function War:markKilled(mid)
  self.state.killedMoves = self.state.killedMoves or {}
  self.state.killedMoves[mid] = self.state.tick
end

-- ---------------------------------------------------------------------------
-- Tick phases
-- ---------------------------------------------------------------------------
-- Production. Each depot earns points every tick; a full point is a new
-- platoon. The rate scales with ground won or lost since the start (start =
-- base rate), which gives momentum: ground won makes the next push easier,
-- so a war ends instead of see-sawing forever.
function War:startCount(side)
  local n = 0
  for _, id in ipairs(self.T.order) do if self.T.nodes[id].startSide == side then n = n + 1 end end
  return math.max(n, 1)
end

-- Each node gained (or lost) since the start moves the rate by the same
-- amount for both sides, whatever their starting size.
function War:productionFactor(side)
  local gained = self:countNodes(side) - self:startCount(side)
  local factor = 1 + self.cfg.productionPerNode * gained
  factor = U.clamp(factor, self.cfg.productionMinFactor, self.cfg.productionMaxFactor)
  return factor * (self.balance[side] or 1)   -- per-theater balance knob
end

-- Depot output also drops with strike damage to its buildings (dcc_ops.lua).
function War:depotFactor(id)
  local side = self.state.nodes[id].side
  local f = self:productionFactor(side)
  if self.infraFactor then f = f * self:infraFactor(id) end
  return f
end

function War:produce()
  self.state.prodPoints = self.state.prodPoints or {}
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    if tn.depot then
      local factor = self:depotFactor(id)
      local pts = (self.state.prodPoints[id] or 0) + factor / self.cfg.depotProductionEveryTicks
      while pts >= 1 and #ns.platoons < self.cfg.garrisonMax.depot do
        self:newPlatoon(ns.side, self:pickRole("garrison"), id)
        self.state.stats.produced[ns.side] = self.state.stats.produced[ns.side] + 1
        pts = pts - 1
      end
      self.state.prodPoints[id] = math.min(pts, 1) -- a full depot does not bank points
    end
  end
end

function War:arrive(mv)
  if mv.cargo then return self:deliver(mv) end
  local ns = self.state.nodes[mv.to]
  if ns.side == mv.side then
    self:joinGarrison(mv)
  else
    mv.status, mv.progress = "fighting", 1
    self:log("battle", mv.side, string.format("%s forces attack %s", mv.side:upper(), self:nodeName(mv.to)), { node = mv.to })
  end
end

function War:advanceMoves()
  local kmPerTick = self.cfg.groundSpeedKmh * self.cfg.tickSeconds / 3600
  local airKmPerTick = self.cfg.supply.airliftSpeedKmh * self.cfg.tickSeconds / 3600
  local heloKmPerTick = (self.cfg.supply.heliliftSpeedKmh or 200) * self.cfg.tickSeconds / 3600
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv and mv.status == "moving" then
      if #mv.platoons == 0 and not mv.cargo then
        self:markKilled(mid)
        self.state.moves[mid] = nil
      else
        -- Live moves are advanced by the bridge from real unit positions.
        local step = (mv.kind == "airlift") and (mv.helo and heloKmPerTick or airKmPerTick) or kmPerTick
        if self.moveSpeedFactor then step = step * self:moveSpeedFactor(mv) end   -- weather
        if not self:isMoveLive(mv) then mv.progress = mv.progress + step / math.max(mv.km, 0.1) end
        if mv.progress >= 1 then self:arrive(mv) end
      end
    end
  end
end

function War:capture(mv, carried)
  local ns = self.state.nodes[mv.to]
  local old = ns.side
  ns.side = mv.side
  self:joinGarrison(mv)
  self:onCaptureSupply(mv.to, carried)
  self.state.stats.captures[mv.side] = self.state.stats.captures[mv.side] + 1
  self:log("capture", mv.side, string.format("%s captured %s from %s",
    mv.side:upper(), self:nodeName(mv.to), old:upper()), { node = mv.to, from = old })
  if self.onCaptureOps then self:onCaptureOps(mv.to) end
end

-- One round of dice for every attacker at a node against its garrison.
-- All assault groups that have arrived fight as one force.
function War:abstractRound(target, attackers)
  local ns = self.state.nodes[target]
  local combined = {}
  for _, mv in ipairs(attackers) do
    for _, pid in ipairs(mv.platoons) do combined[#combined + 1] = pid end
  end
  local bonus = self:bonusOf(target)
  local A = self:power(combined)
  local D = self:power(ns.platoons) * bonus
  local rate = self.cfg.battleLossRate * (self.battleFactor and self:battleFactor() or 1)
  local attLoss = D * rate * self.rng:range(0.6, 1.4)
  local defLoss = A * rate * self.rng:range(0.6, 1.4)
  self:damage(combined, attLoss)
  self:damage(ns.platoons, defLoss)
end

-- Decide every fight. Outcomes are logged as events.
function War:resolveBattles()
  -- Group arrived assaults by the node they are attacking.
  local byTarget = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.status == "fighting" then
      byTarget[mv.to] = byTarget[mv.to] or {}
      table.insert(byTarget[mv.to], mv)
    end
  end

  for _, target in ipairs(U.sortedKeys(byTarget)) do
    local ns = self.state.nodes[target]
    local attackers = {}
    for _, mv in ipairs(byTarget[target]) do
      if mv.side == ns.side then self:joinGarrison(mv)   -- node is already ours
      else attackers[#attackers + 1] = mv end
    end

    if #attackers > 0 then
      if #ns.platoons > 0 then
        if not self:isNodeLive(target) then
          ns.liveFight = nil
          self:abstractRound(target, attackers)
        else
          -- DCS is fighting this one. If spawned units get stuck and nothing
          -- dies for a while, roll one round of dice so it cannot hang forever.
          ns.liveFight = (ns.liveFight or 0) + 1
          if ns.liveFight % self.cfg.liveStallTicks == 0 then self:abstractRound(target, attackers) end
        end
      end
      local alive = {}
      for _, mv in ipairs(attackers) do
        if #mv.platoons > 0 then alive[#alive + 1] = mv else self.state.moves[mv.id] = nil end
      end
      if #alive == 0 then
        self:log("repulsed", ns.side, string.format("%s held %s against a %s assault",
          ns.side:upper(), self:nodeName(target), attackers[1].side:upper()), { node = target })
      elseif #ns.platoons == 0 then
        local carried = 0
        for _, mv in ipairs(alive) do carried = carried + (mv.carried or 0) end
        self:capture(alive[1], carried)
        for i = 2, #alive do self:joinGarrison(alive[i]) end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Planning: each side's commander. Phase 2 gates it on supply: an attack
-- costs supply at the node it starts from (see dcc_supply.lua).
-- ---------------------------------------------------------------------------
function War:sortedGarrison(id, forAssault)
  local list = {}
  for _, pid in ipairs(self.state.nodes[id].platoons) do list[#list + 1] = pid end
  local P = self.state.platoons
  table.sort(list, function(a, b)
    if forAssault then
      local ra, rb = ROLE_ORDER[P[a].role] or 9, ROLE_ORDER[P[b].role] or 9
      if ra ~= rb then return ra < rb end
    end
    if P[a].health ~= P[b].health then return P[a].health > P[b].health end
    return a < b
  end)
  return list
end

-- Concentration of force: for each enemy node, every friendly neighbour that
-- is not already attacking offers its spare platoons. The target with the
-- best combined odds is attacked from all of them at once; repeat until no
-- target is worth it. Massing on one point is what breaks a stalemate,
-- because the defender has to spread over the whole front.
function War:planAssaults(side, dist, focus)
  local enemy = U.otherSide(side)
  local depotsOpen = self:depotsOpen(side)
  local used = {}

  local function offer(nodeId, isFocus)
    local ns = self.state.nodes[nodeId]
    -- Platoons that can attack: spare ones, and only as many as the node can supply.
    local available = math.min(#ns.platoons - self.cfg.frontKeep, self:assaultAffordable(nodeId))
    if available <= 0 or used[nodeId] or #self:movesFrom(nodeId, "assault") > 0 then return nil end
    -- The main effort commits everything it staged; other attacks are capped.
    local limit = isFocus and available or math.min(self.cfg.assaultMax, available)
    local sorted, picked = self:sortedGarrison(nodeId, true), {}
    for i = 1, limit do picked[i] = sorted[i] end
    return picked
  end

  -- Are the staging areas for the main effort full? Then waiting gains nothing.
  local function stagingFull(target)
    for nb in pairs(self.T.nodes[target].nb) do
      local nns = self.state.nodes[nb]
      if nns.side == side then
        local scap = self.cfg.garrisonMax[self:classOf(nb)] * self.cfg.stagingCapFactor
        if #nns.platoons + self:incoming(nb, side) < scap then return false end
      end
    end
    return true
  end

  while true do
    local best
    for _, target in ipairs(self.T.order) do
      local tns, ttn = self.state.nodes[target], self.T.nodes[target]
      local allowed = tns.side == enemy and (not ttn.depot or depotsOpen)
      if allowed and #self:movesTo(target, side, "assault") == 0 then
        local isFocus = (target == focus)
        local groups, count, A = {}, 0, 0
        for _, nb in ipairs(U.sortedKeys(ttn.nb)) do
          if self.state.nodes[nb].side == side then
            local picked = offer(nb, isFocus)
            if picked then
              groups[#groups + 1] = { from = nb, pids = picked }
              count = count + #picked
              A = A + self:power(picked)
            end
          end
        end
        if count >= self.cfg.assaultMin then
          local odds = A / math.max(self:defenceOf(target), 0.1)
          local need = self.cfg.assaultOdds
          if isFocus then
            -- Attack at lower odds when waiting gains nothing: staging is full,
            -- or the main effort has been building for focusPatienceTicks.
            local f = self.state.focus and self.state.focus[side]
            local age = f and (self.state.tick - f.since) or 0
            if stagingFull(target) or age >= self.cfg.focusPatienceTicks then
              need = self.cfg.assaultOddsStalled
            end
          end
          local score = odds / need
          if not best or score > best.score then
            best = { target = target, groups = groups, odds = odds, count = count, score = score }
          end
        end
      end
    end

    if not best or best.score < 1 then break end
    for _, g in ipairs(best.groups) do
      local carried = self:payAssault(g.from, #g.pids)
      local mv = self:startMove("assault", side, g.from, best.target, g.pids)
      mv.carried = carried
      used[g.from] = true
    end
    self:log("assault", side, string.format("%s launches %d platoons from %d node(s) toward %s (odds %.1f)",
      side:upper(), best.count, #best.groups, self:nodeName(best.target), best.odds))
  end
end

-- ---------------------------------------------------------------------------
-- Main effort ("focus"): each side picks one enemy node to break. Friendly
-- nodes next to it become staging areas that may hold far more than their
-- normal cap, and spare platoons from the whole side flow there. Without a
-- main effort, equal caps plus the defender bonus give a permanent stalemate.
-- ---------------------------------------------------------------------------
function War:defenceOf(target)
  local ns = self.state.nodes[target]
  local d = self:power(ns.platoons)
  for _, rmv in ipairs(self:movesTo(target, ns.side, "reinforce")) do d = d + self:power(rmv.platoons) end
  return d * self:bonusOf(target)
end

-- Nodes a side can supply: reachable from one of its depots over its own nodes.
-- A pocket cut off from every depot gets no reinforcements.
function War:supplied(side)
  local seen, queue, head = {}, {}, 1
  for _, id in ipairs(self.T.order) do
    if self.T.nodes[id].depot and self.state.nodes[id].side == side then
      seen[id] = true; queue[#queue + 1] = id
    end
  end
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if not seen[nb] and self.state.nodes[nb].side == side then seen[nb] = true; queue[#queue + 1] = nb end
    end
  end
  return seen
end

function War:chooseFocus(side)
  self.state.focus = self.state.focus or {}
  local enemy = U.otherSide(side)
  local f = self.state.focus[side]
  local supplied = self:supplied(side)
  -- A main effort must be stageable from a node our supply can reach.
  local function valid(target)
    local tns, ttn = self.state.nodes[target], self.T.nodes[target]
    if not tns or tns.side ~= enemy then return false end
    if ttn.depot and not self:depotsOpen(side) then return false end
    for nb in pairs(ttn.nb) do
      if self.state.nodes[nb].side == side and supplied[nb] then return true end
    end
    return false
  end
  if f and valid(f.target) and self.state.tick - f.since < self.cfg.focusTicks then return f.target end
  -- Weakest reachable enemy node; ties broken by name for reproducible runs.
  local best, bestD
  for _, target in ipairs(self.T.order) do
    if valid(target) then
      local d = self:defenceOf(target) + self.rng:range(0, 0.5) -- a little noise avoids predictability
      if not bestD or d < bestD then best, bestD = target, d end
    end
  end
  self.state.focus[side] = best and { target = best, since = self.state.tick } or nil
  if best and (not f or f.target ~= best) then
    self:log("focus", side, string.format("%s shifts its main effort toward %s", side:upper(), self:nodeName(best)))
  end
  return best
end

-- Friendly steps from each node to the nearest staging node (next to the focus).
function War:stagingDistance(side, focus)
  local dist, queue, head = {}, {}, 1
  if not focus then return dist end
  for nb in pairs(self.T.nodes[focus].nb) do
    if self.state.nodes[nb].side == side then dist[nb] = 0; queue[#queue + 1] = nb end
  end
  table.sort(queue)
  while head <= #queue do
    local id = queue[head]; head = head + 1
    for nb in pairs(self.T.nodes[id].nb) do
      if dist[nb] == nil and self.state.nodes[nb].side == side then
        dist[nb] = dist[id] + 1; queue[#queue + 1] = nb
      end
    end
  end
  return dist
end

function War:incoming(id, side)
  local n = 0
  for _, rmv in ipairs(self:movesTo(id, side, "reinforce")) do n = n + #rmv.platoons end
  return n
end

-- How many platoons a node holds on to before it passes any on.
--   front node : its max plus the front staging allowance
--   staging    : its max x stagingCapFactor (it never passes on)
--   depot      : a small reserve
--   rear node  : a token garrison
function War:keepLevel(id, side, dist, sdist)
  local tn = self.T.nodes[id]
  local max = self.cfg.garrisonMax[classOf(tn)]
  if sdist[id] == 0 then return max * self.cfg.stagingCapFactor end
  if dist[id] == 1 then return max + self.cfg.frontStaging end
  if tn.depot then return self.cfg.rearKeep + 2 end
  return self.cfg.rearKeep
end

-- Reinforcement flow. A node passes on whatever it holds above its keep level:
--   (a) to a neighbour nearer the front that is below ITS keep level, else
--   (b) toward the main effort, to a neighbour nearer the staging nodes.
-- Because (a) only fills a node up to the level at which it would start
-- passing platoons on, a column is never sent straight back (no ping-pong).
function War:planReinforcements(side, dist, focus)
  local sdist = self:stagingDistance(side, focus)
  local cols = self.cfg.reinforceColumnMax
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    local d, sd = dist[id], sdist[id]
    if ns.side == side and sd ~= 0 then
      local surplus = #ns.platoons - self:keepLevel(id, side, dist, sdist)
      if surplus > 0 then
        local best, bestKey
        for _, nb in ipairs(U.sortedKeys(tn.nb)) do
          local nns = self.state.nodes[nb]
          if nns.side == side then
            local held = #nns.platoons + self:incoming(nb, side)
            local keep = self:keepLevel(nb, side, dist, sdist)
            -- (a) fill toward the front
            if d and dist[nb] and dist[nb] < d and held < keep then
              local key = dist[nb] * 100 - (keep - held)
              if not bestKey or key < bestKey then best, bestKey = { id = nb, room = keep - held }, key end
            end
            -- (b) toward the main effort; pass-through nodes take a small buffer
            if not best and sd and sdist[nb] and sdist[nb] < sd then
              local room = (sdist[nb] == 0) and (keep - held) or (keep + 2 * cols - held)
              if room > 0 then
                local key = 10000 + sdist[nb] * 100 - room
                if not bestKey or key < bestKey then best, bestKey = { id = nb, room = room }, key end
              end
            end
          end
        end
        if best then
          local n = math.min(surplus, best.room, cols)
          local sorted = self:sortedGarrison(id, true)
          local picked = {}
          for i = 1, n do picked[i] = sorted[i] end
          self:startMove("reinforce", side, id, best.id, picked)
        end
      end
    end
  end
end

-- Who flew for which side in this war (saved with the war; read at victory).
-- startScore: the pilot's career score at their first sortie of this war, so
-- the war report can show what they scored in this war alone.
local function rosterEntry(self, key, name, startScore)
  self.state.roster = self.state.roster or {}
  local r = self.state.roster[key]
  if not r then
    r = { name = name, blue = 0, red = 0, blue_missions = 0, red_missions = 0, start = startScore }
    self.state.roster[key] = r
  end
  r.name = name or r.name
  return r
end

function War:recordSortie(key, side, name, startScore)
  local r = rosterEntry(self, key, name, startScore)
  r[side] = (r[side] or 0) + 1
end

function War:recordMissionDone(key, side, name)
  local r = rosterEntry(self, key, name)
  r[side .. "_missions"] = (r[side .. "_missions"] or 0) + 1
end

-- Did this pilot do enough for this side to share its victory?
function War.earnedVictory(r, side, minSorties)
  return (r[side] or 0) >= (minSorties or 1) or (r[side .. "_missions"] or 0) >= 1
end

-- End the war: the loser's stray units are removed so one lost truck cannot stall the end.
function War:declareWinner(winner, how)
  local loser = U.otherSide(winner)
  self.state.winner, self.state.winBy = winner, how
  if how == "conquest" then
    for pid, pl in pairs(self.state.platoons) do
      if pl.side == loser then self:destroyPlatoon(pid) end
    end
    for mid, mv in pairs(self.state.moves) do
      if mv.side == loser then self.state.moves[mid] = nil end
    end
  end
  local s = self:summary()
  local days = (self.state.tick - (self.state.clockStart or 0)) * self.cfg.tickSeconds / 86400
  self:log("victory", winner, string.format("%s wins the war on %s %s after %.1f days (BLUE %d bases, RED %d bases; %s %+d since the start)",
    winner:upper(), self.T.name, how == "conquest" and "by conquest" or "on the war clock", days,
    s.blue.nodes, s.red.nodes, winner:upper(), self:groundGained(winner)))
end

-- War clock: the war ends after cfg.warClockDays. The side that has GAINED
-- more ground since the start wins (bases held now minus bases held at the
-- start), so a map where one side starts bigger stays fair. A tie goes to the
-- stronger army, then to the larger stock of supply.
function War:clockTicksLeft()
  local days = self.noSave and self.cfg.warClockDaysNoSave or self.cfg.warClockDays
  if not days or days <= 0 then return nil end
  local limit = math.floor(days * 86400 / self.cfg.tickSeconds + 0.5)
  return limit - (self.state.tick - (self.state.clockStart or 0))
end

function War:groundGained(side)
  local n = 0
  for _, id in ipairs(self.T.order) do if self.state.nodes[id].side == side then n = n + 1 end end
  local start = 0
  for _, id in ipairs(self.T.order) do if self.T.nodes[id].startSide == side then start = start + 1 end end
  return n - start
end

function War:clockLeader()
  local power, sup = { blue = 0, red = 0 }, self:supplySummary()
  for _, pl in pairs(self.state.platoons) do power[pl.side] = power[pl.side] + pl.health end
  local gb = self:groundGained("blue")     -- RED's gain is exactly -gb
  if gb ~= 0 then return gb > 0 and "blue" or "red" end
  if math.abs(power.blue - power.red) > 1e-6 then return power.blue > power.red and "blue" or "red" end
  return sup.blue >= sup.red and "blue" or "red"
end

local CLOCK_WARNINGS = { { 24, "24 hours" }, { 6, "6 hours" }, { 1, "1 hour" } }

function War:checkVictory()
  if self.state.winner then return end
  for _, side in ipairs(SIDES) do
    if self:countNodes(side) == 0 then self:declareWinner(U.otherSide(side), "conquest"); return end
  end
  local left = self:clockTicksLeft()
  if not left then return end
  local perHour = 3600 / self.cfg.tickSeconds
  for _, w in ipairs(CLOCK_WARNINGS) do
    local text = w[2]
    if left == math.floor(w[1] * perHour + 0.5) then
      local lead = self:clockLeader()
      self:log("clock", nil, string.format("War clock: %s left on %s. %s has gained ground (%+d bases since the start) and wins if it stays that way.",
        text, self.T.name, lead:upper(), math.abs(self:groundGained("blue"))))
    end
  end
  if left <= 0 then self:declareWinner(self:clockLeader(), "clock") end
end

-- One war step. Returns the events that happened in it, plus any logged
-- since the last tick by the bridge (rescues, crate drops), so missions
-- can be judged on them.
function War:tick()
  if self.state.winner then self.newEvents = {}; return {} end
  self.state.clockStart = self.state.clockStart or (self.state.tick > 0 and self.state.tick or 0)  -- older saves start their clock now
  self.state.tick = self.state.tick + 1
  self:produce()
  self:produceSupply()
  self:advanceMoves()
  self:resolveBattles()
  self:upkeep()
  self:restockAircraft()
  if self.opsTick then self:opsTick() end
  if self.intelTick then self:intelTick() end
  if self.missionsTick then self:missionsTick() end
  self:checkVictory()
  if not self.state.winner then
    -- Alternate which side plans first so neither always gets first pick.
    local order = (self.state.tick % 2 == 0) and { "blue", "red" } or { "red", "blue" }
    for _, side in ipairs(order) do
      local dist = self:frontDistance(side)
      local focus = self:chooseFocus(side)
      self:planAssaults(side, dist, focus)
      self:planReinforcements(side, dist, focus)
      self:planConvoys(side, dist, focus)
      self:planAirlifts(side, dist, focus)
    end
  end
  local evs = self.newEvents
  self.newEvents = {}
  return evs
end

-- ---------------------------------------------------------------------------
-- Bridge API: how live DCS results flow back into the model
-- ---------------------------------------------------------------------------
-- Health of a spawned platoon after polling its DCS group (0..1).
function War:setHealth(pid, health)
  local pl = self.state.platoons[pid]
  if not pl then return end
  pl.health = math.min(pl.health, health)
  if pl.health < self.cfg.destroyedBelow then self:destroyPlatoon(pid) end
end

-- Progress (0..1) of a live move, measured from its lead vehicle's position.
function War:setProgress(mid, progress)
  local mv = self.state.moves[mid]
  if mv and mv.status == "moving" then mv.progress = U.clamp(progress, mv.progress, 1) end
end

-- Totals per side for status messages.
function War:summary()
  local s = { blue = { nodes = 0, platoons = 0 }, red = { nodes = 0, platoons = 0 } }
  for _, ns in pairs(self.state.nodes) do s[ns.side].nodes = s[ns.side].nodes + 1 end
  for _, pl in pairs(self.state.platoons) do s[pl.side].platoons = s[pl.side].platoons + 1 end
  return s
end

end

-- >>> src/dcc_supply.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - supply economy (phase 2, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Adds supply to the war model. Load after dcc_war.lua.
--
-- Concepts
--   supply (SU) : one number per node - fuel, ammunition and spares together.
--   depot       : produces supply every tick (scaled like platoon production).
--   upkeep      : every platoon uses a little supply each tick where it sits.
--                 A node at 0 supply is OUT OF SUPPLY: its platoons lose
--                 health every tick and it defends without its bonus.
--                 (This replaces phase 1's "cut off" rule: a pocket that no
--                 convoy can reach simply runs dry.)
--   assault     : launching an attack costs supply per platoon at the node it
--                 starts from. No supply at the front = no attack.
--   convoy      : trucks carrying supply one road edge at a time, from nodes
--                 with surplus toward the front and the main effort. Near
--                 players they are real DCS trucks - kill them and the cargo
--                 never arrives.
--   airlift     : a transport aircraft carrying supply between two friendly
--                 airbases, any distance. Feeds cut-off airbases. Always a
--                 real aircraft in DCS, so it can be intercepted anywhere.
--   aircraft    : player aircraft stock per airbase (dynamic spawn). The
--                 bridge mirrors it into the DCS warehouse. Lost aircraft
--                 are replaced over time, paid for in supply - only at a
--                 supplied base.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function S(self) return self.cfg.supply end

-- ---------------------------------------------------------------------------
-- Node supply helpers
-- ---------------------------------------------------------------------------
function War:supplyCap(id)
  return S(self).cap[self:classOf(id)]
end

function War:hasSupply(id)
  return (self.state.nodes[id].supply or 0) > 0
end

-- Defender bonus only counts for a node that still has supply.
function War:bonusOf(id)
  if not self:hasSupply(id) then return 1 end
  return self.cfg.defenderBonus[self:classOf(id)]
end

function War:incomingSupply(id, side)
  local n = 0
  for _, mv in pairs(self.state.moves) do
    if mv.to == id and mv.side == side and mv.cargo then n = n + mv.cargo * (mv.health or 1) end
  end
  -- rounded: the sum runs in hash order, which differs after a restore
  return math.floor(n * 1e6 + 0.5) / 1e6
end

-- Owner's player aircraft types (from the catalog), as a flat list.
function War:aircraftTypes(side)
  local air = self.cat.aircraft and self.cat.aircraft[side]
  local list = {}
  if air then
    for _, t in ipairs(air.planes or {}) do list[#list + 1] = t end
    for _, t in ipairs(air.helicopters or {}) do list[#list + 1] = t end
  end
  return list
end

function War:airTarget(id)
  local st = self.cat.aircraftStock or { airbase = 4, depot = 8 }
  return self.T.nodes[id].depot and st.depot or st.airbase
end

-- Fresh stock for a node: full at war start, empty after a capture.
function War:initNodeSupply(id, fresh)
  local ns, tn = self.state.nodes[id], self.T.nodes[id]
  if ns.supply == nil then
    ns.supply = math.max(S(self).startSU or 0, self:supplyCap(id) * S(self).startFraction)
  end
  if tn.kind == "airbase" and (ns.air == nil or fresh ~= nil) then
    ns.air = {}
    local n = (fresh == "empty") and 0 or self:airTarget(id)
    for _, t in ipairs(self:aircraftTypes(ns.side)) do ns.air[t] = n end
  end
end

function War:initAllSupply()
  for _, id in ipairs(self.T.order) do self:initNodeSupply(id) end
  self.state.stats.delivered = self.state.stats.delivered or { blue = 0, red = 0 }
  self.state.stats.cargoLost = self.state.stats.cargoLost or { blue = 0, red = 0 }
end

-- ---------------------------------------------------------------------------
-- Production and upkeep
-- ---------------------------------------------------------------------------
function War:produceSupply()
  local cfg = S(self)
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    if tn.depot then
      ns.supply = math.min(self:supplyCap(id), ns.supply + cfg.depotPerTick * self:depotFactor(id))
    end
  end
end

function War:upkeep()
  local cfg = S(self)
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local need = #ns.platoons * cfg.upkeepPerPlatoon
    if need > 0 then
      if ns.supply >= need then
        ns.supply = ns.supply - need
        ns.outOfSupply = nil
      else
        ns.supply = 0
        if not ns.outOfSupply then
          ns.outOfSupply = true
          self:log("nosupply", ns.side, string.format("%s garrison at %s is out of supply",
            ns.side:upper(), self:nodeName(id)))
        end
        for i = #ns.platoons, 1, -1 do
          local pid = ns.platoons[i]
          local pl = self.state.platoons[pid]
          pl.health = pl.health - cfg.outOfSupplyAttrition
          if pl.health < self.cfg.destroyedBelow then self:destroyPlatoon(pid) end
        end
      end
    end
  end
end

-- Lost player aircraft come back one at a time, paid for in supply.
function War:restockAircraft()
  local cfg = S(self)
  -- v0.38: every own type at least airMinStock at every airbase, free and every tick (a captured
  -- base starts empty, players use them up, an old save lacks newer types): never a type with
  -- nothing to spawn
  local min = cfg.airMinStock or 0
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.air and (ns.side == "blue" or ns.side == "red") then
      for _, t in ipairs(self:aircraftTypes(ns.side)) do
        if ns.air[t] == nil then ns.air[t] = self:airTarget(id) end          -- a type added since the save
        if ns.air[t] < min then ns.air[t] = min end
      end
    end
  end
  if self.state.tick % cfg.airRestockTicks ~= 0 then return end
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local intact = not self.infraFactor or self:infraFactor(id) > 0.5
    if ns.air and intact and ns.supply >= cfg.airRestockCost then
      local target, lowest, lowType = self:airTarget(id), nil, nil
      for _, t in ipairs(self:aircraftTypes(ns.side)) do
        local n = ns.air[t] or 0
        if n < target and (not lowest or n < lowest) then lowest, lowType = n, t end
      end
      if lowType then
        ns.air[lowType] = (ns.air[lowType] or 0) + 1
        ns.supply = ns.supply - cfg.airRestockCost
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Cargo moves (convoys and airlifts)
-- ---------------------------------------------------------------------------
function War:startCargo(kind, side, from, to, amount)
  local ns = self.state.nodes[from]
  amount = math.min(amount, ns.supply)
  if amount <= 0 then return nil end
  ns.supply = ns.supply - amount
  local km = self.T.nodes[from].nb[to] or U.distKm(self.T.nodes[from], self.T.nodes[to])
  local mid = self:newId(kind == "airlift" and "a" or "c")
  local mv = { id = mid, kind = kind, side = side, from = from, to = to, platoons = {},
               cargo = amount, health = 1, progress = 0, km = km, status = "moving" }
  self.state.moves[mid] = mv
  return mv
end

-- A cargo move arrives: friendly destination gets it, anything else loses it.
function War:deliver(mv)
  local ns = self.state.nodes[mv.to]
  if self.ambushCheck then self:ambushCheck(mv) end
  local amount = mv.cargo * (mv.health or 1)
  if ns.side == mv.side then
    self.state.deliveredMoves = self.state.deliveredMoves or {}
    self.state.deliveredMoves[mv.id] = { tick = self.state.tick, health = mv.health or 1 }
    ns.supply = math.min(self:supplyCap(mv.to) * S(self).overfillFactor, ns.supply + amount)
    self.state.stats.delivered[mv.side] = self.state.stats.delivered[mv.side] + amount
    if mv.kind == "airlift" then
      self:log("airlift_in", mv.side, string.format("%s %s landed at %s with %d supply",
        mv.side:upper(), mv.helo and "supply helicopter" or "airlift", self:nodeName(mv.to), math.floor(amount + 0.5)))
    end
  else
    self.state.stats.cargoLost[mv.side] = self.state.stats.cargoLost[mv.side] + amount
    self:log("cargo_lost", mv.side, string.format("%s %s to %s lost: the destination fell",
      mv.side:upper(), mv.kind, self:nodeName(mv.to)))
  end
  self.state.moves[mv.id] = nil
end

-- A convoy or airlift destroyed (by players, or by the bridge on total loss).
function War:destroyCargo(mid, reason)
  local mv = self.state.moves[mid]
  if not mv or not mv.cargo then return end
  self:markKilled(mid)
  self.state.stats.cargoLost[mv.side] = self.state.stats.cargoLost[mv.side] + mv.cargo * (mv.health or 1)
  self.state.moves[mid] = nil
  self:log(mv.kind == "airlift" and "airlift_lost" or "convoy_lost", mv.side,
    string.format("%s %s from %s to %s destroyed%s", mv.side:upper(), mv.helo and "supply helicopter" or mv.kind,
      self:nodeName(mv.from), self:nodeName(mv.to), reason and (" (" .. reason .. ")") or ""))
end

-- Share of a live convoy's trucks (or airlift aircraft) still alive.
function War:setCargoHealth(mid, health)
  local mv = self.state.moves[mid]
  if not mv or not mv.cargo then return end
  mv.health = math.min(mv.health or 1, health)
  if mv.health <= 0 then self:destroyCargo(mid, "all vehicles lost") end
end

-- ---------------------------------------------------------------------------
-- Planning
-- ---------------------------------------------------------------------------
-- Supply a node holds before it passes any on (same idea as keepLevel).
-- Never less than keepHours of upkeep for the platoons actually there.
function War:supplyKeep(id, dist, sdist)
  local cfg, tn = S(self), self.T.nodes[id]
  local cap = self:supplyCap(id)
  local level
  if sdist[id] == 0 then level = cap * cfg.stagingFactor
  elseif dist[id] == 1 then level = cap
  elseif tn.depot then level = cfg.depotReserve
  else level = cfg.rearKeep end
  local ticks = cfg.keepHours * 3600 / self.cfg.tickSeconds
  local upkeep = #self.state.nodes[id].platoons * cfg.upkeepPerPlatoon * ticks
  return math.max(level, upkeep)
end

-- Convoys: each node sends at most one convoy per tick, carrying what it
-- holds above its keep level, to the neighbour that needs it most, nearer
-- the front (or nearer the main effort when the front is full).
function War:planConvoys(side, dist, focus)
  local cfg = S(self)
  local sdist = self:stagingDistance(side, focus)
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    local d, sd = dist[id], sdist[id]
    local out = 0
    for _, mv in pairs(self.state.moves) do if mv.from == id and mv.kind == "convoy" then out = out + 1 end end
    if ns.side == side and sd ~= 0 and out < cfg.convoysPerNode then
      local surplus = ns.supply - self:supplyKeep(id, dist, sdist)
      if surplus >= cfg.convoyMin then
        local best, bestKey
        for _, nb in ipairs(U.sortedKeys(tn.nb)) do
          if self.state.nodes[nb].side == side then
            local held = self.state.nodes[nb].supply + self:incomingSupply(nb, side)
            local keep = self:supplyKeep(nb, dist, sdist)
            if d and dist[nb] and dist[nb] < d and held < keep then
              local key = dist[nb] * 1000 - (keep - held) + (self.routeCost and self:routeCost(side, id, nb) or 0)
              if not bestKey or key < bestKey then best, bestKey = { id = nb, room = keep - held }, key end
            end
            if not best and sd and sdist[nb] and sdist[nb] < sd then
              local room = keep + cfg.convoyCapacity * 2 - held
              if room > 0 then
                local key = 100000 + sdist[nb] * 1000 - room + (self.routeCost and self:routeCost(side, id, nb) or 0)
                if not bestKey or key < bestKey then best, bestKey = { id = nb, room = room }, key end
              end
            end
          end
        end
        if best then
          local mv = self:startCargo("convoy", side, id, best.id, math.min(surplus, best.room, cfg.convoyCapacity))
          if mv and dist[best.id] == 1 then mv.front = true end   -- last leg to the front: ambush risk
        end
      end
    end
  end
end

-- Airlifts: a few per side at a time. Source = the friendly airbase with the
-- biggest surplus; destination = the friendly airbase with the biggest need,
-- cut-off airbases first. Only worth flying beyond airliftMinKm.
function War:planAirlifts(side, dist, focus)
  local cfg = S(self)
  local active = 0
  for _, mv in pairs(self.state.moves) do
    if mv.kind == "airlift" and mv.side == side then active = active + 1 end
  end
  if active >= cfg.maxAirlifts then return end
  local sdist = self:stagingDistance(side, focus)
  local supplied = self:supplied(side)

  local src, srcSurplus
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    if ns.side == side and tn.kind == "airbase" then
      local surplus = ns.supply - self:supplyKeep(id, dist, sdist)
      if surplus >= cfg.airliftCapacity and (not srcSurplus or surplus > srcSurplus) then
        src, srcSurplus = id, surplus
      end
    end
  end
  if not src then return end

  local dst, dstKey
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    if id ~= src and ns.side == side and tn.kind == "airbase" then
      local need = self:supplyKeep(id, dist, sdist) - ns.supply - self:incomingSupply(id, side)
      local km = U.distKm(self.T.nodes[src], tn)
      local cutOff = not supplied[id]
      if need >= cfg.airliftCapacity * 0.5 and (cutOff or km >= cfg.airliftMinKm) then
        local key = (cutOff and 0 or 1) * 100000 - need
        if not dstKey or key < dstKey then dst, dstKey = id, key end
      end
    end
  end
  if not dst then return end
  local mv = self:startCargo("airlift", side, src, dst, cfg.airliftCapacity)
  if mv then
    self:log("airlift", side, string.format("%s airlift departs %s for %s", side:upper(),
      self:nodeName(src), self:nodeName(dst)))
  end
end

-- What a node can afford to send into an assault.
-- Only supply above a reserve for the garrison that stays behind can be
-- spent, so an attack never leaves its start node out of supply.
function War:assaultAffordable(id)
  local cfg, ns = S(self), self.state.nodes[id]
  local ticks = cfg.keepHours * 3600 / self.cfg.tickSeconds
  local reserve = self.cfg.frontKeep * cfg.upkeepPerPlatoon * ticks
  return math.max(0, math.floor(((ns.supply or 0) - reserve) / cfg.assaultCostPerPlatoon))
end

-- Returns the supply the attackers carry with them (dropped into the node
-- they capture, so a fresh conquest is not instantly out of supply).
function War:payAssault(id, count)
  local ns, cfg = self.state.nodes[id], S(self)
  local cost = count * cfg.assaultCostPerPlatoon
  ns.supply = math.max(0, ns.supply - cost)
  return cost * cfg.assaultCarryShare
end

-- On capture: the new owner seizes part of the stores; airbase stock is lost.
function War:onCaptureSupply(id, carried)
  local ns = self.state.nodes[id]
  ns.supply = ns.supply * S(self).captureShare + (carried or 0)
  ns.outOfSupply = nil
  self:initNodeSupply(id, "empty")
end

-- Bridge API: aircraft count at an airbase as read from the DCS warehouse.
function War:setAircraft(id, typeName, count)
  local ns = self.state.nodes[id]
  if ns and ns.air and ns.air[typeName] ~= nil then ns.air[typeName] = math.max(0, count) end
end

-- Totals per side (for status messages and the plot).
function War:supplySummary()
  local s = { blue = 0, red = 0 }
  for _, ns in pairs(self.state.nodes) do s[ns.side] = s[ns.side] + (ns.supply or 0) end
  return s
end

end

-- >>> src/dcc_ops.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - operations state (phase 3, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Everything players can hit or help, as numbers in the save. Load after
-- dcc_supply.lua. The DCS bridge (dcc_dcs_ops.lua) spawns these as real
-- objects and reports back what happened to them.
--
--   SAM site    : airbases and depots have an air-defence site.
--                 up -> suppressed (radar killed; back in ~2 h for a little
--                 supply) -> destroyed (radar and launchers; rebuilt in ~6 h
--                 for a lot of supply). A captured site is destroyed and the
--                 new owner builds its own.
--   Structures  : fuel, ammo and warehouse buildings at depots and airbases
--                 (strike targets). Each one destroyed burns supply and cuts
--                 the node's output; one is repaired every few hours.
--   Air pools   : each side's AI fighters and attack aircraft (abstract
--                 squadrons). AI sorties draw from them; losses are real;
--                 depots pay supply to replace them.
--   Air cover   : a side that flew CAP over a node holds air superiority there
--                 for an hour - enemy AI attack sorties stay away.
--   Intel       : what a side's recon last saw at an enemy node.
--   Carried     : platoons inside a player helicopter (airmobile troops).
--   Downed      : ejected pilots waiting for CSAR.
--   Ambush      : the last convoy leg to the front can be ambushed when
--                 nobody escorts it (abstract, away from players).
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function O(self) return self.cfg.ops end

-- ---------------------------------------------------------------------------
-- Initialisation (new wars, and older saves on restore)
-- ---------------------------------------------------------------------------
function War:initOps()
  local st, cfg = self.state, O(self)
  st.airPool = st.airPool or {}
  st.airCover = st.airCover or { blue = {}, red = {} }
  st.intel = st.intel or { blue = {}, red = {} }
  st.carried = st.carried or {}
  st.downed = st.downed or {}
  st.killedMoves = st.killedMoves or {}
  for _, side in ipairs(SIDES) do
    st.airPool[side] = st.airPool[side] or { fighter = cfg.airPoolStart.fighter, attack = cfg.airPoolStart.attack }
  end
  for _, id in ipairs(self.T.order) do
    local ns, class = st.nodes[id], self:classOf(id)
    if cfg.samAt[class] and ns.sam == nil then ns.sam = { status = "up" } end
    local n = cfg.infraPerNode[class]
    if n and ns.infra == nil then ns.infra = { total = n, lost = {} } end
  end
end

-- ---------------------------------------------------------------------------
-- SAM sites
-- ---------------------------------------------------------------------------
function War:samHit(id, what)
  local ns = self.state.nodes[id]
  if not ns or not ns.sam or ns.sam.status == "destroyed" then return end
  local cfg = O(self)
  if what == "destroyed" then
    ns.sam = { status = "destroyed", since = self.state.tick }
    self:log("sam_destroyed", ns.side, string.format("%s air defence at %s destroyed",
      ns.side:upper(), self:nodeName(id)), { node = id })
  elseif what == "radar" and ns.sam.status == "up" then
    ns.sam = { status = "suppressed", since = self.state.tick }
    self:log("sam_suppressed", ns.side, string.format("%s air defence radar at %s knocked out",
      ns.side:upper(), self:nodeName(id)), { node = id })
  end
end

-- Repairs happen on their timers, paid from the node's supply.
function War:repairSams()
  local cfg = O(self)
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local sam = ns.sam
    if sam and sam.status ~= "up" then
      local wait = (sam.status == "suppressed") and cfg.samRepairTicks or cfg.samRebuildTicks
      local cost = (sam.status == "suppressed") and cfg.samRepairCost or cfg.samRebuildCost
      if self.state.tick - (sam.since or 0) >= wait and (ns.supply or 0) >= cost then
        ns.supply = ns.supply - cost
        ns.sam = { status = "up" }
        self:log("sam_up", ns.side, string.format("%s air defence at %s back up", ns.side:upper(),
          self:nodeName(id)), { node = id })
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Structures (strike targets)
-- ---------------------------------------------------------------------------
function War:infraLost(id)
  local inf = self.state.nodes[id].infra
  if not inf then return 0 end
  local n = 0
  for _ in pairs(inf.lost) do n = n + 1 end
  return n
end

-- Output multiplier from damage: all buildings gone = 30 % output.
function War:infraFactor(id)
  local inf = self.state.nodes[id].infra
  if not inf or inf.total == 0 then return 1 end
  return 1 - 0.7 * self:infraLost(id) / inf.total
end

function War:infraHit(id, k)
  local ns = self.state.nodes[id]
  local inf = ns and ns.infra
  if not inf or inf.lost[tostring(k)] then return end
  inf.lost[tostring(k)] = self.state.tick
  inf.repairAt = inf.repairAt or (self.state.tick + O(self).infraRepairTicks)
  ns.supply = math.max(0, (ns.supply or 0) - O(self).infraSupplyHit)
  self:log("infra_hit", ns.side, string.format("%s %s at %s destroyed (%d of %d)", ns.side:upper(),
    k == 1 and "fuel store" or "supply building", self:nodeName(id), self:infraLost(id), inf.total), { node = id })
end

function War:repairInfra()
  local cfg = O(self)
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local inf = ns.infra
    if inf and inf.repairAt and self.state.tick >= inf.repairAt then
      local k = U.sortedKeys(inf.lost)[1]
      if k and (ns.supply or 0) >= cfg.infraRepairCost then
        ns.supply = ns.supply - cfg.infraRepairCost
        inf.lost[k] = nil
      end
      inf.repairAt = next(inf.lost) and (self.state.tick + cfg.infraRepairTicks) or nil
    end
  end
end

-- ---------------------------------------------------------------------------
-- AI air pools and air cover
-- ---------------------------------------------------------------------------
function War:airAvailable(side, role, n)
  return (self.state.airPool[side][role] or 0) >= (n or 1)
end

function War:airTake(side, role, n)
  local p = self.state.airPool[side]
  p[role] = math.max(0, (p[role] or 0) - n)
end

-- Surviving aircraft of a finished sortie return to the pool.
function War:airReturn(side, role, n)
  local p, max = self.state.airPool[side], O(self).airPoolMax[role]
  p[role] = math.min(max, (p[role] or 0) + n)
end

function War:airLoss(side, role, n)
  self.state.stats.airLost = self.state.stats.airLost or { blue = 0, red = 0 }
  self.state.stats.airLost[side] = self.state.stats.airLost[side] + n
end

function War:restockAirPools()
  local cfg = O(self)
  if self.state.tick % cfg.airPoolRestockTicks ~= 0 then return end
  for _, side in ipairs(SIDES) do
    local p = self.state.airPool[side]
    local role = (p.fighter <= p.attack) and "fighter" or "attack"
    if p[role] < cfg.airPoolMax[role] then
      for _, id in ipairs(self.T.order) do
        local ns = self.state.nodes[id]
        if self.T.nodes[id].depot and ns.side == side and ns.supply >= cfg.airPoolRestockCost then
          ns.supply = ns.supply - cfg.airPoolRestockCost
          p[role] = p[role] + 1
          break
        end
      end
    end
  end
end

function War:setAirCover(side, id)
  self.state.airCover[side][id] = self.state.tick + O(self).airCoverTicks
end

function War:hasAirCover(side, id)
  local t = self.state.airCover[side][id]
  return t ~= nil and t >= self.state.tick
end

-- ---------------------------------------------------------------------------
-- Intel (recon)
-- ---------------------------------------------------------------------------
function War:recordIntel(side, id)
  local ns = self.state.nodes[id]
  self.state.intel[side][id] = {
    tick = self.state.tick, platoons = #ns.platoons,
    sam = ns.sam and ns.sam.status or "none", supply = math.floor((ns.supply or 0) + 0.5),
    owner = ns.side,
  }
end

function War:intelAge(side, id)
  local i = self.state.intel[side][id]
  return i and (self.state.tick - i.tick) or math.huge
end

-- ---------------------------------------------------------------------------
-- Airmobile: supply crates and troops in player helicopters
-- ---------------------------------------------------------------------------
function War:takeCrate(id, su)
  local ns = self.state.nodes[id]
  if (ns.supply or 0) < su then return 0 end
  ns.supply = ns.supply - su
  return su
end

function War:deliverCrate(side, id, su)
  local ns = self.state.nodes[id]
  if ns.side ~= side then return false end
  ns.supply = math.min(self:supplyCap(id) * self.cfg.supply.overfillFactor, ns.supply + su)
  self.state.stats.delivered[side] = self.state.stats.delivered[side] + su
  self:log("airdrop", side, string.format("%s helicopters delivered %d supply to %s", side:upper(),
    math.floor(su + 0.5), self:nodeName(id)), { node = id, su = su })
  return true
end

-- A platoon leaves its node and boards a helicopter.
function War:carryPlatoon(pid, by)
  local pl = self.state.platoons[pid]
  if not pl or not pl.node then return false end
  U.removeValue(self.state.nodes[pl.node].platoons, pid)
  self.state.carried[pid] = { from = pl.node, by = by }
  pl.node = nil
  return true
end

-- Troops get off at a node: a friendly node takes them in; an enemy node is
-- attacked at once (an empty one is simply taken).
function War:dropPlatoons(pids, id, side)
  local ns = self.state.nodes[id]
  local list = {}
  for _, pid in ipairs(pids) do
    if self.state.carried[pid] and self.state.platoons[pid] then
      self.state.carried[pid] = nil
      list[#list + 1] = pid
    end
  end
  if #list == 0 then return nil end
  if ns.side == side then
    for _, pid in ipairs(list) do
      self.state.platoons[pid].node = id
      ns.platoons[#ns.platoons + 1] = pid
    end
    self:log("airmobile", side, string.format("%s troops landed by helicopter at %s", side:upper(),
      self:nodeName(id)), { node = id })
    return "reinforced"
  end
  -- Air assault: a move that has already arrived and is fighting. Several
  -- helicopters landing at the same base fight as one assault.
  for _, mv in pairs(self.state.moves) do
    if mv.airAssault and mv.side == side and mv.to == id and mv.status == "fighting" then
      for _, pid in ipairs(list) do
        self.state.platoons[pid].move = mv.id
        mv.platoons[#mv.platoons + 1] = pid
      end
      self:log("airassault", side, string.format("%s reinforces the air assault on %s", side:upper(),
        self:nodeName(id)), { node = id })
      return "assault"
    end
  end
  local mid = self:newId("m")
  local mv = { id = mid, kind = "assault", side = side, from = id, to = id, platoons = {},
               progress = 1, km = 1, status = "fighting", airAssault = true }
  for _, pid in ipairs(list) do
    self.state.platoons[pid].move = mid
    mv.platoons[#mv.platoons + 1] = pid
  end
  self.state.moves[mid] = mv
  self:log("airassault", side, string.format("%s air assault on %s", side:upper(), self:nodeName(id)), { node = id })
  return "assault"
end

function War:loseCarried(pid)
  if not self.state.carried[pid] then return end
  self.state.carried[pid] = nil
  local pl = self.state.platoons[pid]
  if pl then
    self.state.stats.lost[pl.side] = self.state.stats.lost[pl.side] + 1
    self.state.platoons[pid] = nil
  end
end

-- Back to where they came from (player left the slot, server restart).
function War:returnCarried(pid)
  local c = self.state.carried[pid]
  local pl = self.state.platoons[pid]
  if not c then return end
  if not pl then self.state.carried[pid] = nil; return end
  local ns = self.state.nodes[c.from]
  if ns and ns.side == pl.side then
    self.state.carried[pid] = nil
    pl.node = c.from
    ns.platoons[#ns.platoons + 1] = pid
  else
    self:loseCarried(pid)          -- their base fell while they were away
  end
end

function War:returnAllCarried()
  for pid in pairs(self.state.carried) do self:returnCarried(pid) end
end

-- ---------------------------------------------------------------------------
-- Downed pilots (CSAR)
-- ---------------------------------------------------------------------------
-- pos is a DCS map point {x, z}; the model only stores it.
function War:addDowned(side, pos, pilot, aircraftType, home, key)
  local id = self:newId("d")
  self.state.downed[id] = { id = id, side = side, pos = pos, pilot = pilot, type = aircraftType,
                            home = home, key = key, tick = self.state.tick }
  self:log("downed", side, string.format("%s pilot %s down - CSAR needed", side:upper(),
    tostring(pilot or "unknown")), { downed = id })
  return id
end

-- Rescued: the pilot is safe and the aircraft is refunded at the base where
-- the pilot was brought (or the home base).
function War:rescue(did, atNode)
  local d = self.state.downed[did]
  if not d then return false end
  self.state.downed[did] = nil
  local base = atNode or d.home
  local ns = base and self.state.nodes[base]
  if ns and ns.air and d.type and ns.air[d.type] ~= nil then ns.air[d.type] = ns.air[d.type] + 1 end
  self:log("rescued", d.side, string.format("%s pilot %s rescued", d.side:upper(), tostring(d.pilot)),
    { downed = did, pilot = d.pilot, pilotKey = d.key })
  return true
end

function War:expireDowned()
  for did, d in pairs(self.state.downed) do
    if self.state.tick - d.tick > O(self).csarTimeoutTicks then
      self.state.downed[did] = nil
      self:log("captured", d.side, string.format("%s pilot %s was captured", d.side:upper(), tostring(d.pilot)),
        { downed = did, pilot = d.pilot, pilotKey = d.key })
    end
  end
end

-- ---------------------------------------------------------------------------
-- Convoy ambush (abstract) - escorted convoys are safe
-- ---------------------------------------------------------------------------
function War:ambushCheck(mv)
  if mv.kind ~= "convoy" or not mv.front or mv.escorted or self:isMoveLive(mv) or self:onSea(mv) then return end
  if self.rng:next() < O(self).convoyAmbushChance then
    mv.health = (mv.health or 1) * (1 - O(self).convoyAmbushLoss)
    self:log("ambush", mv.side, string.format("%s convoy to %s ambushed, cargo damaged", mv.side:upper(),
      self:nodeName(mv.to)), { node = mv.to })
  end
end

-- ---------------------------------------------------------------------------
-- Capture side effects and the per-tick step
-- ---------------------------------------------------------------------------
function War:onCaptureOps(id)
  local ns = self.state.nodes[id]
  if ns.sam then ns.sam = { status = "destroyed", since = self.state.tick } end
  for _, side in ipairs(SIDES) do self.state.airCover[side][id] = nil end
end

function War:opsTick()
  self:repairSams()
  self:repairInfra()
  self:restockAirPools()
  self:expireDowned()
  for mid, t in pairs(self.state.killedMoves) do
    if self.state.tick - t > 12 then self.state.killedMoves[mid] = nil end
  end
end

end

-- >>> src/dcc_missions.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - mission board (phase 3, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Each side gets a board of player missions generated from the live war. A
-- mission is an OFFER pointed at something real in the model; its effect
-- happens through the model itself (a destroyed convoy really loses its cargo,
-- a SAM really goes down). The board only decides whether the players who
-- took it succeeded, and credits them.
--
--   type       target            success when                       needs
--   CAS        node in battle    the battle goes our way            A2G
--   BAI        enemy move        that column/convoy is destroyed    A2G
--   STRIKE     enemy node        one of its buildings destroyed     A2G
--   SEAD       enemy node        its SAM is suppressed or destroyed SEAD
--   CAP        own node          20 min on station or an air kill   A2A   -> air cover 1 h
--   ESCORT     own airlift       delivered, escort stayed close     A2A
--   CONVOY     own convoy        delivered, escort stayed close     HELO  -> no ambush
--   RECON      enemy node        overflown low (intel recorded)     ANY
--   CSAR       downed pilot      pilot brought back                 LIFT
--   LOGISTICS  own node          crate unloaded there               LIFT
--
-- Detection that needs DCS (on station, overflight, escort distance, pickup)
-- lives in the bridge, which calls completeMission / recordIntel / rescue.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

War.MISSION_NEEDS = {
  CAS = "A2G", BAI = "A2G", STRIKE = "A2G", SEAD = "SEAD", CAP = "A2A",
  ESCORT = "A2A", CONVOY = "HELO", RECON = "ANY", CSAR = "LIFT", LOGISTICS = "LIFT",
}
War.MISSION_ORDER = { "CAS", "BAI", "SEAD", "STRIKE", "CAP", "ESCORT", "CONVOY", "RECON", "CSAR", "LOGISTICS" }

local function M(self) return self.cfg.missions end

-- ---------------------------------------------------------------------------
-- Candidates per type: { key, type, target, node, label, prio, base }
-- ---------------------------------------------------------------------------
local gen = {}
War.missionGenerators = gen   -- later modules add mission types here

function gen.CAS(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.status == "fighting" and not seen[mv.to] then
      local ns = self.state.nodes[mv.to]
      if mv.side == side or ns.side == side then
        seen[mv.to] = true
        local attack = (mv.side == side)
        out[#out + 1] = { type = "CAS", target = mv.to, node = mv.to, prio = 0,
          label = (attack and "support attack on " or "defend ") .. self:nodeName(mv.to),
          base = { attack = attack } }
      end
    end
  end
  return out
end

function gen.BAI(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)       -- enemy nodes near OUR territory have small values
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    local seen = (not self.fogOfWar) or self:isFresh(side, "m:" .. mid)    -- phase 4: only what we saw
    if seen and mv.side == enemy and mv.status == "moving" and mv.kind ~= "airlift" and not self:onSea(mv)
       and math.min(dist[mv.to] or 99, dist[mv.from] or 99) <= 2 then
      local what = mv.cargo and "convoy" or (mv.kind == "assault" and "assault column" or "reinforcements")
      out[#out + 1] = { type = "BAI", target = mid, node = mv.to,
        prio = (mv.cargo and 0 or 1) * 10 + (dist[mv.to] or 9),
        label = string.format("%s %s %s > %s", enemy:upper(), what, self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.STRIKE(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and ns.infra and self:infraLost(id) < ns.infra.total then
      out[#out + 1] = { type = "STRIKE", target = id, node = id,
        prio = (self.T.nodes[id].depot and 0 or 5) + (dist[id] or 9),
        label = self:nodeName(id) .. (self.T.nodes[id].depot and " depot" or " airbase stores"),
        base = { lost = self:infraLost(id) } }
    end
  end
  return out
end

function gen.SEAD(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local known = (not self.fogOfWar) or self:samKnown(side, id) == "known"  -- phase 4
    if known and ns.side == enemy and ns.sam and ns.sam.status == "up" then
      local c = self.fogOfWar and self:contact(side, "sam:" .. id)
      local how = (c and c.source == "elint") and string.format(" (ELINT +/-%.1f km)", (c.err or 0) / 1000) or ""
      out[#out + 1] = { type = "SEAD", target = id, node = id, prio = dist[id] or 9,
        label = "air defence at " .. self:nodeName(id) .. how }
    end
  end
  return out
end

function gen.CAP(self, side)
  local f = self.state.focus and self.state.focus[side]
  local out = {}
  if f then
    for _, nb in ipairs(U.sortedKeys(self.T.nodes[f.target].nb)) do
      if self.state.nodes[nb].side == side then
        out[#out + 1] = { type = "CAP", target = nb, node = nb, prio = 0,
          label = "over " .. self:nodeName(nb) .. " (main effort)" }
        break
      end
    end
  end
  return out
end

function gen.ESCORT(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "airlift" and mv.status == "moving" then
      out[#out + 1] = { type = "ESCORT", target = mid, node = mv.to, prio = 0,
        needs = mv.helo and "ANY" or nil,        -- helicopters escort helicopters too
        label = string.format("%s %s > %s", mv.helo and "supply helicopter" or "airlift",
          self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.CONVOY(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "convoy" and mv.front and mv.status == "moving" and mv.progress < 0.6
       and not self:onSea(mv) then
      out[#out + 1] = { type = "CONVOY", target = mid, node = mv.to, prio = 0,
        label = string.format("convoy %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.RECON(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local f = self.state.focus and self.state.focus[side]
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and (dist[id] or 9) <= 2 and self:intelAge(side, id) > self.cfg.ops.intelFreshTicks then
      out[#out + 1] = { type = "RECON", target = id, node = id,
        prio = ((f and f.target == id) and 0 or 5) + (dist[id] or 9), label = self:nodeName(id) }
    end
  end
  return out
end

function gen.CSAR(self, side)
  local out = {}
  for _, did in ipairs(U.sortedKeys(self.state.downed)) do
    local d = self.state.downed[did]
    if d.side == side then
      out[#out + 1] = { type = "CSAR", target = did, prio = d.tick, label = "pilot " .. tostring(d.pilot) }
    end
  end
  return out
end

function gen.LOGISTICS(self, side)
  local dist = self:frontDistance(side)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == side and not self.T.nodes[id].depot then
      local low = ns.outOfSupply or (dist[id] == 1 and ns.supply < self:supplyCap(id) * 0.3)
      if low then
        out[#out + 1] = { type = "LOGISTICS", target = id, node = id,
          prio = (ns.outOfSupply and 0 or 5) + (dist[id] or 9), label = "supply to " .. self:nodeName(id) }
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Validity and completion of open missions
-- ---------------------------------------------------------------------------
-- Returns "open", "done", "failed" or "expired".
function War:missionOutcome(m, events)
  local st = self.state
  local t = m.type
  if t == "CAS" then
    for _, ev in ipairs(events) do
      if ev.node == m.target and (ev.kind == "capture" or ev.kind == "repulsed") then
        local ours = (ev.side == m.side)
        return ours and "done" or "failed"
      end
    end
    for _, mv in pairs(st.moves) do if mv.status == "fighting" and mv.to == m.target then return "open" end end
    return "expired"
  elseif t == "BAI" then
    if st.moves[m.target] then return "open" end
    return st.killedMoves[m.target] and "done" or "expired"
  elseif t == "STRIKE" then
    if st.nodes[m.target].side == m.side then return "expired" end
    return (self:infraLost(m.target) > (m.base.lost or 0)) and "done" or "open"
  elseif t == "SEAD" then
    local ns = st.nodes[m.target]
    if ns.side == m.side then return "expired" end
    return (ns.sam and ns.sam.status ~= "up") and "done" or "open"
  elseif t == "CAP" then
    return (st.nodes[m.target].side == m.side) and "open" or "expired"
  elseif t == "ESCORT" or t == "CONVOY" then
    if st.moves[m.target] then return "open" end
    if st.killedMoves[m.target] then return "failed" end
    local d = st.deliveredMoves and st.deliveredMoves[m.target]
    if d and m.escortOk and (t == "ESCORT" or d.health >= 0.5) then return "done" end
    return "expired"
  elseif t == "RECON" then
    if st.nodes[m.target].side == m.side then return "expired" end
    local i = st.intel[m.side][m.target]
    return (i and i.tick >= m.created and next(m.taken)) and "done" or "open"
  elseif t == "CSAR" then
    if st.downed[m.target] then return "open" end
    for _, ev in ipairs(events) do
      if ev.downed == m.target then return ev.kind == "rescued" and "done" or "failed" end
    end
    return "expired"
  elseif t == "LOGISTICS" then
    if st.nodes[m.target].side ~= m.side then return "expired" end
    for _, ev in ipairs(events) do
      if ev.kind == "airdrop" and ev.node == m.target and ev.side == m.side then return "done" end
    end
    return "open"
  end
  return "expired"
end

-- Finish a mission and credit whoever took it.
function War:finishMission(m, outcome)
  m.status, m.finished = outcome, self.state.tick
  if outcome == "done" and m.type == "CAP" then self:setAirCover(m.side, m.target) end
  if outcome == "done" then
    for key, name in pairs(m.taken) do self:recordMissionDone(key, m.side, name) end
  end
  if next(m.taken) and (outcome == "done" or outcome == "failed") then
    local names = {}
    for _, n in pairs(m.taken) do names[#names + 1] = n end
    table.sort(names)
    self:log("mission_" .. outcome, m.side, string.format("%s mission %s: %s %s - %s",
      m.side:upper(), outcome == "done" and "complete" or "failed", m.type, m.label,
      table.concat(names, ", ")), { mission = m.id })
  end
  if self.onMissionDone then self.onMissionDone(m, outcome) end
end

-- Called by the bridge when it detects success (CAP on station, recon pass...).
function War:completeMission(mid, ok)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return end
  if m.type == "RECON" and ok then self:recordIntel(m.side, m.target) end
  self:finishMission(m, ok and "done" or "failed")
end

-- ---------------------------------------------------------------------------
-- Taking and leaving missions
-- ---------------------------------------------------------------------------
function War:takeMission(mid, key, name)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return nil end
  m.taken[key] = name or key
  if m.type == "CONVOY" and self.state.moves[m.target] then self.state.moves[m.target].escorted = true end
  return m
end

function War:leaveMission(mid, key)
  local m = self.state.missions[mid]
  if m then m.taken[key] = nil end
end

-- Escort bookkeeping from the bridge: one sample per poll.
function War:escortSample(mid, close)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return end
  m.escort = m.escort or { inside = 0, total = 0 }
  m.escort.total = m.escort.total + 1
  if close then m.escort.inside = m.escort.inside + 1 end
  m.escortOk = m.escort.total >= 3 and (m.escort.inside / m.escort.total) >= M(self).escortShare
end

function War:openMissions(side)
  local list = {}
  self.state.missions = self.state.missions or {}   -- a player may slot in before the first tick
  for _, id in ipairs(U.sortedKeys(self.state.missions)) do
    local m = self.state.missions[id]
    if m.side == side and m.status == "open" then list[#list + 1] = m end
  end
  local order = {}
  for i, t in ipairs(War.MISSION_ORDER) do order[t] = i end
  table.sort(list, function(a, b)
    if a.type ~= b.type then return order[a.type] < order[b.type] end
    return a.id < b.id
  end)
  return list
end

-- ---------------------------------------------------------------------------
-- The per-tick board update
-- ---------------------------------------------------------------------------
function War:missionsTick()
  local st = self.state
  st.missions = st.missions or {}
  st.deliveredMoves = st.deliveredMoves or {}

  -- 1. Resolve open missions against what happened this tick.
  for _, id in ipairs(U.sortedKeys(st.missions)) do
    local m = st.missions[id]
    if m.status == "open" then
      local outcome = self:missionOutcome(m, self.newEvents)
      if outcome ~= "open" then self:finishMission(m, outcome) end
    elseif st.tick - (m.finished or st.tick) > 12 then
      st.missions[id] = nil               -- finished missions linger 1 h for messages
    end
  end
  for mid, d in pairs(st.deliveredMoves) do
    if st.tick - d.tick > 12 then st.deliveredMoves[mid] = nil end
  end

  -- 2. Fill each side's board up to the per-type limits.
  for _, side in ipairs(SIDES) do
    local have = {}
    for _, m in pairs(st.missions) do
      if m.side == side and m.status == "open" then
        have[m.type .. ":" .. tostring(m.target)] = true
        if not m.hub then have[m.type] = (have[m.type] or 0) + 1 end   -- local extras don't fill the board
      end
    end
    for _, t in ipairs(War.MISSION_ORDER) do
      local limit = M(self).perType[t] or 0
      if (have[t] or 0) < limit then
        local cands = gen[t](self, side)
        table.sort(cands, function(a, b)
          if a.prio ~= b.prio then return a.prio < b.prio end
          return tostring(a.target) < tostring(b.target)
        end)
        for _, c in ipairs(cands) do
          if (have[t] or 0) >= limit then break end
          local key = t .. ":" .. tostring(c.target)
          if not have[key] then
            local mid = self:newId("x")
            st.missions[mid] = { id = mid, side = side, type = t, target = c.target, node = c.node,
              label = c.label, base = c.base or {}, created = st.tick, taken = {}, status = "open",
              needs = c.needs or War.MISSION_NEEDS[t] }
            have[key] = true
            have[t] = (have[t] or 0) + 1
          end
        end
      end
    end
  end
  -- 3. Local missions near where helicopters and slow movers spawned.
  self:hubMissions()
end

-- ---------------------------------------------------------------------------
-- Hubs: local missions for helicopters and slow aircraft
-- ---------------------------------------------------------------------------
-- The board above is built from the whole front, so a Huey at a rear base can
-- find every mission 300 nm away. The bridge reports where such players are
-- (setHubs); for each hub and each mission type that player can fly, if no open
-- mission of that type lies within the hub's range, the nearest candidate is
-- added on top of the normal board (m.hub). Some types get a relaxed local
-- generator so a rear base still has work: supply runs to any low base nearby,
-- escorting any convoy passing through, FARPs near the front.
--   hub = { node = id, km = range, caps = { HELO = true, LIFT = true, ... } }
War.HUB_TYPES = { CAS = true, BAI = true, CONVOY = true, ESCORT = true, RECON = true, LOGISTICS = true,
                  FARP = true, FARPSUP = true, ARTY = true, FORT = true, COIN = true, BRIDGE = true }
local hubGen = {}
War.hubGenerators = hubGen

function hubGen.LOGISTICS(self, side, hub)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == side and id ~= hub.node and not self.T.nodes[id].depot
       and (ns.supply or 0) < self:supplyCap(id) * (M(self).hubSupplyBelow or 0.7) then
      out[#out + 1] = { type = "LOGISTICS", target = id, node = id, prio = 0,
        label = "supply run to " .. self:nodeName(id) }
    end
  end
  return out
end

function hubGen.CONVOY(self, side, hub)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "convoy" and mv.status == "moving" and mv.progress < 0.6
       and not self:onSea(mv) then
      out[#out + 1] = { type = "CONVOY", target = mid, node = mv.to, near = { mv.from, mv.to }, prio = 0,
        label = string.format("convoy %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function hubGen.FARP(self, side, hub)
  if not self.canHaveFarp or (self.isStorm and self:isStorm()) then return {} end
  local dist = self:frontDistance(side)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == side and self:canHaveFarp(id) and not self:farpAt(id) and (dist[id] or 9) <= 3 then
      out[#out + 1] = { type = "FARP", target = id, node = id, prio = 0,
        label = string.format("build a FARP at %s (FARP kit, or crates %d/%d SU)", self:nodeName(id),
          math.floor(ns.farpSU or 0), self.cfg.world.farpBuildSU) }
    end
  end
  return out
end

function War:setHubs(side, hubs)
  self.hubs = self.hubs or {}
  self.hubs[side] = hubs or {}
end

function War:hubKm(hub, c)
  local a = self.T.nodes[hub.node]
  local best = math.huge
  for _, id in ipairs(c.near or { c.node }) do
    local b = id and self.T.nodes[id]
    if a and b then best = math.min(best, U.distKm(a, b)) end
  end
  return best
end

function War:hubMissions()
  local st = self.state
  st.missions = st.missions or {}
  for _, side in ipairs(SIDES) do
    local hubs = (self.hubs and self.hubs[side]) or {}
    local live = {}
    for _, h in ipairs(hubs) do live[h.node] = true end
    -- local missions nobody took, for a hub that is gone, are withdrawn
    for _, id in ipairs(U.sortedKeys(st.missions)) do
      local m = st.missions[id]
      if m.side == side and m.hub and m.status == "open" and not live[m.hub] and not next(m.taken) then
        st.missions[id] = nil
      end
    end
    for _, hub in ipairs(hubs) do
      for _, t in ipairs(War.MISSION_ORDER) do
        local g = gen[t]
        if War.HUB_TYPES[t] and g and (M(self).perType[t] or 0) > 0 then
          local near, have = false, {}
          for _, m in pairs(st.missions) do
            if m.side == side and m.status == "open" then
              have[t .. ":" .. tostring(m.target)] = true
              if m.type == t and self:hubKm(hub, m) <= hub.km then near = true end
            end
          end
          if not near then
            local cands = g(self, side)
            if hubGen[t] then for _, c in ipairs(hubGen[t](self, side, hub)) do cands[#cands + 1] = c end end
            local best, bestKm
            for _, c in ipairs(cands) do
              local needs = c.needs or War.MISSION_NEEDS[t]
              local key = t .. ":" .. tostring(c.target)
              local km = self:hubKm(hub, c)
              if (needs == "ANY" or (hub.caps or {})[needs]) and not have[key] and km <= hub.km
                 and (not bestKm or km < bestKm or (km == bestKm and tostring(c.target) < tostring(best.target))) then
                best, bestKm = c, km
              end
            end
            if best then
              local mid = self:newId("x")
              st.missions[mid] = { id = mid, side = side, type = t, target = best.target, node = best.node,
                label = best.label, base = best.base or {}, created = st.tick, taken = {}, status = "open",
                needs = best.needs or War.MISSION_NEEDS[t], hub = hub.node, near = best.near }
            end
          end
        end
      end
    end
  end
end

end

-- >>> src/dcc_pilots.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - persistent pilot records (phase 3, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- One record per player, kept in its own file (Saved Games\DCS\DCC\pilots.json)
-- so it survives the end of a war and the move to the next map.
--
-- A player is identified by their DCS UCID when the server can read it, and
-- by their player name otherwise.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local Pilots = {}
Pilots.__index = Pilots
DCC.Pilots = Pilots

-- Points per achievement. Score decides rank.
Pilots.POINTS = {
  kills_air = 10, kills_ground = 3, kills_convoy = 2, kills_sam = 8, kills_structure = 5,
  missions = 20, rescues = 25, deaths = -10, captured = -5, prisoners = 15,
  packages = 10, medevacs = 15, pows = 10, team = 5, qra = 10,
  wins_conquest = 150,   -- flew for the side that conquered the whole map
  wins_clock = 50,       -- flew for the side that was ahead when the war clock ran out
}

Pilots.RANKS = {
  { 0, "Lieutenant" }, { 100, "Captain" }, { 300, "Major" },
  { 700, "Lieutenant Colonel" }, { 1500, "Colonel" }, { 3000, "General" },
}

function Pilots.new(data)
  local self = setmetatable({ data = data or { version = 1, pilots = {} }, dirty = false }, Pilots)
  self.data.pilots = self.data.pilots or {}
  return self
end

local FIELDS = { "sorties", "flightMinutes", "kills_air", "kills_ground", "kills_convoy", "kills_sam",
                 "kills_structure", "missions", "rescues", "deaths", "ejections", "captured", "saved",
                 "wins_conquest", "wins_clock", "prisoners", "packages", "medevacs", "pows", "team", "qra" }

-- Squadron tag from a player name: "[VKG] Morten", "VKG | Morten", "-=VKG=- Morten",
-- "Morten [VKG]". Tags are 2-8 letters/digits; returned upper-case, or nil.
function Pilots.squadronOf(name)
  if type(name) ~= "string" then return nil end
  local tag = name:match("^%s*%[([%w_%-]+)%]") or name:match("^%s*([%w_%-]+)%s*|")
           or name:match("^%s*%-=([%w_]+)=%-") or name:match("%[([%w_%-]+)%]%s*$")
  if tag and #tag >= 2 and #tag <= 8 then return tag:upper() end
  return nil
end

function Pilots:get(key, name)
  local p = self.data.pilots[key]
  if not p then
    p = { name = name or key, sides = { blue = 0, red = 0 }, byType = {}, wars = {} }
    for _, f in ipairs(FIELDS) do p[f] = 0 end
    self.data.pilots[key] = p
    self.dirty = true
  end
  if name and p.name ~= name then p.name = name; self.dirty = true end
  local sq = Pilots.squadronOf(p.name)
  if sq ~= p.squadron then p.squadron = sq; self.dirty = true end
  return p
end

function Pilots:add(key, field, n, name)
  local p = self:get(key, name)
  p[field] = (p[field] or 0) + (n or 1)
  self.dirty = true
  return p
end

-- A completed mission, by type.
function Pilots:mission(key, mtype, name)
  local p = self:add(key, "missions", 1, name)
  p.byType[mtype] = (p.byType[mtype] or 0) + 1
end

function Pilots:sortie(key, side, theater, name)
  local p = self:add(key, "sorties", 1, name)
  p.sides[side] = (p.sides[side] or 0) + 1
  p.wars[theater] = true
end

-- War won: every pilot who did enough for the winner in this war - at least
-- minSorties sorties, or one completed mission, for that side.
-- roster = war.state.roster ({ [key] = { name, blue = sorties, red = sorties } }).
-- Returns the names that got the bonus.
function Pilots:warWon(roster, winner, how, minSorties)
  local field = (how == "conquest") and "wins_conquest" or "wins_clock"
  local names = {}
  for _, key in ipairs(U.sortedKeys(roster or {})) do
    local r = roster[key]
    if DCC.War.earnedVictory(r, winner, minSorties) then
      self:add(key, field, 1, r.name)
      names[#names + 1] = r.name or key
    end
  end
  return names, Pilots.POINTS[field]
end

function Pilots:score(key)
  local p = self.data.pilots[key]
  if not p then return 0 end
  local s = 0
  for f, pts in pairs(Pilots.POINTS) do s = s + (p[f] or 0) * pts end
  return s
end

function Pilots:rank(key)
  local s, r = self:score(key), Pilots.RANKS[1][2]
  for _, step in ipairs(Pilots.RANKS) do if s >= step[1] then r = step[2] end end
  return r
end

-- Position of a rank name in RANKS (1 = Lieutenant), or of a pilot's rank.
function Pilots.rankIndexOf(name)
  for i, step in ipairs(Pilots.RANKS) do if step[2] == name then return i end end
  return 1
end

function Pilots:rankIndex(key) return Pilots.rankIndexOf(self:rank(key)) end

function Pilots:summary(key)
  local p = self.data.pilots[key]
  if not p then return "No record yet - fly a sortie." end
  local types = {}
  for _, t in ipairs(U.sortedKeys(p.byType)) do types[#types + 1] = t .. " " .. p.byType[t] end
  local wars = U.sortedKeys(p.wars)
  return table.concat({
    string.format("%s %s  -  %d points%s", self:rank(key), p.name, self:score(key),
      p.squadron and ("  (squadron " .. p.squadron .. ")") or ""),
    string.format("Sorties %d (BLUE %d, RED %d), %d h %02d min in the air", p.sorties, p.sides.blue or 0,
      p.sides.red or 0, math.floor(p.flightMinutes / 60), math.floor(p.flightMinutes % 60)),
    string.format("Kills: air %d, ground %d, convoy trucks %d, SAM %d, buildings %d",
      p.kills_air, p.kills_ground, p.kills_convoy, p.kills_sam, p.kills_structure),
    string.format("Missions %d%s", p.missions, #types > 0 and (" (" .. table.concat(types, ", ") .. ")") or ""),
    string.format("Rescues flown %d, rescued %d times, ejections %d, deaths %d, captured %d",
      p.rescues, p.saved, p.ejections, p.deaths, p.captured),
    string.format("Wars won: %d by conquest, %d on the war clock", p.wins_conquest or 0, p.wins_clock or 0),
    "Theaters: " .. (#wars > 0 and table.concat(wars, ", ") or "-"),
  }, "\n")
end

-- Squadrons: members' scores added up, plus wars won by any member.
function Pilots:squadrons()
  local by = {}
  for key, p in pairs(self.data.pilots) do
    local sq = p.squadron or Pilots.squadronOf(p.name)
    if sq then
      local s = by[sq] or { tag = sq, score = 0, members = 0, wins = 0 }
      s.score = s.score + self:score(key)
      s.members = s.members + 1
      s.wins = s.wins + (p.wins_conquest or 0) + (p.wins_clock or 0)
      by[sq] = s
    end
  end
  local list = {}
  for _, s in pairs(by) do list[#list + 1] = s end
  table.sort(list, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.tag < b.tag end)
  return list
end

function Pilots:topSquadrons(n)
  local out = {}
  for i, s in ipairs(self:squadrons()) do
    if i > n then break end
    out[i] = string.format("%2d. %-8s %6d points, %d pilots, %d war wins", i, s.tag, s.score, s.members, s.wins)
  end
  if #out == 0 then out[1] = "No squadrons yet. Put your tag in your name: [TAG] Name" end
  return out
end

-- Top N by score, for the leaderboard.
function Pilots:top(n)
  local list = {}
  for key in pairs(self.data.pilots) do list[#list + 1] = key end
  table.sort(list, function(a, b)
    local sa, sb = self:score(a), self:score(b)
    if sa ~= sb then return sa > sb end
    return a < b
  end)
  local out = {}
  for i = 1, math.min(n, #list) do
    local k = list[i]
    out[i] = string.format("%2d. %-12s %-20s %5d", i, self:rank(k), self.data.pilots[k].name, self:score(k))
  end
  return out
end

end

-- >>> src/dcc_intel.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - intel and fog of war (phase 4, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Each side keeps a CONTACT table: what its units have actually seen, when,
-- how, and how precisely. The map and the mission board read this table, never
-- the true positions. Load after dcc_missions.lua.
--
--   contact key   what it is
--   m:<move>      an enemy column or convoy on a road
--   g:<node>      enemy garrison units seen at a node
--   sam:<node>    an enemy air-defence site
--   air:<group>   enemy aircraft
--   n:<node>      a recon report on a whole enemy base (phase 3 intel)
--
--   source        visual (eyes on), sensor (AI radar/optics), elint (radar
--                 emissions; position has an error that shrinks with more
--                 observations), recon (a recon pass)
--
--   age           fresh < staleTicks (30 min) - drawn solid, can be tasked
--                 stale < expireTicks (3 h)   - drawn faded "last seen ..."
--                 older                        - forgotten
--
-- Front-line estimate: every side sees roughly how strong the enemy bases right
-- on the front are (light / medium / heavy) - troops in contact know that much.
-- Exact numbers need recon.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function I(self) return self.cfg.intel end

function War:initIntel()
  self.state.contacts = self.state.contacts or { blue = {}, red = {} }
end

-- data: { kind, node, pos = {x,z}, label, size, source, err }
function War:addContact(side, key, data)
  local list = self.state.contacts[side]
  local c = list[key]
  local fresh = c and (self.state.tick - c.seen) < I(self).staleTicks
  local oldErr, oldPos = c and c.err, c and c.pos
  c = c or { key = key }
  for k, v in pairs(data) do c[k] = v end
  -- ELINT: keep the better fix if a worse one arrives while the old is fresh
  if data.source == "elint" and fresh and oldErr and data.err and oldErr < data.err then
    c.err, c.pos = oldErr, oldPos
  end
  c.seen = self.state.tick
  list[key] = c
  return c
end

function War:contact(side, key) return self.state.contacts[side][key] end

function War:contactAge(side, key)
  local c = self.state.contacts[side][key]
  return c and (self.state.tick - c.seen) or math.huge
end

function War:isFresh(side, key)
  return self:contactAge(side, key) < I(self).staleTicks
end

function War:pruneContacts()
  for _, side in ipairs(SIDES) do
    for key, c in pairs(self.state.contacts[side]) do
      -- recon reports on whole bases are kept as long as recon intel counts
      local expire = (c.kind == "node") and self.cfg.ops.intelFreshTicks or I(self).expireTicks
      local gone = (c.kind == "move" and not self.state.moves[key:sub(3)])
      if self.state.tick - c.seen > expire or (gone and self.state.tick - c.seen > I(self).staleTicks) then
        self.state.contacts[side][key] = nil
      end
    end
  end
end

-- Rough strength of an enemy base on the front, or nil if not on the front.
function War:frontEstimate(side, id)
  local ns = self.state.nodes[id]
  if ns.side == side then return nil end
  local touching = false
  for nb in pairs(self.T.nodes[id].nb) do
    if self.state.nodes[nb].side == side then touching = true; break end
  end
  if not touching then return nil end
  local n = #ns.platoons
  if n == 0 then return "empty?" end
  if n <= 3 then return "light" end
  if n <= 8 then return "medium" end
  return "heavy"
end

-- What side knows about an enemy SAM site: "known" (fresh contact or recent
-- recon that saw it up), "stale", or nil.
function War:samKnown(side, id)
  local key = "sam:" .. id
  if self:isFresh(side, key) then return "known" end
  local i = self.state.intel[side] and self.state.intel[side][id]
  if i and i.sam == "up" and (self.state.tick - i.tick) < self.cfg.ops.intelFreshTicks then return "known" end
  if self:contact(side, key) then return "stale" end
  return nil
end

-- A contact for an enemy column, with where it was when seen (the map shows
-- that spot, not where the column is now).
function War:moveLabel(mv)
  local what = mv.cargo and "supply convoy" or (mv.kind == "assault" and "assault column" or "reinforcements")
  return string.format("%s (%d)", what, math.max(#mv.platoons, mv.cargo and 1 or 0))
end

function War:spotMove(side, mid, source, pos)
  local mv = self.state.moves[mid]
  if not mv or mv.side == side then return nil end
  return self:addContact(side, "m:" .. mid, { kind = "move", from = mv.from, to = mv.to,
    progress = mv.progress, pos = pos, source = source, label = self:moveLabel(mv) })
end

-- Recon also leaves a node contact (for drawing and aging), and reports the
-- enemy columns on the roads into and out of the base.
local baseRecordIntel = War.recordIntel
function War:recordIntel(side, id)
  baseRecordIntel(self, side, id)
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if (mv.from == id or mv.to == id) and mv.kind ~= "airlift" then self:spotMove(side, mid, "recon") end
  end
  local ns = self.state.nodes[id]
  self:addContact(side, "n:" .. id, { kind = "node", node = id, source = "recon",
    label = string.format("%d plt, SAM %s", #ns.platoons, ns.sam and ns.sam.status or "none") })
  if ns.sam and ns.sam.status ~= "destroyed" then
    self:addContact(side, "sam:" .. id, { kind = "sam", node = id, source = "recon",
      label = "SAM site (" .. ns.sam.status .. ")", err = 500 })
  end
end

-- Troops in contact: every base sees enemy columns on the road within
-- groundObsKm of it, and anything attacking it.
function War:groundObservation()
  local km = I(self).groundObsKm or 0
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.kind ~= "airlift" then
      local toSide, fromSide = self.state.nodes[mv.to].side, self.state.nodes[mv.from].side
      local toKm, fromKm = mv.km * (1 - mv.progress), mv.km * mv.progress
      if toSide ~= mv.side and (mv.status == "fighting" or toKm <= km) then self:spotMove(toSide, mid, "sensor") end
      if fromSide ~= mv.side and fromKm <= km then self:spotMove(fromSide, mid, "sensor") end
    end
  end
end

function War:intelTick()
  self:groundObservation()
  self:pruneContacts()
end

end

-- >>> src/dcc_radar.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - radar stations, AWACS and recon photos (phase 5,
-- pure Lua 5.1). Load after dcc_intel.lua.
-- ----------------------------------------------------------------------------
--   EWR site   : an early-warning radar at depots (and nodes a theater pack
--                marks with `ewr = true`). While up, it gives its side an air
--                picture: enemy aircraft above the radar horizon within
--                radar.ewrKm show on that side's map. It always emits, so the
--                enemy can find it with ELINT. Destroyed -> rebuilt after
--                ewrRebuildTicks for ewrRebuildCost supply. Captured = destroyed.
--   AWACS      : each side has a small pool of AWACS aircraft. While players
--                are online one orbits behind the front and sees enemy aircraft
--                out to radar.awacsKm. Shoot it down and the side is half blind
--                until a replacement is bought.
--   Missions   : EWR (strike a known radar site) and HVAA (shoot down the enemy
--                AWACS once it has been detected).
--   Recon photo: a recon pass stores what was photographed - every platoon
--                with its vehicle types - so the map can show it unit by unit.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function R(self) return self.cfg.radar end

-- ---------------------------------------------------------------------------
-- Initialisation (new wars and older saves)
-- ---------------------------------------------------------------------------
function War:initRadar()
  local st, cfg = self.state, R(self)
  st.awacs = st.awacs or { blue = {}, red = {} }
  for _, side in ipairs(SIDES) do
    local p = st.airPool[side]
    if p.awacs == nil then p.awacs = cfg.awacsPoolStart end
  end
  for _, id in ipairs(self.T.order) do
    local ns, tn = st.nodes[id], self.T.nodes[id]
    if ns.ewr == nil and (tn.ewr or cfg.ewrAt[self:classOf(id)]) then ns.ewr = { status = "up" } end
  end
end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  self:initRadar()
end

-- ---------------------------------------------------------------------------
-- EWR sites
-- ---------------------------------------------------------------------------
function War:ewrUp(id)
  local e = self.state.nodes[id].ewr
  return e ~= nil and e.status == "up"
end

function War:ewrHit(id)
  local ns = self.state.nodes[id]
  if not ns or not ns.ewr or ns.ewr.status ~= "up" then return end
  ns.ewr = { status = "destroyed", since = self.state.tick }
  self:log("ewr_destroyed", ns.side, string.format("%s early-warning radar at %s destroyed",
    ns.side:upper(), self:nodeName(id)), { node = id })
end

function War:repairEwrs()
  local cfg = R(self)
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local e = ns.ewr
    if e and e.status == "destroyed" and self.state.tick - (e.since or 0) >= cfg.ewrRebuildTicks
       and (ns.supply or 0) >= cfg.ewrRebuildCost then
      ns.supply = ns.supply - cfg.ewrRebuildCost
      ns.ewr = { status = "up" }
      self:log("ewr_up", ns.side, string.format("%s early-warning radar at %s back on the air",
        ns.side:upper(), self:nodeName(id)), { node = id })
    end
  end
end

-- ---------------------------------------------------------------------------
-- AWACS
-- ---------------------------------------------------------------------------
-- The bridge reports whether a side has an AWACS on station.
function War:setAwacs(side, up)
  self.state.awacs[side].up = up and true or nil
end

function War:awacsUp(side) return self.state.awacs[side].up == true end

function War:awacsLost(side)
  self.state.awacs[side].up = nil
  self:airLoss(side, "awacs", 1)
  self:log("awacs_lost", side, string.format("%s AWACS shot down", side:upper()), {})
end

function War:restockAwacs()
  local cfg = R(self)
  if self.state.tick % cfg.awacsRestockTicks ~= 0 then return end
  for _, side in ipairs(SIDES) do
    local p = self.state.airPool[side]
    if (p.awacs or 0) < cfg.awacsPoolMax then
      for _, id in ipairs(self.T.order) do
        local ns = self.state.nodes[id]
        if self.T.nodes[id].depot and ns.side == side and ns.supply >= cfg.awacsRestockCost then
          ns.supply = ns.supply - cfg.awacsRestockCost
          p.awacs = (p.awacs or 0) + 1
          break
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Radar horizon: how high an aircraft must fly to be seen by a radar at
-- antenna height hRadar (m) from dKm away. Standard 4/3-earth rule:
--   d [km] = 4.12 * (sqrt(hRadar) + sqrt(hTarget))
-- ---------------------------------------------------------------------------
function War.radarHorizonM(dKm, hRadar)
  local need = dKm / 4.12 - math.sqrt(math.max(hRadar, 0))
  if need <= 0 then return 0 end
  return need * need
end

-- ---------------------------------------------------------------------------
-- Recon photos: platoon by platoon, with vehicle types from the catalog.
-- ---------------------------------------------------------------------------
function War:photoOf(id)
  local ns, out = self.state.nodes[id], {}
  for _, pid in ipairs(ns.platoons) do
    local pl = self.state.platoons[pid]
    local entry = self.cat.roles[pl.role] and self.cat.roles[pl.role][pl.side]
    local types = entry and entry.units or {}
    local alive = math.max(1, math.ceil(#types * pl.health - 1e-6))
    local count = {}
    for i = 1, math.min(alive, #types) do count[types[i]] = (count[types[i]] or 0) + 1 end
    local parts = {}
    for _, t in ipairs(U.sortedKeys(count)) do parts[#parts + 1] = count[t] .. "x " .. t end
    out[#out + 1] = { pid = pid, role = pl.role, text = table.concat(parts, ", ") }
  end
  return out
end

local baseRecordIntel = War.recordIntel
function War:recordIntel(side, id)
  baseRecordIntel(self, side, id)
  local ns = self.state.nodes[id]
  local c = self:contact(side, "n:" .. id)
  if c then
    c.photo = self:photoOf(id)
    c.ewr = ns.ewr and ns.ewr.status or "none"
  end
  if ns.ewr and ns.ewr.status == "up" then
    self:addContact(side, "ewr:" .. id, { kind = "ewr", node = id, source = "recon", err = 300,
      label = "Early-warning radar" })
  end
end

-- What a side knows about an enemy radar site.
function War:ewrKnown(side, id)
  if self:isFresh(side, "ewr:" .. id) then return "known" end
  if self:contact(side, "ewr:" .. id) then return "stale" end
  return nil
end

-- ---------------------------------------------------------------------------
-- Missions: EWR strike and HVAA (high-value airborne asset)
-- ---------------------------------------------------------------------------
War.MISSION_NEEDS.EWR = "A2G"
War.MISSION_NEEDS.HVAA = "A2A"
do
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if t ~= "EWR" and t ~= "HVAA" then order[#order + 1] = t end
    if t == "SEAD" then order[#order + 1] = "EWR" end
    if t == "CAP" then order[#order + 1] = "HVAA" end
  end
  War.MISSION_ORDER = order
end

local gen = War.missionGenerators
gen.EWR = function(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local known = (not self.fogOfWar) or self:ewrKnown(side, id) == "known"
    if known and ns.side == enemy and ns.ewr and ns.ewr.status == "up" then
      out[#out + 1] = { type = "EWR", target = id, node = id, prio = dist[id] or 9,
        label = "early-warning radar at " .. self:nodeName(id) }
    end
  end
  return out
end

gen.HVAA = function(self, side)
  local enemy = U.otherSide(side)
  local seen = (not self.fogOfWar) or self:isFresh(side, "awacs:" .. enemy)
  if self:awacsUp(enemy) and seen then
    return { { type = "HVAA", target = enemy, prio = 0, label = enemy:upper() .. " AWACS" } }
  end
  return {}
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "EWR" then
    local ns = self.state.nodes[m.target]
    if ns.side == m.side then return "expired" end
    return (ns.ewr and ns.ewr.status ~= "up") and "done" or "open"
  elseif m.type == "HVAA" then
    for _, ev in ipairs(events) do
      if ev.kind == "awacs_lost" and ev.side == m.target then return "done" end
    end
    return self:awacsUp(m.target) and "open" or "expired"
  end
  return baseOutcome(self, m, events)
end

-- ---------------------------------------------------------------------------
-- Hooks into the tick and captures
-- ---------------------------------------------------------------------------
local baseCapture = War.onCaptureOps
function War:onCaptureOps(id)
  baseCapture(self, id)
  local ns = self.state.nodes[id]
  if ns.ewr then ns.ewr = { status = "destroyed", since = self.state.tick } end
end

local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:repairEwrs()
  self:restockAwacs()
end

end

-- >>> src/dcc_world.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - weather, night, AI adaptation, FARPs and ships
-- (pure Lua 5.1). Load after dcc_radar.lua.
-- ----------------------------------------------------------------------------
--   Weather  : a front passes every few hours: clear -> overcast -> rain ->
--              storm and back (a seeded Markov chain, saved with the war).
--              Rain and storms slow ground columns and soften battles; a storm
--              grounds helicopter missions and AI attack sorties.
--   Night    : the bridge tells the model when it is dark. Night halves
--              visual detection and stops AI attack sorties.
--   Adaption : every enemy kill on a road raises that road's THREAT for the
--              side that lost the column (decays by half every 3 h). The AI
--              then (1) routes convoys around threatened roads when it can,
--              (2) gives convoys on them an air-defence escort, and (3) sends
--              its CAP to cover the worst road.
--   FARPs    : helicopters that deliver farp.buildSU of crates to a friendly
--              town turn it into a FARP: rearm, refuel and helicopter spawns.
--              Lost when the town is captured.
--   Ships    : naval groups from the theater pack (a carrier in the Gulf).
--              Sunk = gone for the rest of the war, with its air wing. The
--              enemy gets an ANTISHIP mission once it has found the ship.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function W(self) return self.cfg.world end

-- ===========================================================================
-- Initialisation
-- ===========================================================================
function War:initWorld()
  local st = self.state
  st.weather = st.weather or { kind = "clear", since = st.tick }
  st.warId = st.warId or string.format("%s-%d", self.T.name, self.rng:int(1000000000))
  st.threat = st.threat or { blue = {}, red = {} }
  st.naval = st.naval or {}
  for _, ship in ipairs(self.theater and self.theater.naval or {}) do
    st.naval[ship.id] = st.naval[ship.id] or { status = "up", side = ship.side }
  end
end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  self:initWorld()
end

-- ===========================================================================
-- Weather and night
-- ===========================================================================
War.WEATHER_NEXT = {
  clear    = { { "clear", 0.5 }, { "overcast", 0.35 }, { "rain", 0.15 } },
  overcast = { { "clear", 0.3 }, { "overcast", 0.3 }, { "rain", 0.3 }, { "storm", 0.1 } },
  rain     = { { "clear", 0.1 }, { "overcast", 0.4 }, { "rain", 0.3 }, { "storm", 0.2 } },
  storm    = { { "overcast", 0.4 }, { "rain", 0.6 } },
}
War.WEATHER_TEXT = {
  clear = "clear skies", overcast = "overcast", rain = "rain and low cloud",
  storm = "storm - helicopters grounded",
}

-- Weather is one number, severity 0..1, that drifts a little every tick toward a
-- target (the next weather front). Every few hours a new front is picked from the
-- table above; the sky then turns over an hour or two, not at once:
--   clear 0 - overcast 0.33 - rain 0.66 - storm 1   (kind = nearest band)
-- Everything that depends on the weather (column speed, battles, eyes, fog)
-- follows the severity smoothly between those points.
War.WEATHER_SEV = { clear = 0, overcast = 0.33, rain = 0.66, storm = 1 }
local KINDS = { "clear", "overcast", "rain", "storm" }

local function kindOf(sev)
  if sev >= 0.85 then return "storm" elseif sev >= 0.5 then return "rain"
  elseif sev >= 0.18 then return "overcast" end
  return "clear"
end
War.weatherKindOf = kindOf

function War:weatherSeverity()
  local w = self.state.weather or {}
  return w.sev or War.WEATHER_SEV[w.kind or "clear"] or 0
end

function War:weatherKind() return self.state.weather and self.state.weather.kind or "clear" end
function War:isStorm() return self:weatherKind() == "storm" end
function War:isNight() return self.night == true end   -- set by the bridge, not saved

-- "getting worse", "clearing" or "" (steady)
function War:weatherTrend()
  local w = self.state.weather or {}
  local t, s = w.target, self:weatherSeverity()
  if not t or math.abs(t - s) < 0.05 then return "" end
  return t > s and "getting worse" or "clearing"
end

-- A value from a per-kind table ({ rain = 0.8, ... }, missing = 1) at the current
-- severity, interpolated between the kinds either side of it.
function War:weatherValue(tbl, sev)
  sev = sev or self:weatherSeverity()
  for i = 1, #KINDS - 1 do
    local a, b = KINDS[i], KINDS[i + 1]
    local sa, sb = War.WEATHER_SEV[a], War.WEATHER_SEV[b]
    if sev <= sb then
      local f = math.max(0, math.min(1, (sev - sa) / (sb - sa)))
      local va, vb = tbl[a] or 1, tbl[b] or 1
      return va + (vb - va) * f
    end
  end
  return tbl.storm or 1
end

function War:weatherTick()
  local cfg = W(self)
  local w = self.state.weather or { kind = "clear", since = self.state.tick }
  self.state.weather = w
  w.sev = w.sev or War.WEATHER_SEV[w.kind] or 0
  -- a new front: every frontTicks (random between the two), from the Markov table
  if not w.target or not w.nextFront or self.state.tick >= w.nextFront then
    local from = kindOf(w.target or w.sev)
    local roll, acc, nextKind = self.rng:next(), 0, from
    for _, opt in ipairs(War.WEATHER_NEXT[from]) do
      acc = acc + opt[2]
      if roll < acc then nextKind = opt[1]; break end
    end
    local jitter = (self.rng:next() - 0.5) * 0.12
    w.target = math.max(0, math.min(1, War.WEATHER_SEV[nextKind] + jitter))
    local lo, hi = cfg.weatherFrontTicks[1], cfg.weatherFrontTicks[2]
    w.nextFront = self.state.tick + lo + math.floor(self.rng:next() * (hi - lo + 1))
    if kindOf(w.target) ~= kindOf(w.sev) then
      local hours = math.abs(w.target - w.sev) / cfg.weatherDrift * self.cfg.tickSeconds / 3600
      self:log("weather_front", nil, string.format("Forecast for %s: %s within about %d h.", self.T.name,
        War.WEATHER_TEXT[kindOf(w.target)], math.max(1, math.floor(hours + 0.5))))
    end
  end
  -- drift toward it, with a little noise on the way
  local step = cfg.weatherDrift * (0.6 + 0.8 * self.rng:next())
  local d = w.target - w.sev
  if math.abs(d) <= step then w.sev = w.target else w.sev = w.sev + (d > 0 and step or -step) end
  local kind = kindOf(w.sev)
  if kind ~= w.kind then
    w.kind, w.since = kind, self.state.tick
    self:log("weather", nil, string.format("Weather on %s: %s.", self.T.name, War.WEATHER_TEXT[kind]))
  end
end

-- Ground column speed and dice battles in bad weather.
function War:moveSpeedFactor(mv)
  if mv.kind == "airlift" then return 1 end
  return self:weatherValue(W(self).speedFactor)
end

function War:battleFactor()
  return self:weatherValue(W(self).battleFactor)
end

-- Visual detection range multiplier (players' eyes).
function War:visualFactor(air)
  local f = self:weatherValue(W(self).visualFactor)
  if self:isNight() then f = f * W(self).nightVisual end
  return f
end

-- Can AI attack aircraft fly now?
function War:aiAttackAllowed()
  return not self:isStorm() and not self:isNight()
end

-- ===========================================================================
-- AI adaptation: road threat
-- ===========================================================================
local function edgeKey(a, b) if a < b then return a .. "|" .. b end return b .. "|" .. a end
War.edgeKey = edgeKey

function War:threatOn(side, a, b)
  return (self.state.threat[side] or {})[edgeKey(a, b)] or 0
end

function War:addThreat(side, a, b, amount)
  local t = self.state.threat[side]
  local k = edgeKey(a, b)
  local before = t[k] or 0
  t[k] = before + (amount or 1)
  local cfg = W(self)
  if before < cfg.escortThreat and t[k] >= cfg.escortThreat then
    self:log("adapt", side, string.format("%s command: convoys between %s and %s will get air-defence escorts",
      side:upper(), self:nodeName(a), self:nodeName(b)), { a = a, b = b })
  end
end

function War:decayThreat()
  local cfg = W(self)
  if self.state.tick % cfg.threatDecayTicks ~= 0 then return end
  for _, side in ipairs(SIDES) do
    for k, v in pairs(self.state.threat[side]) do
      v = v * 0.5
      self.state.threat[side][k] = (v >= 0.25) and v or nil
    end
  end
end

-- The road a side should cover with CAP: its worst threatened road.
function War:worstRoad(side)
  local best, bestV
  for _, k in ipairs(U.sortedKeys(self.state.threat[side])) do
    local v = self.state.threat[side][k]
    if v >= W(self).capThreat and (not bestV or v > bestV) then best, bestV = k, v end
  end
  if not best then return nil end
  local a, b = best:match("^(.-)|(.+)$")
  return a, b, bestV
end

-- Extra cost for planning a convoy on a threatened road (planConvoys adds it).
function War:routeCost(side, a, b)
  local t = self:threatOn(side, a, b)
  if t >= W(self).rerouteThreat then return W(self).reroutePenalty * t end
  return 0
end

-- Every killed column raises the threat on its road.
local baseMarkKilled = War.markKilled
function War:markKilled(mid)
  local mv = self.state.moves[mid]
  if mv and mv.kind ~= "airlift" and self.state.threat then self:addThreat(mv.side, mv.from, mv.to, 1) end
  baseMarkKilled(self, mid)
end

-- Convoys on threatened roads get an escort (an air-defence vehicle in the
-- column; abstract ambushes cannot touch them).
local baseStartCargo = War.startCargo
function War:startCargo(kind, side, from, to, amount)
  local mv = baseStartCargo(self, kind, side, from, to, amount)
  if mv and kind == "convoy" and self:threatOn(side, from, to) >= W(self).escortThreat then
    mv.aiEscort, mv.escorted = true, true
  end
  return mv
end

-- ===========================================================================
-- FARPs
-- ===========================================================================
function War:canHaveFarp(id)
  return self.T.nodes[id].kind == "town"
end

local baseDeliverCrate = War.deliverCrate
function War:deliverCrate(side, id, su)
  local ok = baseDeliverCrate(self, side, id, su)
  local ns = self.state.nodes[id]
  if ok and self:canHaveFarp(id) and not ns.farp then
    ns.farpSU = (ns.farpSU or 0) + su
    local need = W(self).farpBuildSU
    if ns.farpSU >= need then self:buildFarp(id, side, "crates") end
  end
  return ok
end

-- A FARP goes up at town id: from supply crates, a FARP kit (Chinook / Mi-8)
-- or a CTLD FOB. Returns false if the town cannot have one.
function War:buildFarp(id, side, how, extra)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side or not self:canHaveFarp(id) or self:farpAt(id) then return false end
  ns.farp = { side = side, built = self.state.tick, how = how, stock = W(self).farpStock }
  for k, v in pairs(extra or {}) do ns.farp[k] = v end
  ns.farpSU = nil
  local what = (how == "kit" and "flew in a FARP kit") or (how == "fob" and "built a FOB") or "built a FARP"
  self:log("farp_built", side, string.format("%s helicopters %s at %s - rearm, refuel and spawn there",
    side:upper(), what, self:nodeName(id)), { node = id })
  return true
end

function War:farpAt(id)
  local f = self.state.nodes[id].farp
  return f ~= nil and f.side == self.state.nodes[id].side
end

-- FARP stock: fuel, ammo and spares the FARP itself holds (SU). It runs down
-- every tick; at 0 the FARP is dry - no helicopter spawns, empty shelves -
-- until a helicopter brings crates (FARPSUP mission).
function War:farpStock(id)
  local f = self.state.nodes[id].farp
  if not f then return 0 end
  return f.stock or W(self).farpStock          -- saves from before v0.17 start full
end

function War:farpDry(id)
  return self:farpAt(id) and self:farpStock(id) <= 0
end

function War:farpTick()
  for _, id in ipairs(self.T.order) do
    if self:farpAt(id) then
      local f = self.state.nodes[id].farp
      local before = self:farpStock(id)
      f.stock = math.max(0, before - W(self).farpUsePerTick)
      if before > 0 and f.stock <= 0 then
        self:log("farp_dry", f.side, string.format("The %s FARP at %s has run dry - no rearm or helicopter spawns "
          .. "until it is resupplied", f.side:upper(), self:nodeName(id)), { node = id })
      end
    end
  end
end

-- Crates set down at a FARP town fill the FARP first, the rest goes to the town.
local baseDeliverFarp = War.deliverCrate
function War:deliverCrate(side, id, su)
  local ns = self.state.nodes[id]
  if ns.side ~= side or not self:farpAt(id) then return baseDeliverFarp(self, side, id, su) end
  local f = ns.farp
  local put = math.min(su, math.max(0, W(self).farpStock - self:farpStock(id)))
  if put > 0 then
    f.stock = self:farpStock(id) + put
    self:log("airdrop", side, string.format("%s helicopters resupplied the FARP at %s (+%d SU, %d/%d)",
      side:upper(), self:nodeName(id), math.floor(put + 0.5), math.floor(f.stock + 0.5), W(self).farpStock),
      { node = id, su = put, farp = true })
  end
  if su - put > 0 then return baseDeliverFarp(self, side, id, su - put) end
  return true
end

-- ===========================================================================
-- Ships
-- ===========================================================================
function War:shipUp(id) return self.state.naval[id] ~= nil and self.state.naval[id].status == "up" end

function War:shipLost(id)
  local s = self.state.naval[id]
  if not s or s.status ~= "up" then return end
  s.status, s.since = "sunk", self.state.tick
  local name = id
  for _, ship in ipairs(self.theater and self.theater.naval or {}) do if ship.id == id then name = ship.name end end
  self:log("ship_sunk", s.side, string.format("%s %s has been sunk - its air wing is lost for the rest of the war",
    s.side:upper(), name), { ship = id })
end

War.MISSION_NEEDS.ANTISHIP = "A2G"
War.MISSION_NEEDS.FARP = "LIFT"
War.MISSION_NEEDS.FARPSUP = "LIFT"
do
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if t ~= "ANTISHIP" and t ~= "FARP" and t ~= "FARPSUP" then order[#order + 1] = t end
    if t == "STRIKE" then order[#order + 1] = "ANTISHIP" end
    if t == "LOGISTICS" then order[#order + 1] = "FARP"; order[#order + 1] = "FARPSUP" end
  end
  War.MISSION_ORDER = order
end

local gen = War.missionGenerators
gen.ANTISHIP = function(self, side)
  local out = {}
  for _, ship in ipairs(self.theater and self.theater.naval or {}) do
    local known = (not self.fogOfWar) or self:isFresh(side, "ship:" .. ship.id)
    if ship.side ~= side and self:shipUp(ship.id) and known then
      out[#out + 1] = { type = "ANTISHIP", target = ship.id, prio = 0, label = ship.name }
    end
  end
  return out
end

-- Build a FARP: friendly towns right behind the front, no FARP yet.
gen.FARP = function(self, side)
  if self:isStorm() then return {} end
  local dist = self:frontDistance(side)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == side and self:canHaveFarp(id) and not self:farpAt(id) and (dist[id] or 9) <= 2 then
      out[#out + 1] = { type = "FARP", target = id, node = id, prio = dist[id] or 9,
        label = string.format("build a FARP at %s (FARP kit, or crates %d/%d SU)", self:nodeName(id),
          math.floor(ns.farpSU or 0), W(self).farpBuildSU) }
    end
  end
  return out
end

-- Resupply a FARP: own FARPs below half stock, the emptiest first.
gen.FARPSUP = function(self, side)
  local out, max = {}, W(self).farpStock
  for _, id in ipairs(self.T.order) do
    if self.state.nodes[id].side == side and self:farpAt(id) and self:farpStock(id) < max * W(self).farpLowShare then
      local st = self:farpStock(id)
      out[#out + 1] = { type = "FARPSUP", target = id, node = id, prio = st,
        label = string.format("resupply the FARP at %s (%d/%d SU%s)", self:nodeName(id), math.floor(st + 0.5), max,
          st <= 0 and ", DRY" or "") }
    end
  end
  return out
end

-- Helicopter missions stay on the ground in a storm.
local HELO = { CONVOY = true, CSAR = true, LOGISTICS = true, FARP = true, FARPSUP = true }
for t in pairs(HELO) do
  local g = gen[t]
  if g then
    gen[t] = function(self, side)
      if self:isStorm() then return {} end
      return g(self, side)
    end
  end
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "ANTISHIP" then
    return self:shipUp(m.target) and "open" or "done"
  elseif m.type == "FARP" then
    if self.state.nodes[m.target].side ~= m.side then return "expired" end
    return self:farpAt(m.target) and "done" or "open"
  elseif m.type == "FARPSUP" then
    if not self:farpAt(m.target) or self.state.nodes[m.target].side ~= m.side then return "expired" end
    for _, ev in ipairs(events) do
      if ev.kind == "airdrop" and ev.farp and ev.node == m.target and ev.side == m.side then return "done" end
    end
    return "open"
  end
  return baseOutcome(self, m, events)
end

-- ===========================================================================
-- Hooks
-- ===========================================================================
local baseCapture = War.onCaptureOps
function War:onCaptureOps(id)
  baseCapture(self, id)
  local ns = self.state.nodes[id]
  ns.farp, ns.farpSU = nil, nil
end

local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:farpTick()
  self:weatherTick()
  self:decayThreat()
end

end

-- >>> src/dcc_air.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - air war additions (pure Lua 5.1).
-- Load after dcc_world.lua.
-- ----------------------------------------------------------------------------
--   Assets    : tankers and recon drones per side (pools, bought with supply,
--               like the AWACS). The bridge flies them and reports losses.
--   Packages  : AI raids the defender can stop. A STRIKE package (strikers +
--               escort + SEAD) flies at a real target - a depot's stores, a
--               SAM site, an early-warning radar or a FARP. An AIRMOBILE raid
--               (transport helicopters with a platoon) flies at a weak enemy
--               base behind the front. Each one opens an INTERCEPT mission
--               for the other side once it has been detected.
--                 reaches the target -> the damage / the landing happens
--                 shot down first    -> nothing happens (and the platoon is lost)
--   Missions  : INTERCEPT (packages), TANKER (shoot down the enemy tanker).
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function A(self) return self.cfg.air end

-- ---------------------------------------------------------------------------
-- Initialisation
-- ---------------------------------------------------------------------------
function War:initAir()
  local st, cfg = self.state, A(self)
  st.packages = st.packages or {}
  st.assets = st.assets or { blue = {}, red = {} }
  for _, side in ipairs(SIDES) do
    local p = st.airPool[side]
    for kind, n in pairs(cfg.assetPoolStart) do
      if p[kind] == nil then p[kind] = n end
    end
  end
end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  self:initAir()
end

-- ---------------------------------------------------------------------------
-- Tankers and drones
-- ---------------------------------------------------------------------------
function War:setAsset(side, kind, up) self.state.assets[side][kind] = up and true or nil end
function War:assetUp(side, kind) return self.state.assets[side][kind] == true end

function War:assetLost(side, kind)
  self.state.assets[side][kind] = nil
  self:airLoss(side, kind, 1)
  local name = (kind == "tanker") and "tanker" or "recon drone"
  self:log(kind .. "_lost", side, string.format("%s %s shot down", side:upper(), name), {})
end

function War:restockAssets()
  local cfg = A(self)
  for kind, every in pairs(cfg.assetRestockTicks) do
    if self.state.tick % every == 0 then
      for _, side in ipairs(SIDES) do
        local p = self.state.airPool[side]
        if (p[kind] or 0) < cfg.assetPoolMax[kind] then
          for _, id in ipairs(self.T.order) do
            local ns = self.state.nodes[id]
            if self.T.nodes[id].depot and ns.side == side and ns.supply >= cfg.assetRestockCost[kind] then
              ns.supply = ns.supply - cfg.assetRestockCost[kind]
              p[kind] = (p[kind] or 0) + 1
              break
            end
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Packages
-- ---------------------------------------------------------------------------
-- What a strike package goes for: the best target the side knows of.
-- Returns { node, kind = "infra" | "sam" | "ewr" | "farp" } or nil.
function War:pickStrikeTarget(side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(side)          -- enemy nodes near our front have small values
  local best, bestScore
  for _, id in ipairs(self.T.order) do
    local ns, d = self.state.nodes[id], dist[id] or 9
    if ns.side == enemy and d <= 3 then
      local cands = {}
      if ns.infra and self:infraLost(id) < ns.infra.total then cands[#cands + 1] = { "infra", self.T.nodes[id].depot and 0 or 2 } end
      if ns.sam and ns.sam.status == "up" then cands[#cands + 1] = { "sam", 1 } end
      if ns.ewr and ns.ewr.status == "up" then cands[#cands + 1] = { "ewr", 1 } end
      if self.farpAt and self:farpAt(id) then cands[#cands + 1] = { "farp", 0 } end
      for _, c in ipairs(cands) do
        local score = c[2] * 10 + d
        if not bestScore or score < bestScore then best, bestScore = { node = id, kind = c[1] }, score end
      end
    end
  end
  return best
end

-- A weak enemy base behind the front for an air assault from a friendly base.
function War:pickAirAssault(side, maxKm)
  local enemy = U.otherSide(side)
  local best, bestKey
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and #ns.platoons <= A(self).airAssaultMaxDefenders and not self.T.nodes[id].depot then
      for _, from in ipairs(self.T.order) do
        local fs = self.state.nodes[from]
        if fs.side == side and #fs.platoons >= 3 and U.distKm(self.T.nodes[from], self.T.nodes[id]) <= maxKm then
          local key = #ns.platoons * 1000 + U.distKm(self.T.nodes[from], self.T.nodes[id])
          if not bestKey or key < bestKey then best, bestKey = { from = from, to = id }, key end
        end
      end
    end
  end
  return best
end

-- The bridge launched a package. For an air assault, one platoon boards.
function War:packageLaunched(side, kind, target, from)
  local id = self:newId("k")
  local pk = { id = id, side = side, kind = kind, target = target, from = from, status = "inbound",
               launched = self.state.tick }
  if kind == "airmobile" then
    local ns = self.state.nodes[from]
    local pid = ns.platoons[#ns.platoons]
    if not pid or not self:carryPlatoon(pid, "ai:" .. id) then return nil end
    pk.platoon = pid
  end
  self.state.packages[id] = pk
  return pk
end

-- Shot down before it got there.
function War:packageDestroyed(id)
  local pk = self.state.packages[id]
  if not pk or pk.status ~= "inbound" then return end
  pk.status, pk.ended = "destroyed", self.state.tick
  if pk.platoon then self:loseCarried(pk.platoon) end
  self:log("package_down", pk.side, string.format("%s %s on its way to %s shot down", pk.side:upper(),
    pk.kind == "airmobile" and "air assault" or "strike package", self:nodeName(pk.target.node or pk.target)), {})
end

-- It got through.
function War:packageArrived(id)
  local pk = self.state.packages[id]
  if not pk or pk.status ~= "inbound" then return end
  pk.status, pk.ended = "hit", self.state.tick
  if pk.kind == "airmobile" then
    self:dropPlatoons({ pk.platoon }, pk.target, pk.side)     -- logs the assault itself
  else
    local node, kind = pk.target.node, pk.target.kind
    local ns = self.state.nodes[node]
    if kind == "infra" and ns.infra then
      for k = 1, ns.infra.total do
        if not ns.infra.lost[tostring(k)] then self:infraHit(node, k); break end
      end
    elseif kind == "sam" then self:samHit(node, "radar")
    elseif kind == "ewr" then self:ewrHit(node)
    elseif kind == "farp" and ns.farp then
      ns.farp = nil
      self:log("farp_lost", ns.side, string.format("%s FARP at %s destroyed", ns.side:upper(), self:nodeName(node)), { node = node })
    end
    self:log("strike_hit", pk.side, string.format("%s strike package hit %s at %s", pk.side:upper(),
      kind == "infra" and "the stores" or (kind == "sam" and "the SAM site" or (kind == "ewr" and "the radar" or "the FARP")),
      self:nodeName(node)), { node = node })
  end
end

function War:packagesTick()
  for id, pk in pairs(self.state.packages) do
    if pk.status ~= "inbound" and self.state.tick - (pk.ended or 0) > 12 then self.state.packages[id] = nil end
  end
end

-- ---------------------------------------------------------------------------
-- Missions
-- ---------------------------------------------------------------------------
War.MISSION_NEEDS.INTERCEPT = "A2A"
War.MISSION_NEEDS.TANKER = "A2A"
do
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if t ~= "INTERCEPT" and t ~= "TANKER" then order[#order + 1] = t end
    if t == "CAP" then order[#order + 1] = "INTERCEPT" end
    if t == "HVAA" then order[#order + 1] = "TANKER" end
  end
  War.MISSION_ORDER = order
end

local gen = War.missionGenerators
gen.INTERCEPT = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.packages)) do
    local pk = self.state.packages[id]
    local seen = (not self.fogOfWar) or self:isFresh(side, "pkg:" .. id)
    if pk.side ~= side and pk.status == "inbound" and seen then
      local node = pk.target.node or pk.target
      out[#out + 1] = { type = "INTERCEPT", target = id, node = node, prio = 0,
        label = string.format("%s %s inbound to %s", pk.side:upper(),
          pk.kind == "airmobile" and "assault helicopters" or "strike package", self:nodeName(node)) }
    end
  end
  return out
end

gen.TANKER = function(self, side)
  local enemy = U.otherSide(side)
  local seen = (not self.fogOfWar) or self:isFresh(side, "tanker:" .. enemy)
  if self:assetUp(enemy, "tanker") and seen then
    return { { type = "TANKER", target = enemy, prio = 1, label = enemy:upper() .. " tanker" } }
  end
  return {}
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "INTERCEPT" then
    local pk = self.state.packages[m.target]
    if not pk then return "expired" end
    if pk.status == "destroyed" then return "done" end
    if pk.status == "hit" then return "failed" end
    return "open"
  elseif m.type == "TANKER" then
    for _, ev in ipairs(events) do
      if ev.kind == "tanker_lost" and ev.side == m.target then return "done" end
    end
    return self:assetUp(m.target, "tanker") and "open" or "expired"
  end
  return baseOutcome(self, m, events)
end

local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:restockAssets()
  self:packagesTick()
end

-- ---------------------------------------------------------------------------
-- Helicopter supply runs: short hops to the front by real AI transport
-- helicopters (towns too, not only airbases). A kind of airlift (mv.helo):
-- escortable (ESCORT, any aircraft), interceptable, lost when shot down.
-- Cut-off bases and bases behind a threatened road come first.
-- ---------------------------------------------------------------------------
local basePlanAirlifts = War.planAirlifts
function War:planAirlifts(side, dist, focus)
  basePlanAirlifts(self, side, dist, focus)
  self:planHelilifts(side, dist, focus)
end

function War:planHelilifts(side, dist, focus)
  local cfg = self.cfg.supply
  local cap = cfg.heliliftCapacity or 0
  if (cfg.maxHelilifts or 0) <= 0 or cap <= 0 then return end
  if self.isStorm and self:isStorm() then return end
  local active = 0
  for _, mv in pairs(self.state.moves) do
    if mv.helo and mv.side == side then active = active + 1 end
  end
  if active >= cfg.maxHelilifts then return end
  local sdist = self:stagingDistance(side, focus)
  local supplied = self:supplied(side)

  -- candidate destinations, most urgent first
  local cands = {}
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    local busy = false
    for _, mv in pairs(self.state.moves) do if mv.helo and mv.to == id then busy = true end end
    self.state.heliLast = self.state.heliLast or {}
    local last = self.state.heliLast[id]
    if last and self.state.tick - last < (cfg.heliliftEveryTicks or 0) then busy = true end
    if ns.side == side and tn.kind ~= "carrier" and not busy and (dist[id] == 1 or sdist[id] == 0) then
      local keep = self:supplyKeep(id, dist, sdist)
      local need = keep - ns.supply - self:incomingSupply(id, side)
      local threat = 0
      if self.threatOn then
        for nb in pairs(tn.nb) do
          if self.state.nodes[nb].side == side then threat = math.max(threat, self:threatOn(side, nb, id)) end
        end
      end
      -- helicopters are for emergencies: cut off, or the road in is under attack
      local urgent = not supplied[id] or threat > 0
      if need >= cap * 0.5 and urgent then
        cands[#cands + 1] = { id = id, key = (supplied[id] and 1 or 0) * 100000 - threat * 1000 - need }
      end
    end
  end
  table.sort(cands, function(a, b) if a.key ~= b.key then return a.key < b.key end return a.id < b.id end)

  -- the first one a base 15-120 km away can supply
  local dst, src, srcKm
  for _, c in ipairs(cands) do
    for _, id in ipairs(self.T.order) do
      local ns, tn = self.state.nodes[id], self.T.nodes[id]
      if id ~= c.id and ns.side == side and tn.kind ~= "carrier" and dist[id] and dist[id] > 1 then
        local km = U.distKm(self.T.nodes[id], self.T.nodes[c.id])
        local surplus = ns.supply - self:supplyKeep(id, dist, sdist)
        if km >= cfg.heliliftMinKm and km <= cfg.heliliftMaxKm and surplus >= cap and (not srcKm or km < srcKm) then
          src, srcKm = id, km
        end
      end
    end
    if src then dst = c.id; break end
  end
  if not dst then return end
  local mv = self:startCargo("airlift", side, src, dst, cap)
  if mv then
    mv.helo, mv.km = true, srcKm
    self.state.heliLast = self.state.heliLast or {}
    self.state.heliLast[dst] = self.state.tick
    self:log("helilift", side, string.format("%s supply helicopter departs %s for %s", side:upper(),
      self:nodeName(src), self:nodeName(dst)), { node = dst })
  end
end

-- ---------------------------------------------------------------------------
-- INTERCEPT also for enemy airlifts and supply helicopters once detected
-- (target = the move). Helicopters: any aircraft may take it; transports: A2A.
--   shot down -> done, landed -> failed.
-- ---------------------------------------------------------------------------
local genIntercept = gen.INTERCEPT
gen.INTERCEPT = function(self, side)
  local out = genIntercept(self, side)
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    local seen = (not self.fogOfWar) or self:isFresh(side, "m:" .. mid)
    if mv.kind == "airlift" and mv.side ~= side and mv.status == "moving" and seen then
      out[#out + 1] = { type = "INTERCEPT", target = mid, node = mv.to, prio = mv.helo and 1 or 2,
        needs = mv.helo and "ANY" or nil,
        label = string.format("%s %s %s > %s", mv.side:upper(), mv.helo and "supply helicopters" or "airlift",
          self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

local baseOutcomeLift = War.missionOutcome
function War:missionOutcome(m, events)
  local st = self.state
  if m.type == "INTERCEPT" and not st.packages[m.target] then
    if st.moves[m.target] then return "open" end
    if st.killedMoves and st.killedMoves[m.target] then return "done" end
    if st.deliveredMoves and st.deliveredMoves[m.target] then return "failed" end
  end
  return baseOutcomeLift(self, m, events)
end

end

-- >>> src/dcc_ground.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - ground war additions (pure Lua 5.1).
-- Load after dcc_air.lua.
-- ----------------------------------------------------------------------------
--   Artillery     : each side has a few batteries. Every tick they move up to
--                   the friendly bases next to the side's main effort target.
--                   A battery next to a battle makes the enemy bleed faster
--                   (x ground.artyFactor). Firing gives it away: the enemy
--                   gets a contact and an ARTY strike mission. Destroyed
--                   batteries are rebuilt at a depot after 6 h for supply.
--   Fortifications: a base nobody attacks digs in, one level every 6 h for a
--                   little supply, up to 3 levels (+10 % defence each). STRIKE
--                   the bunkers (FORT mission) before an assault. Lost on capture.
--   Bridges       : the bridge layer finds real DCS bridges on the roads; a
--                   destroyed bridge closes that road for ground.bridgeTicks
--                   (columns on it stop, the AI plans around it) until the
--                   engineers have a crossing up. BRIDGE missions target the
--                   enemy's supply roads.
--   Morale        : a base cut off from its depots, or out of supply, defends
--                   worse (x0.8 / x0.7). A cut-off, out-of-supply base with
--                   only a couple of platoons left surrenders to the enemy.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function G(self) return self.cfg.ground end

function War:initGround()
  local st, cfg = self.state, G(self)
  st.artillery = st.artillery or {}
  for _, side in ipairs(SIDES) do
    if not st.artillery[side] then
      st.artillery[side] = {}
      for i = 1, cfg.batteries do
        st.artillery[side][i] = { id = side:sub(1, 1) .. "a" .. i, status = "up", node = nil }
      end
    end
  end
  st.blocked = st.blocked or {}
  for _, id in ipairs(self.T.order) do
    local ns = st.nodes[id]
    ns.fort = ns.fort or 0
    ns.fortSince = ns.fortSince or st.tick
  end
  -- re-close roads that were closed when the war was saved
  for key in pairs(st.blocked) do
    local a, b = key:match("^(.-)|(.+)$")
    self:closeRoad(a, b)
  end
end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  self:initGround()
end

-- ===========================================================================
-- Artillery
-- ===========================================================================
function War:batteries(side) return self.state.artillery[side] end

-- Batteries move up behind the main effort (abstract: a battery "is at" a node).
function War:placeArtillery()
  for _, side in ipairs(SIDES) do
    local f = self.state.focus and self.state.focus[side]
    local spots = {}
    if f then
      for _, nb in ipairs(U.sortedKeys(self.T.nodes[f.target].nb)) do
        if self.state.nodes[nb].side == side then spots[#spots + 1] = nb end
      end
    end
    -- also cover our own bases under attack
    for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
      local mv = self.state.moves[mid]
      if mv.status == "fighting" and mv.side ~= side and self.state.nodes[mv.to].side == side then
        spots[#spots + 1] = mv.to
      end
    end
    local i = 1
    for _, b in ipairs(self:batteries(side)) do
      if b.status == "up" then
        local spot = spots[((i - 1) % math.max(#spots, 1)) + 1]
        if spot and self.state.nodes[spot].side == side then b.node = spot else b.node = nil end
        i = i + 1
      elseif b.status == "destroyed" and self.state.tick - (b.since or 0) >= G(self).batteryRebuildTicks then
        for _, id in ipairs(self.T.order) do
          local ns = self.state.nodes[id]
          if self.T.nodes[id].depot and ns.side == side and ns.supply >= G(self).batteryRebuildCost then
            ns.supply = ns.supply - G(self).batteryRebuildCost
            b.status, b.node, b.since = "up", nil, nil
            break
          end
        end
      end
    end
  end
end

-- Batteries of `side` in range of a battle at `target`.
function War:artyAt(side, target)
  local out = {}
  for _, b in ipairs(self:batteries(side)) do
    if b.status == "up" and b.node and self.state.nodes[b.node].side == side
       and (b.node == target or self.T.nodes[target].nb[b.node]) then
      out[#out + 1] = b
    end
  end
  return out
end

-- Loss multiplier the ENEMY of `side` suffers at `target` (artillery fire).
function War:artyFactor(side, target)
  local n = #self:artyAt(side, target)
  if n == 0 then return 1 end
  -- firing gives the batteries away (counter-battery radar, muzzle flashes)
  for _, b in ipairs(self:artyAt(side, target)) do
    self:addContact(U.otherSide(side), "arty:" .. b.id, { kind = "arty", node = b.node, source = "sensor",
      label = "artillery battery" })
  end
  return 1 + (G(self).artyFactor - 1) * math.min(n, 2)
end

function War:batteryHit(id)
  for _, side in ipairs(SIDES) do
    for _, b in ipairs(self:batteries(side)) do
      if b.id == id and b.status == "up" then
        b.status, b.since = "destroyed", self.state.tick
        self:log("arty_destroyed", side, string.format("%s artillery battery at %s destroyed", side:upper(),
          b.node and self:nodeName(b.node) or "the front"), { node = b.node })
        b.node = nil
        return true
      end
    end
  end
end

-- ===========================================================================
-- Fortifications
-- ===========================================================================
function War:fortTick()
  local cfg = G(self)
  local attacked = {}
  for _, mv in pairs(self.state.moves) do
    if mv.status == "fighting" then attacked[mv.to] = true end
  end
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if attacked[id] then
      ns.fortSince = self.state.tick
    elseif ns.fort < cfg.fortMax and self.state.tick - ns.fortSince >= cfg.fortTicks
           and (ns.supply or 0) >= cfg.fortCost then
      ns.supply = ns.supply - cfg.fortCost
      ns.fort, ns.fortSince = ns.fort + 1, self.state.tick
    end
  end
end

function War:fortHit(id)
  local ns = self.state.nodes[id]
  if ns.fort > 0 then
    ns.fort, ns.fortSince = ns.fort - 1, self.state.tick
    self:log("fort_hit", ns.side, string.format("%s fortifications at %s damaged (level %d left)", ns.side:upper(),
      self:nodeName(id), ns.fort), { node = id })
  end
end

-- ===========================================================================
-- Morale
-- ===========================================================================
-- Is a node cut off from every own depot?
function War:cutOff(id)
  local side = self.state.nodes[id].side
  -- cached per tick: bonusOf (and so this) runs many times while planning
  if self._supTick ~= self.state.tick then self._supTick, self._sup = self.state.tick, {} end
  self._sup[side] = self._sup[side] or self:supplied(side)
  return not self._sup[side][id]
end

function War:moraleFactor(id)
  local ns, f = self.state.nodes[id], 1
  if ns.outOfSupply then f = f * G(self).moraleNoSupply end
  if self:cutOff(id) then f = f * G(self).moraleCutOff end
  return f
end

-- Defence bonus: fortifications and morale on top of the old bonus.
local baseBonus = War.bonusOf
function War:bonusOf(id)
  local ns = self.state.nodes[id]
  return baseBonus(self, id) * (1 + G(self).fortBonus * (ns.fort or 0)) * self:moraleFactor(id)
end

-- Cut off, out of supply and nearly gone: surrender to the strongest neighbour.
function War:surrenderTick()
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.outOfSupply and #ns.platoons <= G(self).surrenderAt and self:cutOff(id) and not self.T.nodes[id].depot then
      local best, bestN
      for nb in pairs(self.T.nodes[id].nb) do
        local o = self.state.nodes[nb]
        if o.side ~= ns.side and (not bestN or #o.platoons > bestN) then best, bestN = nb, #o.platoons end
      end
      if best and bestN > 0 then
        local loser, winner = ns.side, self.state.nodes[best].side
        for _, pid in ipairs(U.copy(ns.platoons)) do self:destroyPlatoon(pid) end
        -- one platoon of the neighbour walks in
        local pid = self.state.nodes[best].platoons[#self.state.nodes[best].platoons]
        U.removeValue(self.state.nodes[best].platoons, pid)
        ns.side = winner
        self.state.platoons[pid].node = id
        ns.platoons = { pid }
        if self.onCaptureSupply then self:onCaptureSupply(id) end
        if self.onCaptureOps then self:onCaptureOps(id) end
        self.state.stats.captures[winner] = self.state.stats.captures[winner] + 1
        self:log("surrender", winner, string.format("%s garrison at %s surrendered to %s - cut off and out of supply",
          loser:upper(), self:nodeName(id), winner:upper()), { node = id })
        self:log("capture", winner, string.format("%s captured %s from %s", winner:upper(), self:nodeName(id),
          loser:upper()), { node = id, from = loser })
      end
    end
  end
end

-- ===========================================================================
-- Bridges and closed roads
-- ===========================================================================
local function key(a, b) if a < b then return a .. "|" .. b end return b .. "|" .. a end

function War:roadClosed(a, b) return self.state.blocked[key(a, b)] ~= nil end

-- Take the road out of the network (planning, front distance, movement).
function War:closeRoad(a, b)
  local na, nb = self.T.nodes[a], self.T.nodes[b]
  if not na or not nb then return end
  self.closedKm = self.closedKm or {}
  local km = na.nb[b] or nb.nb[a]
  if km then self.closedKm[key(a, b)] = km end
  na.nb[b], nb.nb[a] = nil, nil
end

function War:openRoad(a, b)
  local km = self.closedKm and self.closedKm[key(a, b)]
  if km then
    self.T.nodes[a].nb[b], self.T.nodes[b].nb[a] = km, km
    self.closedKm[key(a, b)] = nil
  end
end

-- A bridge on road a-b is down.
function War:bridgeDown(a, b)
  if self:roadClosed(a, b) then return end
  self.state.blocked[key(a, b)] = self.state.tick + G(self).bridgeTicks
  self:closeRoad(a, b)
  self:log("bridge_down", self.state.nodes[a].side, string.format("Bridge on the road %s - %s destroyed: road closed for %d h",
    self:nodeName(a), self:nodeName(b), G(self).bridgeTicks * self.cfg.tickSeconds / 3600), { a = a, b = b })
end

function War:bridgesTick()
  for k, untilTick in pairs(self.state.blocked) do
    if self.state.tick >= untilTick then
      local a, b = k:match("^(.-)|(.+)$")
      self.state.blocked[k] = nil
      self:openRoad(a, b)
      self:log("bridge_up", nil, string.format("Engineers reopened the road %s - %s", self:nodeName(a), self:nodeName(b)),
        { a = a, b = b })
    end
  end
end

-- Columns on a closed road wait.
local baseSpeed = War.moveSpeedFactor
function War:moveSpeedFactor(mv)
  if mv.kind ~= "airlift" and mv.from and mv.to and self:roadClosed(mv.from, mv.to) then return 0 end
  return baseSpeed and baseSpeed(self, mv) or 1
end

-- Bridges the bridge layer found: war.bridges = { { a, b, pos = {x,z} }, ... } (not saved)

-- ===========================================================================
-- Missions: ARTY, FORT, BRIDGE
-- ===========================================================================
War.MISSION_NEEDS.ARTY = "A2G"
War.MISSION_NEEDS.FORT = "A2G"
War.MISSION_NEEDS.BRIDGE = "A2G"
do
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if t ~= "ARTY" and t ~= "FORT" and t ~= "BRIDGE" then order[#order + 1] = t end
    if t == "BAI" then order[#order + 1] = "ARTY" end
    if t == "STRIKE" then order[#order + 1] = "FORT"; order[#order + 1] = "BRIDGE" end
  end
  War.MISSION_ORDER = order
end

local gen = War.missionGenerators
gen.ARTY = function(self, side)
  local enemy, out = U.otherSide(side), {}
  for _, b in ipairs(self:batteries(enemy)) do
    local known = (not self.fogOfWar) or self:isFresh(side, "arty:" .. b.id)
    if b.status == "up" and b.node and known then
      out[#out + 1] = { type = "ARTY", target = b.id, node = b.node, prio = 0,
        label = "artillery battery at " .. self:nodeName(b.node) }
    end
  end
  return out
end

gen.FORT = function(self, side)
  local enemy, out = U.otherSide(side), {}
  local f = self.state.focus and self.state.focus[side]
  local dist = self:frontDistance(enemy)
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and ns.fort > 0 and (dist[id] or 9) <= 1 then
      out[#out + 1] = { type = "FORT", target = id, node = id, prio = (f and f.target == id) and 0 or 5,
        label = string.format("fortifications at %s (level %d)", self:nodeName(id), ns.fort), base = { fort = ns.fort } }
    end
  end
  return out
end

gen.BRIDGE = function(self, side)
  local enemy, out = U.otherSide(side), {}
  local dist = self:frontDistance(enemy)
  for _, br in ipairs(self.bridges or {}) do
    local sa, sb = self.state.nodes[br.a].side, self.state.nodes[br.b].side
    if sa == enemy and sb == enemy and not self:roadClosed(br.a, br.b)
       and math.min(dist[br.a] or 9, dist[br.b] or 9) <= 2 then
      out[#out + 1] = { type = "BRIDGE", target = br.a .. "|" .. br.b, node = br.a,
        prio = math.min(dist[br.a] or 9, dist[br.b] or 9),
        label = string.format("bridge on the road %s - %s", self:nodeName(br.a), self:nodeName(br.b)) }
    end
  end
  return out
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "ARTY" then
    for _, side in ipairs(SIDES) do
      for _, b in ipairs(self:batteries(side)) do
        if b.id == m.target then return (b.status == "up") and (b.node and "open" or "expired") or "done" end
      end
    end
    return "expired"
  elseif m.type == "FORT" then
    local ns = self.state.nodes[m.target]
    if ns.side == m.side then return "expired" end
    return (ns.fort < (m.base.fort or 0)) and "done" or "open"
  elseif m.type == "BRIDGE" then
    local a, b = m.target:match("^(.-)|(.+)$")
    return self:roadClosed(a, b) and "done" or "open"
  end
  return baseOutcome(self, m, events)
end

-- ===========================================================================
-- Hooks
-- ===========================================================================
local baseRound = War.abstractRound
function War:abstractRound(target, attackers)
  -- artillery: wrap the loss multiplier into the battle factor for this round
  local defSide = self.state.nodes[target].side
  local attSide = attackers[1] and attackers[1].side
  local fAtt = attSide and self:artyFactor(attSide, target) or 1     -- hurts the defender
  local fDef = self:artyFactor(defSide, target)                       -- hurts the attacker
  local damage = self.damage
  local defenders = self.state.nodes[target].platoons
  self.damage = function(me, pids, loss)
    if pids == defenders then loss = loss * fAtt else loss = loss * fDef end
    return damage(me, pids, loss)
  end
  local ok, err = pcall(baseRound, self, target, attackers)
  self.damage = nil                                                   -- back to War.damage
  if not ok then error(err) end
end

local baseCapture = War.onCaptureOps
function War:onCaptureOps(id)
  baseCapture(self, id)
  local ns = self.state.nodes[id]
  ns.fort, ns.fortSince = 0, self.state.tick
end

local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:placeArtillery()
  self:fortTick()
  self:bridgesTick()
  self:surrenderTick()
end

end

-- >>> src/dcc_ext.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - more air and ground war (pure Lua 5.1).
-- Load after dcc_ground.lua.
-- ----------------------------------------------------------------------------
--   Armoury      : what a base can arm aircraft with follows its supply
--                  (basic / guided / advanced weapons); guided and advanced
--                  weapons cost supply when an aircraft takes off with them.
--   Runways      : bomb hits on an enemy runway; enough of them close the
--                  airbase for hours (no airlifts, no fixed-wing spawns).
--                  Mission RUNWAY.
--   SAM moves    : sites that moved after firing leave the enemy's fix stale.
--   Crews        : AI aircrews that eject can be rescued (aircraft back in
--                  the pool) or snatched by the enemy (mission SNATCH, which
--                  also takes enemy player pilots prisoner).
--   Support      : artillery / CAS on call, paid from a base's supply.
--   Engineers    : a bridge kit reopens a road with a downed bridge.
--   Minefields   : a mined road slows the other side and costs it.
--   Veterancy    : platoons that win fights get better (veteran, elite).
--   Industry     : factories, power plants, refineries behind each side's
--                  lines; each one destroyed cuts that side's production.
--                  Mission INDUSTRY. Rebuilt after a day, for supply.
--   Partisans    : (some maps) cells rise in occupied towns, sabotage supply
--                  and ambush columns. Mission COIN for the occupier.
--   Scaling      : the side with fewer players online takes fewer losses.
--   Wrecks       : what died stays on the map through restarts.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function X(self) return self.cfg.ext end
local function key(a, b) if a < b then return a .. "|" .. b end return b .. "|" .. a end

-- ---------------------------------------------------------------------------
-- Initialisation (new wars and older saves)
-- ---------------------------------------------------------------------------
function War:initExt()
  local st = self.state
  st.runways = st.runways or {}
  st.mines = st.mines or {}
  st.wrecks = st.wrecks or {}
  st.partisans = st.partisans or {}
  if not st.industry then self:placeIndustry() end
  self.players = self.players or { blue = 0, red = 0 }
end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  self:initExt()
end

-- ===========================================================================
-- 1. Armoury
-- ===========================================================================
-- "basic" (guns, rockets, dumb bombs) always; "guided" from guidedAt of the
-- supply cap; "advanced" from advancedAt.
function War:armouryTier(id)
  local ns, cfg = self.state.nodes[id], X(self).armoury
  if not cfg.tiers then return "advanced" end            -- v0.37: every tier, whatever the supply
  local cap = math.max(1, self:supplyCap(id))
  local f = (ns.supply or 0) / cap
  if f >= cfg.advancedAt then return "advanced" end
  if f >= cfg.guidedAt then return "guided" end
  return "basic"
end

local TIER = { basic = 1, guided = 2, advanced = 3 }
War.ARMOURY_TIER = TIER

-- An aircraft takes off from base id with n guided and m advanced weapons.
-- Returns true (paid) or false, reason.
function War:armTakeoff(id, nGuided, nAdvanced)
  local cfg = X(self).armoury
  local need = (nAdvanced > 0 and 3) or (nGuided > 0 and 2) or 1
  local tier = self:armouryTier(id)
  if TIER[tier] < need then return false, tier end
  local cost = nGuided * cfg.guidedSU + nAdvanced * cfg.advancedSU
  local ns = self.state.nodes[id]
  ns.supply = math.max(0, (ns.supply or 0) - cost)
  return true, tier, cost
end

-- ===========================================================================
-- 2. Runways
-- ===========================================================================
function War:runwayClosed(id)
  local r = self.state.runways[id]
  return r ~= nil and r.closedUntil ~= nil and self.state.tick < r.closedUntil
end

function War:runwayHit(id)
  local cfg = X(self)
  if self:runwayClosed(id) then return false end
  local r = self.state.runways[id] or { hits = 0 }
  self.state.runways[id] = r
  r.hits = r.hits + 1
  if r.hits >= cfg.runwayHits then
    r.hits, r.closedUntil = 0, self.state.tick + cfg.runwayTicks
    local ns = self.state.nodes[id]
    self:log("runway_closed", ns.side, string.format("%s runway at %s cratered: closed for %d h", ns.side:upper(),
      self:nodeName(id), cfg.runwayTicks * self.cfg.tickSeconds / 3600), { node = id })
    return true
  end
  return false
end

function War:runwaysTick()
  for id, r in pairs(self.state.runways) do
    if r.closedUntil and self.state.tick >= r.closedUntil then
      local ns = self.state.nodes[id]
      local cost = X(self).runwayRepairSU
      if (ns.supply or 0) >= cost then
        ns.supply = ns.supply - cost
        self.state.runways[id] = nil
        self:log("runway_open", ns.side, string.format("%s runway at %s repaired", ns.side:upper(), self:nodeName(id)),
          { node = id })
      end
    end
  end
end

-- no airlifts into or out of a closed airfield (helicopters do not need one)
local baseStartCargo = War.startCargo
function War:startCargo(kind, side, from, to, amount)
  if kind == "airlift" and (self:runwayClosed(from) or self:runwayClosed(to)) then return nil end
  return baseStartCargo(self, kind, side, from, to, amount)
end

-- ===========================================================================
-- 3. SAM sites that moved: the enemy's fix is off by the distance moved
-- ===========================================================================
function War:samMoved(id, dx, dz, which)
  local ns = self.state.nodes[id]
  if not ns.sam then return end
  if which == "pd" then ns.sam.pdOff = { dx = dx, dz = dz } else ns.sam.off = { dx = dx, dz = dz } end
  local enemy = U.otherSide(ns.side)
  local c = self.state.contacts and self.state.contacts[enemy] and self.state.contacts[enemy]["sam:" .. id]
  if c then
    local moved = math.sqrt(dx * dx + dz * dz)
    c.err = math.max(c.err or 0, moved)
  end
end

-- ===========================================================================
-- 4. Aircrews: AI crews, rescue and capture
-- ===========================================================================
local baseRescue = War.rescue
function War:rescue(did, atNode)
  local d = self.state.downed[did]
  local ok = baseRescue(self, did, atNode)
  if ok and d and d.aiRole then
    local pool = self.state.airPool[d.side]
    pool[d.aiRole] = (pool[d.aiRole] or 0) + 1
  end
  return ok
end

-- An enemy helicopter picked the pilot up and brought him in: prisoner.
-- The captors learn about the base he flew from.
function War:snatch(did, bySide, atNode)
  local d = self.state.downed[did]
  if not d or d.side == bySide then return false end
  self.state.downed[did] = nil
  self:log("snatched", bySide, string.format("%s took %s pilot %s prisoner%s", bySide:upper(), d.side:upper(),
    tostring(d.pilot), atNode and (" at " .. self:nodeName(atNode)) or ""), { downed = did, pilot = d.pilot,
    pilotKey = d.key, captured = true })
  if d.home and self.state.nodes[d.home] and self.state.nodes[d.home].side ~= bySide then
    self:recordIntel(bySide, d.home)                 -- interrogation
  end
  return true
end

-- ===========================================================================
-- 5. Support on call: paid from the nearest own base
-- ===========================================================================
function War:paySupport(id, su)
  local ns = self.state.nodes[id]
  if not ns or (ns.supply or 0) < su then return false end
  ns.supply = ns.supply - su
  return true
end

-- ===========================================================================
-- 6. Engineers: a bridge kit reopens the road
-- ===========================================================================
function War:repairBridge(a, b, side)
  local k = key(a, b)
  if not self.state.blocked[k] then return false end
  self.state.blocked[k] = nil
  self:openRoad(a, b)
  self:log("bridge_up", side, string.format("%s engineers bridged the road %s - %s", (side or "?"):upper(),
    self:nodeName(a), self:nodeName(b)), { a = a, b = b })
  return true
end

-- ===========================================================================
-- 7. Minefields on roads
-- ===========================================================================
function War:mineRoad(a, b, side)
  local k = key(a, b)
  self.state.mines[k] = { side = side, untilTick = self.state.tick + X(self).mineTicks }
  self:log("mined", side, string.format("%s mined the road %s - %s", side:upper(), self:nodeName(a), self:nodeName(b)),
    { a = a, b = b })
end

function War:minedAgainst(mv)
  if mv.kind == "airlift" or not mv.from or not mv.to then return nil end
  local m = self.state.mines[key(mv.from, mv.to)]
  if m and m.side ~= mv.side and self.state.tick < m.untilTick then return m end
  return nil
end

local baseSpeed = War.moveSpeedFactor
function War:moveSpeedFactor(mv)
  local f = baseSpeed and baseSpeed(self, mv) or 1
  if self:minedAgainst(mv) then f = f * X(self).mineSpeed end
  return f
end

function War:minesTick()
  for k, m in pairs(self.state.mines) do
    if self.state.tick >= m.untilTick then self.state.mines[k] = nil end
  end
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv and mv.status == "moving" and not mv.mineHit and self:minedAgainst(mv) and mv.progress > 0.2 then
      mv.mineHit = true
      local loss = X(self).mineLoss
      if mv.cargo then self:setCargoHealth(mid, (mv.health or 1) * (1 - loss))
      elseif #mv.platoons > 0 then self:damage(mv.platoons, loss * #mv.platoons) end
      self:log("mine_hit", mv.side, string.format("%s column on the road %s - %s ran into a minefield",
        mv.side:upper(), self:nodeName(mv.from), self:nodeName(mv.to)), { a = mv.from, b = mv.to })
    end
  end
end

-- ===========================================================================
-- 8. Veterancy
-- ===========================================================================
function War:vetLevel(pid)
  local pl = self.state.platoons[pid]
  local xp, cfg = pl and pl.xp or 0, X(self).veterancy
  if xp >= cfg.eliteXp then return 2 end
  if xp >= cfg.vetXp then return 1 end
  return 0
end

function War:vetBonus(pid)
  local lvl, cfg = self:vetLevel(pid), X(self).veterancy
  return (lvl == 2 and cfg.eliteBonus) or (lvl == 1 and cfg.vetBonus) or 0
end

local basePower = War.power
function War:power(pids)
  local p = 0
  for _, pid in ipairs(pids) do
    local pl = self.state.platoons[pid]
    if pl then p = p + pl.health * (1 + self:vetBonus(pid)) end
  end
  return p
end

local function gainXp(self, id)
  for _, pid in ipairs(self.state.nodes[id].platoons) do
    local pl = self.state.platoons[pid]
    if pl then pl.xp = (pl.xp or 0) + 1 end
  end
end

-- ===========================================================================
-- 9. Industry
-- ===========================================================================
local KINDS = { "factory", "power plant", "refinery" }

function War:placeIndustry()
  local st, cfg = self.state, X(self)
  st.industry = { blue = {}, red = {} }
  for _, side in ipairs(SIDES) do
    local dist = self:frontDistance(side)
    local cands = {}
    for _, id in ipairs(self.T.order) do
      local tn = self.T.nodes[id]
      if tn.startSide == side and tn.kind ~= "carrier" then cands[#cands + 1] = id end
    end
    table.sort(cands, function(a, b)
      local da, db = self.T.nodes[a].depot and 99 or (dist[a] or 0), self.T.nodes[b].depot and 99 or (dist[b] or 0)
      if da ~= db then return da > db end
      return a < b
    end)
    for i = 1, math.min(cfg.industryPerSide, #cands) do
      st.industry[side][i] = { id = side:sub(1, 1) .. "i" .. i, node = cands[i], kind = KINDS[(i - 1) % #KINDS + 1],
                               status = "up" }
    end
  end
end

function War:industrySites(side) return self.state.industry[side] or {} end

function War:industryFactor(side)
  local down = 0
  for _, s in ipairs(self:industrySites(side)) do if s.status ~= "up" then down = down + 1 end end
  return math.max(0.4, 1 - X(self).industryFactor * down)
end

function War:industryHit(sid)
  for _, side in ipairs(SIDES) do
    for _, s in ipairs(self:industrySites(side)) do
      if s.id == sid and s.status == "up" then
        s.status, s.since = "destroyed", self.state.tick
        self:log("industry_hit", side, string.format("%s %s at %s destroyed - production down to %d %%", side:upper(),
          s.kind, self:nodeName(s.node), math.floor(self:industryFactor(side) * 100 + 0.5)), { node = s.node })
        return true
      end
    end
  end
  return false
end

function War:industryTick()
  local cfg = X(self)
  for _, side in ipairs(SIDES) do
    for _, s in ipairs(self:industrySites(side)) do
      local ns = self.state.nodes[s.node]
      if ns.side ~= side then
        if s.status == "up" then s.status, s.since = "lost", self.state.tick end      -- overrun
      elseif s.status ~= "up" and self.state.tick - (s.since or 0) >= cfg.industryRebuildTicks
             and (ns.supply or 0) >= cfg.industryRebuildSU then
        ns.supply = ns.supply - cfg.industryRebuildSU
        s.status, s.since = "up", nil
        self:log("industry_up", side, string.format("%s %s at %s rebuilt", side:upper(), s.kind, self:nodeName(s.node)),
          { node = s.node })
      end
    end
  end
end

local baseProd = War.productionFactor
function War:productionFactor(side)
  return baseProd(self, side) * self:industryFactor(side)
end

-- ===========================================================================
-- 10. Partisans
-- ===========================================================================
function War:partisansOn()
  local maps = X(self).partisans.maps or {}
  return maps[self.T.name or (self.theater and self.theater.name) or ""] == true
end

function War:partisanCells(side)
  local out = {}
  for _, c in pairs(self.state.partisans) do if not side or c.side == side then out[#out + 1] = c end end
  table.sort(out, function(a, b) return a.id < b.id end)
  return out
end

function War:partisanKilled(cid, bySide)
  local c = self.state.partisans[cid]
  if not c then return end
  self.state.partisans[cid] = nil
  self:log("partisans_killed", bySide, string.format("%s cleared the partisan cell at %s", (bySide or "?"):upper(),
    self:nodeName(c.node)), { node = c.node, cell = cid, killed = true })
end

function War:partisansTick()
  if not self:partisansOn() then return end
  local cfg = X(self).partisans
  local dist = {}
  for _, side in ipairs(SIDES) do dist[side] = self:frontDistance(side) end
  local n = 0
  for _ in pairs(self.state.partisans) do n = n + 1 end
  -- uprisings in occupied towns away from the front
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    local has = false
    for _, c in pairs(self.state.partisans) do if c.node == id then has = true end end
    if n < cfg.max and not has and tn.kind == "town" and ns.side ~= tn.startSide
       and (dist[ns.side][id] or 0) >= 2 and self.rng:next() < cfg.chance then
      local cid = self:newId("pz")
      self.state.partisans[cid] = { id = cid, node = id, side = tn.startSide, born = self.state.tick }
      n = n + 1
      self:log("partisans", ns.side, string.format("Partisans active around %s (%s-held)", self:nodeName(id),
        ns.side:upper()), { node = id, cell = cid })
    end
  end
  for cid, c in pairs(U.copy(self.state.partisans)) do
    local ns = self.state.nodes[c.node]
    if ns.side == c.side or self.state.tick - c.born > cfg.lifeTicks then
      self.state.partisans[cid] = nil                       -- liberated, or melted away
    else
      ns.supply = math.max(0, (ns.supply or 0) - cfg.sabotageSU)
      -- the garrison sweeps the area
      if self.rng:next() < cfg.sweepPerPlatoon * #ns.platoons then
        self.state.partisans[cid] = nil
        self:log("partisans_swept", ns.side, string.format("%s garrison at %s broke up a partisan cell",
          ns.side:upper(), self:nodeName(c.node)), { node = c.node })
      else
        -- ambush a column of the occupier on a road out of the town
        for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
          local mv = self.state.moves[mid]
          if mv and mv.side == ns.side and mv.status == "moving" and mv.kind ~= "airlift" and not mv.partisanHit
             and (mv.from == c.node or mv.to == c.node) and self.rng:next() < cfg.ambush then
            mv.partisanHit = true
            if mv.cargo then self:setCargoHealth(mid, (mv.health or 1) * 0.6)
            elseif #mv.platoons > 0 then self:damage(mv.platoons, 0.3) end
            self:log("partisan_ambush", ns.side, string.format("Partisans ambushed a %s column near %s",
              ns.side:upper(), self:nodeName(c.node)), { node = c.node })
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 13. Scaling to the players online
-- ===========================================================================
function War:setPlayers(blue, red) self.players = { blue = blue or 0, red = red or 0 } end

-- Loss reduction for a side the other side outnumbers in players.
function War:scaleBonus(side)
  local cfg, p = X(self).scaling, self.players or {}
  local diff = (p[U.otherSide(side)] or 0) - (p[side] or 0)
  if diff <= 0 then return 0 end
  return math.min(cfg.max, cfg.perPlayer * diff)
end

local baseDamage = War.damage
function War:damage(pids, loss)
  local first = pids[1] and self.state.platoons[pids[1]]
  if first then loss = loss * (1 - self:scaleBonus(first.side)) end
  return baseDamage(self, pids, loss)
end

-- ===========================================================================
-- 15. Wrecks
-- ===========================================================================
function War:addWreck(w)
  local list, cfg = self.state.wrecks, X(self).wrecks
  w.tick = self.state.tick
  list[#list + 1] = w
  while #list > cfg.max do table.remove(list, 1) end
end

function War:wrecksTick()
  local list, keep = self.state.wrecks, {}
  local maxAge = X(self).wrecks.days * 86400 / self.cfg.tickSeconds
  for _, w in ipairs(list) do if self.state.tick - w.tick <= maxAge then keep[#keep + 1] = w end end
  self.state.wrecks = keep
end

-- ===========================================================================
-- Missions: RUNWAY, SNATCH, INDUSTRY, COIN
-- ===========================================================================
War.MISSION_NEEDS.RUNWAY = "A2G"
War.MISSION_NEEDS.SNATCH = "LIFT"
War.MISSION_NEEDS.INDUSTRY = "A2G"
War.MISSION_NEEDS.COIN = "A2G"
do
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    order[#order + 1] = t
    if t == "STRIKE" then order[#order + 1] = "RUNWAY"; order[#order + 1] = "INDUSTRY" end
    if t == "CSAR" then order[#order + 1] = "SNATCH" end
    if t == "BAI" then order[#order + 1] = "COIN" end
  end
  War.MISSION_ORDER = order
end

local gen = War.missionGenerators
gen.RUNWAY = function(self, side)
  local enemy, out = U.otherSide(side), {}
  local dist = self:frontDistance(enemy)
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    if ns.side == enemy and tn.kind == "airbase" and not self:runwayClosed(id)
       and ((dist[id] or 9) <= 2 or tn.depot) then
      out[#out + 1] = { type = "RUNWAY", target = id, node = id, prio = tn.depot and 0 or (dist[id] or 9),
        label = "runway at " .. self:nodeName(id) }
    end
  end
  return out
end

gen.SNATCH = function(self, side)
  local out = {}
  for _, did in ipairs(U.sortedKeys(self.state.downed)) do
    local d = self.state.downed[did]
    if d.side ~= side then
      out[#out + 1] = { type = "SNATCH", target = did, prio = d.tick,
        label = string.format("%s pilot %s", d.side:upper(), tostring(d.pilot)) }
    end
  end
  return out
end

gen.INDUSTRY = function(self, side)
  local enemy, out = U.otherSide(side), {}
  for _, s in ipairs(self:industrySites(enemy)) do
    if s.status == "up" and self.state.nodes[s.node].side == enemy then
      out[#out + 1] = { type = "INDUSTRY", target = s.id, node = s.node, prio = 0,
        label = string.format("%s at %s", s.kind, self:nodeName(s.node)) }
    end
  end
  return out
end

gen.COIN = function(self, side)
  local out = {}
  for _, c in ipairs(self:partisanCells()) do
    if self.state.nodes[c.node].side == side then
      out[#out + 1] = { type = "COIN", target = c.id, node = c.node, prio = 0,
        label = "partisan cell near " .. self:nodeName(c.node) }
    end
  end
  return out
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local st = self.state
  if m.type == "RUNWAY" then
    if st.nodes[m.target].side == m.side then return "expired" end
    return self:runwayClosed(m.target) and "done" or "open"
  elseif m.type == "SNATCH" then
    if st.downed[m.target] then return "open" end
    for _, ev in ipairs(events) do
      if ev.downed == m.target and (ev.kind == "snatched" or ev.kind == "rescued" or ev.kind == "captured") then
        return (ev.kind == "snatched" and ev.side == m.side) and "done" or "failed"
      end
    end
    return "expired"
  elseif m.type == "INDUSTRY" then
    for _, side in ipairs(SIDES) do
      for _, s in ipairs(self:industrySites(side)) do
        if s.id == m.target then
          if s.status == "destroyed" then return "done" end
          return (s.status == "up") and "open" or "expired"
        end
      end
    end
    return "expired"
  elseif m.type == "COIN" then
    if st.partisans[m.target] then return "open" end
    for _, ev in ipairs(events) do
      if ev.cell == m.target and ev.killed then return "done" end
    end
    return "expired"
  end
  return baseOutcome(self, m, events)
end

-- ===========================================================================
-- Hooks
-- ===========================================================================
local baseCapture = War.onCaptureOps
function War:onCaptureOps(id)
  baseCapture(self, id)
  self.state.runways[id] = nil
end

local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:runwaysTick()
  self:minesTick()
  self:industryTick()
  self:partisansTick()
  self:wrecksTick()
end

local baseTick = War.tick
function War:tick()
  local events = baseTick(self)
  for _, ev in ipairs(events or {}) do
    if (ev.kind == "capture" or ev.kind == "repulsed") and ev.node and self.state.nodes[ev.node] then
      gainXp(self, ev.node)
    end
  end
  return events
end

end

-- >>> src/dcc_ext2.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - more air and ground war (pure Lua 5.1, v0.18).
-- Load after dcc_ext.lua.
-- ----------------------------------------------------------------------------
--   2. HVA      : a lost tanker / AWACS is gone for 2 h. HVAESCORT missions
--                 (stay with your own tanker / AWACS); the bridge sends enemy
--                 fighters after them.
--   3. Packages : PKGESCORT missions ride with every STRIKE / INDUSTRY / EWR /
--                 RUNWAY mission. When the strike succeeds, everyone who flew
--                 SEAD or escort for it gets a package bonus.
--   5. Artillery: batteries not busy in a battle shell the nearest enemy base:
--                 it loses supply, and the flashes give the battery away (ARTY).
--   7 + 9. Pick-ups: prisoners after a surrender or capture (POW) and wounded
--                 after a battle (MEDEVAC), flown by helicopter to an airbase
--                 or depot. Prisoners talk (intel on nearby enemy bases);
--                 wounded come back (the garrison heals).
--   8. Heavy    : a generator raises a base's supply cap for 24 h; a runway
--                 repair kit reopens a cratered runway at once.
--   10. CSAR    : an enemy search party can capture a downed pilot.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function E(self) return self.cfg.ext2 end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  local st = self.state
  st.hvaDown = st.hvaDown or { blue = {}, red = {} }
  st.pickups = st.pickups or {}
  st.hvaThreat = st.hvaThreat or {}
end

-- ===========================================================================
-- 2. High-value air assets
-- ===========================================================================
function War:hvaGrounded(side, kind)
  local t = self.state.hvaDown[side][kind]
  return t ~= nil and self.state.tick < t
end

local function grounded(self, side, kind)
  self.state.hvaDown[side][kind] = self.state.tick + E(self).hvaDownTicks
end

local baseAssetLost = War.assetLost
function War:assetLost(side, kind)
  baseAssetLost(self, side, kind)
  if kind == "tanker" then grounded(self, side, "tanker") end
end

local baseAwacsLost = War.awacsLost
function War:awacsLost(side)
  baseAwacsLost(self, side)
  grounded(self, side, "awacs")
end

function War:hvaUp(side, kind)
  if kind == "awacs" then return self:awacsUp(side) end
  return self:assetUp(side, kind)
end

-- The bridge sent enemy fighters after side's kind (or they went home).
function War:setHvaThreat(side, kind, on)
  self.state.hvaThreat[side .. "|" .. kind] = on and self.state.tick or nil
end

-- ===========================================================================
-- 5. Artillery duels: harassing fire when there is no battle to support
-- ===========================================================================
function War:artyHarassTick()
  local cfg = E(self)
  local fighting = {}
  for _, mv in pairs(self.state.moves) do if mv.status == "fighting" then fighting[mv.to] = true end end
  for _, side in ipairs(SIDES) do
    local enemy = U.otherSide(side)
    for _, b in ipairs(self:batteries(side)) do
      b.shelling = nil
      if b.status == "up" and b.node and self.state.nodes[b.node].side == side then
        local busy = fighting[b.node]
        for nb in pairs(self.T.nodes[b.node].nb) do if fighting[nb] then busy = true end end
        if not busy then
          local target
          for _, nb in ipairs(U.sortedKeys(self.T.nodes[b.node].nb)) do
            if self.state.nodes[nb].side == enemy and not target then target = nb end
          end
          if target then
            local ns = self.state.nodes[target]
            ns.supply = math.max(0, (ns.supply or 0) - cfg.harassSU)
            b.shelling = target
            self:addContact(enemy, "arty:" .. b.id, { kind = "arty", node = b.node, source = "sensor",
              label = "artillery battery" })
            if not b.lastLog or self.state.tick - b.lastLog >= cfg.harassLogTicks then
              b.lastLog = self.state.tick
              self:log("shelling", enemy, string.format("%s artillery at %s is shelling %s - supply is burning",
                side:upper(), self:nodeName(b.node), self:nodeName(target)), { node = target, from = b.node })
            end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7 + 9. Prisoners and wounded: helicopter pick-ups
-- ===========================================================================
-- kind "pow": side holds n prisoners at node; "medevac": side has n wounded there.
function War:addPickup(kind, side, node, n)
  local open = 0
  for _, q in pairs(self.state.pickups) do if q.side == side then open = open + 1 end end
  if open >= E(self).maxPickups then return nil end
  for _, q in pairs(self.state.pickups) do
    if q.kind == kind and q.side == side and q.node == node and not q.onboard then
      q.n, q.tick = q.n + n, self.state.tick          -- one group per base
      return q
    end
  end
  local id = self:newId("q")
  local q = { id = id, kind = kind, side = side, node = node, n = n, tick = self.state.tick }
  self.state.pickups[id] = q
  if kind == "pow" then
    self:log("pows", side, string.format("%s holds %d prisoners at %s - fly them to the rear", side:upper(), n,
      self:nodeName(node)), { node = node })
  else
    self:log("casualties", side, string.format("%s has %d wounded at %s - MEDEVAC needed", side:upper(), n,
      self:nodeName(node)), { node = node })
  end
  return q
end

-- Where a pick-up may be delivered: an own airbase or depot, not where it came from.
function War:pickupDropOk(q, id)
  local tn, ns = self.T.nodes[id], self.state.nodes[id]
  return tn ~= nil and id ~= q.node and ns.side == q.side and (tn.kind == "airbase" or tn.depot == true)
end

function War:pickupLoaded(qid)
  local q = self.state.pickups[qid]
  if q and not q.onboard then q.onboard = true; return true end
  return false
end

function War:pickupDelivered(qid, atNode)
  local q = self.state.pickups[qid]
  if not q or not self:pickupDropOk(q, atNode) then return false end
  self.state.pickups[qid] = nil
  local enemy = U.otherSide(q.side)
  if q.kind == "pow" then
    -- interrogation: the two enemy bases nearest to where they were taken
    local list = {}
    for _, id in ipairs(self.T.order) do
      if self.state.nodes[id].side == enemy then
        list[#list + 1] = { id = id, km = U.distKm(self.T.nodes[id], self.T.nodes[q.node]) }
      end
    end
    table.sort(list, function(a, b) if a.km ~= b.km then return a.km < b.km end return a.id < b.id end)
    for i = 1, math.min(2, #list) do self:recordIntel(q.side, list[i].id) end
    self:log("pickup_done", q.side, string.format("%s prisoners from %s delivered to %s - interrogation reports "
      .. "on the nearest enemy bases", q.side:upper(), self:nodeName(q.node), self:nodeName(atNode)),
      { pickup = qid, node = q.node, pkind = "pow" })
  else
    local ns = self.state.nodes[q.node]
    if ns.side == q.side then
      for _, pid in ipairs(ns.platoons) do
        local pl = self.state.platoons[pid]
        if pl then pl.health = math.min(1, pl.health + E(self).medevacHeal) end
      end
    end
    self:log("pickup_done", q.side, string.format("%s wounded from %s flown to %s - the garrison there recovers",
      q.side:upper(), self:nodeName(q.node), self:nodeName(atNode)), { pickup = qid, node = q.node, pkind = "medevac" })
  end
  return true
end

-- The helicopter carrying them went down.
function War:pickupLost(qid)
  local q = self.state.pickups[qid]
  if not q then return end
  self.state.pickups[qid] = nil
  self:log("pickup_lost", q.side, string.format("The helicopter with the %s from %s was lost",
    q.kind == "pow" and "prisoners" or "wounded", self:nodeName(q.node)), { pickup = qid })
end

function War:pickupsTick()
  local cfg = E(self)
  -- new ones from this tick's battles
  local seen = {}
  for _, ev in ipairs(self.newEvents or {}) do
    if ev.kind == "surrender" and ev.node then
      self:addPickup("pow", ev.side, ev.node, cfg.powPerSurrender); seen[ev.node] = true
    end
  end
  for _, ev in ipairs(self.newEvents or {}) do
    if ev.kind == "capture" and ev.node and ev.from and not seen[ev.node] then
      self:addPickup("pow", ev.side, ev.node, cfg.powPerCapture)
      self:addPickup("medevac", ev.side, ev.node, cfg.medevacPerBattle)
    elseif ev.kind == "repulsed" and ev.node then
      self:addPickup("medevac", ev.side, ev.node, cfg.medevacPerBattle)
    end
  end
  -- old ones: walked out by road, or the base changed hands
  for _, qid in ipairs(U.sortedKeys(self.state.pickups)) do
    local q = self.state.pickups[qid]
    local life = q.kind == "pow" and cfg.powTicks or cfg.medevacTicks
    if not q.onboard and (self.state.nodes[q.node].side ~= q.side or self.state.tick - q.tick > life) then
      self.state.pickups[qid] = nil
    end
  end
end

-- ===========================================================================
-- 8. Heavy sling loads
-- ===========================================================================
local baseCap = War.supplyCap
function War:supplyCap(id)
  local cap = baseCap(self, id)
  local ns = self.state.nodes[id]
  if ns and ns.capBoostUntil and self.state.tick < ns.capBoostUntil then
    cap = cap * (1 + E(self).generatorBoost)
  end
  return cap
end

function War:installGenerator(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side then return false end
  ns.capBoostUntil = self.state.tick + E(self).generatorTicks
  self:log("generator", side, string.format("%s heavy lift: generators running at %s - it can store more supply for 24 h",
    side:upper(), self:nodeName(id)), { node = id })
  return true
end

function War:repairRunwayNow(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side or not self:runwayClosed(id) then return false end
  self.state.runways[id] = nil
  self:log("runway_open", side, string.format("%s heavy lift: engineers repaired the runway at %s", side:upper(),
    self:nodeName(id)), { node = id })
  return true
end

-- ===========================================================================
-- 10. A search party found the pilot
-- ===========================================================================
function War:downedCaptured(did, bySide)
  local d = self.state.downed[did]
  if not d or d.side == bySide then return false end
  self.state.downed[did] = nil
  self:log("captured", d.side, string.format("%s pilot %s was captured by a %s search party", d.side:upper(),
    tostring(d.pilot), bySide:upper()), { downed = did, pilot = d.pilot, pilotKey = d.key })
  return true
end

-- ===========================================================================
-- Missions: HVAESCORT, PKGESCORT, MEDEVAC, POW
-- ===========================================================================
War.MISSION_NEEDS.HVAESCORT = "A2A"
War.MISSION_NEEDS.PKGESCORT = "A2A"
War.MISSION_NEEDS.MEDEVAC = "LIFT"
War.MISSION_NEEDS.POW = "LIFT"
do
  local new = { HVAESCORT = true, PKGESCORT = true, MEDEVAC = true, POW = true }
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if not new[t] then order[#order + 1] = t end
    if t == "ESCORT" then order[#order + 1] = "PKGESCORT"; order[#order + 1] = "HVAESCORT" end
    if t == "CSAR" then order[#order + 1] = "MEDEVAC"; order[#order + 1] = "POW" end
  end
  War.MISSION_ORDER = order
end
if War.HUB_TYPES then War.HUB_TYPES.MEDEVAC, War.HUB_TYPES.POW = true, true end

local gen = War.missionGenerators
local HVA_NAME = { tanker = "tanker", awacs = "AWACS" }

gen.HVAESCORT = function(self, side)
  local out = {}
  for _, kind in ipairs({ "awacs", "tanker" }) do
    if self:hvaUp(side, kind) then
      local hot = self.state.hvaThreat[side .. "|" .. kind] ~= nil
      out[#out + 1] = { type = "HVAESCORT", target = side .. "|" .. kind, prio = hot and 0 or 5,
        label = string.format("our %s%s", HVA_NAME[kind], hot and " - enemy fighters inbound" or "") }
    end
  end
  return out
end

gen.PKGESCORT = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.missions or {})) do
    local m = self.state.missions[id]
    if m.side == side and m.status == "open" and E(self).pkgTypes[m.type] then
      out[#out + 1] = { type = "PKGESCORT", target = m.id, node = m.node, prio = next(m.taken) and 0 or 5,
        label = string.format("escort the %s on %s", m.type, m.label) }
    end
  end
  return out
end

local function genPickup(kind)
  return function(self, side)
    if self.isStorm and self:isStorm() then return {} end
    local out = {}
    for _, qid in ipairs(U.sortedKeys(self.state.pickups)) do
      local q = self.state.pickups[qid]
      if q.kind == kind and q.side == side and not q.onboard then
        out[#out + 1] = { type = kind == "pow" and "POW" or "MEDEVAC", target = qid, node = q.node, prio = q.tick,
          label = string.format(kind == "pow" and "%d prisoners at %s to the rear" or "%d wounded at %s", q.n,
            self:nodeName(q.node)) }
      end
    end
    return out
  end
end
gen.MEDEVAC = genPickup("medevac")
gen.POW = genPickup("pow")

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local st = self.state
  if m.type == "HVAESCORT" then
    local side, kind = m.target:match("^(.-)|(.+)$")
    for _, ev in ipairs(events) do
      if ev.kind == kind .. "_lost" and ev.side == side then return "failed" end
    end
    return self:hvaUp(side, kind) and "open" or "expired"
  elseif m.type == "PKGESCORT" then
    local s = st.missions[m.target]
    if not s or s.status == "failed" or s.status == "expired" then return "expired" end
    if s.status == "done" then return m.escortOk and "done" or "failed" end
    return "open"
  elseif m.type == "MEDEVAC" or m.type == "POW" then
    for _, ev in ipairs(events) do
      if ev.pickup == m.target then return ev.kind == "pickup_done" and "done" or "failed" end
    end
    return st.pickups[m.target] and "open" or "expired"
  end
  return baseOutcome(self, m, events)
end

-- Strike success: SEAD at the same target and the escorts share a package bonus.
local baseFinish = War.finishMission
function War:finishMission(m, outcome)
  baseFinish(self, m, outcome)
  if outcome ~= "done" or not E(self).pkgTypes[m.type] or not next(m.taken) then return end
  local crew, others = {}, 0
  for k, n in pairs(m.taken) do crew[k] = n end
  for _, o in pairs(self.state.missions) do
    local recent = o.status == "open" or (o.status == "done" and self.state.tick - (o.finished or 0) <= 2)
    if o ~= m and o.side == m.side and recent and next(o.taken)
       and ((o.type == "SEAD" and o.node == m.node) or (o.type == "PKGESCORT" and o.target == m.id)) then
      for k, n in pairs(o.taken) do if not crew[k] then others = others + 1 end; crew[k] = n end
    end
  end
  if others == 0 then return end
  local names = {}
  for _, n in pairs(crew) do names[#names + 1] = n end
  table.sort(names)
  self:log("package_done", m.side, string.format("%s strike package on %s: complete - %s", m.side:upper(), m.label,
    table.concat(names, ", ")), { crew = crew, node = m.node })
end

-- ===========================================================================
-- Tick
-- ===========================================================================
local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:artyHarassTick()
  self:pickupsTick()
end

end

-- >>> src/dcc_ext3.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - naval and hidden-threat war (pure Lua 5.1, v0.25).
-- Load after dcc_ext2.lua.
-- ----------------------------------------------------------------------------
--   1. Amphibious : an amphibious ship (Tarawa, Kuznetsov) lands marines by
--                   helicopter on a weak enemy coastal town (a package of kind
--                   "amphib"). Own side: AMPHIB escort mission; enemy:
--                   INTERCEPT. Once ashore it is a normal battle (CAS).
--   2. Shipping   : supply ships sail the theater's lanes to own ports (40 SU).
--                   Enemy: SHIPSTRIKE; own: SHIPESCORT. Sunk = cargo lost.
--   4. Scuds      : RED's mobile launchers in the rear fire at BLUE airbases
--                   and depots (supply lost, sometimes a runway closed). The
--                   launch gives them away; they move on soon after. SCUD hunt.
--   7. Pop-ups    : MANPADS teams and mobile SHORAD appear near the front for a
--                   while; only known once someone sees them. POPUP missions.
--   (3, carrier recovery tanker and CAP, is bridge-only: dcc_dcs_ext3.lua)
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function E(self) return self.cfg.ext3 end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  local st, cfg = self.state, E(self)
  st.shipping = st.shipping or {}
  st.popups = st.popups or {}
  st.amphibReady = st.amphibReady or {}
  if not st.scuds then
    st.scuds = {}
    for i = 1, cfg.scud.launchers do
      st.scuds[i] = { id = "sc" .. i, side = cfg.scud.side, status = "up", last = st.tick - cfg.scud.everyTicks + 6 * i }
    end
  end
end

local function shipSpec(self, id)
  for _, s in ipairs(self.theater and self.theater.naval or {}) do if s.id == id then return s end end
end

-- ===========================================================================
-- 1. Amphibious assault (the bridge picks ship and beach, the model does the rest)
-- ===========================================================================
function War:amphibShips(side)
  local out = {}
  for _, s in ipairs(self.theater and self.theater.naval or {}) do
    local ready = self.state.amphibReady[s.id]
    if s.side == side and s.amphib and self:shipUp(s.id) and (not ready or self.state.tick >= ready) then
      out[#out + 1] = s
    end
  end
  return out
end

-- A beach worth landing on: enemy, not a depot, few defenders.
function War:amphibTargetOk(side, id)
  local ns = self.state.nodes[id]
  return ns ~= nil and ns.side ~= side and not self.T.nodes[id].depot and #ns.platoons <= E(self).amphib.maxDefenders
end

-- Marines embark: new platoons at `home` (the own node nearest the ship), carried at once.
function War:amphibLaunched(side, shipId, target, home)
  if not self:amphibTargetOk(side, target) or not self.state.nodes[home] or self.state.nodes[home].side ~= side then
    return nil
  end
  local cfg = E(self).amphib
  local id = self:newId("k")
  local pk = { id = id, side = side, kind = "amphib", target = target, from = home, ship = shipId,
               status = "inbound", launched = self.state.tick, platoons = {} }
  for _ = 1, cfg.platoons do
    local pid = self:newPlatoon(side, "MECH_PLT", home)
    if self:carryPlatoon(pid, "ai:" .. id) then pk.platoons[#pk.platoons + 1] = pid end
  end
  self.state.packages[id] = pk
  self.state.amphibReady[shipId] = self.state.tick + cfg.cooldownTicks
  local s = shipSpec(self, shipId)
  self:log("amphib", side, string.format("%s marines leave %s for %s", side:upper(), s and s.name or shipId,
    self:nodeName(target)), { node = target })
  return pk
end

local baseArrived = War.packageArrived
function War:packageArrived(id)
  local pk = self.state.packages[id]
  if pk and pk.kind == "amphib" and pk.status == "inbound" then
    pk.status, pk.ended = "hit", self.state.tick
    self:log("amphib_ashore", pk.side, string.format("%s marines are ashore at %s", pk.side:upper(),
      self:nodeName(pk.target)), { node = pk.target })
    self:dropPlatoons(pk.platoons, pk.target, pk.side)
    return
  end
  return baseArrived(self, id)
end

local baseDestroyed = War.packageDestroyed
function War:packageDestroyed(id)
  local pk = self.state.packages[id]
  if pk and pk.kind == "amphib" and pk.status == "inbound" then
    pk.status, pk.ended = "destroyed", self.state.tick
    for _, pid in ipairs(pk.platoons) do self:loseCarried(pid) end
    self:log("package_down", pk.side, string.format("%s landing at %s shot down", pk.side:upper(),
      self:nodeName(pk.target)), {})
    return
  end
  return baseDestroyed(self, id)
end

-- ===========================================================================
-- 2. Shipping: supply ships on the theater's lanes
-- ===========================================================================
function War:lanes() return self.theater and self.theater.shipping or {} end

function War:laneOf(port)
  for _, l in ipairs(self:lanes()) do if l.port == port then return l end end
end

function War:planShipping()
  local cfg = E(self).shipping
  if self.state.tick % cfg.everyTicks ~= 0 then return end
  for _, side in ipairs(SIDES) do
    local active = 0
    for _, s in pairs(self.state.shipping) do if s.side == side then active = active + 1 end end
    if active < cfg.maxPerSide then
      local best, bestF
      for _, l in ipairs(self:lanes()) do
        local ns = self.state.nodes[l.port]
        local busy = false
        for _, s in pairs(self.state.shipping) do if s.port == l.port then busy = true end end
        if ns and ns.side == side and not busy then
          local f = (ns.supply or 0) / math.max(1, self:supplyCap(l.port))
          if f < cfg.belowShare and (not bestF or f < bestF) then best, bestF = l, f end
        end
      end
      if best then
        local id = self:newId("sh")
        local km = U.distKm(best.start, best.dock)
        self.state.shipping[id] = { id = id, side = side, port = best.port, su = cfg.su, km = km, progress = 0,
                                    started = self.state.tick }
        self:log("shipping_out", side, string.format("%s supply ship bound for %s (%d SU, about %d h)",
          side:upper(), self:nodeName(best.port), cfg.su, math.max(1, math.floor(km / cfg.speedKmh + 0.5))),
          { node = best.port })
      end
    end
  end
end

function War:shippingTick()
  local cfg = E(self).shipping
  local step = cfg.speedKmh * self.cfg.tickSeconds / 3600
  for _, id in ipairs(U.sortedKeys(self.state.shipping)) do
    local s = self.state.shipping[id]
    s.progress = math.min(1, s.progress + step / math.max(s.km, 0.1))
    if s.progress >= 1 then
      self.state.shipping[id] = nil
      self.state.deliveredShips = self.state.deliveredShips or {}
      self.state.deliveredShips[id] = self.state.tick
      local ns = self.state.nodes[s.port]
      if ns.side == s.side then
        ns.supply = math.min(self:supplyCap(s.port) * self.cfg.supply.overfillFactor, (ns.supply or 0) + s.su)
        self:log("shipping_in", s.side, string.format("%s supply ship unloaded at %s (+%d SU)", s.side:upper(),
          self:nodeName(s.port), s.su), { node = s.port, ship = id })
      else
        self:log("shipping_in", s.side, string.format("%s supply ship turned back - %s has fallen", s.side:upper(),
          self:nodeName(s.port)), { node = s.port, ship = id })
      end
    end
  end
end

function War:shippingSunk(id)
  local s = self.state.shipping[id]
  if not s then return false end
  self.state.shipping[id] = nil
  self.state.sunkShips = self.state.sunkShips or {}
  self.state.sunkShips[id] = self.state.tick
  self:log("shipping_sunk", s.side, string.format("%s supply ship to %s sunk - %d SU lost", s.side:upper(),
    self:nodeName(s.port), s.su), { node = s.port, ship = id })
  return true
end

-- ===========================================================================
-- 4. Scuds
-- ===========================================================================
function War:scuds() return self.state.scuds end

function War:scudTick()
  local cfg = E(self).scud
  for _, b in ipairs(self.state.scuds) do
    local side, enemy = b.side, U.otherSide(b.side)
    if b.status == "destroyed" then
      if self.state.tick - (b.since or 0) >= cfg.rebuildTicks then
        for _, id in ipairs(self.T.order) do
          local ns = self.state.nodes[id]
          if self.T.nodes[id].depot and ns.side == side and (ns.supply or 0) >= cfg.rebuildSU then
            ns.supply = ns.supply - cfg.rebuildSU
            b.status, b.node, b.since, b.last = "up", nil, nil, self.state.tick
            break
          end
        end
      end
    else
      -- hide somewhere in the rear (or move on after a launch)
      if not b.node or self.state.nodes[b.node].side ~= side or (b.moveAt and self.state.tick >= b.moveAt) then
        local dist, spots = self:frontDistance(side), {}
        for _, id in ipairs(self.T.order) do
          local d = dist[id]
          if self.state.nodes[id].side == side and d and d >= cfg.depth[1] and d <= cfg.depth[2] and id ~= b.node then
            spots[#spots + 1] = id
          end
        end
        if #spots > 0 then
          b.node = spots[self.rng:int(#spots)]
          b.off = { dx = (self.rng:next() - 0.5) * 6000, dz = (self.rng:next() - 0.5) * 6000 }
        end
        b.moveAt = nil
      end
      -- fire
      if b.node and self.state.tick - (b.last or 0) >= cfg.everyTicks then
        local best, bestScore
        for _, id in ipairs(self.T.order) do
          local ns, tn = self.state.nodes[id], self.T.nodes[id]
          if ns.side == enemy and (tn.kind == "airbase" or tn.depot) then
            local km = U.distKm(self.T.nodes[b.node], tn)
            if km <= cfg.rangeKm then
              local score = (tn.depot and 0 or 1) * 1000 + km
              if not bestScore or score < bestScore then best, bestScore = id, score end
            end
          end
        end
        if best then
          b.last, b.moveAt = self.state.tick, self.state.tick + cfg.scootTicks
          local ns = self.state.nodes[best]
          ns.supply = math.max(0, (ns.supply or 0) - cfg.damageSU)
          local closed = false
          if self.T.nodes[best].kind == "airbase" and self.rng:next() < cfg.runwayChance and self.runwayHit then
            for _ = 1, (self.cfg.ext and self.cfg.ext.runwayHits) or 3 do
              if self:runwayHit(best) then closed = true end
            end
          end
          self:addContact(enemy, "scud:" .. b.id, { kind = "scud", node = b.node, off = b.off, source = "sensor",
            label = "SCUD launcher" })
          b.target = best
          self:log("scud", enemy, string.format("SCUD impact at %s - supply hit%s. Launch detected near %s: hunt the launcher",
            self:nodeName(best), closed and ", runway closed" or "", self:nodeName(b.node)), { node = best, from = b.node })
        end
      end
    end
  end
end

function War:scudKilled(id)
  for _, b in ipairs(self.state.scuds) do
    if b.id == id and b.status == "up" then
      b.status, b.since = "destroyed", self.state.tick
      self:log("scud_destroyed", U.otherSide(b.side), string.format("%s SCUD launcher destroyed near %s",
        b.side:upper(), b.node and self:nodeName(b.node) or "the rear"), { node = b.node })
      b.node = nil
      return true
    end
  end
  return false
end

-- ===========================================================================
-- 7. Pop-up threats
-- ===========================================================================
function War:popupTick()
  local cfg = E(self).popup
  for _, id in ipairs(U.sortedKeys(self.state.popups)) do
    local p = self.state.popups[id]
    if self.state.tick - p.tick > cfg.lifeTicks or self.state.nodes[p.node].side ~= p.side then
      self.state.popups[id] = nil                         -- moved on
    end
  end
  for _, side in ipairs(SIDES) do
    local n = 0
    for _, p in pairs(self.state.popups) do if p.side == side then n = n + 1 end end
    if n < cfg.max and self.rng:next() < cfg.chance then
      local dist, spots = self:frontDistance(side), {}
      for _, id in ipairs(self.T.order) do
        if self.state.nodes[id].side == side and dist[id] == 1 then spots[#spots + 1] = id end
      end
      if #spots > 0 then
        local node = spots[self.rng:int(#spots)]
        local kind = (self.rng:next() < cfg.manpadsShare) and "manpads" or "shorad"
        -- toward the nearest enemy base, a few km out
        local enemyNb
        for nb in pairs(self.T.nodes[node].nb) do
          if self.state.nodes[nb].side ~= side then enemyNb = enemyNb or nb end
        end
        local id = self:newId("pu")
        self.state.popups[id] = { id = id, side = side, node = node, kind = kind, tick = self.state.tick,
          toward = enemyNb, frac = 0.15 + self.rng:next() * 0.25, jitter = (self.rng:next() - 0.5) * 3000 }
      end
    end
  end
end

-- The bridge saw it (or it fired).
function War:popupSeen(id, bySide, how)
  local p = self.state.popups[id]
  if not p or p.side == bySide then return end
  self:addContact(bySide, "popup:" .. id, { kind = "popup", node = p.node, popup = id, source = how or "visual",
    label = p.kind == "manpads" and "MANPADS team" or "mobile SAM" })
end

function War:popupKilled(id)
  local p = self.state.popups[id]
  if not p then return false end
  self.state.popups[id] = nil
  self.state.killedPopups = self.state.killedPopups or {}
  self.state.killedPopups[id] = self.state.tick
  self:log("popup_killed", U.otherSide(p.side), string.format("%s %s near %s destroyed", p.side:upper(),
    p.kind == "manpads" and "MANPADS team" or "mobile SAM", self:nodeName(p.node)), { node = p.node })
  return true
end

-- ===========================================================================
-- Missions: AMPHIB, SHIPSTRIKE, SHIPESCORT, SCUD, POPUP
-- ===========================================================================
War.MISSION_NEEDS.AMPHIB = "ANY"
War.MISSION_NEEDS.SHIPSTRIKE = "A2G"
War.MISSION_NEEDS.SHIPESCORT = "ANY"
War.MISSION_NEEDS.SCUD = "A2G"
War.MISSION_NEEDS.POPUP = "A2G"
do
  local new = { AMPHIB = true, SHIPSTRIKE = true, SHIPESCORT = true, SCUD = true, POPUP = true }
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if not new[t] then order[#order + 1] = t end
    if t == "SEAD" then order[#order + 1] = "POPUP"; order[#order + 1] = "SCUD" end
    if t == "ANTISHIP" then order[#order + 1] = "SHIPSTRIKE" end
    if t == "ESCORT" then order[#order + 1] = "AMPHIB"; order[#order + 1] = "SHIPESCORT" end
  end
  War.MISSION_ORDER = order
end
if War.HUB_TYPES then
  War.HUB_TYPES.AMPHIB, War.HUB_TYPES.SHIPESCORT, War.HUB_TYPES.POPUP = true, true, true
end

local gen = War.missionGenerators

gen.AMPHIB = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.packages)) do
    local pk = self.state.packages[id]
    if pk.kind == "amphib" and pk.side == side and pk.status == "inbound" then
      out[#out + 1] = { type = "AMPHIB", target = id, node = pk.target, prio = 0,
        label = "escort the landing at " .. self:nodeName(pk.target) }
    end
  end
  return out
end

gen.SHIPSTRIKE = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.shipping)) do
    local s = self.state.shipping[id]
    if s.side ~= side then
      out[#out + 1] = { type = "SHIPSTRIKE", target = id, node = s.port, prio = 1 - s.progress,
        label = string.format("%s supply ship to %s", s.side:upper(), self:nodeName(s.port)) }
    end
  end
  return out
end

gen.SHIPESCORT = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.shipping)) do
    local s = self.state.shipping[id]
    if s.side == side and s.progress < 0.7 then
      out[#out + 1] = { type = "SHIPESCORT", target = id, node = s.port, prio = 0,
        label = "supply ship to " .. self:nodeName(s.port) }
    end
  end
  return out
end

gen.SCUD = function(self, side)
  local out = {}
  for _, b in ipairs(self.state.scuds) do
    local known = self:isFresh(side, "scud:" .. b.id)
    if b.side ~= side and b.status == "up" and b.node and known then
      local c = self:contact(side, "scud:" .. b.id)
      if c and c.node == b.node then
        out[#out + 1] = { type = "SCUD", target = b.id, node = b.node, prio = 0,
          label = "SCUD launcher near " .. self:nodeName(b.node) }
      end
    end
  end
  return out
end

gen.POPUP = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.popups)) do
    local p = self.state.popups[id]
    if p.side ~= side and self:isFresh(side, "popup:" .. id) then
      out[#out + 1] = { type = "POPUP", target = id, node = p.node, prio = 0,
        label = string.format("%s near %s", p.kind == "manpads" and "MANPADS team" or "mobile SAM",
          self:nodeName(p.node)) }
    end
  end
  return out
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local st = self.state
  if m.type == "AMPHIB" then
    local pk = st.packages[m.target]
    if not pk then return "expired" end
    if pk.status == "destroyed" then return "failed" end
    if pk.status == "hit" then return m.escortOk and "done" or "expired" end
    return "open"
  elseif m.type == "SHIPSTRIKE" then
    if st.shipping[m.target] then return "open" end
    if st.sunkShips and st.sunkShips[m.target] then return "done" end
    return "failed"
  elseif m.type == "SHIPESCORT" then
    if st.shipping[m.target] then return "open" end
    if st.sunkShips and st.sunkShips[m.target] then return "failed" end
    return m.escortOk and "done" or "expired"
  elseif m.type == "SCUD" then
    for _, b in ipairs(st.scuds) do
      if b.id == m.target then
        if b.status ~= "up" then return "done" end
        return (b.node == m.node) and "open" or "expired"     -- it moved on: the trail is cold
      end
    end
    return "expired"
  elseif m.type == "POPUP" then
    if st.popups[m.target] then return "open" end
    return (st.killedPopups and st.killedPopups[m.target]) and "done" or "expired"
  end
  return baseOutcome(self, m, events)
end

-- INTERCEPT on an enemy landing reads right
local genIntercept = gen.INTERCEPT
gen.INTERCEPT = function(self, side)
  local out = genIntercept(self, side)
  for _, c in ipairs(out) do
    local pk = self.state.packages[c.target]
    if pk and pk.kind == "amphib" then
      c.label = string.format("%s landing helicopters inbound to %s", pk.side:upper(), self:nodeName(pk.target))
    end
  end
  return out
end

-- ===========================================================================
-- Tick
-- ===========================================================================
local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:planShipping()
  self:shippingTick()
  self:scudTick()
  self:popupTick()
  if self.state.tick % 12 == 0 then
    for id, t in pairs(self.state.sunkShips or {}) do if self.state.tick - t > 12 then self.state.sunkShips[id] = nil end end
    for id, t in pairs(self.state.deliveredShips or {}) do
      if self.state.tick - t > 12 then self.state.deliveredShips[id] = nil end
    end
    for id, t in pairs(self.state.killedPopups or {}) do
      if self.state.tick - t > 12 then self.state.killedPopups[id] = nil end
    end
  end
end

end

-- >>> src/dcc_ext4.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - engineers (pure Lua 5.1, v0.27).
-- Load after dcc_ext3.lua.
-- ----------------------------------------------------------------------------
--  15. Engineer repair: a CTLD repair kit set down at an own base fixes one
--      thing at once instead of waiting hours for the base to do it:
--        1. a destroyed strike building (fuel, ammo, warehouse ...), else
--        2. the air defence (suppressed or destroyed SAM), else
--        3. a destroyed early-warning radar.
--      The kit is paid for when it is requested (CTLD), so no supply here.
--  (6 Combined Arms, 7 QRA and 16 performance guard are bridge-only:
--   dcc_dcs_ext4.lua)
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War

-- What a repair kit would fix at base id, or nil: "infra", "sam" or "ewr".
function War:repairNeed(id)
  local ns = self.state.nodes[id]
  if not ns then return nil end
  if ns.infra and next(ns.infra.lost or {}) then return "infra" end
  if ns.sam and ns.sam.status ~= "up" then return "sam" end
  if ns.ewr and ns.ewr.status == "destroyed" then return "ewr" end
  return nil
end

-- Engineers repair one thing at base id (held by side). Returns a text or nil.
function War:engineerRepair(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side then return nil end
  local need = self:repairNeed(id)
  local name = self:nodeName(id)
  local text
  if need == "infra" then
    local k = U.sortedKeys(ns.infra.lost)[1]
    ns.infra.lost[k] = nil
    ns.infra.repairAt = next(ns.infra.lost) and ns.infra.repairAt or nil
    text = string.format("Engineers rebuilt the %s at %s", k == "1" and "fuel store" or "supply building", name)
  elseif need == "sam" then
    ns.sam = { status = "up" }
    text = string.format("Engineers put the air defence at %s back up", name)
  elseif need == "ewr" then
    ns.ewr = { status = "up" }
    text = string.format("Engineers put the early-warning radar at %s back on the air", name)
  else
    return nil
  end
  self:log("engineer_repair", side, side:upper() .. ": " .. text, { node = id, what = need })
  return text
end

-- ============================================================================
-- 6b. Ground missions for Combined Arms players (v0.28)
-- ----------------------------------------------------------------------------
--   ASSAULT  own attack on an enemy base   the base is captured        GROUND
--   HOLD     own base under attack         the attack is repulsed      GROUND
--   GCONVOY  own supply convoy by road     it arrives                  GROUND
-- Only players in ground vehicles see them. Credit goes to those who were
-- there: the bridge samples who is within presenceKm (War:groundPresence) and
-- players with less than presenceMin minutes are dropped before the credit.
-- ============================================================================
local gen = War.missionGenerators
local function G(self) return self.cfg.ext4.ground end

War.MISSION_NEEDS.ASSAULT, War.MISSION_NEEDS.HOLD, War.MISSION_NEEDS.GCONVOY = "GROUND", "GROUND", "GROUND"
for _, t in ipairs({ "ASSAULT", "HOLD", "GCONVOY" }) do War.MISSION_ORDER[#War.MISSION_ORDER + 1] = t end

gen.ASSAULT = function(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "assault" and not seen[mv.to]
       and (mv.status == "fighting" or mv.status == "moving") and self.state.nodes[mv.to].side ~= side then
      seen[mv.to] = true
      out[#out + 1] = { type = "ASSAULT", target = mv.to, node = mv.to, prio = mv.status == "fighting" and 0 or 1,
        label = "take " .. self:nodeName(mv.to) }
    end
  end
  return out
end

gen.HOLD = function(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side ~= side and mv.kind == "assault" and not seen[mv.to] and self.state.nodes[mv.to].side == side
       and (mv.status == "fighting" or mv.status == "moving") then
      seen[mv.to] = true
      out[#out + 1] = { type = "HOLD", target = mv.to, node = mv.to, prio = mv.status == "fighting" and 0 or 1,
        label = "hold " .. self:nodeName(mv.to) }
    end
  end
  return out
end

gen.GCONVOY = function(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "convoy" and mv.status == "moving" and (mv.progress or 0) < 0.8
       and not (self.onSea and self:onSea(mv)) then
      out[#out + 1] = { type = "GCONVOY", target = mid, node = mv.to, prio = mv.front and 0 or 1,
        label = string.format("convoy %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

-- The bridge: player key was near the mission for `seconds`.
function War:groundPresence(mid, key, seconds)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" or not m.taken[key] then return end
  m.presence = m.presence or {}
  m.presence[key] = (m.presence[key] or 0) + seconds
end

-- Only players who were there are credited.
local function onlyPresent(self, m)
  local need = G(self).presenceMin * 60
  for key in pairs(m.taken) do
    if ((m.presence or {})[key] or 0) < need then m.taken[key] = nil end
  end
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local t, st = m.type, self.state
  local r
  if t == "ASSAULT" or t == "HOLD" then
    for _, ev in ipairs(events) do
      if ev.node == m.target and (ev.kind == "capture" or ev.kind == "repulsed") then
        r = (ev.side == m.side) and "done" or "failed"
      end
    end
    if not r then
      local attacker = (t == "ASSAULT") and m.side or U.otherSide(m.side)
      local holder = st.nodes[m.target].side
      if (t == "ASSAULT" and holder == m.side) or (t == "HOLD" and holder ~= m.side) then return "expired" end
      for _, mv in pairs(st.moves) do
        if mv.to == m.target and mv.side == attacker and mv.kind == "assault" then return "open" end
      end
      return "expired"
    end
  elseif t == "GCONVOY" then
    if st.moves[m.target] then return "open" end
    if st.killedMoves[m.target] then return "failed" end
    r = (st.deliveredMoves and st.deliveredMoves[m.target]) and "done" or "expired"
  else
    return baseOutcome(self, m, events)
  end
  if r == "done" then onlyPresent(self, m) end
  return r
end

-- ============================================================================
-- 8. Harbour mines (v0.34)
-- ----------------------------------------------------------------------------
-- Now and then each side's minelayers (submarines, aircraft - abstract) mine an
-- enemy port on a shipping lane. While mined: no supply ship sails for that
-- port, and a ship already on its way strikes a mine on the approach (sunk,
-- cargo lost). The port's side gets a MINESWEEP mission (helicopters: fly low
-- over the harbour). Mines also clear by themselves after lifeTicks.
-- ============================================================================
local function MC(self) return self.cfg.ext4.mines end

War.MISSION_NEEDS.MINESWEEP = "SWEEP"                -- the bridge: any helicopter
War.MISSION_ORDER[#War.MISSION_ORDER + 1] = "MINESWEEP"

function War:minedPorts() return self.state.seaMines or {} end
function War:isMined(port) return (self.state.seaMines or {})[port] ~= nil end

-- side lays mines off port (an enemy port on a lane). Returns true if laid.
function War:layMines(side, port)
  local ns = self.state.nodes[port]
  self.state.seaMines = self.state.seaMines or {}
  if not ns or ns.side == side or self.state.seaMines[port] or not self:laneOf(port) then return false end
  self.state.seaMines[port] = { side = side, tick = self.state.tick, till = self.state.tick + MC(self).lifeTicks }
  self:log("mines_laid", ns.side, string.format("Mines reported off %s - %s supply ships hold until it is swept",
    self:nodeName(port), ns.side:upper()), { node = port, layer = side })
  return true
end

function War:clearMines(port, how)
  local m = (self.state.seaMines or {})[port]
  if not m then return false end
  self.state.seaMines[port] = nil
  local ns = self.state.nodes[port]
  self:log("mines_cleared", ns.side, string.format("%s harbour %s - shipping resumes", self:nodeName(port),
    how == "swept" and "swept clear of mines" or "clear, the mines have drifted or sunk"), { node = port })
  return true
end

function War:harbourMinesTick()
  local cfg = MC(self)
  self.state.seaMines = self.state.seaMines or {}
  for port, m in pairs(self.state.seaMines) do
    if self.state.tick >= m.till or self.state.nodes[port].side == m.side then self:clearMines(port, "time") end
  end
  if self.state.tick % cfg.everyTicks ~= 0 or self.state.tick == 0 then return end
  for _, side in ipairs({ "blue", "red" }) do
    -- own pseudo-random draw: does not shift the war's dice for everything else
    local roll = ((self.state.tick * 7919 + (side == "blue" and 13 or 61)) % 997) / 997
    if roll < cfg.chance then
      -- the enemy port that hurts most: a ship on its way, else the lowest supply
      local best, bestScore
      for _, l in ipairs(self:lanes()) do
        local ns = self.state.nodes[l.port]
        local busy = false
        for _, ml in pairs(self.state.minelayers or {}) do if ml.port == l.port then busy = true end end
        if ns and ns.side ~= side and not self.state.seaMines[l.port] and not busy then
          local score = (ns.supply or 0) / math.max(1, self:supplyCap(l.port))
          for _, s in pairs(self.state.shipping) do if s.port == l.port then score = score - 10 end end
          if not bestScore or score < bestScore then best, bestScore = l.port, score end
        end
      end
      if best then self:sendMinelayer(side, best) end
    end
  end
  self:minelayerTick()
end

-- ----------------------------------------------------------------------------
-- 8b. Minelayer ships (v0.35): mines are laid by a real patrol ship (BLUE Castle
-- class, RED Vasily Bykov) that sails the lane into the enemy harbour and lays
-- them at strikeAt. It is spotted by coastal radar at detectAt (or by anyone
-- who sees it) and the port's side gets a MINELAYER mission: sink it first.
-- ----------------------------------------------------------------------------
War.MISSION_NEEDS.MINELAYER = "A2G"
War.MISSION_ORDER[#War.MISSION_ORDER + 1] = "MINELAYER"

function War:minelayers() return self.state.minelayers or {} end

function War:sendMinelayer(side, port)
  local l = self:laneOf(port)
  if not l then return nil end
  self.state.minelayers = self.state.minelayers or {}
  local id = self:newId("ml")
  self.state.minelayers[id] = { id = id, side = side, port = port, progress = 0, km = U.distKm(l.start, l.dock),
                                started = self.state.tick }
  self:log("minelayer_out", side, string.format("%s minelayer sails for %s", side:upper(), self:nodeName(port)),
    { node = port, minelayer = id })
  return id
end

-- The port's side sees it (coastal radar, or a pilot): the hunt is on.
function War:spotMinelayer(id)
  local ml = (self.state.minelayers or {})[id]
  if not ml or ml.seen then return false end
  ml.seen = true
  local enemy = U.otherSide(ml.side)
  self:log("minelayer_seen", enemy, string.format("%s minelayer heading for %s - sink it before it lays mines",
    ml.side:upper(), self:nodeName(ml.port)), { node = ml.port, minelayer = id })
  return true
end

function War:minelayerSunk(id)
  local ml = (self.state.minelayers or {})[id]
  if not ml then return false end
  self.state.minelayers[id] = nil
  self.state.sunkMinelayers = self.state.sunkMinelayers or {}
  self.state.sunkMinelayers[id] = self.state.tick
  self:log("minelayer_sunk", U.otherSide(ml.side), string.format("%s minelayer bound for %s sunk - no mines",
    ml.side:upper(), self:nodeName(ml.port)), { node = ml.port, minelayer = id })
  return true
end

function War:minelayerTick()
  local cfg = MC(self)
  local step = cfg.layerSpeedKmh * self.cfg.tickSeconds / 3600
  for _, id in ipairs(U.sortedKeys(self.state.minelayers or {})) do
    local ml = self.state.minelayers[id]
    ml.progress = math.min(1, ml.progress + step / math.max(ml.km, 0.1))
    if ml.progress >= cfg.detectAt then self:spotMinelayer(id) end
    if self.state.nodes[ml.port].side == ml.side then
      self.state.minelayers[id] = nil                              -- the port changed hands: called off
    elseif ml.progress >= cfg.strikeAt then
      self.state.minelayers[id] = nil                              -- mines down, the ship heads home
      self.state.laidBy = self.state.laidBy or {}
      self.state.laidBy[id] = self.state.tick
      self:layMines(ml.side, ml.port)
    end
  end
  for id, t in pairs(self.state.sunkMinelayers or {}) do
    if self.state.tick - t > 12 then self.state.sunkMinelayers[id] = nil end
  end
  for id, t in pairs(self.state.laidBy or {}) do
    if self.state.tick - t > 12 then self.state.laidBy[id] = nil end
  end
end

gen.MINELAYER = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.minelayers or {})) do
    local ml = self.state.minelayers[id]
    if ml.side ~= side and ml.seen then
      out[#out + 1] = { type = "MINELAYER", target = id, node = ml.port, prio = 0,
        label = string.format("%s minelayer bound for %s", ml.side:upper(), self:nodeName(ml.port)) }
    end
  end
  return out
end

-- No ship sails for a mined port: they look "busy" to the planner.
local basePlan = War.planShipping
function War:planShipping()
  local dummies = {}
  for port in pairs(self.state.seaMines or {}) do
    local id = "_mined_" .. port
    self.state.shipping[id] = { id = id, side = "none", port = port, su = 0, km = 1, progress = 0 }
    dummies[#dummies + 1] = id
  end
  local s, err = pcall(basePlan, self)
  for _, id in ipairs(dummies) do self.state.shipping[id] = nil end
  if not s then error(err) end
end

-- A ship on the last stretch into a mined port strikes a mine.
local baseShipTick = War.shippingTick
function War:shippingTick()
  for _, id in ipairs(U.sortedKeys(self.state.shipping)) do
    local s = self.state.shipping[id]
    local m = (self.state.seaMines or {})[s.port]
    if m and m.side ~= s.side and (s.progress or 0) >= MC(self).strikeAt then
      self:log("mine_strike", s.side, string.format("%s supply ship struck a mine off %s", s.side:upper(),
        self:nodeName(s.port)), { node = s.port, ship = id })
      self:shippingSunk(id)
    end
  end
  return baseShipTick(self)
end

local baseOps4 = War.opsTick
function War:opsTick()
  baseOps4(self)
  self:harbourMinesTick()
end

gen.MINESWEEP = function(self, side)
  local out = {}
  for _, port in ipairs(U.sortedKeys(self.state.seaMines or {})) do
    if self.state.nodes[port].side == side then
      out[#out + 1] = { type = "MINESWEEP", target = port, node = port, prio = 0,
        label = "sweep the harbour at " .. self:nodeName(port) }
    end
  end
  return out
end

-- The bridge: a helicopter on the mission was low over the harbour for `seconds`.
function War:sweepSample(mid, seconds)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" or m.type ~= "MINESWEEP" then return end
  m.swept = (m.swept or 0) + seconds
  if m.swept >= MC(self).sweepMin * 60 and self:clearMines(m.target, "swept") then m.sweepDone = true end
end

local baseOutcome2 = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "MINELAYER" then
    if (self.state.minelayers or {})[m.target] then return "open" end
    if (self.state.sunkMinelayers or {})[m.target] then return "done" end
    if (self.state.laidBy or {})[m.target] then return "failed" end
    return "expired"
  end
  if m.type ~= "MINESWEEP" then return baseOutcome2(self, m, events) end
  if m.sweepDone then return "done" end
  if self.state.nodes[m.target].side ~= m.side or not self:isMined(m.target) then return "expired" end
  return "open"
end

-- ============================================================================
-- Main base / HQ (v0.38)
-- ----------------------------------------------------------------------------
-- Each side's HQ is `main` in the theater pack (a depot). Lost, the side's
-- next depot (theater order) takes over, else its first airbase. The bridge
-- draws it as a star on everyone's map; Campaign status names it.
-- ============================================================================
function War:mainBase(side)
  local want = self.theater.main and self.theater.main[side]
  if want and self.state.nodes[want] and self.state.nodes[want].side == side then return want end
  local airbase
  for _, id in ipairs(self.T.order) do
    if self.state.nodes[id].side == side then
      if self.T.nodes[id].depot then return id end
      if not airbase and self.T.nodes[id].kind == "airbase" then airbase = id end
    end
  end
  return airbase
end

end

-- >>> src/dcc_front.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - front-line geometry (pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- The front is not hand-drawn. It is computed from ownership: every road edge
-- whose two ends belong to different sides is "contested", and the front
-- crosses it at its midpoint, at right angles to the road. Joined together,
-- those crossings trace the line between the two sides on any map.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local F = {}
DCC.front = F

-- Returns a list of { a = {lat,lon}, b = {lat,lon}, edge = {a, b, km} }.
function F.segments(war)
  local segs = {}
  for _, e in ipairs(war.T.edges) do
    local sa, sb = war.state.nodes[e.a].side, war.state.nodes[e.b].side
    if sa ~= sb then
      local na, nb = war.T.nodes[e.a], war.T.nodes[e.b]
      local mid = U.lerp(na, nb, 0.5)
      local brg = U.bearing(na, nb)
      local half = U.clamp(e.km * 0.35, 4, 15)
      segs[#segs + 1] = {
        a = U.destination(mid, brg - 90, half),
        b = U.destination(mid, brg + 90, half),
        edge = e,
      }
    end
  end
  return segs
end

end

-- >>> src/dcc_territory.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - territory and front line from Voronoi cells
-- (pure Lua 5.1). Load after dcc_front.lua.
-- ----------------------------------------------------------------------------
-- Idea (as in rurouniJones/frontline, written here from scratch in Lua): give
-- every base the ground that is closer to it than to any other base - its
-- Voronoi cell. A side's territory is the union of its bases' cells, and the
-- front line is every cell border where a BLUE cell meets a RED cell.
--
--   * Cells are capped at territory.reachKm around their base (a 24-gon), so
--     territory does not run out over open sea or off the map. With fillHoles
--     the cap is shared: the convex hull of every base's circle, so there are
--     no holes between bases that are far apart.
--   * Each cell is computed by clipping that cap with the perpendicular
--     bisector against every other base (Sutherland-Hodgman on a convex
--     polygon; ~50 bases = 2,500 clips, a few milliseconds).
--   * Every cell edge remembers which neighbour made it, so the borders
--     between BLUE and RED cells come out as the front, joined into polylines.
--   * Work is in kilometres on a local flat projection around the map's centre
--     (good to well under 1 % over a DCS map); results come back as lat/lon,
--     so the F10 map (coord.LLtoLO) and the web map (Leaflet) both use them.
--   * Cached: recomputed only when a base changes hands.
-- ============================================================================

DCC = DCC or {}
local T = {}
DCC.territory = T

local KM_LAT = 110.574

local function cfg()
  return (DCC.config and DCC.config.territory) or { reachKm = 75, capSides = 24 }
end

-- ---------------------------------------------------------------------------
-- Projection
-- ---------------------------------------------------------------------------
local function projector(nodes)
  local lat0, lon0, n = 0, 0, 0
  for _, nd in ipairs(nodes) do lat0, lon0, n = lat0 + nd.lat, lon0 + nd.lon, n + 1 end
  local c = { lat = lat0 / n, lon = lon0 / n }
  local U = DCC.util
  -- azimuthal equidistant around the map's centre: distance and bearing from
  -- the centre are exact, other distances are off by < 0.1 % within 400 km
  return function(lat, lon)
           local p = { lat = lat, lon = lon }
           local d, b = U.distKm(c, p), math.rad(U.bearing(c, p))
           return d * math.sin(b), d * math.cos(b)
         end,
         function(x, y)
           local p = U.destination(c, math.deg(math.atan2(x, y)), math.sqrt(x * x + y * y))
           return p.lat, p.lon
         end
end

-- ---------------------------------------------------------------------------
-- Clipping a convex polygon (list of {x, y, tag}) by the half-plane that is
-- closer to site s than to site o. Edge tags say which neighbour made an edge
-- (the tag sits on the vertex that STARTS the edge).
-- ---------------------------------------------------------------------------
local function clip(poly, s, o, tag)
  -- keep points p with (p - m) . (o - s) <= 0, m = midpoint
  local mx, my = (s.x + o.x) / 2, (s.y + o.y) / 2
  local nx, ny = o.x - s.x, o.y - s.y
  local function side(p) return (p.x - mx) * nx + (p.y - my) * ny end
  local out = {}
  local n = #poly
  for i = 1, n do
    local a, b = poly[i], poly[i % n + 1]
    local da, db = side(a), side(b)
    if da <= 0 then out[#out + 1] = a end
    if (da <= 0) ~= (db <= 0) then
      local t = da / (da - db)
      local p = { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t }
      if da <= 0 then
        p.tag = tag                -- leaving: the new edge from here on lies on the bisector
      else
        p.tag = a.tag              -- entering: continue the edge we were cutting
      end
      out[#out + 1] = p
    end
  end
  return out
end

-- Convex hull (Andrew's monotone chain) of points {x, y}, counter-clockwise.
local function convexHull(points)
  local p = {}
  for _, q in ipairs(points) do p[#p + 1] = { x = q.x, y = q.y } end
  table.sort(p, function(a, b) if a.x ~= b.x then return a.x < b.x end return a.y < b.y end)
  if #p < 3 then return p end
  local function cross(o, a, b) return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) end
  local lower, upper = {}, {}
  for _, q in ipairs(p) do
    while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], q) <= 0 do lower[#lower] = nil end
    lower[#lower + 1] = q
  end
  for i = #p, 1, -1 do
    local q = p[i]
    while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], q) <= 0 do upper[#upper] = nil end
    upper[#upper + 1] = q
  end
  lower[#lower] = nil
  upper[#upper] = nil
  for _, q in ipairs(upper) do lower[#lower + 1] = q end
  return lower
end

-- ---------------------------------------------------------------------------
-- Cells
-- ---------------------------------------------------------------------------
-- sites: { {id, lat, lon, side}, ... } -> cells[id] = { side, poly = {{x,y,tag}} }
function T.cells(sites)
  local toXY, toLL = projector(sites)
  local pts = {}
  for i, s in ipairs(sites) do
    local x, y = toXY(s.lat, s.lon)
    pts[i] = { x = x, y = y, id = s.id, side = s.side }
  end
  local reach, k = cfg().reachKm, cfg().capSides
  local fill = cfg().fillHoles ~= false
  local function ring(s)
    local r = {}
    for j = 0, k - 1 do
      local a = 2 * math.pi * j / k
      r[#r + 1] = { x = s.x + reach * math.cos(a), y = s.y + reach * math.sin(a) }
    end
    return r
  end
  -- fillHoles: one cap for everybody, the convex hull of every base's reach circle
  -- (the area spanned by all bases, plus reach around it). Ground between bases
  -- that are far apart is always somebody's - no holes - while the outer edge still
  -- stops at reach beyond the outermost bases.
  local shared
  if fill then
    local all = {}
    for _, s in ipairs(pts) do for _, v in ipairs(ring(s)) do all[#all + 1] = v end end
    shared = convexHull(all)
  end
  local cells = {}
  for i, s in ipairs(pts) do
    local poly = {}
    for _, v in ipairs(shared or ring(s)) do poly[#poly + 1] = { x = v.x, y = v.y, tag = false } end
    local far = 0
    for _, v in ipairs(poly) do far = math.max(far, (v.x - s.x) ^ 2 + (v.y - s.y) ^ 2) end
    for j, o in ipairs(pts) do
      if j ~= i and #poly > 0 then
        local dx, dy = o.x - s.x, o.y - s.y
        if dx * dx + dy * dy < 4 * far then               -- farther sites cannot touch this cell
          poly = clip(poly, s, o, o.id)
        end
      end
    end
    cells[s.id] = { id = s.id, side = s.side, poly = poly, x = s.x, y = s.y }
  end
  return cells, toLL
end

-- ---------------------------------------------------------------------------
-- Front: cell edges made by a neighbour of the other side, joined into lines
-- ---------------------------------------------------------------------------
local function key(p) return string.format("%.2f,%.2f", p.x, p.y) end   -- 10 m: the same corner seen from two cells

local function chains(segs)
  -- join segments that share end points into polylines
  local byEnd, used, out = {}, {}, {}
  for i, s in ipairs(segs) do
    for _, p in ipairs({ s[1], s[2] }) do
      local k = key(p)
      byEnd[k] = byEnd[k] or {}
      table.insert(byEnd[k], i)
    end
  end
  local function nextSeg(p, from)
    for _, j in ipairs(byEnd[key(p)] or {}) do
      if not used[j] and j ~= from then return j end
    end
  end
  -- start from loose ends first, so open lines come out whole
  local order = {}
  for i, s in ipairs(segs) do
    local loose = #(byEnd[key(s[1])]) == 1 or #(byEnd[key(s[2])]) == 1
    table.insert(order, loose and 1 or #order + 1, i)
  end
  for _, i in ipairs(order) do
    if not used[i] then
      used[i] = true
      local s = segs[i]
      local a, b = s[1], s[2]
      if #(byEnd[key(b)]) == 1 and #(byEnd[key(a)]) > 1 then a, b = b, a end
      local line = { a, b }
      local tail, cur = b, i
      while true do
        local j = nextSeg(tail, cur)
        if not j then break end
        used[j] = true
        local t = segs[j]
        tail = (key(t[1]) == key(tail)) and t[2] or t[1]
        line[#line + 1] = tail
        cur = j
      end
      out[#out + 1] = line
    end
  end
  return out
end

-- Everything the map needs, from the war's current ownership.
--   territory = { {side, poly = {{lat,lon},...}}, ... }     one per base
--   front     = { {{lat,lon}, {lat,lon}, ...}, ... }         polylines
function T.compute(war)
  local sig = {}
  for _, id in ipairs(war.T.order) do sig[#sig + 1] = war.state.nodes[id].side:sub(1, 1) end
  sig = table.concat(sig)
  if war._territory and war._territory.sig == sig then return war._territory end

  local sites = {}
  for _, id in ipairs(war.T.order) do
    local tn = war.T.nodes[id]
    sites[#sites + 1] = { id = id, lat = tn.lat, lon = tn.lon, side = war.state.nodes[id].side }
  end
  local cells, toLL = T.cells(sites)
  local function ll(p)
    local lat, lon = toLL(p.x, p.y)
    return { lat = lat, lon = lon }
  end

  local territory, segs = {}, {}
  for _, id in ipairs(war.T.order) do
    local c = cells[id]
    if #c.poly >= 3 then
      local poly = {}
      for _, p in ipairs(c.poly) do poly[#poly + 1] = ll(p) end
      territory[#territory + 1] = { id = id, side = c.side, poly = poly }
      local n = #c.poly
      for i = 1, n do
        local a, b = c.poly[i], c.poly[i % n + 1]
        local nb = a.tag and cells[a.tag]
        -- each BLUE/RED border once: from the BLUE cell
        if nb and nb.side ~= c.side and c.side == "blue" then segs[#segs + 1] = { a, b } end
      end
    end
  end
  local front = {}
  for _, line in ipairs(chains(segs)) do
    local out = {}
    for _, p in ipairs(line) do out[#out + 1] = ll(p) end
    front[#front + 1] = out
  end
  war._territory = { sig = sig, territory = territory, front = front }
  return war._territory
end

-- Length of the front in km (for status and tests).
function T.frontKm(war)
  local km = 0
  for _, line in ipairs(T.compute(war).front) do
    for i = 2, #line do km = km + DCC.util.distKm(line[i - 1], line[i]) end
  end
  return km
end

end

-- >>> src/dcc_persist.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - persistence (save / load the war as JSON)
-- ----------------------------------------------------------------------------
-- All file access lives in this one module. DCS sandboxes mission scripts and
-- removes `io` and `lfs` unless the server owner re-enables them in
-- DCS World\Scripts\MissionScripting.lua. If they are missing the campaign
-- still runs, it just cannot remember anything between restarts.
--
-- Files (under Saved Games\DCS\DCC\):
--   <Theater>_war.json          the live save, written every tick
--   <Theater>_war_bak<N>.json   rotating backups (N = tick mod saveSlots)
--   <Theater>_war_final_<T>.json archive of a finished war
--   pilots.json                 pilot records (all maps)
--   rotation.json               which map the server is on / goes to next
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local P = {}
DCC.persist = P

local warned = false

function P.available()
  local ok = (io ~= nil and io.open ~= nil and lfs ~= nil and lfs.writedir ~= nil)
  if not ok and not warned then
    warned = true
    U.log("persistence OFF: io/lfs are sanitized in MissionScripting.lua - the war will not be saved")
  end
  return ok
end

local function folder()
  local dir = lfs.writedir() .. DCC.config.saveFolder .. "\\"
  pcall(lfs.mkdir, dir)
  return dir
end

local function writeFile(path, text)
  local f, err = io.open(path, "w")
  if not f then U.log("save failed (%s): %s", path, tostring(err)); return false end
  f:write(text)
  f:close()
  return true
end

local function readFile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function decodeSafe(text)
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" and v.nodes then return v end
  return nil
end

-- Write the live save plus one rotating backup.
function P.save(theaterName, state)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, state)
  if not ok then U.log("save encode failed: %s", tostring(text)); return false end
  local dir = folder()
  local main = dir .. theaterName .. "_war.json"
  local slot = (state.tick or 0) % DCC.config.saveSlots
  local done = writeFile(main, text)
  writeFile(dir .. theaterName .. "_war_bak" .. slot .. ".json", text)
  return done
end

-- Load the newest readable save. A corrupt main file falls back to the
-- backup with the highest tick, so a crash mid-write costs one tick at most.
function P.load(theaterName)
  if not P.available() then return nil end
  local dir = folder()
  local best = decodeSafe(readFile(dir .. theaterName .. "_war.json"))
  if best then return best end
  U.log("main save missing or unreadable, trying backups")
  for slot = 0, DCC.config.saveSlots - 1 do
    local s = decodeSafe(readFile(dir .. theaterName .. "_war_bak" .. slot .. ".json"))
    if s and (not best or (s.tick or 0) > (best.tick or 0)) then best = s end
  end
  return best
end

-- Keep a finished war for the record before a new one overwrites the save.
function P.archive(theaterName, state)
  if not P.available() then return end
  local ok, text = pcall(DCC.json.encode, state)
  if ok then
    writeFile(folder() .. theaterName .. "_war_final_" .. tostring(state.tick or 0) .. ".json", text)
  end
end

-- Pilot records live in one file for all theaters (they outlast a war).
function P.savePilots(data)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, data)
  if not ok then return false end
  return writeFile(folder() .. DCC.config.pilotsFile, text)
end

function P.loadPilots()
  if not P.available() then return nil end
  local text = readFile(folder() .. DCC.config.pilotsFile)
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" then return v end
  return nil
end

-- Map rotation (phase 5): one small file shared with the server hook
-- (hooks/DCC_rotation_hook.lua), which does the actual mission change.
--   { current = "<map the server should be on>", state = "running" | "ended" | "loading",
--     finished = "<map whose war just ended>", winner = "blue" | "red", next = "<map>" }
function P.readRotation()
  if not P.available() then return nil end
  local text = readFile(folder() .. "rotation.json")
  if not text or text == "" then return nil end
  local ok, v = pcall(DCC.json.decode, text)
  if ok and type(v) == "table" then return v end
  return nil
end

function P.writeRotation(rot)
  if not P.available() then return false end
  local ok, text = pcall(DCC.json.encode, rot)
  if not ok then return false end
  return writeFile(folder() .. "rotation.json", text)
end

-- The end-of-war report as plain text (for Discord, the forum, the record).
function P.writeReport(theaterName, tick, text)
  if not P.available() then return false end
  return writeFile(folder() .. theaterName .. "_war_report_" .. tostring(tick or 0) .. ".txt", text)
end

-- Plain files for the companion tool (web map, Discord): public.json (rewritten)
-- and feed.jsonl (one event per line, appended).
function P.writeFile(name, text)
  if not P.available() then return false end
  return writeFile(folder() .. name, text)
end

function P.appendFile(name, text)
  if not P.available() then return false end
  local f = io.open(folder() .. name, "a")
  if not f then return false end
  f:write(text)
  f:close()
  return true
end

end

-- >>> src/dcc_dcs.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge
-- ----------------------------------------------------------------------------
-- The war model (dcc_war.lua) is only numbers. This module is where those
-- numbers meet the DCS world:
--
--   * Live bubble  - nodes within liveRadiusKm of any player are "live".
--                    Their garrisons and the columns on roads touching them
--                    are spawned as real DCS ground groups.
--   * Read-back    - every liveCheckSeconds each spawned group is polled.
--                    Dead vehicles lower the platoon's health in the model,
--                    and a moving column's position becomes its progress.
--   * Despawn      - when players leave, groups are removed again, keeping
--                    their damage. Far from players the war runs on dice.
--   * Map          - front line, node circles and labels, own assault arrows
--                    are drawn on the F10 map.
--   * Airbases     - DCS auto-capture is switched off; airbase coalitions
--                    follow node ownership in the model.
--
-- Concept: the spawned units are a VIEW of the model, rebuilt from it at any
-- time. That is why a server restart only needs the save file - every unit
-- on the map can be recreated from the numbers.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = {
  war = nil, theater = nil, catalog = nil,
  nodePos = {},     -- node id -> vec3 (snapped to the airbase when there is one)
  airbases = {},    -- node id -> DCS airbase name
  liveNodes = {},   -- node id -> true
  spawned = {},     -- platoon id -> { group, size, base, key, kind, mid, failed }
  marks = {},       -- F10 mark ids drawn last time
  typeOk = {},      -- unit type -> bool (exists in this DCS install)
}
DCC.dcs = B

local COAL = { red = 1, blue = 2 }
B.COAL = COAL

-- ---------------------------------------------------------------------------
-- Geometry helpers (DCS: x = north, z = east, y = altitude)
-- ---------------------------------------------------------------------------
local function toVec3(ll)
  local v = coord.LLtoLO(ll.lat, ll.lon, 0)
  v.y = land.getHeight({ x = v.x, y = v.z })
  return v
end

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function isWater(x, z)
  local t = land.getSurfaceType({ x = x, y = z })
  return t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER
end

-- ---------------------------------------------------------------------------
-- Ground units never stand in the sea: every ground group and static object
-- spawned by any script (ours, CTLD) is moved to the nearest dry land, and
-- its waypoints too. Coastal towns, sea crossings and offsets near the shore
-- otherwise put units in the water.
-- ---------------------------------------------------------------------------
-- EPLRS (datalink) on for a group, by name.
function B.datalinkOn(gname)
  local okE = pcall(function()
    local g = Group.getByName(gname)
    if not g or not g:isExist() then return end
    local c = g:getController()
    c:setCommand({ id = "EPLRS", params = { value = true, groupId = g:getID() } })
    -- v0.42: AI jamming (ECM pods) filled the F-16s' screens with jamming strobes; off unless config.aiEcm says so
    local ecm = DCC.config.aiEcm
    if ecm ~= nil then
      local A = AI and AI.Option and AI.Option.Air
      local id = A and A.id and A.id.ECM_USING or 13
      local vals = A and A.val and A.val.ECM_USING or {}
      local v = ({ never = vals.NEVER_USE or 0, lock = vals.USE_IF_ONLY_LOCK_BY_RADAR or 1,
                   detected = vals.USE_IF_DETECTED_LOCK_BY_RADAR or 2, always = vals.ALWAYS_USE or 3 })[ecm]
      if v then c:setOption(id, v) end
    end
  end)
  return okE
end

-- On (or within runwayClearM of) a runway, taxiway or apron (v0.37: platoons
-- garrisoning an airbase stood and drove on the runway).
local function isRunway(x, z, m)
  local R = land.SurfaceType.RUNWAY
  if not R then return false end
  if land.getSurfaceType({ x = x, y = z }) == R then return true end
  for k = 0, 3 do
    local a = k * math.pi / 2
    if land.getSurfaceType({ x = x + m * math.cos(a), y = z + m * math.sin(a) }) == R then return true end
  end
  return false
end
B.isRunway = isRunway

-- The nearest good spot: dry land, and (avoidRunway) clear of runways and aprons.
function B.landNear(x, z, avoidRunway)
  local m = DCC.config.runwayClearM or 60
  local function bad(px, pz) return isWater(px, pz) or (avoidRunway and isRunway(px, pz, m)) end
  if not bad(x, z) then return x, z end
  for r = 50, 6000, 50 do
    for k = 0, 15 do
      local a = k * math.pi / 8
      local nx, nz = x + r * math.cos(a), z + r * math.sin(a)
      if not bad(nx, nz) then return nx, nz end
    end
  end
  return x, z
end

function B.dryGroundData(data)
  local moved = 0
  for _, u in ipairs(data.units or {}) do
    if u.x and u.y then
      local nx, nz = B.landNear(u.x, u.y, true)
      if nx ~= u.x or nz ~= u.y then u.x, u.y, moved = nx, nz, moved + 1 end
    end
  end
  for _, p in ipairs((data.route and data.route.points) or {}) do
    if p.x and p.y then p.x, p.y = B.landNear(p.x, p.y, true) end
  end
  return moved
end

if coalition and coalition.addGroup and not coalition.dccDry then
  local rawAddGroup, rawAddStatic = coalition.addGroup, coalition.addStaticObject
  coalition.addGroup = function(country, category, data)
    -- v0.41: every AI unit at DCC.config.aiSkill (Ace by default); player slots stay as they are
    local skill = DCC.config and DCC.config.aiSkill
    if skill and type(data) == "table" then
      for _, u in ipairs(data.units or {}) do
        if type(u) == "table" and u.skill ~= "Client" and u.skill ~= "Player" then u.skill = skill end
      end
    end
    if Group and category == Group.Category.GROUND and type(data) == "table" then
      local okD, n = pcall(B.dryGroundData, data)
      if okD and n > 0 and DCC.util then DCC.util.log("%s: %d units moved out of the water / off a runway", tostring(data.name), n) end
    end
    local g = rawAddGroup(country, category, data)
    -- Aircraft spawned by script have no EPLRS (the Mission Editor switches it on for
    -- every group): without it an AWACS / tanker / fighter shares nothing on the
    -- datalink, so F-16 / F/A-18 / A-10C II players see no AWACS tracks.
    if Group and (category == Group.Category.AIRPLANE or category == Group.Category.HELICOPTER)
       and type(data) == "table" and data.name then
      B.datalinkOn(data.name)
      if timer and timer.scheduleFunction then
        timer.scheduleFunction(function() B.datalinkOn(data.name) end, nil, timer.getTime() + 2)
      end
    end
    return g
  end
  if rawAddStatic then
    coalition.addStaticObject = function(country, data)
      if type(data) == "table" and data.x and data.y and data.category ~= "Ships" and data.category ~= "Heliports" then
        data.x, data.y = B.landNear(data.x, data.y)
      end
      return rawAddStatic(country, data)
    end
  end
  coalition.dccDry = true
end

-- Messages stay at least config.messageSeconds on screen (CTLD's included).
if trigger and trigger.action and not trigger.action.dccMinTime then
  local function minTime(fn, durIdx)
    local raw = trigger.action[fn]
    if not raw then return end
    trigger.action[fn] = function(...)
      local n = select("#", ...)
      local args = { ... }
      local min = (DCC.config and DCC.config.messageSeconds) or 10
      if n < durIdx then n = durIdx end
      if type(args[durIdx]) ~= "number" or args[durIdx] < min then args[durIdx] = min end
      return raw(unpack(args, 1, n))
    end
  end
  minTime("outText", 2)
  for _, fn in ipairs({ "outTextForCoalition", "outTextForGroup", "outTextForUnit", "outTextForCountry" }) do
    minTime(fn, 3)
  end
  trigger.action.dccMinTime = true
end

local function pidNumber(pid) return tonumber(tostring(pid):match("%d+")) or 1 end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------
local function resolveAirbase(tn, pos)
  local ab = tn.airbase and Airbase.getByName(tn.airbase)
  if ab then return ab end
  -- Names differ between DCS versions: fall back to the nearest airfield.
  local best, bestD
  for _, a in ipairs(world.getAirbases() or {}) do
    local desc = a:getDesc()
    if desc and desc.category == Airbase.Category.AIRDROME then
      local d = dist2D(a:getPoint(), pos)
      if d < 5000 and (not bestD or d < bestD) then best, bestD = a, d end
    end
  end
  return best
end

function B.init(war, theater, catalog)
  B.war, B.theater, B.catalog = war, theater, catalog
  B.nodePos, B.airbases, B.liveNodes, B.spawned = {}, {}, {}, {}   -- a clean view for this war
  for _, id in ipairs(war.T.order) do
    local tn = war.T.nodes[id]
    local pos = toVec3(tn)
    if tn.airbase then
      local ab = resolveAirbase(tn, pos)
      if ab then
        local p = ab:getPoint()
        pos = { x = p.x, y = p.y, z = p.z }
        B.airbases[id] = ab:getName()
        pcall(function() ab:autoCapture(false) end) -- the model decides who owns it
      else
        U.log("airbase '%s' for node %s not found - using its lat/lon", tn.airbase, id)
      end
    end
    B.nodePos[id] = pos
  end
  war.liveFn = function(id) return B.liveNodes[id] == true end
  war.airLive = true          -- airlifts are always real aircraft while DCS runs
  war.forcedMoveFn = function(mid) return B.forced ~= nil and B.forced[mid] == true end
  B.syncAirbases()
end

function B.syncAirbases()
  for id, name in pairs(B.airbases) do
    local ab = Airbase.getByName(name)
    local want = COAL[B.war.state.nodes[id].side]
    if ab then
      pcall(function()
        if ab:getCoalition() ~= want then ab:setCoalition(want) end
      end)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Live bubble
-- ---------------------------------------------------------------------------
function B.playerPositions()
  local pts = {}
  for _, c in ipairs({ coalition.side.RED, coalition.side.BLUE }) do
    for _, u in ipairs(coalition.getPlayers(c) or {}) do
      if u and u:isExist() then pts[#pts + 1] = u:getPoint() end
    end
  end
  return pts
end

-- Nodes near players become live, nearest first, until the spawn budget is used.
function B.updateLive()
  local cfg, war = DCC.config, B.war
  local players = B.playerPositions()
  local R = cfg.liveRadiusKm * 1000
  local H = (cfg.liveRadiusKm + cfg.liveHysteresisKm) * 1000
  local cand = {}
  for id, pos in pairs(B.nodePos) do
    local nearest
    for _, p in ipairs(players) do
      local d = dist2D(p, pos)
      if not nearest or d < nearest then nearest = d end
    end
    local limit = B.liveNodes[id] and H or R   -- hysteresis: no flicker at the edge
    if nearest and nearest <= limit then cand[#cand + 1] = { id = id, d = nearest } end
  end
  table.sort(cand, function(a, b) return a.d < b.d end)

  local budget, live = cfg.maxLivePlatoons, {}
  for _, c in ipairs(cand) do
    local cost = #war.state.nodes[c.id].platoons
    for _, mv in pairs(war.state.moves) do
      if mv.from == c.id or mv.to == c.id then cost = cost + #mv.platoons end
    end
    if cost <= budget then live[c.id] = true; budget = budget - cost end
  end
  B.liveNodes = live
end

-- What should exist in DCS right now, by platoon id.
function B.desired()
  local war, want = B.war, {}
  for id in pairs(B.liveNodes) do
    for _, pid in ipairs(war.state.nodes[id].platoons) do
      want[pid] = { key = "g:" .. id, kind = "garrison", node = id }
    end
  end
  for mid, mv in pairs(war.state.moves) do
    if (B.liveNodes[mv.from] or B.liveNodes[mv.to] or (B.forced and B.forced[mid])) and not war:onSea(mv) then
      for _, pid in ipairs(mv.platoons) do
        want[pid] = { key = "m:" .. mid, kind = "move", mv = mv }
      end
    end
  end
  return want
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
function B.validType(t)
  if B.typeOk[t] == nil then
    local ok, desc = pcall(Unit.getDescByName, t)
    B.typeOk[t] = ok and type(desc) == "table"
    if not B.typeOk[t] then U.log("unit type '%s' not found - using fallback", t) end
  end
  return B.typeOk[t]
end

function B.unitTypes(role, side)
  local entry = B.catalog.roles[role][side]
  for _, t in ipairs(entry.units) do
    if not B.validType(t) then return entry.fallback end
  end
  return entry.units
end

function B.countryId(side)
  local name = B.theater.country and B.theater.country[side]
  return (name and country.id[name]) or (side == "blue" and country.id.CJTF_BLUE or country.id.CJTF_RED)
end

-- A spot inside the node for a garrison platoon, the same every time for the
-- same platoon, and never in the sea.
function B.scatter(nodeId, pid)
  local c, n = B.nodePos[nodeId], pidNumber(pid)
  local spread = DCC.config.spawnSpreadM
  for i = 0, 7 do
    local ang = math.rad((n * 137.5 + i * 45) % 360)
    local r = spread * (0.3 + 0.7 * ((n * 0.618) % 1))
    local x, z = c.x + r * math.cos(ang), c.z + r * math.sin(ang)
    if not isWater(x, z) and not isRunway(x, z, DCC.config.runwayClearM or 60) then return { x = x, z = z } end
  end
  return { x = c.x, z = c.z }
end

local function roadPoint(x, z)
  local ok, rx, rz = pcall(land.getClosestPointOnRoads, "roads", x, z)
  if ok and rx and rz then return rx, rz end
  return x, z
end

local function wp(x, z, action, speed)
  return { x = x, y = z, type = "Turning Point", action = action, speed = speed,
           speed_locked = true, ETA = 0, ETA_locked = false, formation_template = "" }
end

function B.spawn(pid, w)
  -- veteran and elite platoons (dcc_ext.lua) spawn with better crews
  local lvl = B.war.vetLevel and B.war:vetLevel(pid) or 0
  local vetSkill = (lvl == 2 and "Excellent") or (lvl == 1 and "Good") or "Average"
  local war = B.war
  local pl = war.state.platoons[pid]
  local types = B.unitTypes(pl.role, pl.side)
  local n = math.max(1, math.ceil(#types * pl.health - 1e-6))
  local cfg = DCC.config
  local start, points

  if w.kind == "garrison" then
    start = B.scatter(w.node, pid)
    points = { wp(start.x, start.z, "Off Road", 0) }
  else
    local mv = w.mv
    local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
    local total = math.max(dist2D(a, b), 1)
    local t = mv.status == "fighting" and math.max(0, 1 - 2500 / total) or mv.progress
    start = { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t }
    local s = cfg.liveSpeedMps
    local r1x, r1z = roadPoint(start.x, start.z)
    local r2x, r2z = roadPoint(b.x, b.z)
    -- Off-road to the nearest road, on roads to the target, off-road into it.
    points = { wp(start.x, start.z, "Off Road", s), wp(r1x, r1z, "On Road", s),
               wp(r2x, r2z, "On Road", s), wp(b.x, b.z, "Off Road", s) }
  end

  local gname = "DCC_" .. pid
  local units = {}
  for i = 1, n do
    units[i] = { name = gname .. "_" .. i, type = types[i], skill = vetSkill,
                 x = start.x + (i - 1) * 18, y = start.z + (i % 2) * 12,
                 heading = 0, playerCanDrive = false }
  end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = points } }

  local ok, err = pcall(coalition.addGroup, B.countryId(pl.side), Group.Category.GROUND, data)
  B.spawned[pid] = { group = gname, size = n, base = pl.health, key = w.key, kind = w.kind,
                     mid = w.mv and w.mv.id, failed = not ok }
  if not ok then U.log("spawn of %s failed: %s", pid, tostring(err)) end
end

function B.despawn(pid, rec)
  local g = Group.getByName(rec.group)
  if g and g:isExist() then g:destroy() end
  B.spawned[pid] = nil
end

-- Read one spawned group back into the model: health, and progress if moving.
function B.pollOne(pid, rec)
  if rec.failed then return end
  local war, cfg = B.war, DCC.config
  local g = Group.getByName(rec.group)
  local alive, lead = 0, nil
  if g and g:isExist() then
    for _, u in ipairs(g:getUnits() or {}) do
      if u:isExist() and u:getLife() >= 1 then
        alive = alive + 1
        lead = lead or u
      end
    end
  end
  war:setHealth(pid, rec.base * alive / rec.size)

  local mv = rec.mid and war.state.moves[rec.mid]
  if lead and mv and mv.status == "moving" then
    local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
    local d = dist2D(lead:getPoint(), b)
    local p = 1 - d / math.max(dist2D(a, b), 1)
    if d <= cfg.captureRadiusKm * 1000 then p = 1 end
    war:setProgress(mv.id, p)
  end
end

-- Make the DCS world match the model.
function B.reconcile()
  local war = B.war
  local want = B.desired()
  for pid, rec in pairs(B.spawned) do
    local w = want[pid]
    if not war.state.platoons[pid] or not w or w.key ~= rec.key then
      if war.state.platoons[pid] then B.pollOne(pid, rec) end -- keep its damage
      B.despawn(pid, rec)
    end
  end
  for pid, w in pairs(want) do
    if not B.spawned[pid] and war.state.platoons[pid] then B.spawn(pid, w) end
  end
end

-- The 30-second loop: poll, recompute the bubble, then reconcile.
function B.liveCheck()
  for pid, rec in pairs(B.spawned) do
    if B.war.state.platoons[pid] then B.pollOne(pid, rec) end
  end
  if B.pollAllCargo then B.pollAllCargo() end
  B.updateLive()
  B.reconcile()
  if B.reconcileCargo then B.reconcileCargo() end
end

-- Remove every spawned group (used when a war ends).
function B.despawnAll()
  for pid, rec in pairs(B.spawned) do B.despawn(pid, rec) end
  for mid, rec in pairs(B.cargo or {}) do B.despawnCargo(mid, rec) end
end

-- ---------------------------------------------------------------------------
-- F10 map
-- ---------------------------------------------------------------------------
local function newMark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.marks[#B.marks + 1] = B.nextMark
  return B.nextMark
end

local function alpha(c, a) return { c[1], c[2], c[3], a } end

function B.draw()
  local war, cfg = B.war, DCC.config
  for _, id in ipairs(B.marks) do trigger.action.removeMark(id) end
  B.marks = {}

  -- Territory and front line (Voronoi cells, dcc_territory.lua): visible to everyone.
  local terr = DCC.territory.compute(war)
  local fillA = cfg.territory.fillAlpha
  for _, cell in ipairs(terr.territory) do
    local col = cfg.colours[cell.side]
    local args = { 7, -1, newMark() }
    for _, p in ipairs(cell.poly) do args[#args + 1] = toVec3(p) end
    args[#args + 1] = { col[1], col[2], col[3], 0 }          -- no outline: cells of one side merge
    args[#args + 1] = { col[1], col[2], col[3], fillA }
    args[#args + 1] = 0
    args[#args + 1] = true
    pcall(trigger.action.markupToAll, unpack(args))
  end
  for _, line in ipairs(terr.front) do
    for i = 2, #line do
      trigger.action.lineToAll(-1, newMark(), toVec3(line[i - 1]), toVec3(line[i]), cfg.colours.front, 1, true)
    end
  end

  -- Nodes: everyone sees who owns what; only the owner sees the strength.
  for _, id in ipairs(war.T.order) do
    local ns, tn, pos = war.state.nodes[id], war.T.nodes[id], B.nodePos[id]
    local col = cfg.colours[ns.side]
    local radius = tn.depot and 3500 or 2500
    trigger.action.circleToAll(-1, newMark(), pos, radius, col, alpha(col, 0.15), tn.depot and 2 or 1, true)
    trigger.action.textToAll(-1, newMark(), { x = pos.x + radius + 600, y = pos.y, z = pos.z - 2000 },
      col, { 0, 0, 0, 0 }, 12, true, tn.name .. (tn.depot and " (depot)" or ""))
    local label = string.format("%d plt | %d SU", #ns.platoons, math.floor((ns.supply or 0) + 0.5))
    if ns.outOfSupply then label = label .. " | NO SUPPLY" end
    trigger.action.textToAll(COAL[ns.side], newMark(), { x = pos.x - radius - 600, y = pos.y, z = pos.z - 2000 },
      col, { 0, 0, 0, 0.35 }, 11, true, label)
  end

  if B.drawOps then B.drawOps(newMark, toVec3) end

  -- Own assaults in progress: arrows only the attacking side sees.
  for _, mv in pairs(war.state.moves) do
    if mv.kind == "assault" then
      local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
      local s = { x = a.x + (b.x - a.x) * 0.2, y = a.y, z = a.z + (b.z - a.z) * 0.2 }
      local e = { x = a.x + (b.x - a.x) * 0.8, y = b.y, z = a.z + (b.z - a.z) * 0.8 }
      local col = cfg.colours[mv.side]
      trigger.action.arrowToAll(COAL[mv.side], newMark(), s, e, col, alpha(col, 0.35), 1, true)
    elseif mv.kind == "airlift" then
      -- Own airlifts: a dashed line origin -> destination, own side only.
      trigger.action.lineToAll(COAL[mv.side], newMark(), B.nodePos[mv.from], B.nodePos[mv.to],
        alpha(cfg.colours[mv.side], 0.6), 2, true)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Messages and the F10 radio menu
-- ---------------------------------------------------------------------------
function B.announce(events)
  for _, ev in ipairs(events) do
    if ev.kind == "capture" or ev.kind == "victory" or ev.kind == "clock" then
      trigger.action.outText(ev.text, ev.kind == "victory" and 60 or 20)
    elseif ev.kind == "repulsed" then
      trigger.action.outText(ev.text, 15)
    elseif ev.kind == "convoy_lost" or ev.kind == "airlift_lost" then
      trigger.action.outText(ev.text, 15)            -- both sides: the kill mattered
    elseif ev.kind == "sam_destroyed" or ev.kind == "sam_suppressed" or ev.kind == "infra_hit"
           or ev.kind == "ewr_destroyed" or ev.kind == "awacs_lost" or ev.kind == "tanker_lost"
           or ev.kind == "drone_lost" or ev.kind == "strike_hit" or ev.kind == "package_down"
           or ev.kind == "arty_destroyed" or ev.kind == "fort_hit" or ev.kind == "bridge_down"
           or ev.kind == "bridge_up" or ev.kind == "surrender" or ev.kind == "farp_lost"
           or ev.kind == "rescued" or ev.kind == "captured" or ev.kind == "airassault" then
      trigger.action.outText(ev.text, 15)
    elseif (ev.kind == "focus" or ev.kind == "assault" or ev.kind == "airlift" or ev.kind == "airlift_in"
            or ev.kind == "nosupply" or ev.kind == "cargo_lost" or ev.kind == "mission_done"
            or ev.kind == "mission_failed" or ev.kind == "sam_up" or ev.kind == "ewr_up" or ev.kind == "airdrop"
            or ev.kind == "airmobile" or ev.kind == "ambush" or ev.kind == "downed") and ev.side then
      trigger.action.outTextForCoalition(COAL[ev.side], "Command: " .. ev.text, 12)
    end
  end
end

function B.showStatus(side)
  local war = B.war
  local s = war:summary()
  local lines = {
    string.format("DANICA DYNAMIC CAMPAIGN - %s  (war day %.1f)", war.T.name, war.state.tick * DCC.config.tickSeconds / 86400),
    string.format("BLUE: %d nodes   RED: %d nodes", s.blue.nodes, s.red.nodes),
    string.format("Your forces: %d platoons", s[side].platoons),
  }
  local f = war.state.focus and war.state.focus[side]
  if f then lines[#lines + 1] = "Main effort: " .. war:nodeName(f.target) end
  if B.supplyLines then for _, l in ipairs(B.supplyLines(side)) do lines[#lines + 1] = l end end
  local left = war:clockTicksLeft()
  if left then
    local h = math.max(0, left) * DCC.config.tickSeconds / 3600
    local gb = war:groundGained("blue")
    lines[#lines + 1] = string.format("War clock%s: %dd %02dh left - %s", war.noSave and " (no saving on this server)" or "",
      math.floor(h / 24), math.floor(h % 24),
      gb == 0 and "even: no ground gained yet" or string.format("%s is ahead (%+d bases since the start)",
        gb > 0 and "BLUE" or "RED", math.abs(gb)))
  end
  if B.opsStatusLines then for _, l in ipairs(B.opsStatusLines(side)) do lines[#lines + 1] = l end end
  if B.intelStatusLines then for _, l in ipairs(B.intelStatusLines(side)) do lines[#lines + 1] = l end end
  lines[#lines + 1] = "Recent:"
  local evs = war.state.events
  local shown = 0
  for i = #evs, 1, -1 do
    local ev = evs[i]
    if ev.kind == "capture" or ev.kind == "repulsed" or ev.kind == "victory"
       or ev.kind == "convoy_lost" or ev.kind == "airlift_lost" then
      lines[#lines + 1] = "  " .. ev.text
      shown = shown + 1
      if shown >= 5 then break end
    end
  end
  trigger.action.outTextForCoalition(COAL[side], table.concat(lines, "\n"), 25)
end

function B.addMenus()
  for side, c in pairs(COAL) do
    local root = missionCommands.addSubMenuForCoalition(c, "Campaign")
    missionCommands.addCommandForCoalition(c, "Campaign status", root, B.showStatus, side)
  end
end

end

-- >>> src/dcc_dcs_supply.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, phase 2: logistics and warehouses
-- ----------------------------------------------------------------------------
-- Load after dcc_dcs.lua. Adds to DCC.dcs:
--
--   * Convoys  - a supply convoy on a road touching a live node is spawned as
--                real trucks (catalog.convoy). Every 30 s the trucks are
--                polled: dead trucks shrink the cargo, a dead convoy delivers
--                nothing. Its lead truck's position is its progress.
--   * Airlifts - always spawned as a real transport aircraft (catalog.transport)
--                in the air over its origin, flying to land at its destination.
--                Shot down = cargo lost. Landed = cargo delivered.
--   * Warehouses (dynamic spawn) - each airbase's DCS warehouse holds the
--                OWNER's player aircraft at the model's counts and 0 of the
--                enemy's. Read before each tick (players took or brought
--                aircraft), written after (captures, restocks).
--   * Slot guard - a player who spawns at a base their side does not own is
--                removed with a message (protects fixed slots after a capture).
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = DCC.dcs
B.cargo = {}           -- move id -> { group, size, base, kind, failed, born }

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function wp(x, z, action, speed, extra)
  local p = { x = x, y = z, type = "Turning Point", action = action, speed = speed,
              speed_locked = true, ETA = 0, ETA_locked = false, formation_template = "" }
  if extra then for k, v in pairs(extra) do p[k] = v end end
  return p
end

local function roadPoint(x, z)
  local ok, rx, rz = pcall(land.getClosestPointOnRoads, "roads", x, z)
  if ok and rx and rz then return rx, rz end
  return x, z
end

-- ---------------------------------------------------------------------------
-- Which cargo moves should exist in DCS
-- ---------------------------------------------------------------------------
function B.desiredCargo()
  local want = {}
  for mid, mv in pairs(B.war.state.moves) do
    if mv.cargo then
      if mv.kind == "airlift" then want[mid] = mv
      elseif (B.liveNodes[mv.from] or B.liveNodes[mv.to] or (B.forced and B.forced[mid])) and not B.war:onSea(mv) then
        want[mid] = mv
      end
    end
  end
  return want
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
function B.convoyTypes(side)
  local entry = B.catalog.convoy[side]
  for _, t in ipairs(entry.units) do
    if not B.validType(t) then return entry.fallback end
  end
  return entry.units
end

function B.spawnConvoy(mv)
  local types = B.convoyTypes(mv.side)
  local n = math.max(1, math.ceil(#types * (mv.health or 1) - 1e-6))
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local start = { x = a.x + (b.x - a.x) * mv.progress, z = a.z + (b.z - a.z) * mv.progress }
  local s = DCC.config.liveSpeedMps * 0.8      -- loaded trucks are a bit slower
  local r1x, r1z = roadPoint(start.x, start.z)
  local r2x, r2z = roadPoint(b.x, b.z)
  local gname = "DCC_" .. mv.id
  local units = {}
  for i = 1, n do
    units[i] = { name = gname .. "_" .. i, type = types[i], skill = "Average",
                 x = start.x + (i - 1) * 25, y = start.z, heading = 0, playerCanDrive = false }
  end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    wp(start.x, start.z, "Off Road", s), wp(r1x, r1z, "On Road", s),
    wp(r2x, r2z, "On Road", s), wp(b.x, b.z, "Off Road", s) } } }
  local ok, err = pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.GROUND, data)
  B.cargo[mv.id] = { group = gname, size = n, base = mv.health or 1, kind = "convoy",
                     failed = not ok, born = timer.getTime() }
  if not ok then U.log("convoy spawn %s failed: %s", mv.id, tostring(err)) end
end

function B.transportType(side)
  local entry = B.catalog.transport[side]
  if B.validType(entry.type) then return entry.type end
  return entry.fallback
end

function B.spawnAirlift(mv)
  local t = B.transportType(mv.side)
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local p = U.clamp(mv.progress, 0, 0.95)
  local x, z = a.x + (b.x - a.x) * p, a.z + (b.z - a.z) * p
  local alt = math.max(a.y, b.y) + 2500
  local speed = DCC.config.supply.airliftSpeedKmh / 3.6
  local fuel = 10000
  local ok, desc = pcall(Unit.getDescByName, t)
  if ok and type(desc) == "table" and desc.fuelMassMax then fuel = desc.fuelMassMax end
  local abName = B.airbases[mv.to]
  local ab = abName and Airbase.getByName(abName)
  local landing = { type = "Land", action = "Landing", alt = 0, alt_type = "RADIO" }
  if ab then landing.airdromeId = ab:getID() end
  local gname = "DCC_" .. mv.id
  local heading = math.atan2(b.z - z, b.x - x)
  local data = {
    name = gname, task = "Transport",
    units = { { name = gname .. "_1", type = t, skill = "High", x = x, y = z, alt = alt, alt_type = "BARO",
                speed = speed, heading = heading, payload = { fuel = fuel, flare = 60, chaff = 60, gun = 100 },
                callsign = { 1, 1, 1, ["name"] = "Ford11" }, onboard_num = "010" } },
    route = { points = {
      wp(x, z, "Turning Point", speed, { alt = alt, alt_type = "BARO" }),
      wp(b.x, b.z, "Landing", speed, landing),
    } },
  }
  local okAdd, err = pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.AIRPLANE, data)
  B.cargo[mv.id] = { group = gname, size = 1, base = mv.health or 1, kind = "airlift",
                     failed = not okAdd, born = timer.getTime() }
  if not okAdd then U.log("airlift spawn %s failed: %s", mv.id, tostring(err)) end
end

function B.despawnCargo(mid, rec)
  local g = Group.getByName(rec.group)
  if g and g:isExist() then g:destroy() end
  B.cargo[mid] = nil
end

-- ---------------------------------------------------------------------------
-- Read-back
-- ---------------------------------------------------------------------------
function B.pollCargo(mid, rec)
  local war = B.war
  local mv = war.state.moves[mid]
  if not mv or rec.failed then return end
  local g = Group.getByName(rec.group)
  local alive, lead = 0, nil
  if g and g:isExist() then
    for _, u in ipairs(g:getUnits() or {}) do
      if u:isExist() and u:getLife() >= 1 then alive = alive + 1; lead = lead or u end
    end
  end
  war:setCargoHealth(mid, rec.base * alive / rec.size)
  mv = war.state.moves[mid]
  if not mv or not lead then return end

  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local d = dist2D(lead:getPoint(), b)
  local total = math.max(dist2D(a, b), 1)
  local p = 1 - d / total
  if rec.kind == "airlift" then
    -- Delivered once the transport is down near the destination.
    local landed = lead.inAir and not lead:inAir()
    if landed and d < 6000 then p = 1 else p = math.min(p, 0.97) end
    -- Safety: a transport circling for 3x its flight time delivers anyway.
    local kmh = rec.helo and DCC.config.supply.heliliftSpeedKmh or DCC.config.supply.airliftSpeedKmh
    local expect = total / (kmh / 3.6)
    if timer.getTime() - rec.born > 3 * expect + 600 then p = 1 end
  elseif d <= DCC.config.captureRadiusKm * 1000 then
    p = 1
  end
  war:setProgress(mid, p)
end

function B.reconcileCargo()
  local want = B.desiredCargo()
  for mid, rec in pairs(B.cargo) do
    if not want[mid] then
      if B.war.state.moves[mid] then B.pollCargo(mid, rec) end   -- keep its losses
      B.despawnCargo(mid, rec)
    end
  end
  for mid, mv in pairs(want) do
    if not B.cargo[mid] and B.war.state.moves[mid] then
      if mv.kind == "airlift" then B.spawnAirlift(mv) else B.spawnConvoy(mv) end
    end
  end
end

function B.pollAllCargo()
  for mid, rec in pairs(B.cargo) do B.pollCargo(mid, rec) end
end

-- ---------------------------------------------------------------------------
-- Warehouses: player aircraft per airbase follow the owner
-- ---------------------------------------------------------------------------
local function warehouseOf(id)
  local name = B.airbases[id]
  local ab = name and Airbase.getByName(name)
  if not ab or not ab.getWarehouse then return nil end
  local ok, w = pcall(ab.getWarehouse, ab)
  return ok and w or nil
end

-- DCS -> model: what players took off with or landed.
function B.readWarehouses()
  local war = B.war
  for id in pairs(B.airbases) do
    local ns, w = war.state.nodes[id], warehouseOf(id)
    if w and ns.air then
      for t in pairs(ns.air) do
        local ok, n = pcall(w.getItemCount, w, t)
        if ok and type(n) == "number" then war:setAircraft(id, t, n) end
      end
    end
  end
end

-- model -> DCS: owner's types at the model's counts, enemy's types at 0.
function B.writeWarehouses()
  local war = B.war
  for id in pairs(B.airbases) do
    local ns, w = war.state.nodes[id], warehouseOf(id)
    if w and ns.air then
      local enemy = U.otherSide(ns.side)
      for _, t in ipairs(war:aircraftTypes(enemy)) do
        if ns.air[t] == nil then pcall(w.setItem, w, t, 0) end   -- shared types stay
      end
      for t, n in pairs(ns.air) do pcall(w.setItem, w, t, n) end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Slot guard
-- ---------------------------------------------------------------------------
function B.nearestNode(pos, maxM)
  local best, bestD
  for id, p in pairs(B.nodePos) do
    local d = dist2D(pos, p)
    if d <= maxM and (not bestD or d < bestD) then best, bestD = id, d end
  end
  return best
end

function B.onBirth(unit)
  if not unit or not unit.getPlayerName then return end
  local ok, pname = pcall(unit.getPlayerName, unit)
  if not ok or not pname then return end
  local id = B.nearestNode(unit:getPoint(), 5000)
  if not id then return end
  local side = (unit:getCoalition() == B.COAL.blue) and "blue" or "red"
  if B.war.state.nodes[id].side ~= side then
    trigger.action.outTextForUnit(unit:getID(), string.format(
      "%s is held by %s. Pick a slot at a base your side owns.", B.war:nodeName(id),
      B.war.state.nodes[id].side:upper()), 20)
    pcall(function() unit:destroy() end)
    U.log("slot guard: removed %s at enemy-held %s", tostring(pname), id)
  end
end

-- ---------------------------------------------------------------------------
-- Status text extensions
-- ---------------------------------------------------------------------------
function B.supplyLines(side)
  local war = B.war
  local lines = {}
  lines[#lines + 1] = string.format("Your supply: %d SU in stock", math.floor(war:supplySummary()[side]))
  local convoys, lifts, dry = 0, 0, {}
  for _, mv in pairs(war.state.moves) do
    if mv.side == side and mv.kind == "convoy" then convoys = convoys + 1 end
    if mv.side == side and mv.kind == "airlift" then lifts = lifts + 1 end
  end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side and ns.outOfSupply then dry[#dry + 1] = war:nodeName(id) end
  end
  lines[#lines + 1] = string.format("On the move: %d convoys, %d airlifts", convoys, lifts)
  if #dry > 0 then lines[#lines + 1] = "OUT OF SUPPLY: " .. table.concat(dry, ", ") end
  return lines
end

end

-- >>> src/dcc_dcs_ops.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, phase 3: missions and operations
-- ----------------------------------------------------------------------------
-- Load after dcc_dcs_supply.lua. Adds to DCC.dcs:
--
--   1. Players      - who is flying what, pilot records (sorties, kills,
--                     deaths, ejections), per-aircraft F10 menus.
--   2. Mission board- "Missions" menu per aircraft: take, brief, abandon.
--                     Briefing gives target, coordinates and an F10 mark.
--   3. Detection    - every 10 s: recon passes, CAP time on station, escort
--                     distance, CSAR pickups and drop-offs.
--   4. SAM sites    - spawned within 80 km of players; radar and launcher
--                     losses read back (SEAD/DEAD).
--   5. Structures   - fuel/ammo/warehouse statics at depots and airbases
--                     (STRIKE), read back when destroyed.
--   6. AI air       - CAP, CAS and airlift intercept sorties cloned from the
--                     mission's DCC_TPL_* template groups, paid from the
--                     side's air pool; losses read back.
--   7. CSAR         - ejected pilots wait on the ground; a transport
--                     helicopter lands next to them, then at a friendly base.
--   8. Logistics    - transport helicopters load supply crates and troops at
--                     friendly bases and unload them elsewhere (troops dropped
--                     at an enemy base attack it).
--   9. Convoy escort- taking the mission spawns an ambush on the convoy's road.
--  10. Map          - own SAM rings, recon intel, downed pilots.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = DCC.dcs

B.players  = {}   -- unit name -> player record (see B.registerPlayer)
B.sams     = {}   -- node id -> { group, status }
B.statics  = {}   -- node id -> { side, names = { [k] = name } }
B.sorties  = {}   -- group name -> AI sortie
B.downedGroups = {} -- downed id -> group name
B.ambushes = {}   -- mission id -> group name
B.forced   = {}   -- move id -> true while a player mission targets it
B.sortieCount = 0

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function cat() return B.catalog end
local function wpos(p) return { x = p.x, y = land.getHeight({ x = p.x, y = p.z }), z = p.z } end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

local function unitByName(n) return n and ok(Unit.getByName, n) end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function landed(u) return alive(u) and ok(u.inAir, u) == false end

local function agl(u)
  local p = u:getPoint()
  return p.y - land.getHeight({ x = p.x, y = p.z })
end

local function sideOfUnit(u) return (u:getCoalition() == B.COAL.blue) and "blue" or "red" end

-- A spot near a node that is land and not runway, the same each time.
local function spotNear(id, k, radius)
  local c = B.nodePos[id]
  for i = 0, 11 do
    local ang = math.rad((k * 67 + i * 30) % 360)
    local x, z = c.x + radius * math.cos(ang), c.z + radius * math.sin(ang)
    local t = land.getSurfaceType({ x = x, y = z })
    if t ~= land.SurfaceType.WATER and t ~= land.SurfaceType.SHALLOW_WATER and t ~= land.SurfaceType.RUNWAY then
      return { x = x, z = z }
    end
  end
  return { x = c.x + radius, z = c.z }
end

local function nearestNodeOf(pos, side, maxM)
  return B.nearestNodeOf(pos, side, maxM)
end
function B.nearestNodeOf(pos, side, maxM)
  local best, bestD
  for id, p in pairs(B.nodePos) do
    if not side or B.war.state.nodes[id].side == side then
      local d = dist2D(pos, p)
      if (not maxM or d <= maxM) and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  return best, bestD
end

-- ===========================================================================
-- 1. Players and pilot records
-- ===========================================================================
local function playerKey(name)
  if net and net.get_player_list then
    local list = ok(net.get_player_list) or {}
    for _, pid in ipairs(list) do
      local info = ok(net.get_player_info, pid)
      if info and info.name == name and info.ucid then return info.ucid end
    end
  end
  return name
end

function B.registerPlayer(u)
  local name = ok(u.getPlayerName, u)
  if not name then return nil end
  local uname = u:getName()
  local g = u:getGroup()
  local p = {
    unit = uname, name = name, key = playerKey(name), side = sideOfUnit(u),
    type = u:getTypeName(), gid = g and g:getID(), born = timer.getTime(),
    crates = 0, troops = {}, onboard = {}, capSeconds = 0, ticks = 0,
  }
  p.home = nearestNodeOf(u:getPoint(), nil, 6000)
  local d = ok(u.getDesc, u)
  p.heli = d and d.category == Unit.Category.HELICOPTER or false
  local sp = u:getPoint()
  p.spawn = { x = sp.x, y = 0, z = sp.z }     -- helicopters get missions near here
  p.slow = not p.heli and B.isSlowType(p.type)
  B.players[uname] = p
  B.updateHubs(true)
  DCC.pilots:get(p.key, name)
  B.buildMenu(p)
  return p
end

function B.caps(p)
  return (cat().capabilities or {})[p.type] or {}
end

function B.canFly(p, m)
  local c = B.caps(p)
  return m.needs == "ANY" or c[m.needs] == true
end

function B.clearPlayer(uname, how)
  local p = B.players[uname]
  if not p then return end
  if p.mission then B.leaveTeam(p, how == "lost" and "lost" or "left the slot") end
  if #p.troops > 0 then
    for _, pid in ipairs(p.troops) do
      if how == "lost" then B.war:loseCarried(pid) else B.war:returnCarried(pid) end
    end
  end
  if p.takeoff then
    DCC.pilots:add(p.key, "flightMinutes", (timer.getTime() - p.takeoff) / 60)
  end
  if p.menu then ok(missionCommands.removeItemForGroup, p.gid, p.menu) end
  B.players[uname] = nil
  B.updateHubs(true)                     -- its untaken local missions are withdrawn
end

-- Slow movers (A-10, Su-25, trainers) get a wider "local" range than helicopters.
function B.isSlowType(t)
  for _, s in ipairs(DCC.config.missions.slowTypes or {}) do if s == t then return true end end
  return false
end

-- The range a player's mission board is limited to, in km (nil = whole board).
function B.localRangeKm(p)
  local mc = DCC.config.missions
  if p.heli then return mc.heloRangeKm or 110 end
  if p.slow then return mc.slowRangeKm or 222 end
  return nil
end

-- Tell the war where helicopters and slow movers are, so it creates missions
-- near them (War:hubMissions). fill = update the local missions right away.
function B.updateHubs(fill)
  local hubs, seen = { blue = {}, red = {} }, {}
  for _, p in pairs(B.players) do
    local km = B.localRangeKm(p)
    if km and p.spawn and hubs[p.side] then
      local node = B.nearestNodeOf(p.spawn, p.side) or B.nearestNodeOf(p.spawn)
      local key = p.side .. "|" .. tostring(node) .. "|" .. p.type
      if node and not seen[key] then
        seen[key] = true
        table.insert(hubs[p.side], { node = node, km = km, caps = B.caps(p) })
      end
    end
  end
  for side, list in pairs(hubs) do B.war:setHubs(side, list) end
  if fill then ok(B.war.hubMissions, B.war) end
end

-- ===========================================================================
-- 2. Mission board menus
-- ===========================================================================
local function fmtLL(pos)
  local lat, lon = coord.LOtoLL(wpos(pos))
  local function dm(v, pos_, neg)
    local h = v >= 0 and pos_ or neg
    v = math.abs(v)
    local d = math.floor(v)
    return string.format("%s%02d°%06.3f'", h, d, (v - d) * 60)
  end
  local s = dm(lat, "N", "S") .. " " .. dm(lon, "E", "W")
  local m = ok(coord.LLtoMGRS, lat, lon)
  if m and m.UTMZone then
    s = s .. string.format("  MGRS %s %s %05d %05d", m.UTMZone, m.MGRSDigraph, math.floor(m.Easting), math.floor(m.Northing))
  end
  return s
end

-- Where a mission's target is right now (a map point), or nil.
function B.missionPos(m)
  local st = B.war.state
  if m.type == "BAI" or m.type == "ESCORT" or m.type == "CONVOY" then
    local rec = B.cargo[m.target]
    local g = rec and ok(Group.getByName, rec.group)
    if not g then
      local mv = st.moves[m.target]
      local first = mv and mv.platoons[1]
      local pr = first and B.spawned[first]
      g = pr and ok(Group.getByName, pr.group)
    end
    local u = g and ok(g.getUnit, g, 1)
    if alive(u) then return u:getPoint() end
    local mv = st.moves[m.target]
    if mv then
      local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
      return { x = a.x + (b.x - a.x) * mv.progress, y = 0, z = a.z + (b.z - a.z) * mv.progress }
    end
    return nil
  elseif m.type == "CSAR" then
    local d = st.downed[m.target]
    return d and { x = d.pos.x, y = 0, z = d.pos.z }
  end
  return m.node and B.nodePos[m.node]
end

local EFFECT = {
  CAS = "Kill enemy ground forces in the battle. The outcome decides who holds the base.",
  BAI = "Destroy the column on the road. Its cargo or platoons never arrive.",
  STRIKE = "Destroy fuel, ammo or warehouse buildings. Each one burns supply and cuts the base's output for hours.",
  SEAD = "Kill the radar to suppress the site for ~2 h, or radar and launchers to destroy it for ~6 h.",
  CAP = "Stay on station 20 min or shoot down an enemy aircraft. Gives 1 h of air superiority: enemy AI attack sorties stay away.",
  ESCORT = "Stay within 15 km of the transport until it lands. Enemy fighters may try to intercept it.",
  CONVOY = "Stay within 3 km of the convoy. An ambush waits ahead on the road. An escorted convoy is not ambushed.",
  RECON = "Overfly the base within 8 km below 4500 m. Your side gets its garrison and SAM status on the map.",
  CSAR = "Land within 150 m of the pilot (green smoke), then land at a friendly base. The aircraft is refunded.",
  LOGISTICS = "F10 > Missions > Cargo: load a supply crate at a friendly base and unload it at the target.",
}
B.EFFECT = EFFECT      -- other modules (CTLD) add or reword entries

function B.brief(p, m)
  local pos = B.missionPos(m)
  local u = unitByName(p.unit)
  local lines = { string.format("MISSION %s - %s", m.type, m.label) }
  if pos then
    lines[#lines + 1] = "Target: " .. fmtLL(pos)
    -- for typing into the jet or a DTC tool: seconds format and elevation
    local lat, lon = coord.LOtoLL(wpos(pos))
    local function dms(v, h1, h2)
      local h = v >= 0 and h1 or h2
      v = math.abs(v)
      local d = math.floor(v); local mf = (v - d) * 60; local m = math.floor(mf)
      return string.format("%s%02d°%02d'%04.1f\"", h, d, m, (mf - m) * 60)
    end
    local elev = ok(land.getHeight, { x = pos.x, y = pos.z }) or 0
    lines[#lines + 1] = string.format("DMS %s %s  Elev %d ft / %d m", dms(lat, "N", "S"), dms(lon, "E", "W"),
      math.floor(elev * 3.28084 + 0.5), math.floor(elev + 0.5))
    if alive(u) then
      local up = u:getPoint()
      local brg = (math.deg(math.atan2(pos.z - up.z, pos.x - up.x)) + 360) % 360
      lines[#lines + 1] = string.format("From you: %03d° / %d km", math.floor(brg + 0.5),
        math.floor(dist2D(up, pos) / 1000 + 0.5))
    end
    if p.gid then
      B.markId = (B.markId or (DCC.config.markIdBase + 500000)) + 1
      ok(trigger.action.markToGroup, B.markId, m.type .. ": " .. m.label, wpos(pos), p.gid, true)
      p.marks = p.marks or {}
      p.marks[#p.marks + 1] = B.markId
    end
  end
  local team = B.teamOf(m)
  if #team > 1 then
    local names = {}
    for _, w in ipairs(team) do names[#names + 1] = w.name .. (w.type and (" (" .. w.type .. ")") or "") end
    lines[#lines + 1] = "Flight: " .. table.concat(names, ", ")
  end
  lines[#lines + 1] = EFFECT[m.type] or ""
  trigger.action.outTextForGroup(p.gid, table.concat(lines, "\n"), 30)
end

function B.takeMission(args)
  local p = B.players[args.unit]
  if not p then return end
  local m = B.war:takeMission(args.mid, p.key, p.name)
  if not m then
    trigger.action.outTextForGroup(p.gid, "That mission is no longer open.", 10)
    return B.buildMenu(p)
  end
  if p.mission == args.mid then return B.brief(p, m) end
  if p.mission then B.leaveTeam(p, "switched missions") end
  p.mission, p.capSeconds = m.id, 0
  local others = {}
  for _, w in ipairs(B.teamOf(m)) do
    if w.p ~= p then others[#others + 1] = w.name .. (w.type and (" (" .. w.type .. ")") or "") end
  end
  B.tellTeam(m, p, string.format("%s (%s) joined your %s mission: %s.", p.name, p.type, m.type, m.label))
  B.updateForced()                       -- the target spawns for real right away
  if m.type == "CONVOY" then B.spawnAmbush(m) end
  B.brief(p, m)
  if #others > 0 then
    trigger.action.outTextForGroup(p.gid, "Flying with: " .. table.concat(others, ", ")
      .. ". Coordinate on your radio / SRS - everyone on the mission gets the credit.", 20)
  end
  B.refreshMenus()                         -- everyone's board shows the new flight member
end

-- p leaves its mission (abandon, switch, slot change): the rest of the flight is told.
function B.leaveTeam(p, why)
  local m = p.mission and B.war.state.missions[p.mission]
  B.war:leaveMission(p.mission, p.key)
  if m and m.status == "open" then
    B.tellTeam(m, p, string.format("%s left your %s mission (%s).", p.name, m.type, why))
  end
end

function B.myMission(uname)
  local p = B.players[uname]
  if not p then return end
  local m = p.mission and B.war.state.missions[p.mission]
  if not m then trigger.action.outTextForGroup(p.gid, "No mission. F10 > Missions to take one.", 10); return end
  if m.status ~= "open" then
    trigger.action.outTextForGroup(p.gid, "Your mission is " .. m.status .. ".", 10)
    return
  end
  B.brief(p, m)
end

function B.abandon(uname)
  local p = B.players[uname]
  if not p or not p.mission then return end
  B.leaveTeam(p, "abandoned")
  p.mission = nil
  trigger.action.outTextForGroup(p.gid, "Mission abandoned.", 10)
  B.refreshMenus()
end

function B.showRecord(uname)
  local p = B.players[uname]
  if p then trigger.action.outTextForGroup(p.gid, DCC.pilots:summary(p.key), 30) end
end

function B.showLeaderboard(uname)
  local p = B.players[uname]
  if p then
    trigger.action.outTextForGroup(p.gid, "TOP PILOTS\n" .. table.concat(DCC.pilots:top(10), "\n"), 30)
  end
end

function B.showSquadrons(uname)
  local p = B.players[uname]
  if p then
    trigger.action.outTextForGroup(p.gid, "TOP SQUADRONS\n" .. table.concat(DCC.pilots:topSquadrons(10), "\n"), 30)
  end
end

-- ---------------------------------------------------------------------------
-- Flying together: any number of pilots may take the same mission. The board
-- shows who is on it, "Join a flight" lists missions other pilots of your side
-- are flying, and the flight is told when someone joins or leaves.
-- ---------------------------------------------------------------------------
-- The pilots on mission m: { { name, type (aircraft or nil if not in a slot), p } }
function B.teamOf(m)
  local out = {}
  for key, name in pairs(m.taken or {}) do
    local who = { name = name }
    for _, p in pairs(B.players) do
      if p.key == key and p.mission == m.id then who.type, who.p = p.type, p end
    end
    out[#out + 1] = who
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

function B.teamText(m, max)
  local t = B.teamOf(m)
  if #t == 0 then return "" end
  local names = {}
  for i, w in ipairs(t) do if i <= (max or 3) then names[#names + 1] = w.name end end
  return string.format(" [%d: %s%s]", #t, table.concat(names, ", "), #t > (max or 3) and ", ..." or "")
end

-- Tell everyone else on mission m (except p) something.
function B.tellTeam(m, p, text)
  for _, w in ipairs(B.teamOf(m)) do
    if w.p and w.p ~= p then trigger.action.outTextForGroup(w.p.gid, text, 15) end
  end
end

-- The missions this aircraft is offered. Helicopters only see missions within
-- missions.heloRangeKm of where they spawned (slow movers: slowRangeKm), nearest
-- first (a 300 nm CSAR is no use to a Huey); if nothing is that close, the 3
-- nearest are offered instead.
function B.missionsFor(p)
  local out = {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if B.canFly(p, m) then out[#out + 1] = m end
  end
  local rangeKm = B.localRangeKm(p)
  if not rangeKm or not p.spawn then return out end
  local range = rangeKm * 1000
  local list = {}
  for _, m in ipairs(out) do
    local pos = B.missionPos(m)
    local d = pos and math.sqrt((pos.x - p.spawn.x) ^ 2 + (pos.z - p.spawn.z) ^ 2) or math.huge
    list[#list + 1] = { m = m, d = d }
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local near = {}
  for i, e in ipairs(list) do
    if e.d <= range or (i <= 3 and list[1].d > range and e.d < math.huge) then
      -- a shallow copy, so the distance label never leaks into the war state
      local c = setmetatable({ _nm = math.floor(e.d / 1852 + 0.5) }, { __index = e.m })
      near[#near + 1] = c
    end
  end
  return near
end

-- (Re)build one aircraft's "Missions" menu.
function B.buildMenu(p)
  if not p.gid then return end
  if p.menu then ok(missionCommands.removeItemForGroup, p.gid, p.menu) end
  local root = missionCommands.addSubMenuForGroup(p.gid, "Missions")
  p.menu = root
  -- DCS shows at most 10 items per F10 page and its own paging is unreliable,
  -- so no level here ever holds more than 10: the mission types go into
  -- "Mission board", 9 per page with "More missions" as the 10th.
  --   Missions > Join a flight | Mission board | My mission | Pilot records | Cargo | (JTAC)
  local byType, order = {}, {}
  for _, m in ipairs(B.missionsFor(p)) do
    if not byType[m.type] then byType[m.type] = {}; order[#order + 1] = m.type end
    table.insert(byType[m.type], m)
  end
  -- missions other pilots of this side are flying now, whatever the distance
  local joinable = {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if B.canFly(p, m) and next(m.taken) and p.mission ~= m.id then joinable[#joinable + 1] = m end
  end
  if #joinable > 0 then
    local sub = missionCommands.addSubMenuForGroup(p.gid, string.format("Join a flight (%d)", #joinable), root)
    for i, m in ipairs(joinable) do
      if i <= 10 then
        missionCommands.addCommandForGroup(p.gid, m.type .. ": " .. m.label .. B.teamText(m, 2), sub, B.takeMission,
          { unit = p.unit, mid = m.id })
      end
    end
  end
  local total = 0
  for _, t in ipairs(order) do total = total + #byType[t] end
  local page = missionCommands.addSubMenuForGroup(p.gid, string.format("Mission board (%d)", total), root)
  for i, t in ipairs(order) do
    if i > 1 and (i - 1) % 9 == 0 then
      page = missionCommands.addSubMenuForGroup(p.gid, "More missions", page)
    end
    local sub = missionCommands.addSubMenuForGroup(p.gid, string.format("%s (%d)", t, #byType[t]), page)
    for k, m in ipairs(byType[t]) do
      if k <= 10 then
        local mark = (p.mission == m.id) and "> " or ""
        local far = m._nm and string.format(" (%d nm)", m._nm) or ""
        missionCommands.addCommandForGroup(p.gid, mark .. m.type .. ": " .. m.label .. far .. B.teamText(m, 2), sub,
          B.takeMission, { unit = p.unit, mid = m.id })
      end
    end
  end
  local mine = missionCommands.addSubMenuForGroup(p.gid, "My mission", root)
  missionCommands.addCommandForGroup(p.gid, "My mission (brief again)", mine, B.myMission, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Abandon mission", mine, B.abandon, p.unit)
  local rec = missionCommands.addSubMenuForGroup(p.gid, "Pilot records", root)
  missionCommands.addCommandForGroup(p.gid, "My pilot record", rec, B.showRecord, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Leaderboard", rec, B.showLeaderboard, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Squadron leaderboard", rec, B.showSquadrons, p.unit)
  local lift = (cat().lift or {})[p.type]
  if lift and not B.ctldActive then           -- with CTLD in the mission, CTLD's own menu does cargo
    local c = missionCommands.addSubMenuForGroup(p.gid, "Cargo", root)
    if lift.crates > 0 then missionCommands.addCommandForGroup(p.gid, "Load supply crate", c, B.loadCrate, p.unit) end
    if lift.troops > 0 then missionCommands.addCommandForGroup(p.gid, "Load troops", c, B.loadTroops, p.unit) end
    missionCommands.addCommandForGroup(p.gid, "Unload", c, B.unload, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Cargo status", c, B.cargoStatus, p.unit)
  end
end

function B.refreshMenus()
  for _, p in pairs(B.players) do B.buildMenu(p) end
end

-- ===========================================================================
-- 3. Detection (every 10 s)
-- ===========================================================================
function B.detect()
  local war, mc = B.war, DCC.config.missions
  B.detectCount = (B.detectCount or 0) + 1
  for uname, p in pairs(B.players) do
    local u = unitByName(uname)
    if not alive(u) then
      -- unit gone without an event (slot change): tidy up
      if timer.getTime() - p.born > 30 then B.clearPlayer(uname, "left") end
    else
      local pos = u:getPoint()
      local m = p.mission and war.state.missions[p.mission]
      if m and m.status == "open" then
        local tpos = B.missionPos(m)
        if m.type == "RECON" and tpos and dist2D(pos, tpos) <= mc.reconRadiusKm * 1000 and agl(u) <= mc.reconMaxAglM then
          war:completeMission(m.id, true)
          trigger.action.outTextForGroup(p.gid, "Recon pass complete - " .. war:nodeName(m.target) .. " is on your map.", 15)
        elseif m.type == "CAP" and tpos and dist2D(pos, tpos) <= mc.capRadiusKm * 1000 then
          p.capSeconds = p.capSeconds + 10
          if p.capSeconds >= mc.capMinutes * 60 then
            war:completeMission(m.id, true)
            trigger.action.outTextForGroup(p.gid, "CAP complete - air superiority over " .. war:nodeName(m.target) .. " for 1 h.", 15)
          end
        elseif (m.type == "ESCORT" or m.type == "CONVOY") and B.detectCount % 3 == 0 then
          local limit = (m.type == "ESCORT") and mc.escortRadiusKm or mc.convoyEscortKm
          war:escortSample(m.id, tpos ~= nil and dist2D(pos, tpos) <= limit * 1000)
        end
      end
      B.csarCheck(p, u, pos)
    end
  end
end

-- ===========================================================================
-- 4. SAM sites
-- ===========================================================================
local function playerNear(pos, km)
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, pos) <= km * 1000 then return true end
  end
  return false
end

function B.spawnSam(id)
  local ns = B.war.state.nodes[id]
  local spec = cat().sam and cat().sam[ns.side]
  if not spec then return end
  local units, k = {}, 0
  local function add(list, tag)
    for i, t in ipairs(list) do
      if B.validType(t) then
        k = k + 1
        local sp = spotNear(id, 40 + k, 1500 + (k % 3) * 120)
        local off = ns.sam.off                             -- the site moved (shoot and scoot)
        if off then sp = { x = sp.x + off.dx, z = sp.z + off.dz } end
        units[#units + 1] = { name = "DCC_SAM_" .. id .. "_" .. tag .. i, type = t, skill = "High",
                              x = sp.x, y = sp.z, heading = 0, playerCanDrive = false }
      end
    end
  end
  if ns.sam.status == "up" then add(spec.radars, "r") end
  add(spec.launchers, "l")
  add(spec.support, "s")
  if #units == 0 then return end
  local gname = "DCC_SAM_" .. id
  local data = { name = gname, task = "Ground Nothing", units = units,
                 route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point",
                   action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  local s = pcall(coalition.addGroup, B.countryId(ns.side), Group.Category.GROUND, data)
  if s then B.sams[id] = { group = gname, status = ns.sam.status, side = ns.side } end
end

function B.despawnSam(id)
  local rec = B.sams[id]
  if rec then
    local g = ok(Group.getByName, rec.group)
    if g and ok(g.isExist, g) then g:destroy() end
    B.sams[id] = nil
  end
end

function B.pollSam(id, rec)
  local g = ok(Group.getByName, rec.group)
  local radars, launchers = 0, 0
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do
      if alive(u) and u:getLife() >= 1 then
        local n = u:getName()
        if n:find("_r%d+$") then radars = radars + 1 elseif n:find("_l%d+$") then launchers = launchers + 1 end
      end
    end
  end
  if radars == 0 and launchers == 0 then B.war:samHit(id, "destroyed")
  elseif radars == 0 and rec.status == "up" then B.war:samHit(id, "radar") end
end

function B.reconcileSams()
  local war = B.war
  for id, rec in pairs(B.sams) do
    local ns = war.state.nodes[id]
    if ns.sam then B.pollSam(id, rec) end
    local want = ns.sam and ns.sam.status ~= "destroyed" and ns.side == rec.side
                 and playerNear(B.nodePos[id], DCC.config.ops.samLiveRadiusKm + 10)
    if not want or (ns.sam and ns.sam.status ~= rec.status) then B.despawnSam(id) end
  end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if not B.sams[id] and ns.sam and ns.sam.status ~= "destroyed"
       and playerNear(B.nodePos[id], DCC.config.ops.samLiveRadiusKm) then
      B.spawnSam(id)
    end
  end
end

-- ===========================================================================
-- 5. Structures (strike targets)
-- ===========================================================================
function B.reconcileStatics()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local inf = ns.infra
    local rec = B.statics[id]
    -- poll what exists
    if rec then
      for k, name in pairs(rec.names) do
        local o = ok(StaticObject.getByName, name)
        local dead = (not o) or (not ok(o.isExist, o)) or (ok(o.getLife, o) or 0) < 1
        if dead and rec.side == ns.side then war:infraHit(id, k) end
        if dead then rec.names[k] = nil end
      end
    end
    local want = inf and B.liveNodes[id]
    if rec and (not want or rec.side ~= ns.side) then
      for _, name in pairs(rec.names) do
        local o = ok(StaticObject.getByName, name)
        if o and ok(o.isExist, o) then o:destroy() end
      end
      B.statics[id], rec = nil, nil
    end
    if want then
      rec = rec or { side = ns.side, names = {} }
      B.statics[id] = rec
      for k = 1, inf.total do
        if not inf.lost[tostring(k)] and not rec.names[k] then
          local spec = (cat().infra or {})[k] or { type = "Warehouse", category = "Warehouses" }
          local sp = spotNear(id, k, 1900 + (k % 2) * 250)
          local name = string.format("DCC_INF_%s_%d_%d", id, k, B.war.state.tick)
          local s = pcall(coalition.addStaticObject, B.countryId(ns.side),
            { name = name, type = spec.type, category = spec.category, x = sp.x, y = sp.z, heading = 0, dead = false })
          if s then rec.names[k] = name end
        end
      end
    end
  end
end

-- ===========================================================================
-- 6. AI air sorties
-- ===========================================================================
function B.findTemplate(name)
  local mis = env.mission
  if not mis or not mis.coalition then return nil end
  for _, coal in pairs(mis.coalition) do
    for _, ctry in ipairs(coal.country or {}) do
      for _, catName in ipairs({ "plane", "helicopter" }) do
        local list = ctry[catName] and ctry[catName].group
        for _, g in ipairs(list or {}) do
          if g.name == name then return g end
        end
      end
    end
  end
end

local function waypoint(x, z, alt, speed, task)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
           speed = speed, speed_locked = true, ETA = 0, ETA_locked = false, task = task }
end

local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end

-- kind = "CAP" | "CAS" | "INTERCEPT"; target = map point; extra.groupId for intercepts
function B.spawnSortie(side, role, kind, target, extra)
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_" .. role)
  if not tpl then
    if not B.warnedTpl then U.log("AI air: template DCC_TPL_%s_%s not found - regenerate the mission", side, role) end
    B.warnedTpl = true
    return nil
  end
  if not B.war:airAvailable(side, role, #tpl.units) then return nil end
  local base = nearestNodeOf(target, side)
  local from = base and B.nodePos[base] or target
  local hdg = math.atan2(target.z - from.z, target.x - from.x)
  local sp = { x = from.x + math.cos(hdg) * 8000, z = from.z + math.sin(hdg) * 8000 }
  local alt = (kind == "CAS") and 3500 or 7000
  B.sortieCount = B.sortieCount + 1
  local gname = string.format("DCC_AIR_%s_%s_%d", side, kind, B.sortieCount)
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId = gname, nil, nil
  data.task = (kind == "CAS") and "CAS" or "CAP"
  for i, u in ipairs(data.units) do
    u.unitId = nil
    u.name = gname .. "_" .. i
    u.x, u.y, u.alt, u.alt_type = sp.x + (i - 1) * 200, sp.z + (i - 1) * 200, alt, "BARO"
    u.speed, u.heading, u.skill = 220, hdg, "High"
  end
  local task
  if extra and extra.task then
    task = combo(extra.task)
  elseif kind == "CAP" then
    task = combo({ { id = "EngageTargets", key = "CAP", params = { targetTypes = { "Air" }, priority = 0, maxDist = 70000 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 220 } } })
  elseif kind == "CAS" then
    task = combo({ { id = "EngageTargetsInZone", params = { point = { x = target.x, y = target.z }, zoneRadius = 5000,
                     targetTypes = { "Ground Units" }, priority = 0 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 180 } } })
  else
    task = combo({ { id = "AttackGroup", params = { groupId = extra.groupId } },
                   { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 60000 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 220 } } })
  end
  data.route = { points = { waypoint(sp.x, sp.z, alt, 220, combo({})), waypoint(target.x, target.z, alt, 220, task) } }
  local s, err = pcall(coalition.addGroup, B.countryId(side), Group.Category.AIRPLANE, data)
  if not s then U.log("AI sortie spawn failed: %s", tostring(err)); return nil end
  B.war:airTake(side, role, #data.units)
  local life = (kind == "CAP") and 3600 or (kind == "CAS" and 2400 or 2700)
  if extra and extra.life then life = extra.life end
  B.sorties[gname] = { side = side, role = role, kind = kind, born = timer.getTime(), life = life,
                       size = #data.units, alive = #data.units, node = extra and extra.node }
  trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s %s sortie airborne%s", side:upper(),
    kind, extra and extra.node and (" toward " .. B.war:nodeName(extra.node)) or ""), 10)
  return gname
end

function B.pollSorties()
  for gname, s in pairs(B.sorties) do
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then n = n + 1 end end
    end
    if n < s.alive then B.war:airLoss(s.side, s.role, s.alive - n); s.alive = n end
    if n == 0 or timer.getTime() - s.born > s.life then
      if n > 0 then B.war:airReturn(s.side, s.role, n) end
      if g and ok(g.isExist, g) then g:destroy() end
      B.sorties[gname] = nil
    end
  end
end

local function activeSorties(side, kind)
  local list = {}
  for gname, s in pairs(B.sorties) do if s.side == side and s.kind == kind then list[#list + 1] = s end end
  return list
end

-- Decide AI sorties once per tick (only while someone is flying).
function B.planAir()
  local war = B.war
  if #B.playerPositions() == 0 then return end
  for _, side in ipairs({ "blue", "red" }) do
    local enemy = U.otherSide(side)
    -- CAP over the main-effort staging area
    if #activeSorties(side, "CAP") == 0 then
      local f = war.state.focus and war.state.focus[side]
      if f then
        for _, nb in ipairs(U.sortedKeys(war.T.nodes[f.target].nb)) do
          if war.state.nodes[nb].side == side then
            B.spawnSortie(side, "fighter", "CAP", B.nodePos[nb], { node = nb })
            break
          end
        end
      end
    end
    -- CAS on live battles, unless the enemy holds the air or a SAM covers it
    local cas = #activeSorties(side, "CAS")
    for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
      if cas >= 2 then break end
      local mv = war.state.moves[mid]
      if mv.status == "fighting" and B.liveNodes[mv.to] then
        local ns = war.state.nodes[mv.to]
        local involved = (mv.side == side) or (ns.side == side)
        local covered = war:hasAirCover(enemy, mv.to)
        local samUp = ns.side == enemy and ns.sam and ns.sam.status == "up"
        local already = false
        for _, s in pairs(B.sorties) do if s.side == side and s.kind == "CAS" and s.node == mv.to then already = true end end
        if involved and not covered and not samUp and not already then
          if B.spawnSortie(side, "attack", "CAS", B.nodePos[mv.to], { node = mv.to }) then cas = cas + 1 end
        end
      end
    end
    -- Intercept an enemy airlift now and then
    if #activeSorties(side, "INTERCEPT") == 0 and war.rng:next() < 0.25 then
      for mid, rec in pairs(B.cargo) do
        local mv = war.state.moves[mid]
        if rec.kind == "airlift" and mv and mv.side == enemy then
          local g = ok(Group.getByName, rec.group)
          local u = g and ok(g.getUnit, g, 1)
          if alive(u) then
            B.spawnSortie(side, "fighter", "INTERCEPT", u:getPoint(), { groupId = g:getID() })
            break
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7. CSAR
-- ===========================================================================
function B.spawnDowned(did)
  local d = B.war.state.downed[did]
  local t = (cat().downedPilot or {})[d.side] or "Soldier M4"
  local gname = "DCC_CSAR_" .. did
  local data = { name = gname, task = "Ground Nothing",
                 units = { { name = gname .. "_1", type = t, skill = "Average", x = d.pos.x, y = d.pos.z, heading = 0 } },
                 route = { points = { { x = d.pos.x, y = d.pos.z, type = "Turning Point", action = "Off Road",
                   speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(d.side), Group.Category.GROUND, data) then
    B.downedGroups[did] = gname
    local g = ok(Group.getByName, gname)
    local c = g and ok(g.getController, g)
    if c then ok(c.setOption, c, AI and AI.Option.Ground.id.ROE or 0, AI and AI.Option.Ground.val.ROE.WEAPON_HOLD or 4) end
  end
end

function B.reconcileDowned()
  for did, gname in pairs(B.downedGroups) do
    if not B.war.state.downed[did] then
      local g = ok(Group.getByName, gname)
      if g and ok(g.isExist, g) then g:destroy() end
      B.downedGroups[did] = nil
    end
  end
  for did in pairs(B.war.state.downed) do
    if not B.downedGroups[did] then B.spawnDowned(did) end
  end
end

function B.onEjection(u)
  local name = ok(u.getPlayerName, u)
  if not name then return end
  local p = B.players[u:getName()]
  local key = p and p.key or playerKey(name)
  DCC.pilots:add(key, "ejections", 1, name)
  local pos = u:getPoint()
  local t = land.getSurfaceType({ x = pos.x, y = pos.z })
  if t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER then return end
  local did = B.war:addDowned(sideOfUnit(u), { x = pos.x + 150, z = pos.z + 150 }, name, u:getTypeName(),
    p and p.home, key)
  B.spawnDowned(did)
  trigger.action.outTextForCoalition(B.COAL[sideOfUnit(u)], string.format(
    "MAYDAY - %s is down. CSAR on the mission board. 2 hours before capture.", name), 20)
  B.refreshMenus()
end

function B.csarCheck(p, u, pos)
  local lift = (cat().lift or {})[p.type]
  if not lift then return end
  local war = B.war
  -- pickups
  for did, d in pairs(war.state.downed) do
    if d.side == p.side then
      local dd = dist2D(pos, { x = d.pos.x, z = d.pos.z })
      if dd < 2500 and not d.smoked then
        d.smoked = true
        ok(trigger.action.smoke, wpos({ x = d.pos.x, z = d.pos.z }), trigger.smokeColor and trigger.smokeColor.Green or 0)
      end
      if dd <= 150 and landed(u) and not p.onboard[did] then
        p.onboard[did] = true
        local gname = B.downedGroups[did]
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then g:destroy() end
        B.downedGroups[did] = "onboard"
        trigger.action.outTextForGroup(p.gid, "Pilot " .. tostring(d.pilot) .. " on board. Land at a friendly base.", 15)
      end
    end
  end
  -- drop-offs at a friendly base
  if next(p.onboard) and landed(u) then
    local node = nearestNodeOf(pos, p.side, 3000)
    if node then
      for did in pairs(p.onboard) do
        local d = war.state.downed[did]
        if d and war:rescue(did, node) then
          DCC.pilots:add(p.key, "rescues", 1, p.name)
          if d.key then DCC.pilots:add(d.key, "saved", 1) end
          trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s rescued %s - aircraft returned to %s.",
            p.name, tostring(d.pilot), war:nodeName(node)), 15)
        end
        p.onboard[did] = nil
      end
    end
  end
end

-- ===========================================================================
-- 8. Logistics (helicopter cargo)
-- ===========================================================================
local function liftOf(p) return (cat().lift or {})[p.type] or { crates = 0, troops = 0 } end

local function landedAt(p, sideFilter)
  local u = unitByName(p.unit)
  if not landed(u) then
    trigger.action.outTextForGroup(p.gid, "Land first.", 8)
    return nil
  end
  local node = nearestNodeOf(u:getPoint(), sideFilter, 3000)
  if not node then trigger.action.outTextForGroup(p.gid, "No base within 3 km.", 8) end
  return node
end

local function setCargoMass(p)
  ok(trigger.action.setUnitInternalCargo, p.unit, p.crates * 1000 + #p.troops * 1200)
end

function B.loadCrate(uname)
  local p = B.players[uname]
  if not p then return end
  if p.crates >= liftOf(p).crates then
    return trigger.action.outTextForGroup(p.gid, "Cargo bay full.", 8)
  end
  local node = landedAt(p, p.side)
  if not node then return end
  local su = B.war:takeCrate(node, DCC.config.ops.crateSU)
  if su <= 0 then return trigger.action.outTextForGroup(p.gid, B.war:nodeName(node) .. " has no supply to spare.", 8) end
  p.crates = p.crates + 1
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, string.format("Supply crate loaded at %s (%d on board).", B.war:nodeName(node), p.crates), 10)
end

function B.loadTroops(uname)
  local p = B.players[uname]
  if not p then return end
  if #p.troops >= liftOf(p).troops then
    return trigger.action.outTextForGroup(p.gid, "No room for more troops.", 8)
  end
  local node = landedAt(p, p.side)
  if not node then return end
  local ns = B.war.state.nodes[node]
  if #ns.platoons <= 1 then return trigger.action.outTextForGroup(p.gid, "No troops to spare here.", 8) end
  local list = B.war:sortedGarrison(node, false)
  local pid = list[#list]
  for i = #list, 1, -1 do
    if B.war.state.platoons[list[i]].role == "MECH_PLT" then pid = list[i]; break end
  end
  local rec = B.spawned[pid]
  if rec then B.despawn(pid, rec) end
  B.war:carryPlatoon(pid, uname)
  p.troops[#p.troops + 1] = pid
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, "One platoon on board. Unload at a friendly base, or at an enemy base to attack it.", 12)
end

function B.unload(uname)
  local p = B.players[uname]
  if not p then return end
  local node = landedAt(p, nil)
  if not node then return end
  local war = B.war
  local friendly = war.state.nodes[node].side == p.side
  local msg = {}
  if p.crates > 0 then
    if friendly then
      war:deliverCrate(p.side, node, p.crates * DCC.config.ops.crateSU)
      msg[#msg + 1] = string.format("%d supply crate(s) delivered to %s.", p.crates, war:nodeName(node))
      p.crates = 0
    else
      msg[#msg + 1] = "Crates can only be unloaded at a friendly base."
    end
  end
  if #p.troops > 0 then
    local r = war:dropPlatoons(p.troops, node, p.side)
    msg[#msg + 1] = (r == "assault") and ("Troops are attacking " .. war:nodeName(node) .. "!")
                    or ("Troops landed at " .. war:nodeName(node) .. ".")
    p.troops = {}
  end
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, #msg > 0 and table.concat(msg, "\n") or "Nothing on board.", 12)
end

function B.cargoStatus(uname)
  local p = B.players[uname]
  if not p then return end
  local l = liftOf(p)
  local pilots = 0
  for _ in pairs(p.onboard) do pilots = pilots + 1 end
  trigger.action.outTextForGroup(p.gid, string.format("Crates %d/%d, troops %d/%d, rescued pilots %d",
    p.crates, l.crates, #p.troops, l.troops, pilots), 10)
end

-- ===========================================================================
-- 9. Convoy escort ambush
-- ===========================================================================
function B.spawnAmbush(m)
  if B.ambushes[m.id] then return end
  local mv = B.war.state.moves[m.target]
  if not mv then return end
  local enemy = U.otherSide(m.side)
  local types = (cat().ambush or {})[enemy]
  if not types then return end
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local t = math.max(mv.progress + 0.25, 0.6)
  local x, z = a.x + (b.x - a.x) * t + 250, a.z + (b.z - a.z) * t + 250
  local gname = "DCC_AMB_" .. m.id
  local units = {}
  for i, ty in ipairs(types) do
    if B.validType(ty) then
      units[#units + 1] = { name = gname .. "_" .. i, type = ty, skill = "Average", x = x + i * 15, y = z + i * 10, heading = 0 }
    end
  end
  if #units == 0 then return end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(enemy), Group.Category.GROUND, data) then B.ambushes[m.id] = gname end
end

function B.cleanAmbushes()
  for mid, gname in pairs(B.ambushes) do
    local m = B.war.state.missions[mid]
    if not m or m.status ~= "open" then
      local g = ok(Group.getByName, gname)
      if g and ok(g.isExist, g) then g:destroy() end
      B.ambushes[mid] = nil
    end
  end
end

-- ===========================================================================
-- Kill credit and events
-- ===========================================================================
function B.onKill(e)
  local shooter = e.initiator
  local name = shooter and ok(shooter.getPlayerName, shooter)
  if not name then return end
  local p = B.players[shooter:getName()]
  local key = p and p.key or playerKey(name)
  local tgt = e.target
  if not tgt then return end
  local tname = ok(tgt.getName, tgt) or ""
  local field = "kills_ground"
  local category = ok(Object.getCategory, tgt)
  if category == Object.Category.STATIC then
    if not tname:find("^DCC_INF") and not tname:find("^DCC_FORT") and not tname:find("^DCC_IND") then return end
    field = "kills_structure"
  else
    local desc = ok(tgt.getDesc, tgt)
    if desc and (desc.category == Unit.Category.AIRPLANE or desc.category == Unit.Category.HELICOPTER) then
      field = "kills_air"
    elseif tname:find("^DCC_[ca]%d") then field = "kills_convoy"
    elseif tname:find("^DCC_SAM") or tname:find("^DCC_EWR") then field = "kills_sam" end
  end
  DCC.pilots:add(key, field, 1, name)
  -- an air kill completes a CAP on station
  if field == "kills_air" and p and p.mission then
    local m = B.war.state.missions[p.mission]
    if m and m.type == "CAP" and m.status == "open" then
      local tp = B.nodePos[m.target]
      if tp and dist2D(shooter:getPoint(), tp) <= DCC.config.missions.capRadiusKm * 1000 then
        B.war:completeMission(m.id, true)
      end
    end
  end
end

function B.onOpsEvent(e)
  local ev = world.event
  local u = e.initiator
  if e.id == ev.S_EVENT_BIRTH then
    if u and ok(u.getPlayerName, u) and Object.getCategory(u) == Object.Category.UNIT then
      if alive(u) then B.registerPlayer(u) end
    end
  elseif e.id == ev.S_EVENT_TAKEOFF then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p and not p.takeoff then
      p.takeoff = timer.getTime()
      DCC.pilots:sortie(p.key, p.side, B.war.T.name, p.name)
      B.war:recordSortie(p.key, p.side, p.name, DCC.pilots:score(p.key))   -- who flew for whom (victory bonus, report)
    end
  elseif e.id == ev.S_EVENT_LAND then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p and p.takeoff then
      DCC.pilots:add(p.key, "flightMinutes", (timer.getTime() - p.takeoff) / 60)
      p.takeoff = nil
    end
  elseif e.id == ev.S_EVENT_KILL then
    B.onKill(e)
  elseif e.id == ev.S_EVENT_SHOT then
    if B.onShot then B.onShot(e) end
  elseif e.id == ev.S_EVENT_EJECTION then
    if u then B.onEjection(u) end
  elseif e.id == ev.S_EVENT_PILOT_DEAD then
    local name = u and ok(u.getPlayerName, u)
    if name then
      local p = B.players[u:getName()]
      DCC.pilots:add(p and p.key or playerKey(name), "deaths", 1, name)
    end
  elseif e.id == ev.S_EVENT_CRASH or e.id == ev.S_EVENT_DEAD then
    local un = u and ok(u.getName, u)
    if un and B.players[un] then B.clearPlayer(un, "lost") end
  elseif e.id == ev.S_EVENT_PLAYER_LEAVE_UNIT then
    local un = u and ok(u.getName, u)
    if un and B.players[un] then B.clearPlayer(un, "left") end
  end
end

-- Credits for missions finished in the model.
function B.onMissionDone(m, outcome)
  local n = 0
  for _ in pairs(m.taken) do n = n + 1 end
  for key, name in pairs(m.taken) do
    if outcome == "done" then
      DCC.pilots:mission(key, m.type, name)
      if n >= 2 then DCC.pilots:add(key, "team", 1, name) end      -- flew it together
    end
    for _, p in pairs(B.players) do
      if p.key == key and p.mission == m.id then
        trigger.action.outTextForGroup(p.gid, string.format("Mission %s: %s %s.%s",
          outcome == "done" and "COMPLETE" or outcome:upper(), m.type, m.label,
          (outcome == "done" and n >= 2) and string.format(" Team bonus - %d pilots.", n) or ""), 15)
        p.mission = nil
      end
    end
  end
end

-- ===========================================================================
-- 10. Map extras
-- ===========================================================================
function B.drawOps(newMark, toVec3)
  local war, cfg = B.war, DCC.config
  for _, id in ipairs(war.T.order) do
    local ns, pos = war.state.nodes[id], B.nodePos[id]
    if ns.sam and ns.sam.status ~= "destroyed" then
      local col = cfg.colours[ns.side]
      trigger.action.circleToAll(B.COAL[ns.side], newMark(), pos, 25000, { col[1], col[2], col[3], 0.5 },
        { 0, 0, 0, 0 }, 2, true, "")
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = pos.x - 26000, y = pos.y, z = pos.z }, col,
        { 0, 0, 0, 0 }, 10, true, "SAM " .. ns.sam.status)
    end
  end
  for _, side in ipairs(war.fogOfWar and {} or { "blue", "red" }) do   -- with fog: dcc_dcs_intel.lua
    for id, i in pairs(war.state.intel[side]) do
      local ns = war.state.nodes[id]
      if ns and ns.side ~= side then
        local age = (war.state.tick - i.tick) * cfg.tickSeconds / 3600
        local pos = B.nodePos[id]
        trigger.action.textToAll(B.COAL[side], newMark(), { x = pos.x + 4000, y = pos.y, z = pos.z + 3000 },
          { 1, 1, 1, 1 }, { 0, 0, 0, 0.5 }, 10, true,
          string.format("Recon %.0fh ago: %d plt, SAM %s", age, i.platoons, i.sam))
      end
    end
  end
  for _, d in pairs(war.state.downed) do
    trigger.action.textToAll(B.COAL[d.side], newMark(), wpos({ x = d.pos.x, z = d.pos.z }), { 0.2, 1, 0.2, 1 },
      { 0, 0, 0, 0.5 }, 11, true, "Downed: " .. tostring(d.pilot))
  end
end

function B.opsStatusLines(side)
  local war = B.war
  local pool = war.state.airPool[side]
  local open = #war:openMissions(side)
  return { string.format("Air force: %d fighters, %d attack aircraft. Open missions: %d", pool.fighter, pool.attack, open) }
end

-- ===========================================================================
-- Per-tick and per-poll entry points (called from dcc_main.lua)
-- ===========================================================================
function B.updateForced()
  B.forced = {}
  for _, m in pairs(B.war.state.missions or {}) do
    if m.status == "open" and next(m.taken) and B.war.state.moves[m.target] then B.forced[m.target] = true end
  end
end

function B.opsPoll()
  B.pollSorties()
  B.reconcileSams()
  B.reconcileStatics()
  B.reconcileDowned()
end

function B.opsTick()
  B.updateForced()
  B.cleanAmbushes()
  B.planAir()
  B.refreshMenus()
end

end

-- >>> src/dcc_dcs_intel.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, part 4: intel and fog of war
-- ----------------------------------------------------------------------------
-- Turns what each side's units can actually perceive into contacts in the war
-- model (dcc_intel.lua), and draws each side's own picture on the F10 map.
-- Load after dcc_dcs_ops.lua.
--
--   Sources (checked every intel.scanSeconds):
--     visual  - player aircraft see enemy ground units within visualKmGround
--               and aircraft within visualKmAir, if terrain does not block
--               the line of sight (land.isVisible)
--     sensor  - friendly AI (sorties, SAM sites, ground platoons) report what
--               their controllers detect (Controller.getDetectedTargets)
--     elint   - airborne friendly aircraft hear enemy SAM radars that are
--               switched on. The first fix is rough (elintBaseErrM) and every
--               new observation narrows it (x elintShrink, down to elintMinErrM)
--     recon / troops in contact - in the model (dcc_intel.lua)
--
--   SAM radars (EMCON): a site's radar is off until enemy aircraft come within
--   samWakeKm. When an anti-radiation missile is fired at it, it goes dark for
--   harmDarkSeconds - it survives, but it cannot shoot or be heard meanwhile.
--
--   Map layer (redrawn every intel.drawEverySeconds, per coalition):
--     enemy SAM threat ring + ELINT error circle (only when known)
--     enemy columns where they were seen, faded when stale
--     enemy garrisons seen at bases, recon reports, front-line estimates
--     enemy aircraft seen in the last airContactSeconds
--
-- With F10 view "Allies only" in the mission options, this layer is the only
-- way a player sees the enemy on the map.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.intelMarks   = {}   -- mark ids of the intel layer
B.airContacts  = { blue = {}, red = {} }  -- unit name -> { pos, type, t } (not saved: aircraft move)
B.samDark      = {}   -- node id -> mission time until which the radar stays off
B.samAlarm     = {}   -- node id -> "red" / "green" last ordered
B.samAwake     = {}   -- node id -> true while enemy aircraft are within samWakeKm

local SIDES = { "blue", "red" }

local function IC() return DCC.config.intel end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function v3(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function sideOfCoal(c) return c == B.COAL.blue and "blue" or (c == B.COAL.red and "red" or nil) end

local function aglOf(u)
  local p = u:getPoint()
  return p.y - (ok(land.getHeight, { x = p.x, y = p.z }) or 0)
end

-- ---------------------------------------------------------------------------
-- 1. What exists: every spawned object the campaign knows, by DCS group name
-- ---------------------------------------------------------------------------
-- entry = { side, key, kind, node, mid, air, group }
function B.intelIndex()
  local war, idx = B.war, {}
  for pid, rec in pairs(B.spawned) do
    local pl = war.state.platoons[pid]
    if pl and not rec.failed then
      idx[rec.group] = { side = pl.side, key = rec.key, kind = rec.kind, node = rec.key:match("^g:(.+)"),
                         mid = rec.mid, role = pl.role, group = rec.group }
    end
  end
  for mid, rec in pairs(B.cargo or {}) do
    local mv = war.state.moves[mid]
    if mv then idx[rec.group] = { side = mv.side, key = "m:" .. mid, kind = "move", mid = mid,
                                  air = mv.kind == "airlift", group = rec.group } end
  end
  for id, rec in pairs(B.sams) do
    idx[rec.group] = { side = rec.side, key = "sam:" .. id, kind = "sam", node = id, group = rec.group }
  end
  for gname, s in pairs(B.sorties) do
    idx[gname] = { side = s.side, kind = "air", air = true, group = gname, ai = true }
  end
  return idx
end

-- Alive units of a group (lead first).
local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

-- Player aircraft of a side (any player unit, registered for missions or not).
local function playerUnits(side)
  local out = {}
  for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
    if alive(u) then out[#out + 1] = u end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- 2. Reporting a sighting
-- ---------------------------------------------------------------------------
-- side saw unit u, which belongs to index entry e (or is an enemy player).
function B.report(side, e, u, source)
  local war, pos = B.war, u:getPoint()
  if e and e.side == side then return end
  if not e or e.air then
    local name = u:getName()
    B.airContacts[side][name] = { pos = { x = pos.x, z = pos.z }, alt = pos.y,
      type = ok(u.getTypeName, u) or "aircraft", t = timer.getTime(), source = source }
    if not e or not e.mid then return end
  end
  if e.kind == "move" then
    war:spotMove(side, e.mid, source, { x = pos.x, z = pos.z })
  elseif e.kind == "garrison" then
    local key = "g:" .. e.node
    local c = war:contact(side, key)
    local groups = (c and war:isFresh(side, key) and c.groups) or {}
    groups[e.group] = #unitsOf(e.group)
    local n = 0
    for _, k in pairs(groups) do n = n + k end
    war:addContact(side, key, { kind = "garrison", node = e.node, source = source, groups = groups,
                                label = string.format("%d vehicles seen", n) })
  elseif e.kind == "sam" then
    war:addContact(side, "sam:" .. e.node, { kind = "sam", node = e.node, source = source,
      pos = { x = pos.x, z = pos.z }, err = 200, label = "SAM site" })
  end
end

-- ---------------------------------------------------------------------------
-- 3. Players' eyes
-- ---------------------------------------------------------------------------
function B.scanVisual(idx)
  local cfg = IC()
  -- enemy objects with a position, per side
  for _, side in ipairs(SIDES) do
    local eyes = playerUnits(side)
    if #eyes > 0 then
      local targets = {}
      for _, e in pairs(idx) do
        if e.side ~= side then
          for _, u in ipairs(unitsOf(e.group)) do targets[#targets + 1] = { e = e, u = u } end
        end
      end
      for _, u in ipairs(playerUnits(otherSide(side))) do targets[#targets + 1] = { u = u } end
      for _, eye in ipairs(eyes) do
        local ep = eye:getPoint()
        local from = { x = ep.x, y = ep.y + 2, z = ep.z }
        local seen = {}
        for _, t in ipairs(targets) do
          local gkey = t.e and t.e.group or t.u:getName()
          if not seen[gkey] then
            local tp = t.u:getPoint()
            local isAir = (not t.e) or t.e.air
            local range = (isAir and cfg.visualKmAir or cfg.visualKmGround) * (B.visualFactor and B.visualFactor(isAir) or 1)
            if dist2D(ep, tp) <= range * 1000 and ok(land.isVisible, from, { x = tp.x, y = tp.y + 2, z = tp.z }) then
              seen[gkey] = true
              B.report(side, t.e, t.u, "visual")
            end
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 4. AI sensors
-- ---------------------------------------------------------------------------
function B.scanSensors(idx)
  local byUnit = {}
  for _, e in pairs(idx) do
    for _, u in ipairs(unitsOf(e.group)) do byUnit[u:getName()] = e end
  end
  for _, e in pairs(idx) do
    local g = ok(Group.getByName, e.group)
    local ctl = g and ok(g.getController, g)
    local list = ctl and ok(ctl.getDetectedTargets, ctl)
    for _, d in ipairs(list or {}) do
      local o = d.object
      if o and alive(o) and ok(Object.getCategory, o) == Object.Category.UNIT then
        local te = byUnit[o:getName()]
        if te then
          if te.side ~= e.side then B.report(e.side, te, o, "sensor") end
        elseif ok(o.getPlayerName, o) and sideOfCoal(o:getCoalition()) == otherSide(e.side) then
          B.report(e.side, nil, o, "sensor")
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 5. SAM radars: wake, dark, ELINT
-- ---------------------------------------------------------------------------
-- Airborne aircraft of a side: players and AI sorties.
local function airborne(side)
  local out = {}
  for _, u in ipairs(playerUnits(side)) do if ok(u.inAir, u) then out[#out + 1] = u end end
  for gname, s in pairs(B.sorties) do
    if s.side == side then for _, u in ipairs(unitsOf(gname)) do out[#out + 1] = u end end
  end
  return out
end

function B.samEmitting(id)
  local ns = B.war.state.nodes[id]
  return ns.sam and ns.sam.status == "up" and B.samAwake[id] == true
         and (B.samDark[id] or 0) <= timer.getTime()
end

local function setAlarm(id, want)
  if B.samAlarm[id] == want then return end
  local rec = B.sams[id]
  local g = rec and ok(Group.getByName, rec.group)
  local ctl = g and ok(g.getController, g)
  if not ctl then return end
  local AO = AI and AI.Option and AI.Option.Ground
  if AO then
    local val = (want == "red") and AO.val.ALARM_STATE.RED or AO.val.ALARM_STATE.GREEN
    pcall(ctl.setOption, ctl, AO.id.ALARM_STATE, val)
  end
  B.samAlarm[id] = want
end

function B.scanSams()
  local war, cfg = B.war, IC()
  local air = { blue = airborne("blue"), red = airborne("red") }
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.sam and ns.sam.status ~= "destroyed" then
      local pos, enemy = B.nodePos[id], otherSide(ns.side)
      local awake = false
      -- IADS: with an own early-warning radar or AWACS tracking the aircraft the site
      -- lights up at samWakeKm; on its own it only wakes when they are close (samCueKm)
      local cueKm = (DCC.config.air and DCC.config.air.samCueKm) or cfg.samWakeKm
      for _, u in ipairs(air[enemy]) do
        local d = dist2D(u:getPoint(), pos)
        if d <= cueKm * 1000 or (d <= cfg.samWakeKm * 1000 and (not B.cued or B.cued(ns.side, u))) then
          awake = true; break
        end
      end
      B.samAwake[id] = awake
      if B.sams[id] then setAlarm(id, B.samEmitting(id) and "red" or "green") else B.samAlarm[id] = nil end

      -- ELINT: the enemy's airborne aircraft hear an emitting radar
      if B.samEmitting(id) then
        for _, u in ipairs(air[enemy]) do
          local up = u:getPoint()
          if dist2D(up, pos) <= cfg.elintKm * 1000 and aglOf(u) >= cfg.elintMinAglM then
            B.elintFix(enemy, id)
            break
          end
        end
      end
    end
  end
end

-- One ELINT observation: a better fix than the last one.
function B.elintFix(side, id)
  local war, cfg = B.war, IC()
  local key = "sam:" .. id
  local c = war:contact(side, key)
  local err = cfg.elintBaseErrM
  if c and c.err and war:isFresh(side, key) then err = math.max(cfg.elintMinErrM, c.err * cfg.elintShrink) end
  local pos = B.nodePos[id]
  local a, r = math.random() * 2 * math.pi, math.random() * err
  war:addContact(side, key, { kind = "sam", node = id, source = "elint", err = err,
    pos = { x = pos.x + r * math.cos(a), z = pos.z + r * math.sin(a) }, label = "SAM radar" })
end

-- Anti-radiation missile fired: the targeted site switches off for a while.
function B.onShot(e)
  local w = e.weapon
  local desc = w and ok(w.getDesc, w)
  local passive = (Weapon and Weapon.GuidanceType and Weapon.GuidanceType.RADAR_PASSIVE) or 5
  if not desc or desc.guidance ~= passive then return end
  local shooter = e.initiator
  local sside = shooter and sideOfCoal(ok(shooter.getCoalition, shooter))
  if not sside then return end
  local id
  local tgt = ok(w.getTarget, w)
  local tname = tgt and ok(tgt.getName, tgt)
  if tname then id = tname:match("^DCC_SAM_(.-)_[rls]%d+$") end
  if not id then   -- no lock reported: the nearest emitting enemy site
    local sp, best = shooter:getPoint(), nil
    for _, nid in ipairs(B.war.T.order) do
      local ns = B.war.state.nodes[nid]
      if ns.side ~= sside and B.samEmitting(nid) then
        local d = dist2D(sp, B.nodePos[nid])
        if d <= 150000 and (not best or d < best) then id, best = nid, d end
      end
    end
  end
  if not id then return end
  local lo, hi = IC().harmDarkSeconds[1], IC().harmDarkSeconds[2]
  B.samDark[id] = timer.getTime() + lo + math.random() * (hi - lo)
  if B.sams[id] then setAlarm(id, "green") end
  U.log("SAM at %s goes dark (anti-radiation missile)", id)
end

-- ---------------------------------------------------------------------------
-- 6. The scan loop
-- ---------------------------------------------------------------------------
function B.intelScan()
  if not B.war.fogOfWar then return end
  local idx = B.intelIndex()
  B.scanVisual(idx)
  B.scanSensors(idx)
  B.scanSams()
  local now, keep = timer.getTime(), IC().airContactSeconds
  for _, side in ipairs(SIDES) do
    for name, c in pairs(B.airContacts[side]) do
      if now - c.t > keep then B.airContacts[side][name] = nil end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 7. The map layer
-- ---------------------------------------------------------------------------
local function mark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.intelMarks[#B.intelMarks + 1] = B.nextMark
  return B.nextMark
end

local SOURCE = { visual = "seen", sensor = "detected", elint = "ELINT", recon = "recon" }

local function ageText(war, c)
  local min = (war.state.tick - c.seen) * DCC.config.tickSeconds / 60
  if min < 1 then return "now" end
  if min < 90 then return string.format("%d min ago", math.floor(min + 0.5)) end
  return string.format("%.1f h ago", min / 60)
end

-- Where to draw a contact: where it was seen.
function B.contactPos(c)
  if c.pos then return c.pos end
  if c.kind == "move" and c.from and c.to then
    local a, b = B.nodePos[c.from], B.nodePos[c.to]
    local t = c.progress or 0
    return { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t }
  end
  return c.node and B.nodePos[c.node]
end

function B.drawIntel()
  for _, id in ipairs(B.intelMarks) do trigger.action.removeMark(id) end
  B.intelMarks = {}
  local war = B.war
  if not war.fogOfWar then return end
  local cols = DCC.config.colours
  for _, side in ipairs(SIDES) do
    local coal, enemy = B.COAL[side], otherSide(side)
    local ec = cols[enemy]
    local contacts = war.state.contacts[side]

    for _, key in ipairs(U.sortedKeys(contacts)) do
      local c = contacts[key]
      local fresh = war:isFresh(side, key)
      local a = fresh and 1 or 0.45
      local col = { ec[1], ec[2], ec[3], a }
      local p = B.contactPos(c)
      if p then
        local P = v3(p)
        local txt = string.format("%s (%s %s)", c.label or c.kind, SOURCE[c.source] or c.source, ageText(war, c))
        if c.kind == "sam" then
          local ns = war.state.nodes[c.node]
          if ns.side == enemy then
            trigger.action.circleToAll(coal, mark(), P, 25000, col, { 0, 0, 0, 0 }, fresh and 2 or 3, true, "")
            if (c.err or 0) > 1000 then
              trigger.action.circleToAll(coal, mark(), P, c.err, col, { ec[1], ec[2], ec[3], 0.12 }, 3, true, "")
              txt = txt .. string.format(" +/-%.1f km", c.err / 1000)
            end
            trigger.action.textToAll(coal, mark(), { x = P.x - 26000, y = P.y, z = P.z }, col,
              { 0, 0, 0, 0.35 }, 10, true, txt)
          end
        elseif c.kind == "move" then
          trigger.action.circleToAll(coal, mark(), P, 800, col, { ec[1], ec[2], ec[3], 0.3 * a }, 1, true, "")
          trigger.action.textToAll(coal, mark(), { x = P.x + 1200, y = P.y, z = P.z + 800 }, col,
            { 0, 0, 0, 0.35 }, 10, true, txt)
        elseif c.kind == "garrison" or c.kind == "node" then
          if war.state.nodes[c.node].side == enemy then
            local off = (c.kind == "node") and 3000 or -3000
            trigger.action.textToAll(coal, mark(), { x = P.x + 4000 + off, y = P.y, z = P.z + 3000 }, col,
              { 0, 0, 0, 0.5 }, 10, true, (c.kind == "node" and "Recon: " or "") .. txt)
          end
        end
      end
    end

    -- front-line estimates: troops in contact know roughly what faces them
    for _, id in ipairs(war.T.order) do
      local est = war:frontEstimate(side, id)
      if est and not war:isFresh(side, "n:" .. id) then
        local P = B.nodePos[id]
        trigger.action.textToAll(coal, mark(), { x = P.x - 4000, y = P.y, z = P.z + 3000 }, ec,
          { 0, 0, 0, 0.35 }, 10, true, "est. " .. est)
      end
    end

    -- enemy aircraft seen in the last minutes
    local now = timer.getTime()
    for _, name in ipairs(U.sortedKeys(B.airContacts[side])) do
      local c = B.airContacts[side][name]
      local P = v3(c.pos)
      trigger.action.circleToAll(coal, mark(), P, 1500, ec, { 0, 0, 0, 0 }, 1, true, "")
      trigger.action.textToAll(coal, mark(), { x = P.x + 2000, y = P.y, z = P.z }, ec, { 0, 0, 0, 0.35 }, 10, true,
        string.format("%s %d ft (%ds ago)", c.type, math.floor(c.alt * 3.28084 / 1000 + 0.5) * 1000,
          math.floor(now - c.t)))
    end
  end
end

-- Lines for the status message: what this side knows.
function B.intelStatusLines(side)
  local war = B.war
  if not war.fogOfWar then return {} end
  local fresh, stale, sams = 0, 0, 0
  for key, c in pairs(war.state.contacts[side]) do
    if war:isFresh(side, key) then fresh = fresh + 1 else stale = stale + 1 end
    if c.kind == "sam" and war:isFresh(side, key) then sams = sams + 1 end
  end
  local air = 0
  for _ in pairs(B.airContacts[side]) do air = air + 1 end
  return { string.format("Intel: %d fresh contacts (%d SAM sites), %d stale, %d aircraft on the scope",
    fresh, sams, stale, air) }
end

end

-- >>> src/dcc_dcs_radar.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, part 5: radar stations, AWACS and
-- recon photos. Load after dcc_dcs_intel.lua.
-- ----------------------------------------------------------------------------
--   EWR sites   - spawned as real radar units when a player is within
--                 ops.samLiveRadiusKm (kill it -> War:ewrHit). Whether spawned
--                 or not, every EWR that is up in the model gives its side an
--                 air picture: enemy aircraft within radar.ewrKm, above the
--                 radar horizon, with terrain not in the way.
--   AWACS       - one per side orbits radar.awacsStandoffKm behind its own
--                 front while anyone is online (drawn from the AWACS pool).
--                 It sees enemy aircraft out to radar.awacsKm. Shot down ->
--                 War:awacsLost (HVAA mission done). Relieved after 4 h.
--   ELINT       - EWRs always transmit: enemy aircraft above elintMinAglM
--                 within radar.ewrElintKm hear them (EWR strike missions).
--   Recon photo - a completed recon shows every photographed platoon with its
--                 vehicle types on the side's map, and the pilot gets the
--                 photo report as a message.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.ewrs  = {}   -- node id -> { group, side }
B.awacs = {}   -- side -> { group, born }

local SIDES = { "blue", "red" }
local function RC() return DCC.config.radar end
local function IC() return DCC.config.intel end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function ground(p) return ok(land.getHeight, { x = p.x, y = p.z }) or 0 end
local function otherSide(s) return s == "blue" and "red" or "blue" end

local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

local function playersNear(pos, km)
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, pos) <= km * 1000 then return true end
  end
  return false
end

-- ===========================================================================
-- 1. EWR sites
-- ===========================================================================
function B.spawnEwr(id)
  local ns = B.war.state.nodes[id]
  local list = B.catalog.ewr and B.catalog.ewr[ns.side] or {}
  local t
  for _, cand in ipairs(list) do if B.validType(cand) then t = cand; break end end
  if not t then return end
  local c = B.nodePos[id]
  -- a little away from the airfield, on the side away from the SAM site
  local x, z = c.x - 2200, c.z - 1600
  local gname = "DCC_EWR_" .. id
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "High", x = x, y = z, heading = 0, playerCanDrive = false } },
    route = { points = { { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0,
                           ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(ns.side), Group.Category.GROUND, data) then
    B.ewrs[id] = { group = gname, side = ns.side }
  end
end

function B.despawnEwr(id)
  local rec = B.ewrs[id]
  if not rec then return end
  local g = ok(Group.getByName, rec.group)
  if g and ok(g.isExist, g) then g:destroy() end
  B.ewrs[id] = nil
end

function B.reconcileEwrs()
  local war, R = B.war, DCC.config.ops.samLiveRadiusKm
  for id, rec in pairs(B.ewrs) do
    if #unitsOf(rec.group) == 0 then war:ewrHit(id) end
    local ns = war.state.nodes[id]
    if not war:ewrUp(id) or ns.side ~= rec.side or not playersNear(B.nodePos[id], R + 10) then B.despawnEwr(id) end
  end
  for _, id in ipairs(war.T.order) do
    if not B.ewrs[id] and war:ewrUp(id) and playersNear(B.nodePos[id], R) then B.spawnEwr(id) end
  end
end

-- ===========================================================================
-- 2. AWACS
-- ===========================================================================
-- Orbit point: from the middle of the own front, back toward the own rear.
function B.awacsOrbit(side)
  local war = B.war
  local dist = war:frontDistance(side)
  local fx, fz, fn, rx, rz, rn = 0, 0, 0, 0, 0, 0
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side then
      local p = B.nodePos[id]
      rx, rz, rn = rx + p.x, rz + p.z, rn + 1
      if dist[id] == 1 then fx, fz, fn = fx + p.x, fz + p.z, fn + 1 end
    end
  end
  if rn == 0 then return nil end
  rx, rz = rx / rn, rz / rn
  if fn == 0 then return { x = rx, z = rz }, 0 end
  fx, fz = fx / fn, fz / fn
  local dx, dz = rx - fx, rz - fz
  local len = math.sqrt(dx * dx + dz * dz)
  if len < 1 then dx, dz, len = 1, 0, 1 end
  local s = RC().awacsStandoffKm * 1000
  local hdg = math.atan2(dz, dx)
  return { x = fx + dx / len * s, z = fz + dz / len * s }, hdg
end

function B.spawnAwacs(side)
  local war = B.war
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_awacs")
  if not tpl or (war.state.airPool[side].awacs or 0) < 1 then return nil end
  local p, hdg = B.awacsOrbit(side)
  if not p then return nil end
  local alt = RC().awacsAltM
  -- race-track at right angles to the front
  local ax, az = math.cos(hdg + math.pi / 2), math.sin(hdg + math.pi / 2)
  local p1 = { x = p.x - ax * 30000, z = p.z - az * 30000 }
  local p2 = { x = p.x + ax * 30000, z = p.z + az * 30000 }
  B.awacsCount = (B.awacsCount or 0) + 1
  local gname = string.format("DCC_AWACS_%s_%d", side, B.awacsCount)
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId, data.task = gname, nil, nil, "AWACS"
  data.units = { data.units[1] }
  local u = data.units[1]
  u.unitId, u.name = nil, gname .. "_1"
  u.x, u.y, u.alt, u.alt_type, u.speed, u.heading, u.skill = p1.x, p1.z, alt, "BARO", 200, hdg, "High"
  local tasks = { { id = "AWACS", params = {} },
                  { id = "Orbit", params = { pattern = "Race-Track", point = { x = p1.x, y = p1.z },
                    point2 = { x = p2.x, y = p2.z }, altitude = alt, speed = 200 } } }
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  data.route = { points = {
    { x = p1.x, y = p1.z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
      speed = 200, speed_locked = true, ETA = 0, ETA_locked = false,
      task = { id = "ComboTask", params = { tasks = tasks } } },
    { x = p2.x, y = p2.z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
      speed = 200, speed_locked = true, ETA = 0, ETA_locked = false,
      task = { id = "ComboTask", params = { tasks = {} } } } } }
  local s, err = pcall(coalition.addGroup, B.countryId(side), Group.Category.AIRPLANE, data)
  if not s then U.log("AWACS spawn failed: %s", tostring(err)); return nil end
  war:airTake(side, "awacs", 1)
  war:setAwacs(side, true)
  B.awacs[side] = { group = gname, born = timer.getTime() }
  trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s AWACS on station.", side:upper()), 10)
  return gname
end

local function returnAwacs(side)
  local p = B.war.state.airPool[side]
  p.awacs = math.min(RC().awacsPoolMax, (p.awacs or 0) + 1)
end

function B.pollAwacs()
  local war = B.war
  local online = #B.playerPositions() > 0
  for _, side in ipairs(SIDES) do
    local rec = B.awacs[side]
    if rec then
      local us = unitsOf(rec.group)
      if #us == 0 then
        war:awacsLost(side)
        B.awacs[side] = nil
      elseif not online or timer.getTime() - rec.born > RC().awacsLifeSeconds then
        local g = ok(Group.getByName, rec.group)
        if g then g:destroy() end
        returnAwacs(side)
        war:setAwacs(side, false)
        B.awacs[side] = nil
      end
    end
  end
end

function B.planAwacs()
  if #B.playerPositions() == 0 then return end
  for _, side in ipairs(SIDES) do
    if not B.awacs[side] then B.spawnAwacs(side) end
  end
end

-- ===========================================================================
-- 3. Air picture: EWRs and AWACS see enemy aircraft above the radar horizon
-- ===========================================================================
-- Every radar a side has right now: { pos (vec3 antenna), aglM, km }
function B.radarsOf(side)
  local war, out = B.war, {}
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side and war:ewrUp(id) then
      local p = B.nodePos[id]
      local h = RC().ewrAntennaM
      out[#out + 1] = { pos = { x = p.x, y = ground(p) + h, z = p.z }, agl = h, km = RC().ewrKm }
    end
  end
  local rec = B.awacs[side]
  local u = rec and unitsOf(rec.group)[1]
  if u then
    local p = u:getPoint()
    out[#out + 1] = { pos = p, agl = p.y - ground(p), km = RC().awacsKm, awacs = true }
  end
  return out
end

-- Can this radar see this unit?
function B.radarSees(r, u)
  local p = u:getPoint()
  local d = dist2D(r.pos, p)
  if d > r.km * 1000 then return false end
  local agl = p.y - ground(p)
  if agl < DCC.War.radarHorizonM(d / 1000, r.agl) then return false end
  return ok(land.isVisible, r.pos, p) == true
end

function B.scanRadars(idx)
  -- enemy aircraft per side: players in the air, AI sorties, AWACS, airlifts
  local airOf = { blue = {}, red = {} }
  for _, side in ipairs(SIDES) do
    for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
      if alive(u) and ok(u.inAir, u) then airOf[side][#airOf[side] + 1] = { u = u } end
    end
  end
  for _, e in pairs(idx) do
    if e.air then
      for _, u in ipairs(unitsOf(e.group)) do airOf[e.side][#airOf[e.side] + 1] = { u = u, e = e } end
    end
  end
  for _, side in ipairs(SIDES) do
    local radars = B.radarsOf(side)
    if #radars > 0 then
      for _, t in ipairs(airOf[otherSide(side)]) do
        for _, r in ipairs(radars) do
          if B.radarSees(r, t.u) then B.report(side, t.e, t.u, "radar"); break end
        end
      end
    end
  end
end

-- ELINT on early-warning radars (they always transmit).
function B.scanEwrElint()
  local war, cfg = B.war, IC()
  for _, side in ipairs(SIDES) do
    local ears = {}
    for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
      if alive(u) and ok(u.inAir, u) then ears[#ears + 1] = u end
    end
    for gname, s in pairs(B.sorties) do
      if s.side == side then for _, u in ipairs(unitsOf(gname)) do ears[#ears + 1] = u end end
    end
    for _, id in ipairs(war.T.order) do
      local ns = war.state.nodes[id]
      if ns.side ~= side and war:ewrUp(id) then
        local pos = B.nodePos[id]
        for _, u in ipairs(ears) do
          local p = u:getPoint()
          if dist2D(p, pos) <= RC().ewrElintKm * 1000 and p.y - ground(p) >= cfg.elintMinAglM then
            local key = "ewr:" .. id
            local c = war:contact(side, key)
            local err = cfg.elintBaseErrM
            if c and c.err and war:isFresh(side, key) then err = math.max(cfg.elintMinErrM, c.err * cfg.elintShrink) end
            local a, r = math.random() * 2 * math.pi, math.random() * err
            war:addContact(side, key, { kind = "ewr", node = id, source = "elint", err = err,
              pos = { x = pos.x + r * math.cos(a), z = pos.z + r * math.sin(a) }, label = "Early-warning radar" })
            break
          end
        end
      end
    end
  end
end

-- Index: AWACS aircraft are air contacts like sorties, and a sighting of one
-- also records the "awacs:<side>" contact the HVAA mission needs.
local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for side, rec in pairs(B.awacs) do
    idx[rec.group] = { side = side, kind = "air", air = true, group = rec.group, awacs = true }
  end
  for id, rec in pairs(B.ewrs) do
    idx[rec.group] = { side = rec.side, key = "ewr:" .. id, kind = "ewr", node = id, group = rec.group }
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  if e and e.side == side then return end
  baseReport(side, e, u, source)
  if e and e.awacs then
    local p = u:getPoint()
    B.war:addContact(side, "awacs:" .. e.side, { kind = "awacs", source = source,
      pos = { x = p.x, z = p.z }, label = e.side:upper() .. " AWACS" })
  elseif e and e.kind == "ewr" then
    local p = u:getPoint()
    B.war:addContact(side, "ewr:" .. e.node, { kind = "ewr", node = e.node, source = source,
      pos = { x = p.x, z = p.z }, err = 200, label = "Early-warning radar" })
  end
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if not B.war.fogOfWar then return end
  local idx = B.intelIndex()
  B.scanRadars(idx)
  B.scanEwrElint()
end

-- ===========================================================================
-- 4. Map: enemy radars, photos; own radar coverage
-- ===========================================================================
local function mark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.intelMarks[#B.intelMarks + 1] = B.nextMark
  return B.nextMark
end

local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs(SIDES) do
    local coal, enemy = B.COAL[side], otherSide(side)
    local ec = DCC.config.colours[enemy]
    for _, key in ipairs(U.sortedKeys(war.state.contacts[side])) do
      local c = war.state.contacts[side][key]
      local fresh = war:isFresh(side, key)
      local col = { ec[1], ec[2], ec[3], fresh and 1 or 0.45 }
      if c.kind == "ewr" and war.state.nodes[c.node].side == enemy then
        local P = c.pos or B.nodePos[c.node]
        local v = { x = P.x, y = ground(P), z = P.z }
        if (c.err or 0) > 1000 then
          trigger.action.circleToAll(coal, mark(), v, c.err, col, { ec[1], ec[2], ec[3], 0.12 }, 3, true, "")
        end
        trigger.action.textToAll(coal, mark(), { x = v.x + 1500, y = v.y, z = v.z - 4000 }, col,
          { 0, 0, 0, 0.35 }, 10, true, string.format("EWR (%s%s)", c.source,
            (c.err or 0) > 1000 and string.format(" +/-%.1f km", c.err / 1000) or ""))
      elseif c.kind == "awacs" and fresh then
        local v = { x = c.pos.x, y = 0, z = c.pos.z }
        trigger.action.circleToAll(coal, mark(), v, 3000, col, { 0, 0, 0, 0 }, 1, true, "")
        trigger.action.textToAll(coal, mark(), { x = v.x + 3500, y = 0, z = v.z }, col, { 0, 0, 0, 0.35 }, 11, true,
          enemy:upper() .. " AWACS")
      elseif c.kind == "node" and c.photo and war.state.nodes[c.node].side == enemy then
        for _, ph in ipairs(c.photo) do
          local s = B.scatter(c.node, ph.pid)
          trigger.action.textToAll(coal, mark(), { x = s.x, y = ground(s), z = s.z }, col, { 0, 0, 0, 0.25 }, 9, true,
            "[photo] " .. ph.text)
        end
      end
    end
  end
end

local baseDrawOps = B.drawOps
function B.drawOps(newMark, toVec3)
  baseDrawOps(newMark, toVec3)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.ewr then
      local col, P = DCC.config.colours[ns.side], B.nodePos[id]
      if ns.ewr.status == "up" then
        trigger.action.circleToAll(B.COAL[ns.side], newMark(), P, RC().ewrKm * 1000,
          { col[1], col[2], col[3], 0.25 }, { 0, 0, 0, 0 }, 4, true, "")
      end
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = P.x + 1500, y = P.y, z = P.z - 4000 }, col,
        { 0, 0, 0, 0 }, 10, true, "EWR " .. ns.ewr.status)
    end
  end
end

-- ===========================================================================
-- 5. Recon photo report to the pilot
-- ===========================================================================
function B.photoReport(side, id)
  local war = B.war
  local c = war:contact(side, "n:" .. id)
  if not c then return nil end
  local lines = { "RECON PHOTOS - " .. war:nodeName(id) }
  local ns = war.state.nodes[id]
  for i, ph in ipairs(c.photo or {}) do lines[#lines + 1] = string.format("%d. %s (%s)", i, ph.text, ph.role) end
  if #(c.photo or {}) == 0 then lines[#lines + 1] = "No vehicles in the photos." end
  lines[#lines + 1] = "Air defence: " .. (ns.sam and ns.sam.status or "none") ..
                      ".  Early-warning radar: " .. (c.ewr or "none") .. "."
  lines[#lines + 1] = "Photos are on your F10 map ([photo] labels)."
  return table.concat(lines, "\n")
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  if m.type == "RECON" and outcome == "done" then
    local text = B.photoReport(m.side, m.target)
    if text then
      for key in pairs(m.taken) do
        for _, p in pairs(B.players) do
          if p.key == key then trigger.action.outTextForGroup(p.gid, text, 45) end
        end
      end
    end
  end
  baseDone(m, outcome)
end

-- ===========================================================================
-- 6. Status and loop hooks
-- ===========================================================================
local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war, up = B.war, 0
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side and war:ewrUp(id) then up = up + 1 end
  end
  lines[#lines + 1] = string.format("Radar: %d early-warning sites up. AWACS: %s, %d in reserve.", up,
    B.awacs[side] and "on station" or "none airborne", war.state.airPool[side].awacs or 0)
  return lines
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileEwrs()
  B.pollAwacs()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planAwacs()
end

end

-- >>> src/dcc_dcs_world.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: weather, night, AI adaptation,
-- FARPs and ships. Load after dcc_dcs_radar.lua.
-- ----------------------------------------------------------------------------
--   Weather/night - tells the model when it is night (mission clock), and
--                   shows rain and storms as fog where DCS allows it
--                   (world.weather fog functions, DCS 2.9.10+). Clouds and rain
--                   themselves cannot be changed while a mission runs.
--   Adaptation    - convoys the model marked aiEscort get an air-defence
--                   vehicle driving with them; the AI sends a CAP pair over
--                   its most threatened road; storms and night ground AI
--                   attack sorties.
--   FARPs         - each town has two invisible FARPs in the mission (one per
--                   coalition) with an empty helicopter stock. A FARP the
--                   players built gets the owner's helicopters, a fuel truck,
--                   an ammo truck and a map mark; a lost one is emptied.
--   Ships         - naval groups from the theater pack (placed by the mission
--                   generator). Polled for losses, turned around at the end
--                   of their leg, found by enemy radars, attacked by enemy AI.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local SIDES = { "blue", "red" }
local function WC() return DCC.config.world end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function firstValid(list)
  for _, t in ipairs(list or {}) do if B.validType(t) then return t end end
  return nil
end
local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

B.escorts  = {}   -- convoy move id -> escort group name
B.farps    = {}   -- node id -> { side, crew = group name, mark }
B.naval    = {}   -- ship id -> { group, side, leg }
B.fogNow   = nil

-- ===========================================================================
-- 1. Night and weather
-- ===========================================================================
function B.hourOfDay()
  return math.floor((timer.getAbsTime() % 86400) / 3600)
end

function B.updateNight()
  local h, cfg = B.hourOfDay(), WC()
  B.war.night = (h >= cfg.nightStartHour or h < cfg.nightEndHour)
end

-- Fog for a weather severity: none up to fogFromSev, then thickening through
-- the rain value (at rain severity) to the storm value (at 1).
function B.fogAt(sev)
  local cfg, S = WC(), DCC.War.WEATHER_SEV
  local from = cfg.fogFromSev or 0.45
  if sev <= from then return 0, 0 end
  local rain, storm = cfg.fog.rain, cfg.fog.storm
  if sev <= S.rain then
    local f = (sev - from) / (S.rain - from)
    return 10000 + (rain[1] - 10000) * f, 100 + (rain[2] - 100) * f
  end
  local f = math.min(1, (sev - S.rain) / (S.storm - S.rain))
  return rain[1] + (storm[1] - rain[1]) * f, rain[2] + (storm[2] - rain[2]) * f
end

-- Every tick: the fog follows the weather severity. Where DCS can animate fog
-- (world.weather.setFogAnimation) it eases to the new value over the tick, so
-- it rolls in and lifts instead of jumping.
function B.applyWeather()
  local wx = world and world.weather
  if not wx or not wx.setFogVisibilityDistance then return end   -- older DCS: nothing to do
  local vis, thick = B.fogAt(B.war:weatherSeverity())
  vis, thick = math.floor(vis + 0.5), math.floor(thick + 0.5)
  local last = B.fogNow
  if last and last.vis == vis and last.thick == thick then return end
  B.fogNow = { vis = vis, thick = thick }
  if wx.setFogAnimation and last then
    -- one key after the tick: DCS eases from the fog as it is now (0 = no fog)
    local okA = pcall(wx.setFogAnimation, { { DCC.config.tickSeconds, vis, thick } })
    if okA then return end
  end
  pcall(wx.setFogThickness, thick)
  pcall(wx.setFogVisibilityDistance, vis)
end

-- ===========================================================================
-- 2. AI adaptation
-- ===========================================================================
local baseSpawnConvoy = B.spawnConvoy
function B.spawnConvoy(mv)
  baseSpawnConvoy(mv)
  if not mv.aiEscort or not B.cargo[mv.id] then return end
  local t = firstValid(B.catalog.escortAD and B.catalog.escortAD[mv.side])
  local rec = B.cargo[mv.id]
  local g = ok(Group.getByName, rec.group)
  if not t or not g then return end
  local route = g.data and g.data.route or nil
  local lead = g:getUnit(1)
  if not alive(lead) then return end
  local p = lead:getPoint()
  local b = B.nodePos[mv.to]
  local gname = rec.group .. "_esc"
  local s = DCC.config.liveSpeedMps * 0.8
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "Good", x = p.x - 60, y = p.z, heading = 0,
                playerCanDrive = false } },
    route = route or { points = {
      { x = p.x, y = p.z, type = "Turning Point", action = "On Road", speed = s, ETA = 0, ETA_locked = false },
      { x = b.x, y = b.z, type = "Turning Point", action = "Off Road", speed = s, ETA = 0, ETA_locked = false } } } }
  if pcall(coalition.addGroup, B.countryId(mv.side), Group.Category.GROUND, data) then B.escorts[mv.id] = gname end
end

local baseDespawnCargo = B.despawnCargo
function B.despawnCargo(mid, rec)
  baseDespawnCargo(mid, rec)
  local e = B.escorts[mid]
  if e then
    local g = ok(Group.getByName, e)
    if g and ok(g.isExist, g) then g:destroy() end
    B.escorts[mid] = nil
  end
end

local basePlanAir = B.planAir
function B.planAir()
  local war = B.war
  -- storms and night: no AI attack sorties (fighters still fly CAP)
  local spawn = B.spawnSortie
  if not war:aiAttackAllowed() then
    B.spawnSortie = function(side, role, kind, target, extra)
      if role == "attack" then return nil end
      return spawn(side, role, kind, target, extra)
    end
  end
  local okP, err = pcall(basePlanAir)
  B.spawnSortie = spawn
  if not okP then error(err) end
  if #B.playerPositions() == 0 then return end
  -- CAP over the worst threatened road
  for _, side in ipairs(SIDES) do
    local a, b = war:worstRoad(side)
    if a then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "ROADCAP" then busy = true end end
      if not busy then
        local pa, pb = B.nodePos[a], B.nodePos[b]
        local mid = { x = (pa.x + pb.x) / 2, y = 0, z = (pa.z + pb.z) / 2 }
        local gname = B.spawnSortie(side, "fighter", "CAP", mid, { node = a })
        if gname and B.sorties[gname] then
          B.sorties[gname].kind = "ROADCAP"
          trigger.action.outTextForCoalition(B.COAL[side], string.format(
            "Command: fighters to cover the road %s - %s (convoys lost there).", war:nodeName(a), war:nodeName(b)), 10)
        end
      end
    end
  end
  -- AI strike on a known enemy ship, now and then
  for _, ship in ipairs(war.theater.naval or {}) do
    local side = otherSide(ship.side)
    local rec = B.naval[ship.id]
    if rec and war:shipUp(ship.id) and war:isFresh(side, "ship:" .. ship.id) and war:aiAttackAllowed() then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "ANTISHIP" then busy = true end end
      if not busy and war.rng:next() < WC().antishipChance then
        local g = ok(Group.getByName, rec.group)
        local u = g and g:getUnit(1)
        if alive(u) then
          B.spawnSortie(side, "attack", "ANTISHIP", u:getPoint(), { groupId = g:getID(), template = "antiship" })
        end
      end
    end
  end
end

-- ===========================================================================
-- 3. FARPs
-- ===========================================================================
-- A FARP's helipads (v0.38: farpPads of them, so more than one helicopter can spawn).
function B.farpPadNames(id, side)
  local out = { "DCC_FARP_" .. id .. "_" .. side }
  for k = 2, WC().farpPads or 1 do out[#out + 1] = "DCC_FARP_" .. id .. "_" .. side .. "_" .. k end
  return out
end

local function farpWarehouse(id, side)
  local ab = ok(Airbase.getByName, "DCC_FARP_" .. id .. "_" .. side)
  return ab and ok(ab.getWarehouse, ab), ab
end

-- Stock the right FARPs; spawn or remove ground crews.
function B.reconcileFarps()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    if war:canHaveFarp(id) then
      local ns = war.state.nodes[id]
      for _, side in ipairs(SIDES) do
        local wh, ab = farpWarehouse(id, side)
        local want = war:farpAt(id) and ns.side == side
        local n = (want and not war:farpDry(id)) and WC().farpHelos or 0   -- a dry FARP spawns nothing
        for _, pad in ipairs(B.farpPadNames(id, side)) do
          local pab = ok(Airbase.getByName, pad)
          local pwh = pab and ok(pab.getWarehouse, pab)
          if pwh then
            for _, t in ipairs(B.catalog.aircraft[side].helicopters or {}) do pcall(pwh.setItem, pwh, t, n) end
          end
        end
        local rec = B.farps[id]
        if want and (not rec or rec.side ~= side) then
          if rec then B.removeFarpCrew(id) end
          B.spawnFarpCrew(id, side, ab)
        elseif not want and rec and rec.side == side then
          B.removeFarpCrew(id)
        end
      end
    end
  end
end

function B.spawnFarpCrew(id, side, ab)
  local p = (ab and ok(ab.getPoint, ab)) or B.nodePos[id]
  local units = {}
  for i, list in ipairs({ { B.catalog.farpCrew[side][1] }, { B.catalog.farpCrew[side][2] }, { B.catalog.farpCrew[side][3] } }) do
    local t = firstValid(list)
    if t then
      units[#units + 1] = { name = "DCC_FARPCREW_" .. id .. "_" .. i, type = t, skill = "Average",
                            x = p.x + 40 + i * 15, y = p.z + 40, heading = 0, playerCanDrive = false }
    end
  end
  local gname = "DCC_FARPCREW_" .. id
  if #units > 0 then
    pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, { name = gname, task = "Ground Nothing",
      units = units, route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point", action = "Off Road",
      speed = 0, ETA = 0, ETA_locked = false } } } })
  end
  B.farps[id] = { side = side, crew = gname }
  U.log("FARP at %s ready for %s", id, side)
end

function B.removeFarpCrew(id)
  local rec = B.farps[id]
  if not rec then return end
  local g = ok(Group.getByName, rec.crew)
  if g and ok(g.isExist, g) then g:destroy() end
  B.farps[id] = nil
end

-- ===========================================================================
-- 4. Ships
-- ===========================================================================
function B.initNaval()
  local war = B.war
  for _, ship in ipairs(war.theater.naval or {}) do
    local gname = "DCC_NAVAL_" .. ship.id
    local g = ok(Group.getByName, gname)
    if g then
      if not war:shipUp(ship.id) then
        g:destroy()          -- sunk earlier in this war: it stays sunk after a restart
      else
        B.naval[ship.id] = { group = gname, side = ship.side, leg = 0,
          start = (g:getUnit(1) and g:getUnit(1):getPoint()) or B.navalPos(ship) }
      end
    end
  end
end

function B.navalPos(ship)
  local p = coord.LLtoLO(ship.lat, ship.lon, 0)
  return { x = p.x, y = 0, z = p.z }
end

-- Carrier dead -> sunk; at the end of a leg, sail back (DCS ships stop at their last waypoint).
function B.pollNaval()
  local war = B.war
  for id, rec in pairs(B.naval) do
    local g = ok(Group.getByName, rec.group)
    local main = g and g:getUnit(1)
    if not alive(main) or main:getLife() < 1 then
      war:shipLost(id)
      B.naval[id] = nil
    elseif timer.getTime() - (rec.turned or 0) > 1800 then
      local p = main:getPoint()
      local ship
      for _, s in ipairs(war.theater.naval or {}) do if s.id == id then ship = s end end
      local home = rec.start
      local leg = (ship.legKm or 80) * 1000                      -- narrow seas: shorter legs
      local far = { x = home.x + math.cos(math.rad(ship.heading)) * leg, z = home.z + math.sin(math.rad(ship.heading)) * leg }
      local target = (dist2D(p, far) < 8000) and home or ((dist2D(p, home) < 8000) and far or nil)
      if target then
        local ctl = g:getController()
        pcall(ctl.setTask, ctl, { id = "Mission", params = { route = { points = {
          { x = p.x, y = p.z, type = "Turning Point", action = "Turning Point", speed = 12.8 },
          { x = target.x, y = target.z, type = "Turning Point", action = "Turning Point", speed = 12.8 } } } } })
        rec.turned = timer.getTime()
      end
    end
  end
end

-- Enemy radars and eyes find ships (they sit on the sea: radar horizon applies).
function B.scanShips()
  local war = B.war
  for id, rec in pairs(B.naval) do
    local enemy = otherSide(rec.side)
    local g = ok(Group.getByName, rec.group)
    local u = g and g:getUnit(1)
    if alive(u) then
      local seen = false
      for _, r in ipairs(B.radarsOf(enemy)) do
        if B.radarSees(r, u) then seen = "radar"; break end
      end
      if not seen then
        for _, pu in ipairs(coalition.getPlayers(B.COAL[enemy]) or {}) do
          if alive(pu) and dist2D(pu:getPoint(), u:getPoint()) <= 40000 then seen = "visual"; break end
        end
      end
      if seen then
        local p = u:getPoint()
        local name = id
        for _, s in ipairs(war.theater.naval or {}) do if s.id == id then name = s.name end end
        war:addContact(enemy, "ship:" .. id, { kind = "ship", source = seen, pos = { x = p.x, z = p.z }, label = name })
      end
    end
  end
end

-- Ships: radar horizon for something on the sea surface.
local baseRadarSees = B.radarSees
function B.radarSees(r, u)
  local desc = ok(u.getDesc, u)
  if desc and desc.category == 3 then          -- Unit.Category.SHIP
    local p = u:getPoint()
    local d = dist2D(r.pos, p)
    if d > r.km * 1000 then return false end
    local need = DCC.War.radarHorizonM(d / 1000, r.agl)
    return need <= 40                            -- a carrier's island is ~40 m tall
  end
  return baseRadarSees(r, u)
end

-- ===========================================================================
-- 5. Map, status, hooks
-- ===========================================================================
local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs(SIDES) do
    for key, c in pairs(war.state.contacts[side]) do
      if c.kind == "ship" and c.pos then
        local fresh = war:isFresh(side, key)
        local ec = DCC.config.colours[otherSide(side)]
        local col = { ec[1], ec[2], ec[3], fresh and 1 or 0.45 }
        B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.circleToAll(B.COAL[side], B.nextMark, { x = c.pos.x, y = 0, z = c.pos.z }, 5000, col,
          { ec[1], ec[2], ec[3], 0.15 }, 1, true, "")
        B.nextMark = B.nextMark + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.textToAll(B.COAL[side], B.nextMark, { x = c.pos.x + 5500, y = 0, z = c.pos.z }, col,
          { 0, 0, 0, 0.35 }, 11, true, (c.label or "ship") .. (fresh and "" or " (last seen)"))
      end
    end
  end
end

local baseDrawOps = B.drawOps
function B.drawOps(newMark, toVec3)
  baseDrawOps(newMark, toVec3)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if war:farpAt(id) then
      local p = B.nodePos[id]
      local col = DCC.config.colours[ns.side]
      local st, max = war:farpStock(id), WC().farpStock
      local txt = st <= 0 and "FARP (DRY)" or (st < max * WC().farpLowShare
        and string.format("FARP %d/%d", math.floor(st + 0.5), max) or "FARP")
      trigger.action.textToAll(-1, newMark(), { x = p.x + 2500, y = p.y, z = p.z + 2500 }, col, { 0, 0, 0, 0.35 },
        11, true, txt)
    elseif ns.farpSU then
      local p = B.nodePos[id]
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = p.x + 2500, y = p.y, z = p.z + 2500 },
        DCC.config.colours[ns.side], { 0, 0, 0, 0.35 }, 10, true,
        string.format("FARP %d/%d SU", math.floor(ns.farpSU), WC().farpBuildSU))
    end
  end
end

local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war = B.war
  local trend = war:weatherTrend()
  lines[#lines + 1] = string.format("Weather: %s%s%s.", DCC.War.WEATHER_TEXT[war:weatherKind()],
    trend ~= "" and (", " .. trend) or "", war:isNight() and ", night" or "")
  local a, b, v = war:worstRoad(side)
  if a then lines[#lines + 1] = string.format("Most dangerous road: %s - %s (AI escorts and CAP there)",
    war:nodeName(a), war:nodeName(b)) end
  for _, ship in ipairs(war.theater.naval or {}) do
    if ship.side == side then
      lines[#lines + 1] = string.format("%s: %s", ship.name, war:shipUp(ship.id) and "on station" or "SUNK")
    end
  end
  return lines
end

-- AI sortie templates by name (antiship uses the "antiship" template, attack pool).
local baseSpawnSortie = B.spawnSortie
function B.spawnSortie(side, role, kind, target, extra)
  if extra and extra.template then
    local find = B.findTemplate
    B.findTemplate = function(name)
      return find("DCC_TPL_" .. side .. "_" .. extra.template) or find(name)
    end
    local okS, r = pcall(baseSpawnSortie, side, role, kind, target, extra)
    B.findTemplate = find
    return okS and r or nil
  end
  return baseSpawnSortie(side, role, kind, target, extra)
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollNaval()
  B.reconcileFarps()
end

local baseTick = B.opsTick
function B.opsTick()
  B.updateNight()
  B.applyWeather()
  baseTick()
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if B.war.fogOfWar then B.scanShips() end
end

-- eyes see less in bad weather and at night
B.visualFactor = function(air) return B.war:visualFactor(air) end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.escorts, B.farps, B.naval, B.fogNow = {}, {}, {}, nil
  B.updateNight()
  B.initNaval()
end

end

-- >>> src/dcc_dcs_jtac.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: JTAC for CAS missions.
-- Load after dcc_dcs_world.lua.
-- ----------------------------------------------------------------------------
-- When a player takes a CAS mission, a friendly JTAC team (an invisible,
-- immortal light vehicle) sets up jtac.standoffKm from the battle on the
-- friendly side. Every 10 seconds it picks the nearest live enemy vehicle
-- within jtac.searchKm of the battle and keeps a laser (code jtac.laserCode)
-- and an IR pointer on it, following it as it moves and switching when it
-- dies. The pilot's F10 > Missions > JTAC menu: report target (type, MGRS,
-- code), mark with smoke, next target. The team packs up when the mission
-- ends.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.jtacs = {}   -- mission id -> { group, side, node, target, laser, ir, code }

local function JC() return DCC.config.jtac end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function friendlyNeighbour(side, node)
  local war = B.war
  local best, bestD
  for nb in pairs(war.T.nodes[node].nb) do
    if war.state.nodes[nb].side == side then
      local d = dist2D(B.nodePos[nb], B.nodePos[node])
      if not bestD or d < bestD then best, bestD = nb, d end
    end
  end
  return best
end

function B.spawnJtac(m)
  if B.jtacs[m.id] then return B.jtacs[m.id] end
  local side, node = m.side, m.target
  local types = B.catalog.jtac and B.catalog.jtac[side] or {}
  local t
  for _, c in ipairs(types) do if B.validType(c) then t = c; break end end
  if not t then return nil end
  local tp = B.nodePos[node]
  local from = friendlyNeighbour(side, node)
  local fp = from and B.nodePos[from] or { x = tp.x - 1, z = tp.z }
  local dx, dz = fp.x - tp.x, fp.z - tp.z
  local len = math.max(1, math.sqrt(dx * dx + dz * dz))
  local s = JC().standoffKm * 1000
  local x, z = tp.x + dx / len * s, tp.z + dz / len * s
  local gname = "DCC_JTAC_" .. m.id
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "Excellent", x = x, y = z, heading = 0, playerCanDrive = false } },
    route = { points = { { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0,
                           ETA = 0, ETA_locked = false } } } }
  if not pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, data) then return nil end
  local g = ok(Group.getByName, gname)
  local ctl = g and ok(g.getController, g)
  if ctl then
    pcall(ctl.setCommand, ctl, { id = "SetInvisible", params = { value = true } })
    pcall(ctl.setCommand, ctl, { id = "SetImmortal", params = { value = true } })
    if AI and AI.Option and AI.Option.Ground then
      pcall(ctl.setOption, ctl, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
    end
  end
  local rec = { group = gname, side = side, node = node, code = JC().laserCode, mission = m.id }
  B.jtacs[m.id] = rec
  return rec
end

function B.removeJtac(mid)
  local rec = B.jtacs[mid]
  if not rec then return end
  if rec.laser then pcall(rec.laser.destroy, rec.laser) end
  if rec.ir then pcall(rec.ir.destroy, rec.ir) end
  local g = ok(Group.getByName, rec.group)
  if g and ok(g.isExist, g) then g:destroy() end
  B.jtacs[mid] = nil
end

-- Enemy vehicles near the battle: spawned platoons of the other side.
function B.jtacCandidates(rec)
  local war, out = B.war, {}
  local center = B.nodePos[rec.node]
  for pid, srec in pairs(B.spawned) do
    local pl = war.state.platoons[pid]
    if pl and pl.side ~= rec.side then
      local g = ok(Group.getByName, srec.group)
      if g and ok(g.isExist, g) then
        for _, u in ipairs(g:getUnits() or {}) do
          if alive(u) and dist2D(u:getPoint(), center) <= JC().searchKm * 1000 then out[#out + 1] = u end
        end
      end
    end
  end
  return out
end

function B.jtacPick(rec, skipCurrent)
  local g = ok(Group.getByName, rec.group)
  local me = g and g:getUnit(1)
  if not alive(me) then return nil end
  local mp = me:getPoint()
  local best, bestD
  for _, u in ipairs(B.jtacCandidates(rec)) do
    if not (skipCurrent and rec.target == u:getName()) then
      local d = dist2D(mp, u:getPoint())
      if not bestD or d < bestD then best, bestD = u, d end
    end
  end
  return best, me
end

-- Keep the laser on the current target (or a new one).
function B.jtacUpdate(rec, forceNew)
  local target = rec.target and ok(Unit.getByName, rec.target)
  local me
  if forceNew or not alive(target) then
    target, me = B.jtacPick(rec, forceNew)
    rec.target = target and target:getName() or nil
    if rec.laser then pcall(rec.laser.destroy, rec.laser); rec.laser = nil end
    if rec.ir then pcall(rec.ir.destroy, rec.ir); rec.ir = nil end
  end
  if not target then return nil end
  if not me then
    local g = ok(Group.getByName, rec.group)
    me = g and g:getUnit(1)
  end
  if not alive(me) then return nil end
  local p = target:getPoint()
  local aim = { x = p.x, y = p.y + 2, z = p.z }
  if rec.laser then
    pcall(rec.laser.setPoint, rec.laser, aim)
    if rec.ir then pcall(rec.ir.setPoint, rec.ir, aim) end
  elseif Spot then
    rec.laser = ok(Spot.createLaser, me, { x = 0, y = 2, z = 0 }, aim, rec.code)
    rec.ir = ok(Spot.createInfraRed, me, { x = 0, y = 2, z = 0 }, aim)
  end
  return target
end

local function mgrs(p)
  local lat, lon = coord.LOtoLL(p)
  local m = ok(coord.LLtoMGRS, lat, lon)
  if not m then return string.format("%.4f %.4f", lat, lon) end
  return string.format("%s %s %05d %05d", m.UTMZone, m.MGRSDigraph, m.Easting, m.Northing)
end

-- ---------------------------------------------------------------------------
-- Pilot commands
-- ---------------------------------------------------------------------------
local function jtacOf(uname)
  local p = B.players[uname]
  if not p then return nil end
  local m = p.mission and B.war.state.missions[p.mission]
  if not m or m.type ~= "CAS" or m.status ~= "open" then
    trigger.action.outTextForGroup(p.gid, "No JTAC: take a CAS mission first.", 10)
    return nil, p
  end
  return B.jtacs[m.id] or B.spawnJtac(m), p
end

function B.jtacReport(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec)
  if not t then
    trigger.action.outTextForGroup(p.gid, "JTAC: no enemy vehicles in sight at " .. B.war:nodeName(rec.node) ..
      " yet. Stand by.", 15)
    return
  end
  trigger.action.outTextForGroup(p.gid, string.format(
    "JTAC: lasing %s, code %d, IR pointer on.\nMGRS %s\n%d hostile vehicles in the area.",
    ok(t.getTypeName, t) or "vehicle", rec.code, mgrs(t:getPoint()), #B.jtacCandidates(rec)), 30)
end

function B.jtacSmoke(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec)
  if not t then trigger.action.outTextForGroup(p.gid, "JTAC: nothing to mark.", 10); return end
  local tp = t:getPoint()
  pcall(trigger.action.smoke, { x = tp.x, y = tp.y, z = tp.z }, trigger.smokeColor and trigger.smokeColor.Red or 1)
  trigger.action.outTextForGroup(p.gid, "JTAC: red smoke on the target.", 10)
end

function B.jtacNext(uname)
  local rec, p = jtacOf(uname)
  if not rec then return end
  local t = B.jtacUpdate(rec, true)
  if t then B.jtacReport(uname) else trigger.action.outTextForGroup(p.gid, "JTAC: no other target.", 10) end
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------
local baseBuildMenu = B.buildMenu
function B.buildMenu(p)
  baseBuildMenu(p)
  if not p.menu then return end
  local m = p.mission and B.war.state.missions[p.mission]
  if m and m.type == "CAS" then
    local j = missionCommands.addSubMenuForGroup(p.gid, "JTAC", p.menu)
    missionCommands.addCommandForGroup(p.gid, "Report target", j, B.jtacReport, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Mark with smoke", j, B.jtacSmoke, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Next target", j, B.jtacNext, p.unit)
  end
end

local baseTake = B.takeMission
function B.takeMission(args)
  baseTake(args)
  local p = B.players[args.unit]
  local m = p and p.mission and B.war.state.missions[p.mission]
  if m and m.type == "CAS" and m.id == args.mid then
    if B.spawnJtac(m) then
      trigger.action.outTextForGroup(p.gid, string.format(
        "JTAC team moving up to %s. Laser code %d. F10 > Missions > JTAC.", B.war:nodeName(m.target),
        JC().laserCode), 15)
    end
  end
end

-- Every 10 s (detection loop): lase; pack up when the mission is over.
function B.jtacTick()
  for mid, rec in pairs(B.jtacs) do
    local m = B.war.state.missions[mid]
    if not m or m.status ~= "open" then B.removeJtac(mid) else B.jtacUpdate(rec) end
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  B.jtacTick()
end

end

-- >>> src/dcc_dcs_public.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - public status for the web map and Discord.
-- Load after dcc_dcs_jtac.lua.
-- ----------------------------------------------------------------------------
-- Writes two files to Saved Games\DCS\DCC\ for server/dcc_companion.py:
--
--   public.json  - rewritten every public.everySeconds: map, war clock,
--                  weather, every base (position, owner, FARP), the front line,
--                  recent public events, top pilots and squadrons, ships.
--                  ONLY what both sides know anyway: owners and the front, no
--                  garrison sizes, no supply, no enemy positions.
--   feed.jsonl   - one line per public event (captures, kills of radars,
--                  AWACS, ships, convoys, completed missions, weather, war
--                  clock warnings, victory and the war report), each with a
--                  running number per war so the companion posts it once.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.PUBLIC_KINDS = {
  capture = true, victory = true, clock = true, weather = true, ewr_destroyed = true, awacs_lost = true,
  sam_destroyed = true, convoy_lost = true, airlift_lost = true, farp_built = true, ship_sunk = true,
  mission_done = true, rescued = true, report = true, tanker_lost = true, strike_hit = true, package_down = true,
  arty_destroyed = true, bridge_down = true, bridge_up = true, surrender = true, farp_lost = true,
}

local function ll(p)
  local lat, lon = coord.LOtoLL({ x = p.x, y = 0, z = p.z })
  return { lat = math.floor(lat * 1e5 + 0.5) / 1e5, lon = math.floor(lon * 1e5 + 0.5) / 1e5 }
end

function B.publicState()
  local war, cfg = B.war, DCC.config
  local st = war.state
  local s = war:summary()
  local out = {
    map = war.T.name, version = cfg.version, warId = st.warId, tick = st.tick,
    day = (st.tick - (st.clockStart or 0)) * cfg.tickSeconds / 86400,
    updated = timer.getAbsTime(),
    winner = st.winner, winBy = st.winBy,
    bases = { blue = s.blue.nodes, red = s.red.nodes },
    weather = war:weatherKind(), night = war:isNight(),
    nodes = {}, front = {}, events = {}, pilots = {}, squadrons = {}, ships = {},
  }
  local left = war:clockTicksLeft()
  if left then
    out.clock = { hoursLeft = math.max(0, left) * cfg.tickSeconds / 3600, leader = war:clockLeader(),
                  gained = math.abs(war:groundGained("blue")) }
  end
  for _, id in ipairs(war.T.order) do
    local tn, ns = war.T.nodes[id], st.nodes[id]
    out.nodes[#out.nodes + 1] = { id = id, name = tn.name, lat = tn.lat, lon = tn.lon, kind = tn.kind,
      depot = tn.depot, side = ns.side, farp = war:farpAt(id) or nil }
  end
  local terr = DCC.territory.compute(war)
  local function r5(v) return math.floor(v * 1e5 + 0.5) / 1e5 end
  for _, line in ipairs(terr.front) do
    local pl = {}
    for _, p in ipairs(line) do pl[#pl + 1] = { r5(p.lat), r5(p.lon) } end
    out.front[#out.front + 1] = pl
  end
  out.territory = {}
  for _, cell in ipairs(terr.territory) do
    local pl = {}
    for _, p in ipairs(cell.poly) do pl[#pl + 1] = { r5(p.lat), r5(p.lon) } end
    out.territory[#out.territory + 1] = { side = cell.side, poly = pl }
  end
  local evs = st.events
  for i = #evs, 1, -1 do
    local ev = evs[i]
    if B.PUBLIC_KINDS[ev.kind] then
      out.events[#out.events + 1] = { tick = ev.tick, kind = ev.kind, side = ev.side, text = ev.text }
      if #out.events >= cfg.public.events then break end
    end
  end
  for key, p in pairs(DCC.pilots.data.pilots) do
    out.pilots[#out.pilots + 1] = { name = p.name, score = DCC.pilots:score(key), rank = DCC.pilots:rank(key),
      squadron = p.squadron, sorties = p.sorties }
  end
  table.sort(out.pilots, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.name < b.name end)
  while #out.pilots > 20 do table.remove(out.pilots) end
  for i, sq in ipairs(DCC.pilots:squadrons()) do
    if i > 10 then break end
    out.squadrons[i] = sq
  end
  for _, ship in ipairs(war.theater.naval or {}) do
    out.ships[#out.ships + 1] = { name = ship.name, side = ship.side, status = st.naval[ship.id] and st.naval[ship.id].status }
  end
  return out
end

function B.writePublic()
  local okE, text = pcall(DCC.json.encode, B.publicState())
  if okE then DCC.persist.writeFile("public.json", text) end
end

-- Append public events to the feed (each once: numbered per war).
function B.publishFeed(events)
  local war = B.war
  local st = war.state
  local lines = {}
  for _, ev in ipairs(events or {}) do
    if B.PUBLIC_KINDS[ev.kind] then
      st.feedSeq = (st.feedSeq or 0) + 1
      local okE, line = pcall(DCC.json.encode, { seq = st.feedSeq, warId = st.warId, map = war.T.name,
        tick = ev.tick or st.tick, kind = ev.kind, side = ev.side, text = ev.text })
      if okE then lines[#lines + 1] = line end
    end
  end
  if #lines > 0 then DCC.persist.appendFile("feed.jsonl", table.concat(lines, "\n") .. "\n") end
end

local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  B.publishFeed(events)
  B.writePublic()
end

end

-- >>> src/dcc_dcs_air.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: air war additions.
-- Load after dcc_dcs_public.lua.
-- ----------------------------------------------------------------------------
--   Tankers      - each side keeps a tanker orbiting behind its AWACS while
--                  anyone is online (BLUE KC-135MPRS, TACAN 51X; RED IL-78M,
--                  TACAN 52X). Shoot the enemy's down: TANKER mission.
--   Drones       - each side keeps a recon drone over the enemy base it is
--                  attacking; it spots ground units for its side's map.
--   Forward CAP  - the AI covers its own base the enemy is about to attack.
--   Packages     - strike packages (strikers + escort + SEAD) and helicopter
--                  assaults; the defender gets INTERCEPT missions.
--   IADS         - SAM sites only light up early when an own EWR or AWACS is
--                  tracking the target (B.cued), and get short-range point
--                  defence (Avenger / Tor) that stays on when the big radar
--                  goes dark.
--   Credit on landing - mission points are logged once the pilot lands at a
--                  friendly base; lost if they die or eject on the way home.
--   Cooldown     - two deaths within an hour ground a pilot from fast jets
--                  for 15 minutes (helicopters are still fine).
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.assets   = { blue = {}, red = {} }   -- side -> kind -> { group, born }
B.packages = {}                         -- package id -> { strike, escort, sead, target = pos, kind }
B.deaths   = {}                         -- pilot key -> { times }

local SIDES = { "blue", "red" }
local function AC() return DCC.config.air end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function ground(p) return ok(land.getHeight, { x = p.x, y = p.z }) or 0 end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function online() return #B.playerPositions() > 0 end

local TACAN = { blue = { ch = 51, cs = "TKR" }, red = { ch = 52, cs = "TKS" } }

-- ===========================================================================
-- Generic AI flight from a template (planes or helicopters)
-- ===========================================================================
local function wp(x, z, alt, speed, task, typ, action)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = typ or "Turning Point",
           action = action or "Turning Point", speed = speed, speed_locked = true, ETA = 0, ETA_locked = false,
           task = task or { id = "ComboTask", params = { tasks = {} } } }
end

local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end

function B.spawnFlight(side, role, gname, from, alt, speed, points, opts)
  opts = opts or {}
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_" .. role)
  if not tpl then return nil end
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId = gname, nil, nil
  data.task = opts.task or data.task
  local n = opts.size or #data.units
  local units = {}
  for i = 1, math.min(n, #data.units) do
    local u = data.units[i]
    u.unitId, u.name = nil, gname .. "_" .. i
    u.x, u.y, u.alt, u.alt_type, u.speed, u.skill = from.x + (i - 1) * 150, from.z + (i - 1) * 150, alt, "BARO", speed, "High"
    u.heading = 0
    units[i] = u
  end
  data.units = units
  data.route = { points = points }
  local cat = (tpl.units[1] and opts.helicopter) and Group.Category.HELICOPTER or Group.Category.AIRPLANE
  local s, err = pcall(coalition.addGroup, B.countryId(side), cat, data)
  if not s then U.log("spawn %s failed: %s", gname, tostring(err)); return nil end
  return gname
end

-- ===========================================================================
-- 1. Tankers and drones
-- ===========================================================================
function B.spawnAsset(side, kind)
  local war = B.war
  if (war.state.airPool[side][kind] or 0) < 1 then return nil end
  local gname = string.format("DCC_%s_%s_%d", kind:upper(), side, (B.assetCount or 0) + 1)
  local spawned
  if kind == "tanker" then
    local p, hdg = B.awacsOrbit(side)
    if not p then return nil end
    local ax, az = math.cos(hdg or 0), math.sin(hdg or 0)
    local c = { x = p.x - ax * 40000, z = p.z - az * 40000 }           -- behind the AWACS
    local p1 = { x = c.x - az * 35000, z = c.z + ax * 35000 }
    local p2 = { x = c.x + az * 35000, z = c.z - ax * 35000 }
    local alt, spd = 7000, 200
    spawned = B.spawnFlight(side, "tanker", gname, p1, alt, spd, {
      wp(p1.x, p1.z, alt, spd, combo({ { id = "Tanker", params = {} },
        { id = "Orbit", params = { pattern = "Race-Track", point = { x = p1.x, y = p1.z },
          point2 = { x = p2.x, y = p2.z }, altitude = alt, speed = spd } } })),
      wp(p2.x, p2.z, alt, spd) }, { task = "Refueling", size = 1 })
  else
    -- drone: over the enemy base this side attacks (or its front)
    local f = war.state.focus and war.state.focus[side]
    local node = f and f.target
    if not node then return nil end
    local p, alt, spd = B.nodePos[node], 4500, 60
    spawned = B.spawnFlight(side, "drone", gname, { x = p.x - 15000, z = p.z }, alt, spd, {
      wp(p.x, p.z, alt, spd, combo({ { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = spd } } })) },
      { task = "Reconnaissance", size = 1 })
  end
  if not spawned then return nil end
  B.assetCount = (B.assetCount or 0) + 1
  war:airTake(side, kind, 1)
  war:setAsset(side, kind, true)
  B.assets[side][kind] = { group = gname, born = timer.getTime() }
  if kind == "tanker" then
    local u = unitsOf(gname)[1]
    local ctl = u and ok(u.getController, u) or (ok(Group.getByName, gname) and Group.getByName(gname):getController())
    local t = TACAN[side]
    if ctl then
      pcall(ctl.setCommand, ctl, { id = "ActivateBeacon", params = { type = 4, system = 4, callsign = t.cs,
        frequency = (1088 + t.ch - 1) * 1000000, AA = true, channel = t.ch, modeChannel = "X", bearing = true,
        unitId = u and ok(u.getID, u) } })
    end
    trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s tanker on station, TACAN %dX.",
      side:upper(), t.ch), 10)
  end
  return gname
end

function B.pollAssets()
  local war = B.war
  for _, side in ipairs(SIDES) do
    for kind, rec in pairs(B.assets[side]) do
      local us = unitsOf(rec.group)
      if #us == 0 then
        war:assetLost(side, kind)
        B.assets[side][kind] = nil
      elseif not online() or timer.getTime() - rec.born > 4 * 3600 then
        local g = ok(Group.getByName, rec.group)
        if g then g:destroy() end
        local p = war.state.airPool[side]
        p[kind] = math.min(AC().assetPoolMax[kind], (p[kind] or 0) + 1)
        war:setAsset(side, kind, false)
        B.assets[side][kind] = nil
      end
    end
  end
end

function B.planAssets()
  if not online() then return end
  for _, side in ipairs(SIDES) do
    for _, kind in ipairs({ "tanker", "drone" }) do
      if not B.assets[side][kind] then B.spawnAsset(side, kind) end
    end
  end
end

-- Drones see enemy ground units below them (within 8 km).
function B.scanDrones(idx)
  for _, side in ipairs(SIDES) do
    local rec = B.assets[side].drone
    local d = rec and unitsOf(rec.group)[1]
    if d then
      local dp = d:getPoint()
      for _, e in pairs(idx) do
        if e.side ~= side and not e.air then
          for _, u in ipairs(unitsOf(e.group)) do
            if dist2D(u:getPoint(), dp) <= 8000 then B.report(side, e, u, "sensor"); break end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 2. Packages: strike and helicopter assault
-- ===========================================================================
function B.launchStrike(side)
  local war = B.war
  local t = war:pickStrikeTarget(side)
  if not t then return nil end
  if not war:airAvailable(side, "attack", 2) or not war:airAvailable(side, "fighter", 2) then return nil end
  local pk = war:packageLaunched(side, "strike", t)
  if not pk then return nil end
  local tp = B.nodePos[t.node]
  local strike = B.spawnSortie(side, "attack", "STRIKE", tp, { node = t.node, life = 3600,
    task = { { id = "Bombing", params = { point = { x = tp.x, y = tp.z }, expend = "All", attackQty = 1,
      groupAttack = true } } } })
  local escort = B.spawnSortie(side, "fighter", "ESCORT", tp, { node = t.node, life = 3600,
    task = { { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 40000 } },
             { id = "Orbit", params = { pattern = "Circle", altitude = 7000, speed = 220 } } } })
  local sead
  if t.kind == "sam" or (war.state.nodes[t.node].sam and war.state.nodes[t.node].sam.status == "up") then
    sead = B.spawnSortie(side, "attack", "SEAD", tp, { node = t.node, template = "sead", life = 3600,
      task = { { id = "EngageTargets", params = { targetTypes = { "Air Defence" }, priority = 0, maxDist = 60000 } },
               { id = "Orbit", params = { pattern = "Circle", altitude = 6000, speed = 220 } } } })
  end
  if not strike then war:packageDestroyed(pk.id); return nil end
  for _, g in ipairs({ strike, escort, sead }) do if B.sorties[g] then B.sorties[g].pkg = pk.id end end
  B.packages[pk.id] = { strike = strike, escort = escort, sead = sead, target = tp, kind = "strike" }
  return pk
end

function B.launchAirAssault(side)
  local war = B.war
  local t = war:pickAirAssault(side, AC().airAssaultKm)
  if not t then return nil end
  local pk = war:packageLaunched(side, "airmobile", t.to, t.from)
  if not pk then return nil end
  local a, b = B.nodePos[t.from], B.nodePos[t.to]
  local gname = "DCC_AIRASSAULT_" .. pk.id
  local landing = { x = b.x + 600, z = b.z + 600 }
  local g = B.spawnFlight(side, "airmobile", gname, { x = a.x, z = a.z }, 150, 60, {
    wp(a.x, a.z, 150, 60),
    wp(landing.x, landing.z, 0, 50, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
      durationFlag = true, duration = 600 } } })) }, { helicopter = true, task = "Transport" })
  if not g then war:packageDestroyed(pk.id); return nil end
  B.packages[pk.id] = { strike = gname, target = b, kind = "airmobile", landing = landing }
  return pk
end

function B.pollPackages()
  local war = B.war
  for id, rec in pairs(B.packages) do
    local pk = war.state.packages[id]
    if not pk or pk.status ~= "inbound" then
      B.packages[id] = nil
    else
      local us = unitsOf(rec.strike)
      if #us == 0 then
        war:packageDestroyed(id)
        B.packages[id] = nil
      else
        for _, u in ipairs(us) do
          local p = u:getPoint()
          local reached
          if rec.kind == "airmobile" then
            reached = dist2D(p, rec.landing) <= 1500 and (p.y - ground(p)) < 60
          else
            reached = dist2D(p, rec.target) <= 6000
          end
          if reached then
            war:packageArrived(id)
            if rec.kind == "airmobile" then
              local g = ok(Group.getByName, rec.strike)
              -- the helicopters fly home empty: leave them in the sky for a while, then remove
              timer.scheduleFunction(function() if g and ok(g.isExist, g) then g:destroy() end end, nil, timer.getTime() + 600)
            end
            B.packages[id] = nil
            break
          end
        end
      end
    end
  end
end

function B.planPackages()
  if not online() then return end
  local war = B.war
  local per = DCC.config.tickSeconds / 60
  for _, side in ipairs(SIDES) do
    if war:aiAttackAllowed() and war.rng:next() < per / AC().packageMinutes then B.launchStrike(side) end
    if not war:isStorm() and war.rng:next() < per / AC().airAssaultMinutes then B.launchAirAssault(side) end
  end
end

-- ===========================================================================
-- 3. IADS: radar cueing and point defence
-- ===========================================================================
-- Does an own EWR / AWACS track this enemy aircraft?
function B.cued(side, u)
  for _, r in ipairs(B.radarsOf(side)) do
    if B.radarSees(r, u) then return true end
  end
  return false
end

local baseSpawnSam = B.spawnSam
function B.spawnSam(id)
  baseSpawnSam(id)
  local rec = B.sams[id]
  local spec = B.catalog.sam and B.catalog.sam[rec and rec.side or ""]
  if not rec or not spec or not spec.pointDefence then return end
  local c = B.nodePos[id]
  local off = B.war.state.nodes[id].sam and B.war.state.nodes[id].sam.pdOff
  if off then c = { x = c.x + off.dx, z = c.z + off.dz } end
  local units = {}
  for i, t in ipairs(spec.pointDefence) do
    if B.validType(t) then
      units[#units + 1] = { name = "DCC_SAMPD_" .. id .. "_" .. i, type = t, skill = "High",
        x = c.x + 900 * math.cos(i * 2.1), y = c.z + 900 * math.sin(i * 2.1), heading = 0, playerCanDrive = false }
    end
  end
  if #units == 0 then return end
  local gname = "DCC_SAMPD_" .. id
  if pcall(coalition.addGroup, B.countryId(rec.side), Group.Category.GROUND, { name = gname, task = "Ground Nothing",
      units = units, route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point",
      action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
    rec.pd = gname
  end
end

local baseDespawnSam = B.despawnSam
function B.despawnSam(id)
  local rec = B.sams[id]
  if rec and rec.pd then
    local g = ok(Group.getByName, rec.pd)
    if g and ok(g.isExist, g) then g:destroy() end
  end
  baseDespawnSam(id)
end

-- ===========================================================================
-- 4. Forward CAP
-- ===========================================================================
local basePlanAir = B.planAir
function B.planAir()
  basePlanAir()
  local war = B.war
  if not online() or not AC().forwardCap then return end
  for _, side in ipairs(SIDES) do
    local f = war.state.focus and war.state.focus[otherSide(side)]
    local target = f and f.target
    if target and war.state.nodes[target].side == side then
      local busy = false
      for _, s in pairs(B.sorties) do if s.side == side and s.kind == "FWDCAP" then busy = true end end
      if not busy then
        local g = B.spawnSortie(side, "fighter", "CAP", B.nodePos[target], { node = target })
        if g and B.sorties[g] then
          B.sorties[g].kind = "FWDCAP"
          trigger.action.outTextForCoalition(B.COAL[side], string.format(
            "Command: fighters to cover %s - the enemy is massing for an attack there.", war:nodeName(target)), 10)
        end
      end
    end
  end
end

-- ===========================================================================
-- 5. Credit on landing, 6. cooldown
-- ===========================================================================
local function playerByKey(key)
  for uname, p in pairs(B.players) do if p.key == key then return p, uname end end
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  if outcome ~= "done" or not AC().creditOnLanding then return baseDone(m, outcome) end
  -- pilots still in the air: their points wait for the landing (everything else - messages,
  -- photo reports - happens as usual)
  local held = {}
  for key in pairs(m.taken) do
    local p, uname = playerByKey(key)
    local u = uname and ok(Unit.getByName, uname)
    if p and alive(u) and ok(u.inAir, u) then held[key] = p end
  end
  local pilots = DCC.pilots
  local realMission = pilots.mission
  pilots.mission = function(self, key, mtype, name)
    local p = held[key]
    if p then
      p.pendingCredit = p.pendingCredit or {}
      table.insert(p.pendingCredit, { type = mtype, label = m.label })
      return
    end
    return realMission(self, key, mtype, name)
  end
  local okD, err = pcall(baseDone, m, outcome)
  pilots.mission = realMission
  if not okD then error(err) end
  for _, p in pairs(held) do
    trigger.action.outTextForGroup(p.gid, "Land at a friendly base (or your carrier) to log the mission points.", 15)
  end
end

-- landed at a friendly base: log the held missions
function B.creditLanding(u)
  local p = B.players[ok(u.getName, u) or ""]
  if not p or not p.pendingCredit then return end
  local id = B.nearestNode(u:getPoint(), 5000)
  local onCarrier = false
  for _, rec in pairs(B.naval or {}) do
    local cv = unitsOf(rec.group)[1]
    if cv and dist2D(cv:getPoint(), u:getPoint()) < 500 and rec.side == p.side then onCarrier = true end
  end
  if not onCarrier and not (id and B.war.state.nodes[id].side == p.side) then return end
  for _, c in ipairs(p.pendingCredit) do DCC.pilots:mission(p.key, c.type, p.name) end
  trigger.action.outTextForGroup(p.gid, string.format("Welcome back. %d mission(s) logged.", #p.pendingCredit), 15)
  p.pendingCredit = nil
end

function B.recordDeath(key)
  local list = B.deaths[key] or {}
  list[#list + 1] = timer.getTime()
  B.deaths[key] = list
end

-- Minutes this pilot is still grounded from fast jets (0 = free to fly).
function B.groundedFor(key)
  local list, now, cfg = B.deaths[key] or {}, timer.getTime(), AC()
  local recent = {}
  for _, t in ipairs(list) do if now - t <= cfg.cooldownWindowMin * 60 then recent[#recent + 1] = t end end
  B.deaths[key] = recent
  if #recent < cfg.cooldownDeaths then return 0 end
  local left = cfg.cooldownMin * 60 - (now - recent[#recent])
  return left > 0 and math.ceil(left / 60) or 0
end

local function keyOf(u)
  local name = ok(u.getPlayerName, u)
  if not name then return nil end
  local p = B.players[ok(u.getName, u) or ""]
  if p then return p.key end
  for _, pl in pairs(DCC.pilots.data.pilots) do if pl.name == name then return name end end
  return name
end

local baseOnBirth = B.onBirth
function B.onBirth(unit)
  baseOnBirth(unit)
  if not alive(unit) then return end
  local desc = ok(unit.getDesc, unit)
  if not desc or desc.category ~= Unit.Category.AIRPLANE then return end
  local key = keyOf(unit)
  local mins = key and B.groundedFor(key) or 0
  if mins > 0 then
    trigger.action.outTextForUnit(unit:getID(), string.format(
      "Grounded: two losses within the hour. Fast jets again in %d min - helicopters are fine.", mins), 20)
    pcall(function() unit:destroy() end)
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  local ev, u = world.event, e.initiator
  if e.id == ev.S_EVENT_PILOT_DEAD or e.id == ev.S_EVENT_EJECTION then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p then
      p.pendingCredit = nil            -- did not make it home
      if e.id == ev.S_EVENT_PILOT_DEAD then B.recordDeath(p.key) end
    end
  elseif e.id == ev.S_EVENT_LAND and u then
    B.creditLanding(u)
  end
  baseOpsEvent(e)
end

-- ===========================================================================
-- Intel, mission positions, hooks
-- ===========================================================================
local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for _, side in ipairs(SIDES) do
    for kind, rec in pairs(B.assets[side]) do
      idx[rec.group] = { side = side, kind = "air", air = true, group = rec.group, asset = kind }
    end
  end
  for id, rec in pairs(B.packages) do
    if rec.kind == "airmobile" then
      idx[rec.strike] = { side = B.war.state.packages[id] and B.war.state.packages[id].side, kind = "air", air = true,
                          group = rec.strike, pkg = id }
    end
  end
  for gname, s in pairs(B.sorties) do
    if s.pkg and idx[gname] then idx[gname].pkg = s.pkg end
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  if e and e.side == side then return end
  baseReport(side, e, u, source)
  if e and e.pkg then
    B.war:addContact(side, "pkg:" .. e.pkg, { kind = "package", source = source, label = "strike package" })
  end
  if e and e.asset == "tanker" then
    local p = u:getPoint()
    B.war:addContact(side, "tanker:" .. e.side, { kind = "tanker", source = source, pos = { x = p.x, z = p.z },
      label = e.side:upper() .. " tanker" })
  end
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if B.war.fogOfWar then B.scanDrones(B.intelIndex()) end
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "INTERCEPT" then
    local rec = B.packages[m.target]
    local u = rec and unitsOf(rec.strike)[1]
    if u then return u:getPoint() end
    local crec = B.cargo[m.target]                      -- an enemy airlift / supply helicopters
    u = crec and unitsOf(crec.group)[1]
    if u then return u:getPoint() end
  elseif m.type == "TANKER" then
    local rec = B.assets[m.target] and B.assets[m.target].tanker
    local u = rec and unitsOf(rec.group)[1]
    if u then return u:getPoint() end
  end
  return baseMissionPos(m)
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollAssets()
  B.pollPackages()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planAssets()
  B.planPackages()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.assets, B.packages = { blue = {}, red = {} }, {}
  -- assets and packages from before a restart are not in the sky any more
  for _, side in ipairs(SIDES) do
    for kind in pairs(war.state.assets[side]) do
      war:setAsset(side, kind, false)
      local p = war.state.airPool[side]
      p[kind] = math.min(AC().assetPoolMax[kind], (p[kind] or 0) + 1)
    end
  end
  for id, pk in pairs(war.state.packages) do
    if pk.status == "inbound" then
      if pk.platoon and war.state.carried[pk.platoon] then
        -- the troops never left: back to their base
        war.state.carried[pk.platoon] = { from = pk.from, by = "ai" }
        war:returnCarried(pk.platoon)
      end
      war.state.packages[id] = nil
    end
  end
end

-- ===========================================================================
-- Helicopter supply runs (war moves with mv.helo): real AI transport
-- helicopters (the airmobile template), low level, landing at the base.
-- Escort them (ESCORT, any aircraft) - the enemy AI and players can shoot
-- them down. On landing the cargo is set down (as CTLD crates when CTLD is
-- in the mission) and the helicopters lift off home a few minutes later.
-- ===========================================================================
local baseSpawnAirlift = B.spawnAirlift
function B.spawnAirlift(mv)
  if not mv.helo then return baseSpawnAirlift(mv) end
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local p = U.clamp(mv.progress, 0, 0.95)
  local x, z = a.x + (b.x - a.x) * p, a.z + (b.z - a.z) * p
  local landing = { x = b.x + 350, z = b.z + 350 }
  local speed = DCC.config.supply.heliliftSpeedKmh / 3.6
  local gname = "DCC_" .. mv.id
  local g = B.spawnFlight(mv.side, "airmobile", gname, { x = x, z = z }, 150, speed, {
    wp(x, z, 150, speed),
    wp(landing.x, landing.z, 0, speed, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
      durationFlag = true, duration = 900 } } })) }, { helicopter = true, task = "Transport" })
  local n = g and #(unitsOf(gname)) or 1
  B.cargo[mv.id] = { group = gname, size = math.max(1, n), base = mv.health or 1, kind = "airlift", helo = true,
                     landing = landing, side = mv.side, failed = g == nil, born = timer.getTime() }
end

local baseDespawn = B.despawnCargo
function B.despawnCargo(mid, rec)
  local war = B.war
  local delivered = rec.helo and war.state.deliveredMoves and war.state.deliveredMoves[mid]
  if not delivered then return baseDespawn(mid, rec) end
  -- landed and unloaded: crates on the ground, helicopters stay a while, then go
  B.cargo[mid] = nil
  local lead = unitsOf(rec.group)[1]
  local pos = lead and ok(lead.getPoint, lead) or rec.landing
  ok(B.heliCargoDown, rec.side, pos, war.cfg.supply.heliliftCapacity)
  timer.scheduleFunction(function()
    local g = ok(Group.getByName, rec.group)
    if g and ok(g.isExist, g) then g:destroy() end
  end, nil, timer.getTime() + 180)
end

-- The cargo, set down next to the helicopter: one crate per 10 SU (scenery -
-- the supply is already in the base's stock).
function B.heliCargoDown(side, pos, su)
  local names = {}
  B.heliCrateN = (B.heliCrateN or 0) + 1
  for i = 1, math.max(1, math.min(4, math.floor(su / 10))) do
    local name = string.format("DCC_HELICARGO_%d_%d", B.heliCrateN, i)
    local s = pcall(coalition.addStaticObject, B.countryId(side), { name = name, type = "ammo_cargo",
      category = "Cargos", x = pos.x + 25 + i * 6, y = pos.z + 20, heading = 0, canCargo = false, mass = 1000 })
    if s then names[#names + 1] = name end
  end
  timer.scheduleFunction(function()
    for _, n in ipairs(names) do
      local o = ok(StaticObject.getByName, n)
      if o and ok(o.isExist, o) then o:destroy() end
    end
  end, nil, timer.getTime() + DCC.config.supply.heliCargoMinutes * 60)
  return names
end

B.EFFECT.INTERCEPT = "Shoot them down before they get there. A package or air assault stopped does no harm; "
  .. "an airlift or supply helicopters shot down lose their supply. \"My mission\" gives its latest position."

end

-- >>> src/dcc_dcs_ground.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: ground war additions.
-- Load after dcc_dcs_air.lua.
-- ----------------------------------------------------------------------------
--   Artillery      - batteries the model placed next to a battle are spawned
--                    when their base is live and shell the battle for real
--                    (FireAtPoint every 2 min). Killed: War:batteryHit.
--   Skirmishes     - small fights that always run on contested roads, even far
--                    from players, so CAS pilots always find a front to work.
--                    Rebuilt 30 min after they are wiped out; they follow the front.
--   Fortifications - one bunker per fortification level at live bases.
--                    Destroyed: War:fortHit.
--   Bridges        - real DCS bridges on the roads, found once at mission start
--                    (world.searchObjects). A destroyed bridge closes its road.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.batteries  = {}   -- battery id -> { group, node, lastFire }
B.skirmishes = {}   -- road key -> { groups = {blue, red}, born, deadSince }
B.forts      = {}   -- node id -> { names = {k = name}, side }
B.bridgeObjs = {}   -- road key -> scenery object

local SIDES = { "blue", "red" }
local function GC() return DCC.config.ground end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function destroyGroup(gname)
  local g = gname and ok(Group.getByName, gname)
  if g and ok(g.isExist, g) then g:destroy() end
end
local function firstValid(list)
  local out = {}
  for _, t in ipairs(list or {}) do if B.validType(t) then out[#out + 1] = t end end
  return out
end
local function groundGroup(side, gname, types, x, z, spacing)
  local units = {}
  for i, t in ipairs(types) do
    units[i] = { name = gname .. "_" .. i, type = t, skill = "Average", x = x + (i - 1) * (spacing or 30),
                 y = z + (i % 2) * 20, heading = 0, playerCanDrive = false }
  end
  if #units == 0 then return nil end
  local okAdd = pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, { name = gname,
    task = "Ground Nothing", units = units, route = { points = { { x = x, y = z, type = "Turning Point",
    action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } })
  return okAdd and gname or nil
end
local function roadKey(a, b) if a < b then return a .. "|" .. b end return b .. "|" .. a end

-- ===========================================================================
-- 1. Artillery
-- ===========================================================================
function B.reconcileArtillery()
  local war = B.war
  for _, side in ipairs(SIDES) do
    for _, b in ipairs(war:batteries(side)) do
      local rec = B.batteries[b.id]
      -- read back
      if rec and #unitsOf(rec.group) == 0 then
        war:batteryHit(b.id)
        destroyGroup(rec.group)
        B.batteries[b.id] = nil
        rec = nil
      end
      local want = b.status == "up" and b.node and B.liveNodes[b.node]
      if rec and (not want or rec.node ~= b.node) then
        destroyGroup(rec.group)
        B.batteries[b.id] = nil
        rec = nil
      end
      if want and not rec then
        local p = B.scatter(b.node, b.id .. "9")
        local g = groundGroup(side, "DCC_ARTY_" .. b.id, firstValid(B.catalog.artillery[side]), p.x, p.z, 60)
        if g then B.batteries[b.id] = { group = g, node = b.node, lastFire = 0 } end
      end
    end
  end
end

-- Shell the battles next to each live battery.
function B.artilleryFire()
  local war, now = B.war, timer.getTime()
  for id, rec in pairs(B.batteries) do
    if now - rec.lastFire >= 120 then
      local side
      for _, s in ipairs(SIDES) do
        for _, b in ipairs(war:batteries(s)) do if b.id == id then side = s end end
      end
      for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
        local mv = war.state.moves[mid]
        local nearBattle = mv.status == "fighting" and (mv.to == rec.node or war.T.nodes[mv.to].nb[rec.node])
        if nearBattle and (mv.side ~= side or war.state.nodes[mv.to].side ~= side) then
          -- aim at the enemy: the attackers if we defend, the garrison if we attack
          local tp = B.nodePos[mv.to]
          if war.state.nodes[mv.to].side == side then
            local a = B.nodePos[mv.from]
            tp = { x = tp.x + (a.x - tp.x) * 0.15, z = tp.z + (a.z - tp.z) * 0.15 }
          end
          local g = ok(Group.getByName, rec.group)
          local ctl = g and ok(g.getController, g)
          if ctl then
            pcall(ctl.pushTask, ctl, { id = "FireAtPoint", params = { point = { x = tp.x, y = tp.z }, radius = 300,
              expendQty = 12, expendQtyEnabled = true } })
            rec.lastFire = now
            rec.firedAt = tp
          end
          break
        end
      end
    end
  end
end

-- ===========================================================================
-- 2. Skirmishes on the front
-- ===========================================================================
function B.frontRoads()
  local war, out = B.war, {}
  for _, e in ipairs(war.T.edges) do
    local sa, sb = war.state.nodes[e.a].side, war.state.nodes[e.b].side
    if sa ~= sb and not e.sea and not war:roadClosed(e.a, e.b) then out[#out + 1] = e end
  end
  table.sort(out, function(x, y) return x.km < y.km end)   -- short roads: the hottest contact
  return out
end

function B.reconcileSkirmishes()
  if not GC().skirmishes then return end
  local war, now = B.war, timer.getTime()
  local want = {}
  for i, e in ipairs(B.frontRoads()) do
    if i > GC().skirmishMax then break end
    want[roadKey(e.a, e.b)] = e
  end
  for k, rec in pairs(B.skirmishes) do
    if not want[k] then
      for _, g in pairs(rec.groups) do destroyGroup(g) end
      B.skirmishes[k] = nil
    end
  end
  for k, e in pairs(want) do
    local rec = B.skirmishes[k]
    local wiped = rec and (#unitsOf(rec.groups.blue) == 0 or #unitsOf(rec.groups.red) == 0)
    if rec and wiped then
      rec.deadSince = rec.deadSince or now
      if now - rec.deadSince >= 1800 then
        for _, g in pairs(rec.groups) do destroyGroup(g) end
        B.skirmishes[k], rec = nil, nil
      end
    end
    if not rec then
      local pa, pb = B.nodePos[e.a], B.nodePos[e.b]
      local mx, mz = (pa.x + pb.x) / 2, (pa.z + pb.z) / 2
      local dx, dz = pb.x - pa.x, pb.z - pa.z
      local len = math.max(1, math.sqrt(dx * dx + dz * dz))
      dx, dz = dx / len, dz / len
      local groups = {}
      B.skirmishSerial = (B.skirmishSerial or 0) + 1
      for _, node in ipairs({ e.a, e.b }) do
        local side = war.state.nodes[node].side
        local sgn = (node == e.a) and -1 or 1
        local types = {}
        local roleTypes = B.unitTypes("MECH_PLT", side)
        for i = 1, GC().skirmishPerSide do types[i] = roleTypes[i] or roleTypes[1] end
        groups[side] = groundGroup(side, string.format("DCC_SKIRM_%d_%s", B.skirmishSerial, side), types,
          mx + sgn * dx * 700, mz + sgn * dz * 700, 40)
      end
      B.skirmishes[k] = { groups = groups, born = now }
    end
  end
end

-- ===========================================================================
-- 3. Fortifications
-- ===========================================================================
function B.reconcileForts()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local rec = B.forts[id]
    local want = B.liveNodes[id] and ns.fort > 0
    if rec and (not want or rec.side ~= ns.side) then
      for _, n in pairs(rec.names) do local s = ok(StaticObject.getByName, n); if s then pcall(s.destroy, s) end end
      B.forts[id], rec = nil, nil
    end
    if want then
      rec = rec or { names = {}, side = ns.side }
      B.forts[id] = rec
      local count = 0
      for _ in pairs(rec.names) do count = count + 1 end
      for k = count + 1, ns.fort do
        local types = B.catalog.fortifications or { "Sandbox" }
        local c = B.nodePos[id]
        local ang = k * 2.4
        local name = string.format("DCC_FORT_%s_%d_%d", id, k, war.state.tick)
        if pcall(coalition.addStaticObject, B.countryId(ns.side), { name = name, type = types[(k - 1) % #types + 1],
            category = "Fortifications", x = c.x + 700 * math.cos(ang), y = c.z + 700 * math.sin(ang), heading = ang }) then
          rec.names[k] = name
        end
      end
    end
  end
end

-- a bunker destroyed
function B.onFortDead(name)
  for id, rec in pairs(B.forts) do
    for k, n in pairs(rec.names) do
      if n == name then
        rec.names[k] = nil
        B.war:fortHit(id)
        return true
      end
    end
  end
end

-- ===========================================================================
-- 4. Bridges
-- ===========================================================================
-- Find real bridges along every road once (scenery search, 2 km steps).
function B.findBridges()
  local war = B.war
  war.bridges = {}
  B.bridgeObjs = {}
  if not (world.searchObjects and Object.Category.SCENERY and world.VolumeType) then return 0 end
  for _, e in ipairs(war.T.edges) do
    if not e.sea then
      local na, nb = war.T.nodes[e.a], war.T.nodes[e.b]
      local steps = math.max(1, math.floor(e.km / 2))
      local found
      for i = 1, steps - 1 do
        if found then break end
        local p = U.lerp(na, nb, i / steps)
        local v = coord.LLtoLO(p.lat, p.lon, 0)
        pcall(world.searchObjects, Object.Category.SCENERY,
          { id = world.VolumeType.SPHERE, params = { point = { x = v.x, y = land.getHeight({ x = v.x, y = v.z }), z = v.z }, radius = 1200 } },
          function(obj)
            local t = (ok(obj.getTypeName, obj) or ""):lower()
            if t:find("bridge", 1, true) or t:find("most", 1, true) then found = obj; return false end
            return true
          end)
      end
      if found then
        local p = found:getPoint()
        war.bridges[#war.bridges + 1] = { a = e.a, b = e.b, pos = { x = p.x, z = p.z } }
        B.bridgeObjs[roadKey(e.a, e.b)] = found
      end
    end
  end
  U.log("bridges found on %d roads", #war.bridges)
  return #war.bridges
end

function B.pollBridges()
  local war = B.war
  for k, obj in pairs(B.bridgeObjs) do
    local a, b = k:match("^(.-)|(.+)$")
    local dead = not ok(obj.isExist, obj) or (ok(obj.getLife, obj) or 1) <= 0
    if dead and not war:roadClosed(a, b) and not (B.bridgeSeenDead or {})[k] then
      B.bridgeSeenDead = B.bridgeSeenDead or {}
      B.bridgeSeenDead[k] = true          -- the wreck stays; reopening is the engineers' crossing
      war:bridgeDown(a, b)
    end
  end
end

-- ===========================================================================
-- Hooks
-- ===========================================================================
local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "BRIDGE" then
    for _, br in ipairs(B.war.bridges or {}) do
      if br.a .. "|" .. br.b == m.target then return { x = br.pos.x, y = 0, z = br.pos.z } end
    end
  elseif m.type == "ARTY" then
    local rec = B.batteries[m.target]
    local u = rec and unitsOf(rec.group)[1]
    if u then return u:getPoint() end
  end
  return baseMissionPos(m)
end

local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for id, rec in pairs(B.batteries) do
    local side
    for _, s in ipairs(SIDES) do for _, b in ipairs(B.war:batteries(s)) do if b.id == id then side = s end end end
    idx[rec.group] = { side = side, kind = "arty", group = rec.group, battery = id }
  end
  for _, rec in pairs(B.skirmishes) do
    for side, g in pairs(rec.groups) do idx[g] = { side = side, kind = "skirmish", group = g } end
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  baseReport(side, e, u, source)
  if e and e.battery and e.side ~= side then
    B.war:addContact(side, "arty:" .. e.battery, { kind = "arty", node = B.batteries[e.battery] and
      B.batteries[e.battery].node, source = source, label = "artillery battery" })
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  if e.id == world.event.S_EVENT_DEAD and e.initiator then
    local n = ok(e.initiator.getName, e.initiator)
    if n and n:find("^DCC_FORT_") then B.onFortDead(n) end
  end
  baseOpsEvent(e)
end

local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war = B.war
  local up, cut, forts = 0, 0, 0
  for _, b in ipairs(war:batteries(side)) do if b.status == "up" then up = up + 1 end end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side then
      if war:cutOff(id) then cut = cut + 1 end
      if ns.fort > 0 then forts = forts + 1 end
    end
  end
  lines[#lines + 1] = string.format("Artillery: %d batteries ready. Fortified bases: %d. Cut off: %d.", up, forts, cut)
  return lines
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileArtillery()
  B.artilleryFire()
  B.reconcileForts()
  B.pollBridges()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.reconcileSkirmishes()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.batteries, B.skirmishes, B.forts, B.bridgeSeenDead = {}, {}, {}, {}
  B.findBridges()
end

end

-- >>> src/dcc_dcs_ctld.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: VEAF CTLD v2 as the helicopter
-- logistics layer.  Load after dcc_dcs_ground.lua, before dcc_main.lua.
-- ----------------------------------------------------------------------------
-- The mission loads CTLD.lua (with ctld.dontInitialize = true) before our
-- bundle. When CTLD is there, this module
--   * configures it: no ME zones or pilot-name lists, CTLD's JTAC switched
--     off (ours does CAS), and a "Supply crate" added to the crate list;
--   * gives every own base a CTLD pickup (troops) and logistic (crates)
--     zone, and moves them to the other side when the base is captured;
--   * makes crates cost the base's supply (refused when the base is dry);
--   * turns CTLD actions into war-model events:
--       supply crate unloaded at an own base   -> supply delivered (LOGISTICS)
--       FOB built next to a town               -> the town gets a FARP
--       AA system set up next to an own base   -> base dug in one level
--       vehicle unpacked / set down at own base -> joins the garrison as a
--                                                 platoon (artillery: a battery,
--                                                 trucks: their load as supply)
--       troops picked up at a base             -> a platoon leaves the garrison
--       troops unloaded at an own base         -> reinforcement
--       troops unloaded at an enemy base       -> air assault
--       troops unloaded in the field           -> tracked; lost if killed
--       helicopter lost with troops on board   -> platoon lost
--   * removes our own F10 "Cargo" menu (CTLD's menu replaces it).
-- Without CTLD in the mission nothing here runs and the old Cargo menu stays.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.ctld = { zones = {}, zoneNode = {}, field = {}, hooked = false }

local function CC() return DCC.config.ctld end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function sideOf(coal) return coal == 2 and "blue" or (coal == 1 and "red" or nil) end
local function coalOf(side) return side == "blue" and 2 or 1 end
local function say(unit, text)
  local g = unit and ok(unit.getGroup, unit)
  local gid = g and ok(g.getID, g)
  if gid then trigger.action.outTextForGroup(gid, text, 12) end
end
local function playerOf(uname) return uname and B.players[uname] end

function B.ctldPresent()
  return DCC.config.ctld.enabled ~= false and type(CTLDConfig) == "table" and type(ctld) == "table"
    and type(ctld.initialize) == "function" and type(CTLDZoneManager) == "table"
end

-- ===========================================================================
-- 1. Configuration (before ctld.initialize)
-- ===========================================================================
local function isJtacGroup(g)
  return type(g) == "table" and (tonumber(g.jtac) or 0) > 0
end

function B.ctldConfigure()
  local cfg = CTLDConfig.get()
  cfg:load()                                         -- idempotent; parses the default YAML
  local set = function(k, v) cfg:setSetting(k, v) end
  -- our missions have no ME zones or named transport slots: every helicopter
  -- type CTLD knows can lift, and zones come from the bases (section 2)
  set("troopZones", {})
  set("logisticUnits", {})
  set("transportPilotNames", {})
  set("wpZones", {})
  set("aiZones", {})
  set("extractableGroups", {})
  -- troops come out of base garrisons only (a CTLD FOB or FARP is not a barracks)
  set("troopPickupAtFOB", false)
  set("troopPickupAtFARP", false)
  -- our JTAC handles CAS; CTLD's JTACs (crates, drones, JTAC troops) are off
  set("JTAC_LIMIT_BLUE", 0)
  set("JTAC_LIMIT_RED", 0)
  set("JTAC_dropEnabled", false)
  local groups = {}
  for _, g in ipairs(ctld.gs("loadableGroups") or {}) do
    if not isJtacGroup(g) then groups[#groups + 1] = g end
  end
  set("loadableGroups", groups)
  local crates = {}
  for cat, list in pairs(ctld.gs("spawnableCrates") or {}) do
    local keep = {}
    for _, c in ipairs(list) do
      if not c.isJTAC then keep[#keep + 1] = c end
    end
    if #keep > 0 then crates[cat] = keep end
  end
  -- RED's light vehicles (BLUE has its Humvees already): the UAZ flies whole, the Tigr in crates
  local cv = crates["Combat Vehicles"] or {}
  local have = {}
  for _, c in ipairs(cv) do have[c.unit] = true end
  if not have["Tigr_233036"] then
    cv[#cv + 1] = { unit = "Tigr_233036", desc = "Tigr - recon", weight = 1000.13, cratesRequired = 2, side = 1 }
  end
  if not have["UAZ-469"] then
    cv[#cv + 1] = { unit = "UAZ-469", desc = "UAZ - light", weight = 1000.14, cratesRequired = 1, side = 1 }
  end
  crates["Combat Vehicles"] = cv
  -- the supply crate: never unpacked; unloaded at an own base it is supply
  crates["Supply"] = { { unit = "DCC_SUPPLY", desc = string.format("Supply crate (%d SU)", CC().supplyCrateSU),
                         weight = CC().supplyWeight, cratesRequired = 1, dccSupply = true } }
  set("spawnableCrates", crates)
  local weights = ctld.gs("groundVehicleWeights") or {}
  for t, kg in pairs(CC().vehicleWeights or {}) do weights[t] = kg end
  set("groundVehicleWeights", weights)
  -- whole vehicles in a helicopter or transport: light vehicles only (no APCs, no tanks)
  local wv = CC().wholeVehicles or {}
  for _, caps in pairs(ctld.gs("capabilitiesByType") or {}) do
    if type(caps) == "table" and caps.loadableVehiclesBLUE then caps.loadableVehiclesBLUE = U.copy(wv.blue or {}) end
    if type(caps) == "table" and caps.loadableVehiclesRED then caps.loadableVehiclesRED = U.copy(wv.red or {}) end
  end
end

-- ===========================================================================
-- 2. Zones follow base ownership
-- ===========================================================================
local function zoneRadius(id)
  return (B.war.T.nodes[id].kind == "airbase") and CC().zoneRadiusAirbaseM or CC().zoneRadiusM
end

function B.ctldSyncZones()
  local zm = CTLDZoneManager.getInstance()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns, kind = war.state.nodes[id], war.T.nodes[id].kind
    local side = ns.side
    local want = (side == "blue" or side == "red") and kind ~= "carrier" and B.nodePos[id] and coalOf(side) or nil
    local have = B.ctld.zones[id]
    if have and have.coal ~= want then
      ok(zm.unregisterLogistic, zm, have.name)
      ok(zm.unregisterTroopZone, zm, have.name)
      B.ctld.zones[id], B.ctld.zoneNode[have.name] = nil, nil
      have = nil
    end
    if want and not have then
      local p = B.nodePos[id]
      local pt = { x = p.x, y = land.getHeight({ x = p.x, y = p.z }), z = p.z }
      local name = war:nodeName(id)
      ok(zm.registerFOBAsLogistic, zm, name, pt, zoneRadius(id), want)
      ok(zm.registerFOBAsTroopZone, zm, name, pt, zoneRadius(id), want)
      B.ctld.zones[id] = { name = name, coal = want }
      B.ctld.zoneNode[name] = id
    end
  end
end

-- The base that pays for a crate requested at this point: our own zone, or
-- the nearest own base behind a FOB.
local function payingNode(pos, side)
  for id, z in pairs(B.ctld.zones) do
    if z.coal == coalOf(side) then
      local p = B.nodePos[id]
      local dx, dz = pos.x - p.x, pos.z - p.z
      if math.sqrt(dx * dx + dz * dz) <= zoneRadius(id) then return id end
    end
  end
  return B.nearestNodeOf(pos, side, CC().fobChargeKm * 1000)
end

-- ===========================================================================
-- 3. Crates
-- ===========================================================================
local function charge(unit, nCrates)
  local side = sideOf(ok(unit.getCoalition, unit))
  local pos = ok(unit.getPoint, unit)
  if not side or not pos then return true end
  local node = payingNode(pos, side)
  if not node then return true end                    -- a mission-maker zone: free
  local su = CC().crateSU * nCrates
  if B.war:takeCrate(node, su) <= 0 then
    say(unit, string.format("%s has no supply to spare (%d SU needed, %d left).", B.war:nodeName(node), su,
      math.floor(B.war.state.nodes[node].supply or 0)))
    return false
  end
  return true, node, su
end

local function refund(node, su)
  if node and su then
    local ns = B.war.state.nodes[node]
    ns.supply = (ns.supply or 0) + su
  end
end

local function isSupply(desc) return type(desc) == "table" and desc.dccSupply == true end

-- A supply crate on the ground near an own base: delivered.
function B.ctldCrateDown(crate, pos)
  if not (crate and isSupply(crate.descriptor) and pos) then return false end
  local side = sideOf(crate.coalition)
  if not side then return false end
  local node = B.nearestNodeOf(pos, side, CC().dropKm * 1000)
  if not node then return false end
  B.war:deliverCrate(side, node, CC().supplyCrateSU)
  local mgr = CTLDCrateManager.getInstance()
  ok(mgr.destroyCrate, mgr, crate.crateName)
  trigger.action.outTextForCoalition(coalOf(side), string.format("Supply crate delivered to %s (+%d SU).",
    B.war:nodeName(node), CC().supplyCrateSU), 10)
  return true
end

-- ===========================================================================
-- 4. Troops
-- ===========================================================================
local function lastInTransit(tm, uname)
  local list = tm._inTransit and tm._inTransit[uname]
  return list and list[#list]
end

local function addToPlayer(uname, pids)
  local p = playerOf(uname)
  if p then for _, pid in ipairs(pids) do p.troops[#p.troops + 1] = pid end end
end

local function removeFromPlayers(pids)
  for _, p in pairs(B.players) do
    for _, pid in ipairs(pids) do U.removeValue(p.troops, pid) end
  end
end

-- Platoons a CTLD troop template stands for: one per ~10 soldiers.
function B.ctldPlatoonsFor(template)
  return math.max(1, math.floor(((template and template.total) or 10) / 10 + 0.5))
end

local function pickPlatoons(node, n)
  local war = B.war
  local list = war:sortedGarrison(node, false)
  local out = {}
  -- mechanised first (they are the ones that ride), never the last platoon
  for i = #list, 1, -1 do
    if #out < n and #list - #out > 1 and war.state.platoons[list[i]].role == "MECH_PLT" then out[#out + 1] = list[i] end
  end
  for i = #list, 1, -1 do
    local taken = false
    for _, p in ipairs(out) do if p == list[i] then taken = true end end
    if not taken and #out < n and #list - #out > 1 then out[#out + 1] = list[i] end
  end
  return out
end

-- Troops are on the ground at pos (landed, fast-roped or by parachute).
function B.ctldTroopsDown(troopGroup, dcsGroup, pos, side)
  local pids = troopGroup and troopGroup._dccPids
  if not pids or troopGroup._dccDone then return end
  troopGroup._dccDone = true
  removeFromPlayers(pids)
  local war = B.war
  local gname = dcsGroup and ok(dcsGroup.getName, dcsGroup)
  local node = pos and B.nearestNodeOf(pos, nil, CC().dropKm * 1000)
  if node then
    local r = war:dropPlatoons(pids, node, side)
    if r == "reinforced" then
      -- they join the garrison: the bubble spawns them with it from now on
      timer.scheduleFunction(function()
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then ok(g.destroy, g) end
      end, nil, timer.getTime() + 60)
      trigger.action.outTextForCoalition(coalOf(side), string.format("Troops landed at %s and joined the garrison.",
        war:nodeName(node)), 10)
    elseif r == "assault" then
      trigger.action.outTextForCoalition(coalOf(side), string.format("Air assault on %s!", war:nodeName(node)), 15)
    end
    return
  end
  if gname then B.ctld.field[gname] = pids         -- out in the field: still carried
  else for _, pid in ipairs(pids) do war:returnCarried(pid) end end   -- counted into an ME objective zone
end

-- Field troops killed -> lost; re-embarked -> handled by the embarkFromField hook.
function B.ctldPollField()
  for gname, pids in pairs(B.ctld.field) do
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if ok(u.isExist, u) then n = n + 1 end end
    end
    if n == 0 then
      for _, pid in ipairs(pids) do B.war:loseCarried(pid) end
      B.ctld.field[gname] = nil
    end
  end
end

-- ===========================================================================
-- 5. Hooks into CTLD
-- ===========================================================================
function B.ctldHook()
  if B.ctld.hooked then return end
  B.ctld.hooked = true
  local TM, CM, VS = CTLDTroopManager, CTLDCrateManager, CTLDVehicleSpawner

  -- troops board at one of our bases: platoons leave the garrison
  local baseEmbark = TM.embarkFromTroopZone
  TM.embarkFromTroopZone = function(self, unit, zone, template)
    local node = zone and B.ctld.zoneNode[zone.zoneName or ""]
    if not node or not B.war then return baseEmbark(self, unit, zone, template) end
    local want = B.ctldPlatoonsFor(template)
    local spare = #B.war.state.nodes[node].platoons - 1
    if spare < want then
      say(unit, string.format("%s cannot spare %d platoon(s) (%d to spare).", B.war:nodeName(node), want,
        math.max(0, spare)))
      return false
    end
    if not baseEmbark(self, unit, zone, template) then return false end
    local uname = unit:getName()
    local pids = pickPlatoons(node, want)
    for _, pid in ipairs(pids) do
      local rec = B.spawned[pid]
      if rec then B.despawn(pid, rec) end
      B.war:carryPlatoon(pid, uname)
    end
    local tg = lastInTransit(self, uname)
    if tg then tg._dccPids = pids end
    addToPlayer(uname, pids)
    return true
  end

  -- every way troops leave a helicopter on the ground ends in deploy()
  local baseDeploy = CTLDTroopGroup.deploy
  CTLDTroopGroup.deploy = function(self, dcsGroup)
    local r = baseDeploy(self, dcsGroup)
    if self._dccPids and B.war then
      local u1 = dcsGroup and ok(function() return dcsGroup:getUnits()[1] end)
      local pos = u1 and ok(u1.getPoint, u1)
      local s, e = pcall(B.ctldTroopsDown, self, dcsGroup, pos, sideOf(self.coalitionId))
      if not s then U.log("ERROR ctld deploy: %s", tostring(e)) end
    end
    return r
  end

  -- picked up again from the field
  local baseField = TM.embarkFromField
  TM.embarkFromField = function(self, unit)
    local coal = unit:getCoalition()
    local before = {}
    for _, n in ipairs((self._droppedGroups or {})[coal] or {}) do before[n] = true end
    local r = baseField(self, unit)
    if r then
      local still = {}
      for _, n in ipairs((self._droppedGroups or {})[coal] or {}) do still[n] = true end
      for n in pairs(before) do
        if not still[n] and B.ctld.field[n] then
          local pids = B.ctld.field[n]
          B.ctld.field[n] = nil
          local tg = lastInTransit(self, unit:getName())
          if tg then tg._dccPids, tg._dccDone = pids, nil end
          addToPlayer(unit:getName(), pids)
        end
      end
    end
    return r
  end

  -- "return troops to base" at one of our zones: back into that garrison
  local baseReturn = TM.returnToTroopZone
  TM.returnToTroopZone = function(self, unit, zone)
    local list = self._inTransit and self._inTransit[unit:getName()] or {}
    local pids = {}
    for _, g in ipairs(list) do for _, pid in ipairs(g._dccPids or {}) do pids[#pids + 1] = pid end end
    local r = baseReturn(self, unit, zone)
    if r and B.war and #pids > 0 then
      local node = zone and B.ctld.zoneNode[zone.zoneName or ""]
      removeFromPlayers(pids)
      if node then B.war:dropPlatoons(pids, node, sideOf(unit:getCoalition()))
      else for _, pid in ipairs(pids) do B.war:returnCarried(pid) end end
    end
    return r
  end

  -- crates cost supply at the base they are requested at
  local baseSpawn = CM.spawnCrate
  CM.spawnCrate = function(self, descriptor, position, coal, spawnedBy, spawnMethod, ...)
    local node, su
    if spawnMethod == "menu_ctld" and spawnedBy and B.war then
      local u = ok(Unit.getByName, spawnedBy)
      if u then
        -- some crates (the FARP kit) are only for the heavy lifters, and cost more
        local only = type(descriptor) == "table" and descriptor.dccOnly
        if only and not only[ok(u.getTypeName, u) or ""] then
          say(u, descriptor.dccOnlyMsg or "This aircraft cannot lift that crate.")
          return nil
        end
        local paid
        paid, node, su = charge(u, (type(descriptor) == "table" and descriptor.dccCharge) or 1)
        if not paid then return nil end
      end
    end
    local crate = baseSpawn(self, descriptor, position, coal, spawnedBy, spawnMethod, ...)
    if not crate then refund(node, su) end
    return crate
  end

  if VS and VS.spawnVehicleForTransport then
    local baseVeh = VS.spawnVehicleForTransport
    VS.spawnVehicleForTransport = function(self, vehicleType, spawner, zone)
      local node, su
      if B.war and spawner then
        local d = ok(CM.findDescriptorByTypeName, CM.getInstance(), vehicleType)
        local paid
        paid, node, su = charge(spawner, d and d.cratesRequired or 1)
        if not paid then return false end
      end
      local r = baseVeh(self, vehicleType, spawner, zone)
      if not r then refund(node, su) end
      return r
    end
  end

  -- a supply crate is never unpacked into anything
  local baseUnpack = CM.unpackCrate
  CM.unpackCrate = function(self, crateName, unpacker)
    local crate = self.crates and self.crates[crateName]
    if crate and isSupply(crate.descriptor) then
      if not B.ctldCrateDown(crate, crate.position) then
        say(unpacker, "Supply crates are delivered by unloading them at a friendly base.")
      end
      return
    end
    return baseUnpack(self, crateName, unpacker)
  end
  -- a crate vehicle stands on the map: does it join a base?
  if CM._dispatchPostSpawn then
    local basePost = CM._dispatchPostSpawn
    CM._dispatchPostSpawn = function(self, desc, gname)
      basePost(self, desc, gname)
      if B.war and desc and not desc.isJTAC and (desc.spawnAs == nil or desc.spawnAs == "GROUND") then
        local g = ok(Group.getByName, gname)
        local u1 = g and ok(function() return g:getUnits()[1] end)
        local side = u1 and sideOf(ok(u1.getCoalition, u1))
        local s, e = pcall(B.ctldVehicleDown, desc, gname, side)
        if not s then U.log("ERROR ctld vehicle: %s", tostring(e)) end
      end
    end
  end

  if CM._spawnUnpacked then
    local baseSU = CM._spawnUnpacked
    CM._spawnUnpacked = function(self, desc, ...)
      if isSupply(desc) then return nil end
      return baseSU(self, desc, ...)
    end
  end
end

-- ===========================================================================
-- 4b. Vehicles unpacked at an own base join its garrison
-- ===========================================================================
-- What a CTLD crate vehicle is in the war: a platoon role, an artillery
-- battery, or (trucks) supply. Support trucks (CTLD crate family 1001.xx) first, then the catalogue's
-- unit lists, then CTLD's crate families (1000.xx combat,
-- 1002 artillery, 1003 short-range AA).
function B.ctldRoleOf(desc, side)
  local t = desc.unit
  local fam = math.floor(tonumber(desc.weight) or 0)
  if fam == 1001 then return "SUPPLY" end              -- trucks: their load, not the truck, counts
  for role, spec in pairs(B.catalog.roles or {}) do
    local s = spec[side] or {}
    for _, list in ipairs({ s.units or {}, s.fallback or {} }) do
      for _, u in ipairs(list) do if u == t then return role end end
    end
  end
  if fam == 1000 then
    if t:find("Abrams") or t:find("T%-%d") or t:find("Leopard") or t:find("LAV") then return "ARMOR_PLT" end
    return "MECH_PLT"
  elseif fam == 1002 then return "ARTY"
  elseif fam == 1003 then return "SHORAD"
  end
  return nil
end

function B.ctldVehicleDown(desc, gname, side)
  local war = B.war
  if not (desc and gname and side) or isSupply(desc) then return end
  local g = ok(Group.getByName, gname)
  local u1 = g and ok(function() return g:getUnits()[1] end)
  local pos = u1 and ok(u1.getPoint, u1)
  local su = (desc.cratesRequired or 1) * CC().crateSU
  local role = B.ctldRoleOf(desc, side)
  local node = pos and B.nearestNodeOf(pos, side, CC().dropKm * 1000)
  if not node then
    -- set down at an ENEMY base: the vehicle attacks it (with any troops landed there)
    local target = pos and B.nearestNodeOf(pos, nil, CC().dropKm * 1000)
    if not target or war.state.nodes[target].side == side then return end
    if role ~= "MECH_PLT" and role ~= "ARMOR_PLT" and role ~= "SHORAD" then return end
    local home = B.nearestNodeOf(pos, side)
    if not home then return end
    local pid = war:newPlatoon(side, role, home)
    war.state.platoons[pid].health = math.min(1, su / CC().platoonSU)
    war:carryPlatoon(pid, "ctld:" .. gname)
    war:dropPlatoons({ pid }, target, side)
    trigger.action.outTextForCoalition(coalOf(side), string.format("%s joins the air assault on %s!",
      tostring(desc.desc or desc.unit), war:nodeName(target)), 12)
    return                                             -- it fights where it stands
  end
  if not role then return end
  local what
  if role == "SUPPLY" then
    war:deliverCrate(side, node, su)
    what = string.format("%s handed its load to %s (+%d SU)", tostring(desc.desc or desc.unit), war:nodeName(node), su)
  elseif role == "ARTY" then
    local list, extra, revived = war:batteries(side), 0, false
    for _, b in ipairs(list) do
      if b.status ~= "up" and not revived then b.status, b.since, b.node, revived = "up", war.state.tick, node, true end
      if b.ctld then extra = extra + 1 end
    end
    if not revived then
      if extra >= CC().maxExtraBatteries then return end   -- enough guns: it stays where it is
      list[#list + 1] = { id = war:newId(side:sub(1, 1) .. "a"), status = "up", node = node, ctld = true }
    end
    what = string.format("an artillery battery at %s", war:nodeName(node))
  else
    local pid = war:newPlatoon(side, role, node)
    war.state.platoons[pid].health = math.min(1, su / CC().platoonSU)
    what = string.format("%s joined the garrison of %s", tostring(desc.desc or desc.unit), war:nodeName(node))
  end
  war:log("ctld_vehicle", side, string.format("%s: %s", side:upper(), what), { node = node })
  trigger.action.outTextForCoalition(coalOf(side), what:sub(1, 1):upper() .. what:sub(2) .. ".", 10)
  -- it is part of the base now: the live bubble spawns it with the garrison
  timer.scheduleFunction(function()
    local gg = ok(Group.getByName, gname)
    if gg and ok(gg.isExist, gg) then ok(gg.destroy, gg) end
  end, nil, timer.getTime() + CC().joinDelay)
end

function B.ctldSubscribe()
  local ed = EventDispatcher.getInstance()
  local function on(name, fn)
    ed:subscribe(name, function(ev) if B.war then local s, e = pcall(fn, ev); if not s then U.log("ERROR ctld %s: %s", name, tostring(e)) end end end)
  end
  on("OnCrateUnloaded", function(ev) B.ctldCrateDown(ev.crate, ev.position) end)
  on("OnCrateParachuteLanded", function(ev) B.ctldCrateDown(ev.crate, ev.position or (ev.crate and ev.crate.position)) end)
  on("OnTroopsParachuteLanded", function(ev)
    local tg = ev.troops
    local pos = ev.positions and ev.positions[1]
    if tg then B.ctldTroopsDown(tg, ev.spawnedGroup, pos, sideOf(tg.coalitionId)) end
  end)
  -- a whole vehicle carried by a Chinook / Mi-26 and set down at an own base
  on("OnVehicleUnloaded", function(ev)
    local u = ev.dcsUnitObject
    if not u or (ok(u.inAir, u)) then return end
    local g = ok(u.getGroup, u)
    local gname = g and ok(g.getName, g)
    local desc = CTLDCrateManager.getInstance():findDescriptorByUnitType(ev.vehicleType)
    if gname and desc then B.ctldVehicleDown(desc, gname, sideOf(ok(u.getCoalition, u))) end
  end)
  on("OnFOBDeployed", function(ev)
    local side = sideOf(ev.fob and ev.fob.coalitionId)
    local war = B.war
    local node = side and ev.position and B.nearestNodeOf(ev.position, side, CC().fobFarpKm * 1000)
    if node then war:buildFarp(node, side, "fob", { ctld = ev.fob.name }) end
  end)
  on("OnFOBDestroyed", function(ev)
    local war = B.war
    for _, id in ipairs(war.T.order) do
      local ns = war.state.nodes[id]
      if ns.farp and ns.farp.ctld and ev.fob and ns.farp.ctld == ev.fob.name then
        ns.farp = nil
        war:log("farp_lost", ns.side, string.format("The FOB at %s has been destroyed", war:nodeName(id)), { node = id })
      end
    end
  end)
  on("OnAASystemDeployed", function(ev)
    local side = sideOf(ev.coalition)
    local war = B.war
    local node = side and ev.position and B.nearestNodeOf(ev.position, side, CC().aaDefenceKm * 1000)
    if not node then return end
    local ns = war.state.nodes[node]
    local max = DCC.config.ground.fortMax
    if (ns.fort or 0) < max then
      ns.fort, ns.fortSince = (ns.fort or 0) + 1, war.state.tick
      war:log("ctld_aa", side, string.format("%s set up a %s at %s - defences now level %d", side:upper(),
        tostring(ev.systemName or "AA system"), war:nodeName(node), ns.fort), { node = node })
    end
  end)
end

-- ===========================================================================
-- 5b. Supply crates straight from the Missions menu (v0.37)
-- ===========================================================================
-- CTLD's own path (CTLD > Request Equipment > <base> > Supply > ...) is deep
-- and its categories page, so players never found it. Every CTLD transport
-- gets F10 > Missions > "Supply crate (n SU)": the same CTLD crate, spawned
-- beside the aircraft, charged to the base like any CTLD crate.
function B.ctldTransportOk(p)
  local caps = (ctld and ctld.gs and ctld.gs("capabilitiesByType") or {})[p.type]
  return type(caps) == "table" and caps.cratesEnabled == true
end

function B.ctldSupplyCrate(uname)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and u and ok(u.isExist, u)) then return end
  if ok(u.inAir, u) then return say(u, "Land at a friendly base to load a supply crate.") end
  local coal = u:getCoalition()
  local zones = ok(CTLDZoneManager.getInstance().getLogisticZonesAtPoint, CTLDZoneManager.getInstance(),
    u:getPoint(), coal, "cratesPickup") or {}
  if not next(zones) then return say(u, "No logistics here - land at a friendly airbase or town to load supply.") end
  local cm = CTLDCrateManager.getInstance()
  local desc = cm:findDescriptorByWeight(CC().supplyWeight)
  if not desc then return say(u, "Supply crates are not available in this mission.") end
  local n = ok(cm.spawnCratesAligned, cm, { desc }, u, coal, uname, "menu_ctld") or 0
  if n > 0 then
    say(u, string.format("Supply crate (%d SU) is beside you. Load it: F10 > CTLD > Check Cargo / load nearby crate "
      .. "(or sling it). Unload it at a friendly base for the supply.", CC().supplyCrateSU))
  end
end

local baseBuildMenu = B.buildMenu
function B.buildMenu(p)
  baseBuildMenu(p)
  if p and p.gid and p.menu and B.ctldActive and not p.ground and B.ctldTransportOk(p) then
    missionCommands.addCommandForGroup(p.gid, string.format("Supply crate (%d SU)", CC().supplyCrateSU), p.menu,
      B.ctldSupplyCrate, p.unit)
  end
end

-- ===========================================================================
-- 6. Start-up and wiring
-- ===========================================================================
function B.ctldSetup()
  B.ctldActive = false
  if not B.ctldPresent() then return false end
  if not ctld._dccInit then
    if CTLDPlayerManager and CTLDPlayerManager._instance then
      U.log("ERROR CTLD started on its own before the campaign set it up (the mission's DO SCRIPT "
        .. "'ctld.dontInitialize = true' did not run) - CTLD keeps its default settings")
    end
    local s, e = pcall(function()
      B.ctldConfigure()
      B.ctldHook()
      ctld.initialize()
      B.ctldSubscribe()
    end)
    if not s then
      U.log("ERROR CTLD start failed, keeping the DCC cargo menu: %s", tostring(e))
      return false
    end
    ctld._dccInit = true
  end
  B.ctldActive = true
  B.ctld.zones, B.ctld.zoneNode, B.ctld.field = {}, {}, {}
  B.ctldSyncZones()
  B.EFFECT.LOGISTICS = "F10 > Missions > Supply crate at a friendly base (or CTLD > Request Equipment > Supply), fly it to the target and unload it there."
  B.EFFECT.FARP = "Chinook / Mi-8: F10 > CTLD > Engineering > FARP kit, set it down within 3 km of the town. Or bring 3 supply crates (any lift helicopter), or build a CTLD FOB there."
  B.EFFECT.FARPSUP = "F10 > CTLD > load supply crates, set them down within 3 km of the FARP. A FARP kit refills it completely. A dry FARP has no rearm and no helicopter spawns."
  local n = 0
  for _ in pairs(B.ctld.zones) do n = n + 1 end
  U.log("CTLD %s integrated: %d base zones", tostring(ctld.VERSION), n)
  return true
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.ctldSetup()
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  if B.ctldActive then
    B.ctldSyncZones()
    B.ctldPollField()
  end
end

end

-- >>> src/dcc_dcs_ext_air.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more air war, support, ranks, scaling,
-- wrecks.  Load after dcc_dcs_ctld.lua.
-- ----------------------------------------------------------------------------
--   Armoury   - what a base can arm aircraft with follows its supply. Taxi
--               out with weapons the base cannot supply and you are warned;
--               take off with them and you are recalled (aircraft removed).
--               Guided and advanced weapons are paid from the base's supply.
--   Runways   - bombs that land on an enemy runway count; 3 close it.
--               Fixed-wing slots at a closed airfield are refused.
--   SAM moves - point defence (and mobile long-range sites) drive to a new
--               spot after they fire or a HARM comes their way.
--   AI crews  - AI aircrews eject; CSAR for their side, SNATCH for the enemy
--               (enemy player pilots too). Land by the pilot, bring him home.
--   Support   - F10 > Support: artillery or a CAS pair on your newest F10
--               map mark, AWACS picture, the base armoury. Gated by rank.
--   Scaling   - the side outnumbered in players takes fewer losses and its
--               AI flies more strike packages.
--   Ranks     - Captain: artillery, Major: CAS, Lt Col: FARP spawns,
--               Colonel: AWACS picture.
--   Wrecks    - destroyed vehicles stay as wrecks through restarts (3 days),
--               destroyed buildings stay destroyed.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function sideOf(u) return sideOfCoal(ok(u.getCoalition, u)) end
local function say(p, text, t) if p and p.gid then trigger.action.outTextForGroup(p.gid, text, t or 12) end end
local function isHeli(u)
  local d = ok(u.getDesc, u)
  return d and d.category == (Unit.Category and Unit.Category.HELICOPTER or 1)
end

B.ext = { warned = {}, tracked = {}, moved = {}, marks = {}, cooldown = { blue = {}, red = {} }, wreckN = 0 }

-- ===========================================================================
-- 1. Armoury
-- ===========================================================================
local W_MISSILE, W_BOMB = 1, 3
local G_INS, G_RADAR_A, G_RADAR_SA, G_RADAR_P = 1, 3, 4, 5
local MC_ANTISHIP, MC_CRUISE = 4, 5

-- guided and advanced weapons on board
function B.classifyAmmo(u)
  local guided, adv = 0, 0
  for _, a in ipairs(ok(u.getAmmo, u) or {}) do
    local d, n = a.desc or {}, a.count or 0
    if d.category == W_MISSILE then
      local g, mc = d.guidance, d.missileCategory
      if g == G_INS or g == G_RADAR_A or g == G_RADAR_SA or g == G_RADAR_P or mc == MC_ANTISHIP or mc == MC_CRUISE then
        adv = adv + n
      else
        guided = guided + n
      end
    elseif d.category == W_BOMB and d.guidance then
      if d.guidance == G_INS then adv = adv + n else guided = guided + n end
    end
  end
  return guided, adv
end

local TIER_TEXT = { basic = "guns, rockets and unguided bombs", guided = "guided weapons (IR missiles, laser and TV)",
                    advanced = "everything (radar missiles, anti-radiation, GPS)" }

local function ownBase(u, side)
  local pos = ok(u.getPoint, u)
  local id = pos and B.nearestNodeOf(pos, side, 5000)
  return id
end

function B.armouryText(id)
  local war = B.war
  local tier = war:armouryTier(id)
  local a = XC().armoury
  return string.format("Armoury at %s: %s.\nGuided weapons cost %.1f SU each, advanced %.1f SU (supply %d of %d).",
    war:nodeName(id), TIER_TEXT[tier], a.guidedSU, a.advancedSU, math.floor(war.state.nodes[id].supply or 0),
    math.floor(war:supplyCap(id)))
end

-- taxiing: warn once if the loadout is more than the base can supply
function B.armouryCheckTaxi(p, u)
  if not XC().armoury.enforce or ok(u.inAir, u) ~= false then return end
  local v = ok(u.getVelocity, u)
  if not v or math.sqrt(v.x * v.x + v.z * v.z) < 2 then return end
  local id = ownBase(u, p.side)
  if not id then return end
  local g, a = B.classifyAmmo(u)
  local need = (a > 0 and 3) or (g > 0 and 2) or 1
  local tier = B.war:armouryTier(id)
  if B.war.ARMOURY_TIER[tier] < need and not B.ext.warned[p.unit] then
    B.ext.warned[p.unit] = true
    say(p, string.format("WARNING: %s is short of supply and only has %s.\nRe-arm before take-off or you will be recalled.",
      B.war:nodeName(id), TIER_TEXT[tier]), 20)
  end
end

function B.armouryTakeoff(p, u)
  local id = ownBase(u, p.side)
  if not id then return end
  local g, a = B.classifyAmmo(u)
  local war = B.war
  local okArm, tier, cost = war:armTakeoff(id, g, a)
  if okArm then
    if cost and cost > 0 then say(p, string.format("%s issued your weapons: %.1f SU.", war:nodeName(id), cost), 8) end
    return
  end
  if not XC().armoury.enforce then return end
  say(p, string.format("RECALLED: %s cannot supply your weapons (only %s). Pick a slot again and re-arm.",
    war:nodeName(id), TIER_TEXT[tier]), 20)
  timer.scheduleFunction(function() if alive(u) then ok(u.destroy, u) end end, nil, timer.getTime() + 2)
end

-- ===========================================================================
-- 2. Runways
-- ===========================================================================
local function segDist(p, a, b)
  local vx, vz = b.x - a.x, b.z - a.z
  local len2 = vx * vx + vz * vz
  local t = len2 > 0 and U.clamp(((p.x - a.x) * vx + (p.z - a.z) * vz) / len2, 0, 1) or 0
  return dist2D(p, { x = a.x + vx * t, z = a.z + vz * t })
end

-- distance from p to the nearest runway of airbase node id (nil: unknown)
function B.runwayDist(id, p)
  local name = B.airbases[id]
  local ab = name and ok(Airbase.getByName, name)
  local rws = ab and ab.getRunways and ok(ab.getRunways, ab)
  if not rws or #rws == 0 then return nil end
  local best
  for _, r in ipairs(rws) do
    local c, half = r.position, (r.length or 2500) / 2
    for _, crs in ipairs({ r.course or 0, -(r.course or 0) }) do
      local a = { x = c.x + math.cos(crs) * half, z = c.z + math.sin(crs) * half }
      local b = { x = c.x - math.cos(crs) * half, z = c.z - math.sin(crs) * half }
      local d = segDist(p, a, b)
      if not best or d < best then best = d end
    end
  end
  return best
end

function B.bombImpact(side, p)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns, tn = war.state.nodes[id], war.T.nodes[id]
    if tn.kind == "airbase" and ns.side ~= side and B.nodePos[id] and dist2D(p, B.nodePos[id]) < 5000 then
      local d = B.runwayDist(id, p)
      local hit = (d and d <= XC().runwayHitM) or (not d and dist2D(p, B.nodePos[id]) <= 800)
      if hit then
        local closed = war:runwayHit(id)
        local r = war.state.runways[id]
        trigger.action.outTextForCoalition(B.COAL[side], closed and string.format("Runway at %s closed!", war:nodeName(id))
          or string.format("Runway hit at %s (%d of %d).", war:nodeName(id), r and r.hits or 0, XC().runwayHits), 10)
        return id
      end
    end
  end
end

function B.trackBomb(w, side)
  local last
  local born = timer.getTime()
  local function step(_, t)
    if alive(w) then
      last = ok(w.getPoint, w) or last
      if t - born < 180 then return t + 0.5 end
      return nil
    end
    if last then ok(B.bombImpact, side, last) end
    return nil
  end
  timer.scheduleFunction(step, nil, timer.getTime() + 0.5)
end

-- ===========================================================================
-- 3. SAM sites on the move
-- ===========================================================================
function B.relocateSam(id, which)
  local war = B.war
  local ns = war.state.nodes[id]
  if not ns or not ns.sam then return false end
  local k = id .. ":" .. which
  local now = timer.getTime()
  if B.ext.moved[k] and now - B.ext.moved[k] < XC().samMoveCooldown then return false end
  local rec = B.sams[id]
  local gname = which == "pd" and (rec and rec.pd) or (rec and rec.group)
  local g = gname and ok(Group.getByName, gname)
  if not g or not ok(g.isExist, g) then return false end
  B.ext.moved[k] = now
  local lo, hi = XC().samMoveKm[1], XC().samMoveKm[2]
  local ang = war.rng:next() * 2 * math.pi
  local r = (lo + (hi - lo) * war.rng:next()) * 1000
  local dx, dz = math.cos(ang) * r, math.sin(ang) * r
  local c = B.nodePos[id]
  local u1 = ok(function() return g:getUnits()[1] end)
  local from = u1 and ok(u1.getPoint, u1) or c
  local route = { id = "Mission", params = { route = { points = {
    { x = from.x, y = from.z, type = "Turning Point", action = "Off Road", speed = 12, ETA = 0, ETA_locked = false },
    { x = c.x + dx, y = c.z + dz, type = "Turning Point", action = "Off Road", speed = 12, ETA = 0, ETA_locked = false } } } } }
  local ctl = ok(g.getController, g)
  if ctl then ok(ctl.setTask, ctl, route) end
  war:samMoved(id, dx, dz, which)
  U.log("SAM %s at %s relocating %.1f km", which, id, r / 1000)
  return true
end

-- ===========================================================================
-- 4. AI crews, prisoners
-- ===========================================================================
local baseEject = B.onEjection
function B.onEjection(u)
  if ok(u.getPlayerName, u) then return baseEject(u) end
  local g = ok(u.getGroup, u)
  local gname = g and ok(g.getName, g)
  local s = gname and B.sorties[gname]
  if not s then return end
  local war = B.war
  if war.rng:next() > XC().aiCrewChance then return end
  local pos = ok(u.getPoint, u)
  if not pos then return end
  local t = land.getSurfaceType({ x = pos.x, y = pos.z })
  if t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER then return end
  local callsign = string.format("%s crew (%s)", ok(u.getTypeName, u) or "AI", s.side:upper())
  local did = war:addDowned(s.side, { x = pos.x + 150, z = pos.z + 150 }, callsign, ok(u.getTypeName, u),
    B.nearestNodeOf(pos, s.side), nil)
  war.state.downed[did].aiRole = s.role
  B.spawnDowned(did)
  trigger.action.outTextForCoalition(B.COAL[s.side], string.format("MAYDAY - %s down. CSAR on the board.", callsign), 15)
  trigger.action.outTextForCoalition(B.COAL[U.otherSide(s.side)], string.format(
    "Enemy aircrew down (%s). SNATCH on the board - bring him in.", callsign), 15)
  B.refreshMenus()
end

local baseCsar = B.csarCheck
function B.csarCheck(p, u, pos)
  baseCsar(p, u, pos)
  local lift = (B.catalog.lift or {})[p.type]
  if not lift then return end
  local war = B.war
  local landed = ok(u.inAir, u) == false
  p.prisoners = p.prisoners or {}
  if landed then
    for did, d in pairs(war.state.downed) do
      if d.side ~= p.side and not p.prisoners[did] and dist2D(pos, { x = d.pos.x, z = d.pos.z }) <= 150 then
        p.prisoners[did] = true
        local gname = B.downedGroups[did]
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then g:destroy() end
        B.downedGroups[did] = "onboard"
        say(p, string.format("Enemy pilot %s on board. Land at a friendly base.", tostring(d.pilot)), 15)
      end
    end
    if next(p.prisoners) then
      local node = B.nearestNodeOf(pos, p.side, 3000)
      if node then
        for did in pairs(p.prisoners) do
          local d = war.state.downed[did]
          if d and war:snatch(did, p.side, node) then
            DCC.pilots:add(p.key, "prisoners", 1, p.name)
            if d.key then DCC.pilots:add(d.key, "captured", 1) end
            trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s brought in enemy pilot %s.",
              p.name, tostring(d.pilot)), 15)
          end
          p.prisoners[did] = nil
        end
      end
    end
  end
end

-- ===========================================================================
-- 5. Support on call
-- ===========================================================================
function B.newestMark(side, p)
  local list = B.ext.marks[side] or {}
  local maxAge = XC().support.markMinutes * 60
  local now, best = timer.getTime(), nil
  for _, m in ipairs(list) do
    if now - m.t <= maxAge and (not best or (m.by == p.unit and best.by ~= p.unit) or
       ((m.by == p.unit) == (best.by == p.unit) and m.t > best.t)) then best = m end
  end
  return best
end

local function rankOk(p, what)
  local need = XC().ranks[what]
  if not need then return true end
  return DCC.pilots:rankIndex(p.key) >= DCC.Pilots.rankIndexOf(need), need
end

local function cooldownLeft(side, what, minutes)
  local last = B.ext.cooldown[side][what]
  local left = last and (last + minutes * 60 - timer.getTime()) or 0
  return left > 0 and left or 0
end

function B.callArtillery(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "arty")
  if not okRank then return say(p, "Artillery on call needs the rank of " .. need .. ".") end
  local sc = XC().support
  local left = cooldownLeft(p.side, "arty", sc.artyCooldownMin)
  if left > 0 then return say(p, string.format("The guns are busy - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark(p.side, p)
  if not m then return say(p, "Put a mark on the F10 map first (your side, within 15 min).") end
  local war = B.war
  local battery
  for _, b in ipairs(war:batteries(p.side)) do
    if b.status == "up" and b.node and dist2D(B.nodePos[b.node], m.pos) <= sc.artyRangeKm * 1000 then battery = b; break end
  end
  if not battery then return say(p, string.format("No battery within %d km of the mark.", sc.artyRangeKm)) end
  if not war:paySupport(battery.node, sc.artySU) then
    return say(p, war:nodeName(battery.node) .. " has no supply for a fire mission.")
  end
  B.ext.cooldown[p.side].arty = timer.getTime()
  local rec = B.batteries and B.batteries[battery.id]
  local g = rec and ok(Group.getByName, rec.group)
  local ctl = g and ok(g.getController, g)
  if ctl then
    ok(ctl.pushTask, ctl, { id = "FireAtPoint", params = { point = { x = m.pos.x, y = m.pos.z }, radius = 150,
      expendQty = sc.artyRounds, expendQtyEnabled = true } })
  else
    -- the battery is not on the map near you: its shells are
    for i = 1, sc.artyRounds do
      timer.scheduleFunction(function()
        local a = war.rng:next() * 2 * math.pi
        local r = war.rng:next() * 150
        local x, z = m.pos.x + math.cos(a) * r, m.pos.z + math.sin(a) * r
        ok(trigger.action.explosion, { x = x, y = land.getHeight({ x = x, y = z }), z = z }, 60)
      end, nil, timer.getTime() + 20 + i * 3)
    end
  end
  trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s: fire mission from %s, %d rounds, shot - splash in 20 s.",
    p.name, war:nodeName(battery.node), sc.artyRounds), 12)
end

function B.callCas(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "cas")
  if not okRank then return say(p, "CAS on call needs the rank of " .. need .. ".") end
  local sc = XC().support
  local left = cooldownLeft(p.side, "cas", sc.casCooldownMin)
  if left > 0 then return say(p, string.format("No CAS available - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark(p.side, p)
  if not m then return say(p, "Put a mark on the F10 map first (your side, within 15 min).") end
  local node = B.nearestNodeOf(m.pos, p.side)
  if not node or not B.war:paySupport(node, sc.casSU) then return say(p, "No supply to pay for a CAS sortie.") end
  local g = B.spawnSortie(p.side, "attack", "CAS", { x = m.pos.x, y = 0, z = m.pos.z }, {})
  if not g then
    local ns = B.war.state.nodes[node]
    ns.supply = ns.supply + sc.casSU
    return say(p, "No attack aircraft available.")
  end
  B.ext.cooldown[p.side].cas = timer.getTime()
  say(p, "CAS pair inbound to your mark.", 12)
end

function B.picture(uname)
  local p = B.players[uname]
  if not p then return end
  local okRank, need = rankOk(p, "picture")
  if not okRank then return say(p, "The AWACS picture needs the rank of " .. need .. ".") end
  local u = ok(Unit.getByName, uname)
  local me = u and ok(u.getPoint, u)
  if not me then return end
  local list = {}
  for name, c in pairs(B.airContacts[p.side] or {}) do
    if c.pos then list[#list + 1] = { name = name, c = c, d = dist2D(me, c.pos) } end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local lines = { "PICTURE" }
  for i = 1, math.min(5, #list) do
    local c = list[i].c
    local brg = (math.deg(math.atan2(c.pos.z - me.z, c.pos.x - me.x)) + 360) % 360
    lines[#lines + 1] = string.format("%s  BRA %03d / %d nm / %d ft", c.type, math.floor(brg + 0.5),
      math.floor(list[i].d / 1852 + 0.5), math.floor((c.alt or 0) * 3.28 / 1000 + 0.5) * 1000)
  end
  if #list == 0 then lines[#lines + 1] = "Clean - no contacts." end
  say(p, table.concat(lines, "\n"), 20)
end

function B.showArmoury(uname)
  local p = B.players[uname]
  if not p then return end
  local u = ok(Unit.getByName, uname)
  local id = u and ownBase(u, p.side)
  if not id then id = u and B.nearestNodeOf(u:getPoint(), p.side) end
  if id then say(p, B.armouryText(id), 15) end
end

function B.buildSupportMenu(p)
  if not p.gid then return end
  if p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
  local root = missionCommands.addSubMenuForGroup(p.gid, "Support")
  p.supportMenu = root
  missionCommands.addCommandForGroup(p.gid, "Artillery on my map mark", root, B.callArtillery, p.unit)
  missionCommands.addCommandForGroup(p.gid, "CAS pair on my map mark", root, B.callCas, p.unit)
  missionCommands.addCommandForGroup(p.gid, "AWACS picture", root, B.picture, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Armoury at this base", root, B.showArmoury, p.unit)
end

local baseRegister = B.registerPlayer
function B.registerPlayer(u)
  local p = baseRegister(u)
  if p then
    B.buildSupportMenu(p)
    local id = ownBase(u, p.side)
    if id then say(p, B.armouryText(id), 10) end
  end
  return p
end

local baseClear = B.clearPlayer
function B.clearPlayer(uname, how)
  local p = B.players[uname]
  if p and p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
  if p and p.prisoners then
    for did in pairs(p.prisoners) do if B.downedGroups[did] == "onboard" then B.downedGroups[did] = nil end end
  end
  B.ext.warned[uname] = nil
  return baseClear(uname, how)
end

-- ===========================================================================
-- 13 + 14. Scaling, rank-gated FARP spawns, runway slot guard
-- ===========================================================================
function B.playerCounts()
  local n = { blue = 0, red = 0 }
  for _, p in pairs(B.players) do n[p.side] = (n[p.side] or 0) + 1 end
  return n
end

local basePlanPackages = B.planPackages
function B.planPackages()
  basePlanPackages()
  if #B.playerPositions() == 0 then return end
  local war, sc = B.war, XC().scaling
  local n = B.playerCounts()
  local per = DCC.config.tickSeconds / 60
  for _, side in ipairs({ "blue", "red" }) do
    local diff = (n[U.otherSide(side)] or 0) - (n[side] or 0)
    if diff > 0 and war:aiAttackAllowed() then
      local extra = math.min(sc.airMax, sc.airPerPlayer * diff)
      if war.rng:next() < per / DCC.config.air.packageMinutes * extra then B.launchStrike(side) end
    end
  end
end

local baseBirth = B.onBirth
function B.onBirth(unit)
  baseBirth(unit)
  if not alive(unit) or not ok(unit.getPlayerName, unit) then return end
  local war, side = B.war, sideOf(unit)
  local pos = ok(unit.getPoint, unit)
  if not side or not pos then return end
  local id = B.nearestNodeOf(pos, side, 5000)
  if not id then return end
  local heli = isHeli(unit)
  local reason
  if not heli and war:runwayClosed(id) then
    reason = string.format("The runway at %s is closed. Pick a helicopter, or another base.", war:nodeName(id))
  elseif heli and war.T.nodes[id].kind == "town" and war:farpAt(id) then
    local name = ok(unit.getPlayerName, unit)
    local key = (B.players[unit:getName()] or {}).key or name
    local need = XC().ranks.farp
    if need and DCC.pilots:rankIndex(key) < DCC.Pilots.rankIndexOf(need) then
      reason = string.format("FARP spawns need the rank of %s. Spawn at an airbase.", need)
    end
  end
  if reason then
    trigger.action.outTextForUnit(unit:getID(), reason, 20)
    B.clearPlayer(unit:getName(), "left")
    ok(unit.destroy, unit)
  end
end

local baseOpsTick = B.opsTick
function B.opsTick()
  local n = B.playerCounts()
  B.war:setPlayers(n.blue, n.red)
  baseOpsTick()
end

-- ===========================================================================
-- 15. Wrecks
-- ===========================================================================
local function wreckCategory(u)
  if ok(u.hasAttribute, u, "Infantry") then return nil end
  if ok(u.hasAttribute, u, "Air Defence") then return "Air Defence" end
  if ok(u.hasAttribute, u, "Armored vehicles") then return "Armor" end
  return "Unarmed"
end

function B.recordWreck(o)
  local war = B.war
  local cat = ok(Object.getCategory, o)
  local pos = ok(o.getPoint, o)
  if not pos then return end
  if cat == Object.Category.UNIT then
    local d = ok(o.getDesc, o)
    if not d or d.category ~= (Unit.Category and Unit.Category.GROUND_UNIT or 2) then return end
    local wc = wreckCategory(o)
    if not wc then return end
    local p = ok(o.getPosition, o)
    local hdg = p and p.x and math.atan2(p.x.z, p.x.x) or 0
    war:addWreck({ type = ok(o.getTypeName, o), cat = wc, x = pos.x, z = pos.z, hdg = hdg, coal = ok(o.getCoalition, o) })
  elseif cat == (Object.Category.SCENERY or 5) and XC().wrecks.scenery then
    war:addWreck({ scenery = true, x = pos.x, z = pos.z })
  end
end

-- at start: put them back
function B.restoreWrecks()
  local war = B.war
  for _, w in ipairs(war.state.wrecks or {}) do
    if w.scenery then
      ok(trigger.action.explosion, { x = w.x, y = land.getHeight({ x = w.x, y = w.z }), z = w.z }, 120)
    elseif w.type then
      B.ext.wreckN = B.ext.wreckN + 1
      local country = B.countryId(w.coal == 2 and "blue" or "red")
      ok(coalition.addStaticObject, country, { name = "DCC_WRECK_" .. B.ext.wreckN, type = w.type, category = w.cat,
        x = w.x, y = w.z, heading = w.hdg or 0, dead = true })
    end
  end
end

-- ===========================================================================
-- Events and wiring
-- ===========================================================================
local MARK_ADDED, MARK_CHANGE = 25, 26

local baseOps = B.onOpsEvent
function B.onOpsEvent(e)
  baseOps(e)
  local ev, u = world.event, e.initiator
  if e.id == (ev.S_EVENT_MARK_ADDED or MARK_ADDED) or e.id == (ev.S_EVENT_MARK_CHANGE or MARK_CHANGE) then
    local side = sideOfCoal(e.coalition)
    if side and e.pos then
      local list = B.ext.marks[side] or {}
      B.ext.marks[side] = list
      list[#list + 1] = { pos = { x = e.pos.x, z = e.pos.z }, t = timer.getTime(), text = e.text,
                          by = u and ok(u.getName, u) }
      while #list > 20 do table.remove(list, 1) end
    end
  elseif e.id == ev.S_EVENT_TAKEOFF then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p then B.armouryTakeoff(p, u) end
  elseif e.id == ev.S_EVENT_DEAD then
    if u then ok(B.recordWreck, u) end
  end
end

local baseShot = B.onShot
function B.onShot(e)
  if baseShot then baseShot(e) end
  local w, s = e.weapon, e.initiator
  local d = w and ok(w.getDesc, w)
  local side = s and sideOf(s)
  if d and side and d.category == W_BOMB then B.trackBomb(w, side) end
  -- SAMs that fired move
  local sname = s and ok(s.getName, s)
  if sname then
    local pd = sname:match("^DCC_SAMPD_(.-)_%d+$")
    local site = sname:match("^DCC_SAM_(.-)_[rls]%d+$")
    if pd then
      timer.scheduleFunction(function() ok(B.relocateSam, pd, "pd") end, nil, timer.getTime() + 20)
    elseif site then
      local spec = B.catalog.sam and B.catalog.sam[B.war.state.nodes[site].side]
      if spec and spec.mobile then
        timer.scheduleFunction(function() ok(B.relocateSam, site, "site") end, nil, timer.getTime() + 30)
      end
    end
  end
  -- a HARM at a site: mobile sites and its point defence scoot
  if d and d.guidance == G_RADAR_P then
    local tgt = ok(w.getTarget, w)
    local tname = tgt and ok(tgt.getName, tgt)
    local id = tname and (tname:match("^DCC_SAM_(.-)_[rls]%d+$") or tname:match("^DCC_SAMPD_(.-)_%d+$"))
    if id then
      local spec = B.catalog.sam and B.catalog.sam[B.war.state.nodes[id].side]
      if spec and spec.mobile then ok(B.relocateSam, id, "site") end
      ok(B.relocateSam, id, "pd")
    end
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  for _, p in pairs(B.players) do
    local u = ok(Unit.getByName, p.unit)
    if alive(u) then ok(B.armouryCheckTaxi, p, u) end
  end
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.ext = { warned = {}, tracked = {}, moved = {}, marks = {}, cooldown = { blue = {}, red = {} }, wreckN = 0 }
  B.restoreWrecks()
end

B.EFFECT.RUNWAY = "Put 3 bombs on the runway (centre line, 60 m). The airfield closes for 4 h: no airlifts, no fixed-wing spawns."
B.EFFECT.SNATCH = "Land within 150 m of the enemy pilot, then at a friendly base. He talks: your side learns about his base."

end

-- >>> src/dcc_dcs_ext_ground.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more ground war.
-- Load after dcc_dcs_ext_air.lua.
-- ----------------------------------------------------------------------------
--   Engineers  - CTLD "Bridge kit" crates: 2 unpacked within 1.5 km of a
--                downed bridge reopen its road.
--   FARP kit   - one heavy CTLD crate (3 t, Chinook / Mi-8 only, 30 SU):
--                set down or unpacked within 3 km of an own town, it makes
--                the town a FARP at once (the FARP mission's quick way).
--   Minefields - a CTLD minefield laid within 1.5 km of a road mines it for
--                24 h: enemy columns slow down and take losses.
--   Industry   - factories, power plants and refineries behind each side's
--                lines, on the map at all times (ruins while destroyed).
--   Partisans  - cells near occupied towns, on the map when the town is live;
--                wiped out = COIN done.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function segDist(p, a, b)
  local vx, vz = b.x - a.x, b.z - a.z
  local len2 = vx * vx + vz * vz
  local t = len2 > 0 and U.clamp(((p.x - a.x) * vx + (p.z - a.z) * vz) / len2, 0, 1) or 0
  return dist2D(p, { x = a.x + vx * t, z = a.z + vz * t })
end

B.industry, B.partisanGroups = {}, {}

-- ===========================================================================
-- 6 + 7. Engineers and minefields (CTLD)
-- ===========================================================================
-- the road (a, b) whose straight line passes nearest to p, within maxM
function B.roadNear(p, maxM)
  local war, best, bestD = B.war, nil, nil
  for _, a in ipairs(war.T.order) do
    for b in pairs(war.T.nodes[a].nb) do
      if a < b and B.nodePos[a] and B.nodePos[b] then
        local d = segDist(p, B.nodePos[a], B.nodePos[b])
        if d <= maxM and (not bestD or d < bestD) then best, bestD = { a = a, b = b }, d end
      end
    end
  end
  return best
end

-- a closed road whose bridge is near p
function B.downedBridgeNear(p, maxM)
  local war = B.war
  for _, br in ipairs(war.bridges or {}) do
    if br.pos and war:roadClosed(br.a, br.b) and dist2D(p, br.pos) <= maxM then return br end
  end
end

function B.bridgeKitUnpacked(crate, unpacker)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local p = crate.position
  local side = sideOfCoal(crate.coalition)
  local function tell(text) trigger.action.outTextForCoalition(crate.coalition, text, 12) end
  local br = p and B.downedBridgeNear(p, XC().bridgeKitKm * 1000)
  if not br then return tell("Bridge kits go next to a destroyed bridge (within 1.5 km).") end
  local kits = {}
  for _, c in ipairs(ok(cm.getCratesInRange, cm, p, 150) or {}) do
    if c.descriptor and c.descriptor.dccBridge and c.coalition == crate.coalition then kits[#kits + 1] = c end
  end
  local need = XC().bridgeKitCrates
  if #kits < need then return tell(string.format("%d of %d bridge kits here - bring more.", #kits, need)) end
  for i = 1, need do ok(cm.destroyCrate, cm, kits[i].crateName) end
  war:repairBridge(br.a, br.b, side)
  tell(string.format("Engineers bridged the road %s - %s.", war:nodeName(br.a), war:nodeName(br.b)))
end

-- the own town nearest to p within maxM that can take a FARP
function B.farpTownNear(p, side, maxM)
  local war, best, bestD = B.war, nil, nil
  for _, id in ipairs(war.T.order) do
    local np = B.nodePos[id]
    if np and war.state.nodes[id].side == side and war:canHaveFarp(id) then
      local d = dist2D(p, np)
      if d <= maxM and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  return best
end

-- A FARP kit on the ground (unloaded, sling-dropped or unpacked).
-- loud = tell the crew why nothing happened. Returns true when it was used.
function B.farpKitDown(crate, pos, loud)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local side = sideOfCoal(crate.coalition)
  local function tell(text) trigger.action.outTextForCoalition(crate.coalition, text, 12) end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().farpKit.km
  local town = B.farpTownNear(pos, side, km * 1000)
  if not town then
    if loud then tell(string.format("A FARP kit goes down within %d km of a friendly town.", km)) end
    return false
  end
  if war:farpAt(town) then
    local max = DCC.config.world.farpStock
    if war:farpStock(town) >= max then
      if loud then tell("The FARP at " .. war:nodeName(town) .. " is full - take the kit somewhere else.") end
      return false
    end
    war:deliverCrate(side, town, max - war:farpStock(town))   -- a kit refills a FARP completely
    ok(cm.destroyCrate, cm, crate.crateName)
    tell(string.format("FARP kit delivered: the FARP at %s is fully stocked again.", war:nodeName(town)))
    return true
  end
  if not war:buildFarp(town, side, "kit") then return false end
  ok(cm.destroyCrate, cm, crate.crateName)
  tell(string.format("FARP kit delivered: %s is a FARP now - rearm, refuel and helicopter spawns.",
    war:nodeName(town)))
  return true
end

if B.ctldCrateDown then
  local baseDown = B.ctldCrateDown
  function B.ctldCrateDown(crate, pos)
    if crate and crate.descriptor and crate.descriptor.dccFarp then
      local s, r = pcall(B.farpKitDown, crate, pos, true)
      if not s then U.log("ERROR farp kit: %s", tostring(r)) end
      return s and r
    end
    return baseDown(crate, pos)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local fk = XC().farpKit
    local only = {}
    for _, t in ipairs(fk.types) do only[t] = true end
    crates["Engineering"] = { { unit = "DCC_BRIDGEKIT", desc = "Bridge kit", weight = 1500.01, cratesRequired = 1,
                                dccBridge = true },
                              { unit = "DCC_FARPKIT", desc = "FARP kit (Chinook / Mi-8)", weight = fk.weight,
                                cratesRequired = 1, dccFarp = true, dccCharge = math.ceil(fk.su / DCC.config.ctld.crateSU),
                                dccOnly = only,
                                dccOnlyMsg = "A FARP kit weighs 3 t - only a Chinook or a Mi-8 can lift it." } }
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

if B.ctldHook then
  local baseHook = B.ctldHook
  function B.ctldHook()
    local already = B.ctld.hooked
    baseHook()
    if already or B.ctld.extHooked then return end
    B.ctld.extHooked = true
    local CM = CTLDCrateManager
    local baseUnpack = CM.unpackCrate
    CM.unpackCrate = function(self, crateName, unpacker)
      local crate = self.crates and self.crates[crateName]
      if crate and crate.descriptor and crate.descriptor.dccBridge then
        if B.war then ok(B.bridgeKitUnpacked, crate, unpacker) end
        return
      end
      if crate and crate.descriptor and crate.descriptor.dccFarp then
        if B.war then ok(B.farpKitDown, crate, crate.position, true) end
        return
      end
      return baseUnpack(self, crateName, unpacker)
    end
    local baseSU = CM._spawnUnpacked
    if baseSU then
      CM._spawnUnpacked = function(self, desc, ...)
        if desc and (desc.dccBridge or desc.dccFarp) then return nil end
        return baseSU(self, desc, ...)
      end
    end
    -- minefields: CTLD's mineField scene
    local sm = CTLDSceneManager and CTLDSceneManager.getInstance()
    local model = sm and sm._models and sm._models.mineField
    local step = model and model.steps and model.steps[1]
    if step and step.func then
      local baseFunc = step.func
      step.func = function(ctx)
        local okRun, r1, r2 = pcall(baseFunc, ctx)
        if not okRun then U.log("ERROR ctld minefield: %s", tostring(r1)); r1, r2 = false, nil end
        local u = ctx and ctx.unit
        local pos = u and ok(u.getPoint, u)
        local side = u and sideOfCoal(ok(u.getCoalition, u))
        if B.war and pos and side then
          local road = B.roadNear(pos, XC().mineRoadKm * 1000)
          if road then B.war:mineRoad(road.a, road.b, side) end
        end
        return r1, r2
      end
    end
  end
end

-- ===========================================================================
-- 9. Industry
-- ===========================================================================
local DEFAULT_IND = {
  factory = { { "Workshop A", "Fortifications" }, { "Tech combine", "Fortifications" }, { "Workshop A", "Fortifications" } },
  ["power plant"] = { { "Tech combine", "Fortifications" }, { "Chemical tank A", "Fortifications" },
                      { "Chemical tank A", "Fortifications" } },
  refinery = { { "Fuel tank", "Fortifications" }, { "Fuel tank", "Fortifications" }, { "Chemical tank A", "Fortifications" } },
}

local function industrySpot(s, k, i)
  local c = B.nodePos[s.node]
  local ang = (i * 2.4) + k * 0.15
  local r = 3200 + k * 70
  return { x = c.x + math.cos(ang) * r, z = c.z + math.sin(ang) * r }
end

function B.reconcileIndustry()
  local war = B.war
  for _, side in ipairs({ "blue", "red" }) do
    for i, s in ipairs(war:industrySites(side)) do
      local rec = B.industry[s.id]
      local state = s.status == "up" and "up" or "ruin"
      -- poll a standing site
      if rec and rec.state == "up" and s.status == "up" then
        local dead = 0
        for _, name in ipairs(rec.names) do
          local o = ok(StaticObject.getByName, name)
          if not o or not ok(o.isExist, o) or (ok(o.getLife, o) or 0) < 1 then dead = dead + 1 end
        end
        if dead >= 2 then
          war:industryHit(s.id)
          state = "ruin"
        end
      end
      if rec and rec.state ~= state then
        for _, name in ipairs(rec.names) do
          local o = ok(StaticObject.getByName, name)
          if o and ok(o.isExist, o) then ok(o.destroy, o) end
        end
        B.industry[s.id], rec = nil, nil
      end
      if not rec and B.nodePos[s.node] then
        rec = { state = state, names = {} }
        B.industry[s.id] = rec
        B.indN = (B.indN or 0) + 1
        local parts = (B.catalog.industry or DEFAULT_IND)[s.kind] or DEFAULT_IND.factory
        for k, part in ipairs(parts) do
          local sp = industrySpot(s, k, i)
          local name = string.format("DCC_IND_%s_%d_%d", s.id, k, B.indN)
          local okAdd = pcall(coalition.addStaticObject, B.countryId(side), { name = name, type = part[1],
            category = part[2], x = sp.x, y = sp.z, heading = 0, dead = state == "ruin" })
          if okAdd then rec.names[#rec.names + 1] = name end
        end
      end
    end
  end
end

-- ===========================================================================
-- 10. Partisans
-- ===========================================================================
function B.reconcilePartisans()
  local war = B.war
  for cid, gname in pairs(B.partisanGroups) do
    local c = war.state.partisans[cid]
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if ok(u.isExist, u) and (ok(u.getLife, u) or 0) >= 1 then n = n + 1 end end
    end
    if c and n == 0 then
      war:partisanKilled(cid, war.state.nodes[c.node].side)
      B.partisanGroups[cid] = nil
    elseif not c or not B.liveNodes[c.node] then
      if g and ok(g.isExist, g) then ok(g.destroy, g) end
      B.partisanGroups[cid] = nil
    end
  end
  for cid, c in pairs(war.state.partisans) do
    if not B.partisanGroups[cid] and B.liveNodes[c.node] and B.nodePos[c.node] then
      local list = (B.catalog.partisans or {})
      local types = {}
      for _, t in ipairs(list.units or {}) do if B.validType(t) then types[#types + 1] = t end end
      if #types == 0 then
        for _, t in ipairs(list.fallback or { "Infantry AK" }) do if B.validType(t) then types[#types + 1] = t end end
      end
      local c0 = B.nodePos[c.node]
      local ang = (tonumber(cid:match("%d+")) or 1) * 1.7
      local cx, cz = c0.x + math.cos(ang) * 2200, c0.z + math.sin(ang) * 2200
      local units = {}
      for i, t in ipairs(types) do
        units[i] = { name = "DCC_PZ_" .. cid .. "_" .. i, type = t, skill = "Average", x = cx + i * 12, y = cz + (i % 2) * 15,
                     heading = 0, playerCanDrive = false }
      end
      local gname = "DCC_PZ_" .. cid
      if #units > 0 and pcall(coalition.addGroup, B.countryId(c.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = cx, y = cz, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
        B.partisanGroups[cid] = gname
      end
    end
  end
end

-- ===========================================================================
-- Wiring
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  ok(B.reconcileIndustry)
  ok(B.reconcilePartisans)
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.industry, B.partisanGroups = {}, {}
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  local war = B.war
  if m.type == "INDUSTRY" then
    for _, side in ipairs({ "blue", "red" }) do
      for i, s in ipairs(war:industrySites(side)) do
        if s.id == m.target then return industrySpot(s, 2, i) end
      end
    end
  elseif m.type == "COIN" then
    local gname = B.partisanGroups[m.target]
    local g = gname and ok(Group.getByName, gname)
    local u = g and ok(function() return g:getUnits()[1] end)
    if u and ok(u.isExist, u) then return u:getPoint() end
  elseif m.type == "SNATCH" then
    local d = war.state.downed[m.target]
    return d and { x = d.pos.x, y = 0, z = d.pos.z }
  end
  return baseMissionPos(m)
end

B.EFFECT.INDUSTRY = "Destroy 2 of its 3 buildings. Each site down cuts that side's production by 12 % until rebuilt (a day, 80 SU)."
B.EFFECT.COIN = "Wipe out the partisan cell near the town. Partisans sabotage supply and ambush columns."

-- New events on screen (both sides) and on the public feed
for _, k in ipairs({ "runway_closed", "industry_hit", "snatched", "partisan_ambush", "partisans_killed" }) do
  B.PUBLIC_KINDS[k] = true
end
-- "all": everyone sees it; "own": only the side it happened to
local LOUD = { runway_closed = "all", runway_open = "own", industry_hit = "all", industry_up = "own", snatched = "all",
               partisans = "all", partisans_killed = "all", partisans_swept = "own", partisan_ambush = "all",
               mined = "own", mine_hit = "all", ctld_vehicle = "own", ctld_aa = "own", helilift = "own",
               farp_dry = "own" }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    local who = LOUD[ev.kind]
    if who == "all" then trigger.action.outText(ev.text, 15)
    elseif who == "own" and ev.side and B.COAL[ev.side] then
      trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 12)
    end
  end
end

end

-- >>> src/dcc_dcs_ext2.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: more air and ground war (v0.18).
-- Load after dcc_dcs_ext_ground.lua.
-- ----------------------------------------------------------------------------
--   2. HVA      : no tanker / AWACS for 2 h after one is lost; enemy fighters
--                 hunt them (HUNT sorties); HVAESCORT = 20 min within 40 km.
--   3. Packages : PKGESCORT = be within 25 km of the target; package bonus.
--   4. Aces     : 3 air kills in one sortie and the enemy sends fighters at you.
--   5. Artillery: shell impacts at a shelled base when players are near.
--   6. Convoys  : a second ambush further down the road; live, unescorted
--                 front convoys near players can be ambushed too.
--   7 + 9. Pick-ups: prisoners / wounded stand at the base; land, pick up,
--                 fly them to an own airbase or depot.
--   8. Heavy    : CTLD > Engineering > Generator / Runway repair kit
--                 (Chinook / Mi-8 only).
--   10. CSAR    : enemy search parties walk / drive to downed pilots.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext2 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function landed(u) return alive(u) and ok(u.inAir, u) == false end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function destroyGroup(gname)
  local g = gname and ok(Group.getByName, gname)
  if g and ok(g.isExist, g) then g:destroy() end
end
local function online() return #B.playerPositions() > 0 end
local function say(p, text, t) if p and p.gid then trigger.action.outTextForGroup(p.gid, text, t or 12) end end
local function cat() return B.catalog or {} end
local function wpos(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end

local function fresh()
  return { hunts = {}, amb2 = {}, liveAmb = {}, liveTried = {}, pickGroups = {}, search = {} }
end
B.x2 = fresh()

-- ===========================================================================
-- 2. HVA: grounded after a loss, hunted, escorted
-- ===========================================================================
if B.spawnAsset then
  local baseSpawnAsset = B.spawnAsset
  function B.spawnAsset(side, kind)
    if B.war:hvaGrounded(side, kind) then return nil end
    return baseSpawnAsset(side, kind)
  end
end
if B.spawnAwacs then
  local baseSpawnAwacs = B.spawnAwacs
  function B.spawnAwacs(side)
    if B.war:hvaGrounded(side, "awacs") then return nil end
    return baseSpawnAwacs(side)
  end
end

function B.hvaGroup(side, kind)
  local rec = (kind == "awacs") and (B.awacs or {})[side] or ((B.assets or {})[side] or {})[kind]
  return rec and rec.group
end

local HVA_NAME = { tanker = "tanker", awacs = "AWACS" }

function B.planHunts()
  if not online() then return end
  local war = B.war
  local per = DCC.config.tickSeconds / 60
  for _, hunter in ipairs({ "blue", "red" }) do
    local prey = otherSide(hunter)
    for _, kind in ipairs({ "awacs", "tanker" }) do
      local key = prey .. "|" .. kind
      local gname = B.hvaGroup(prey, kind)
      local u = unitsOf(gname)[1]
      if u and not B.x2.hunts[key] and war.rng:next() < per / XC().huntMinutes then
        local g = ok(u.getGroup, u)
        local gid = g and ok(g.getID, g)
        local s = gid and B.spawnSortie(hunter, "fighter", "HUNT", u:getPoint(), { groupId = gid, life = 2700 })
        if s then
          B.x2.hunts[key] = s
          war:setHvaThreat(prey, kind, true)
          trigger.action.outTextForCoalition(B.COAL[prey], string.format(
            "Command: %s fighters are going after our %s - escort it! (Missions > HVAESCORT)", hunter:upper(),
            HVA_NAME[kind]), 20)
          B.refreshMenus()
        end
      end
    end
  end
end

function B.pollHunts()
  for key, gname in pairs(B.x2.hunts) do
    local prey, kind = key:match("^(.-)|(.+)$")
    if #unitsOf(gname) == 0 or not B.hvaGroup(prey, kind) then
      B.x2.hunts[key] = nil
      B.war:setHvaThreat(prey, kind, false)
    end
  end
end

-- ===========================================================================
-- 3 + 2. Detection for the new escort missions (every 10 s)
-- ===========================================================================
local baseDetect = B.detect
function B.detect()
  baseDetect()
  local war = B.war
  for uname, p in pairs(B.players) do
    local m = p.mission and war.state.missions[p.mission]
    local u = ok(Unit.getByName, uname)
    if m and m.status == "open" and alive(u) then
      local pos = u:getPoint()
      if m.type == "HVAESCORT" then
        local side, kind = m.target:match("^(.-)|(.+)$")
        local a = unitsOf(B.hvaGroup(side, kind))[1]
        if a and dist2D(pos, a:getPoint()) <= XC().hvaEscortKm * 1000 then
          p.hvaSeconds = (p.hvaSeconds or 0) + 10
          if p.hvaSeconds >= XC().hvaEscortMin * 60 then
            p.hvaSeconds = 0
            war:completeMission(m.id, true)
            say(p, string.format("Escort complete - the %s is safe.", HVA_NAME[kind]), 15)
          end
        end
      elseif m.type == "PKGESCORT" then
        local tp = m.node and B.nodePos[m.node]
        if tp and dist2D(pos, tp) <= XC().pkgEscortKm * 1000 and not m.escortOk then
          m.escortOk = true
          say(p, "On station with the strike package - stay until the target is hit.", 10)
        end
      end
    end
  end
end

if B.missionPos then
  local baseMissionPos = B.missionPos
  function B.missionPos(m)
    if m.type == "HVAESCORT" then
      local side, kind = m.target:match("^(.-)|(.+)$")
      local a = unitsOf(B.hvaGroup(side, kind))[1]
      return a and a:getPoint()
    elseif m.type == "MEDEVAC" or m.type == "POW" then
      local q = B.war.state.pickups[m.target]
      return q and B.pickupPos(q)
    end
    return baseMissionPos(m)
  end
end

-- ===========================================================================
-- 4. Aces get hunted
-- ===========================================================================
if B.onKill then
  local baseKill = B.onKill
  function B.onKill(e)
    baseKill(e)
    local shooter, tgt = e.initiator, e.target
    local p = shooter and B.players[ok(shooter.getName, shooter) or ""]
    if not p or not tgt then return end
    local d = ok(tgt.getDesc, tgt)
    if not d or (d.category ~= Unit.Category.AIRPLANE and d.category ~= Unit.Category.HELICOPTER) then return end
    if sideOfCoal(ok(tgt.getCoalition, tgt)) == p.side then return end
    p.airKills = (p.airKills or 0) + 1
    local now = timer.getTime()
    if p.airKills >= XC().aceKills and (not p.huntedAt or now - p.huntedAt >= XC().aceCooldownMin * 60) then
      local g = ok(shooter.getGroup, shooter)
      local gid = g and ok(g.getID, g)
      local s = gid and B.spawnSortie(otherSide(p.side), "fighter", "HUNT", shooter:getPoint(),
        { groupId = gid, life = 2400 })
      if s then
        p.huntedAt = now
        say(p, string.format("%d kills - the enemy has noticed you. Fighters are being vectored onto you.",
          p.airKills), 20)
      end
    end
  end
end

-- ===========================================================================
-- 5. Artillery impacts (only where someone can see them)
-- ===========================================================================
function B.shellImpacts()
  local war = B.war
  for _, side in ipairs({ "blue", "red" }) do
    for _, b in ipairs(war:batteries(side)) do
      local t = b.shelling and B.nodePos[b.shelling]
      local near = false
      if t then
        for _, pp in ipairs(B.playerPositions()) do
          if dist2D(pp, t) <= XC().shellKm * 1000 then near = true end
        end
      end
      if near then
        for i = 1, 6 do
          local a, r = math.random() * 2 * math.pi, 300 + math.random() * 600
          local pt = { x = t.x + math.cos(a) * r, z = t.z + math.sin(a) * r }
          timer.scheduleFunction(function()
            ok(trigger.action.explosion, wpos(pt), 8)
          end, nil, timer.getTime() + 5 + i * 35 + math.random() * 20)
        end
      end
    end
  end
end

-- ===========================================================================
-- 6. Convoys: a second ambush, and ambushes on live convoys
-- ===========================================================================
local function ambushGroup(gname, side, x, z)
  local types = (cat().ambush or {})[side]
  if not types then return nil end
  local units = {}
  for i, ty in ipairs(types) do
    if B.validType(ty) then
      units[#units + 1] = { name = gname .. "_" .. i, type = ty, skill = "Average", x = x + i * 15, y = z + i * 10,
                            heading = 0 }
    end
  end
  if #units == 0 then return nil end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false,
      speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(side), Group.Category.GROUND, data) then return gname end
end

local function roadPoint(mv, t)
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  if not a or not b then return nil end
  return a.x + (b.x - a.x) * t - 250, a.z + (b.z - a.z) * t + 250
end

if B.spawnAmbush then
  local baseAmbush = B.spawnAmbush
  function B.spawnAmbush(m)
    local had = B.ambushes[m.id]
    baseAmbush(m)
    if had or B.x2.amb2[m.id] then return end
    local mv = B.war.state.moves[m.target]
    if not mv then return end
    local t = math.min(0.92, math.max(mv.progress + 0.25, 0.6) + XC().secondAmbushAt)
    if t <= math.max(mv.progress + 0.25, 0.6) + 0.05 then return end
    local x, z = roadPoint(mv, t)
    if x then B.x2.amb2[m.id] = ambushGroup("DCC_AMB2_" .. m.id, otherSide(m.side), x, z) end
  end
end

if B.cleanAmbushes then
  local baseClean = B.cleanAmbushes
  function B.cleanAmbushes()
    baseClean()
    for mid, gname in pairs(B.x2.amb2) do
      local m = B.war.state.missions[mid]
      if not m or m.status ~= "open" then destroyGroup(gname); B.x2.amb2[mid] = nil end
    end
    for mid, gname in pairs(B.x2.liveAmb) do
      if not B.war.state.moves[mid] then destroyGroup(gname); B.x2.liveAmb[mid] = nil end
    end
  end
end

function B.liveAmbushes()
  local war = B.war
  for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
    local mv = war.state.moves[mid]
    if mv.kind == "convoy" and mv.front and mv.status == "moving" and not mv.escorted and not B.x2.liveTried[mid]
       and not war:onSea(mv) and war:isMoveLive(mv) and mv.progress < 0.7 then
      local pos = B.missionPos({ type = "CONVOY", target = mid })
      local near = false
      if pos then
        for _, pp in ipairs(B.playerPositions()) do if dist2D(pp, pos) <= 30000 then near = true end end
      end
      if near then
        B.x2.liveTried[mid] = true
        if war.rng:next() < XC().liveAmbushChance then
          local x, z = roadPoint(mv, math.min(0.9, mv.progress + 0.2))
          local g = x and ambushGroup("DCC_AMBL_" .. mid, otherSide(mv.side), x, z)
          if g then
            B.x2.liveAmb[mid] = g
            trigger.action.outTextForCoalition(B.COAL[mv.side], string.format(
              "Command: our convoy to %s reports enemy movement ahead on the road.", war:nodeName(mv.to)), 15)
          end
        end
      end
    end
  end
  for mid in pairs(B.x2.liveTried) do if not war.state.moves[mid] then B.x2.liveTried[mid] = nil end end
end

-- ===========================================================================
-- 7 + 9. Pick-ups: prisoners and wounded
-- ===========================================================================
function B.pickupPos(q)
  local p = B.nodePos[q.node]
  return p and { x = p.x + 600, y = 0, z = p.z + 300 }
end

function B.reconcilePickups()
  local war = B.war
  for qid, gname in pairs(B.x2.pickGroups) do
    local q = war.state.pickups[qid]
    if not q or q.onboard then destroyGroup(gname); B.x2.pickGroups[qid] = nil end
  end
  for _, qid in ipairs(U.sortedKeys(war.state.pickups)) do
    local q = war.state.pickups[qid]
    if not q.onboard and not B.x2.pickGroups[qid] then
      local p = B.pickupPos(q)
      local t = (cat().downedPilot or {})[q.side] or "Soldier M4"
      local gname = "DCC_PICK_" .. qid
      local units = {}
      for i = 1, math.min(q.n, 4) do
        units[i] = { name = gname .. "_" .. i, type = t, skill = "Average", x = p.x + i * 4, y = p.z + (i % 2) * 4,
                     heading = 0 }
      end
      if p and #units > 0 and pcall(coalition.addGroup, B.countryId(q.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = p.x, y = p.z, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }) then
        B.x2.pickGroups[qid] = gname
        local g = ok(Group.getByName, gname)
        local c = g and ok(g.getController, g)
        if c and AI then ok(c.setOption, c, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD) end
      end
    end
  end
end

function B.pickupCheck(p, u, pos)
  local war = B.war
  p.x2pick = p.x2pick or {}
  if landed(u) then
    for _, qid in ipairs(U.sortedKeys(war.state.pickups)) do
      local q = war.state.pickups[qid]
      local qp = B.pickupPos(q)
      if q.side == p.side and not q.onboard and qp and dist2D(pos, qp) <= XC().pickupLandM then
        if war:pickupLoaded(qid) then
          p.x2pick[qid] = true
          destroyGroup(B.x2.pickGroups[qid]); B.x2.pickGroups[qid] = nil
          say(p, string.format("%d %s on board. Fly them to a friendly airbase or depot.", q.n,
            q.kind == "pow" and "prisoners" or "wounded"), 15)
        end
      end
    end
  end
  if next(p.x2pick) and landed(u) then
    local node = B.nearestNodeOf(pos, p.side, 3000)
    if node then
      for qid in pairs(p.x2pick) do
        local q = war.state.pickups[qid]
        if not q then
          p.x2pick[qid] = nil
        elseif war:pickupDropOk(q, node) then
          local kind = q.kind
          if war:pickupDelivered(qid, node) then
            DCC.pilots:add(p.key, kind == "pow" and "pows" or "medevacs", 1, p.name)
            say(p, string.format("%s delivered to %s.", kind == "pow" and "Prisoners" or "Wounded",
              war:nodeName(node)), 15)
            B.refreshMenus()
          end
          p.x2pick[qid] = nil
        elseif node ~= q.node and not p.x2warned then
          p.x2warned = true
          say(p, "Take them to an airbase or depot.", 10)
        end
      end
    end
  end
end

if B.csarCheck then
  local baseCsar = B.csarCheck
  function B.csarCheck(p, u, pos)
    baseCsar(p, u, pos)
    if (cat().lift or {})[p.type] then B.pickupCheck(p, u, pos) end
  end
end

if B.clearPlayer then
  local baseClear = B.clearPlayer
  function B.clearPlayer(uname, how)
    local p = B.players[uname]
    if p and p.x2pick then
      for qid in pairs(p.x2pick) do
        local q = B.war.state.pickups[qid]
        if q then
          if how == "lost" then B.war:pickupLost(qid) else q.onboard = nil end   -- left the slot: they wait again
        end
      end
      p.x2pick = {}
    end
    return baseClear(uname, how)
  end
end

-- ===========================================================================
-- 8. Heavy sling loads (CTLD)
-- ===========================================================================
function B.heavyDown(crate, pos, loud)
  local war, cm = B.war, CTLDCrateManager.getInstance()
  local side = sideOfCoal(crate.coalition)
  local what = crate.descriptor.dccHeavy
  local function tell(text) if loud then trigger.action.outTextForCoalition(crate.coalition, text, 12) end end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().heavyKm
  local done
  if what == "generator" then
    local node = B.nearestNodeOf(pos, side, km * 1000)
    if not node then tell(string.format("Generators go down within %d km of a friendly base.", km)); return false end
    done = war:installGenerator(node, side)
  else
    local node
    for _, id in ipairs(war.T.order) do
      local np = B.nodePos[id]
      if np and war.state.nodes[id].side == side and war:runwayClosed(id) and dist2D(pos, np) <= km * 1000 then
        node = id
      end
    end
    if not node then tell(string.format("A runway repair kit goes down within %d km of a cratered friendly runway.", km))
      return false end
    done = war:repairRunwayNow(node, side)
  end
  if done then ok(cm.destroyCrate, cm, crate.crateName) end
  return done
end

if B.ctldCrateDown then
  local baseDown = B.ctldCrateDown
  function B.ctldCrateDown(crate, pos)
    if crate and crate.descriptor and crate.descriptor.dccHeavy then
      local s, r = pcall(B.heavyDown, crate, pos, true)
      if not s then U.log("ERROR heavy crate: %s", tostring(r)) end
      return s and r
    end
    return baseDown(crate, pos)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local only = {}
    for _, t in ipairs(XC().heavyTypes) do only[t] = true end
    local list = crates["Engineering"] or {}
    local msg = "Heavy lift - only a Chinook or a Mi-8 can carry that."
    list[#list + 1] = { unit = "DCC_GENERATOR", desc = "Generator (Chinook / Mi-8)", weight = 2500.01, cratesRequired = 1,
                        dccHeavy = "generator", dccOnly = only, dccOnlyMsg = msg, dccCharge = 2 }
    list[#list + 1] = { unit = "DCC_RUNWAYKIT", desc = "Runway repair kit (Chinook / Mi-8)", weight = 2500.01,
                        cratesRequired = 1, dccHeavy = "runway", dccOnly = only, dccOnlyMsg = msg, dccCharge = 2 }
    crates["Engineering"] = list
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

if B.ctldHook then
  local baseHook = B.ctldHook
  function B.ctldHook()
    baseHook()
    if not B.ctld or B.ctld.x2Hooked or not CTLDCrateManager then return end
    B.ctld.x2Hooked = true
    local CM = CTLDCrateManager
    local baseUnpack = CM.unpackCrate
    CM.unpackCrate = function(self, crateName, unpacker)
      local crate = self.crates and self.crates[crateName]
      if crate and crate.descriptor and crate.descriptor.dccHeavy then
        if B.war then ok(B.heavyDown, crate, crate.position, true) end
        return
      end
      return baseUnpack(self, crateName, unpacker)
    end
    local baseSU = CM._spawnUnpacked
    if baseSU then
      CM._spawnUnpacked = function(self, desc, ...)
        if desc and desc.dccHeavy then return nil end
        return baseSU(self, desc, ...)
      end
    end
  end
end

-- ===========================================================================
-- 10. CSAR under fire: search parties
-- ===========================================================================
function B.pollSearch()
  local war, cfg = B.war, XC()
  for did, rec in pairs(B.x2.search) do
    local d = war.state.downed[did]
    if not d or (B.downedGroups or {})[did] == "onboard" then
      destroyGroup(rec.group); B.x2.search[did] = nil
    else
      for _, u in ipairs(unitsOf(rec.group)) do
        if dist2D(u:getPoint(), d.pos) <= cfg.searchCatchM then
          if war:downedCaptured(did, rec.side) then
            destroyGroup((B.downedGroups or {})[did]); B.downedGroups[did] = nil
          end
          destroyGroup(rec.group); B.x2.search[did] = nil
          break
        end
      end
    end
  end
  for _, did in ipairs(U.sortedKeys(war.state.downed)) do
    local d = war.state.downed[did]
    local ageMin = (war.state.tick - d.tick) * DCC.config.tickSeconds / 60
    if not B.x2.search[did] and not d.searched and ageMin >= cfg.searchAfterMin
       and (B.downedGroups or {})[did] ~= "onboard" then
      d.searched = true
      local enemy = otherSide(d.side)
      local node = B.nearestNodeOf(d.pos, enemy, cfg.searchKm * 1000)
      local np = node and B.nodePos[node]
      local types = (cat().ambush or {})[enemy] or {}
      local units = {}
      if np then
        local hdg = math.atan2(d.pos.z - np.z, d.pos.x - np.x)
        local sx, sz = np.x + math.cos(hdg) * 300, np.z + math.sin(hdg) * 300
        for i = 1, math.min(2, #types) do
          if B.validType(types[i]) then
            units[#units + 1] = { name = "DCC_SEARCH_" .. did .. "_" .. i, type = types[i], skill = "Average",
                                  x = sx + i * 10, y = sz, heading = hdg }
          end
        end
        local gname = "DCC_SEARCH_" .. did
        if #units > 0 and pcall(coalition.addGroup, B.countryId(enemy), Group.Category.GROUND, { name = gname,
            task = "Ground Nothing", units = units, route = { points = {
              { x = sx, y = sz, type = "Turning Point", action = "Off Road", speed = cfg.searchSpeed, ETA = 0,
                ETA_locked = false, speed_locked = true },
              { x = d.pos.x, y = d.pos.z, type = "Turning Point", action = "Off Road", speed = cfg.searchSpeed,
                ETA = 0, ETA_locked = false, speed_locked = true } } } }) then
          B.x2.search[did] = { group = gname, side = enemy }
          local km = dist2D({ x = sx, z = sz }, d.pos) / 1000
          trigger.action.outTextForCoalition(B.COAL[d.side], string.format(
            "Command: an enemy search party is moving toward %s from %s (%.0f km, about %d min) - hurry.",
            tostring(d.pilot), war:nodeName(node), km, math.floor(km * 1000 / cfg.searchSpeed / 60 + 0.5)), 20)
        end
      end
    end
  end
end

-- ===========================================================================
-- Announcements and points
-- ===========================================================================
local OWN = { shelling = true, pows = true, casualties = true, pickup_done = true, pickup_lost = true,
              generator = true, package_done = true }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    if OWN[ev.kind] and ev.side and B.COAL[ev.side] then
      trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 12)
    end
    if ev.kind == "weather" or ev.kind == "weather_front" then
      trigger.action.outText("Met office: " .. ev.text, 15)          -- everyone flies in it
    end
    if ev.kind == "package_done" and ev.crew then
      for key, name in pairs(ev.crew) do DCC.pilots:add(key, "packages", 1, name) end
    end
  end
end

if B.EFFECT then
  B.EFFECT.HVAESCORT = "Stay within 40 km of it for 20 minutes. Lose it and there is none for 2 hours."
  B.EFFECT.PKGESCORT = "Be within 25 km of the target while the strike goes in. Package bonus for everyone if it hits."
  B.EFFECT.MEDEVAC = "Land next to the wounded at the base, fly them to a friendly airbase or depot: the garrison recovers."
  B.EFFECT.POW = "Land next to the prisoners, fly them to a friendly airbase or depot: interrogation reveals nearby enemy bases."
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.pollHunts()
  B.reconcilePickups()
  B.pollSearch()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planHunts()
  B.shellImpacts()
  B.liveAmbushes()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.x2 = fresh()
end

end

-- >>> src/dcc_dcs_ext3.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: naval and hidden-threat war (v0.25).
-- Load after dcc_dcs_ext2.lua.
-- ----------------------------------------------------------------------------
--   1. Amphibious : landing helicopters (airmobile template) from Tarawa /
--                   Kuznetsov to a weak enemy coastal town.
--   2. Shipping   : real cargo ships on the lanes; sunk = cargo lost; AI
--                   anti-ship strikes on enemy cargo ships.
--   3. Carrier air wing: an AI CAP over each carrier and (BLUE) an S-3B
--                   recovery tanker on TACAN 76X, re-tasked as the ship sails.
--   4. Scuds      : launcher groups in the rear; impacts shown near players.
--   7. Pop-ups    : MANPADS / SHORAD groups spawned when enemy aircraft come
--                   near; seen (or firing) = on the map and the board.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext3 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function otherSide(s) return s == "blue" and "red" or "blue" end
local function unitsOf(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end
local function destroyGroup(gname)
  local g = gname and ok(Group.getByName, gname)
  if g and ok(g.isExist, g) then g:destroy() end
end
local function online() return #B.playerPositions() > 0 end
local function cat() return B.catalog or {} end
local function ll(p) local v = coord.LLtoLO(p.lat, p.lon, 0); return { x = v.x, y = 0, z = v.z } end
local function wpos(p) return { x = p.x, y = ok(land.getHeight, { x = p.x, y = p.z }) or 0, z = p.z } end
local function enemyPlayersNear(side, pos, km)
  local out = {}
  for _, u in ipairs(coalition.getPlayers(B.COAL[otherSide(side)]) or {}) do
    if alive(u) and dist2D(u:getPoint(), pos) <= km * 1000 then out[#out + 1] = u end
  end
  return out
end
local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end
local function wp(x, z, alt, speed, task)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
           speed = speed, speed_locked = true, ETA = 0, ETA_locked = false, task = task or combo({}) }
end
local function say(side, text, t)
  if B.COAL[side] then trigger.action.outTextForCoalition(B.COAL[side], "Command: " .. text, t or 15) end
end
local function shipUnit(id)
  local rec = (B.naval or {})[id]
  return rec and unitsOf(rec.group)[1]
end

local function fresh() return { ships = {}, wing = {}, scuds = {}, pops = {}, n = 0 } end
B.x3 = fresh()
local function nextName(prefix) B.x3.n = B.x3.n + 1; return prefix .. B.x3.n end

-- ===========================================================================
-- 1. Amphibious assault
-- ===========================================================================
function B.launchAmphib(side)
  local war, cfg = B.war, XC().amphib
  if not B.findTemplate("DCC_TPL_" .. side .. "_airmobile") or war:isStorm() then return nil end
  for _, ship in ipairs(war:amphibShips(side)) do
    local u = shipUnit(ship.id)
    if u then
      local sp = u:getPoint()
      local best, bestKey
      for _, id in ipairs(war.T.order) do
        local np = B.nodePos[id]
        if np and war:amphibTargetOk(side, id) and dist2D(np, sp) <= cfg.rangeKm * 1000 then
          local key = #war.state.nodes[id].platoons * 1e6 + dist2D(np, sp)
          if not bestKey or key < bestKey then best, bestKey = id, key end
        end
      end
      local home = best and B.nearestNodeOf(sp, side)
      local pk = home and war:amphibLaunched(side, ship.id, best, home)
      if pk then
        local np = B.nodePos[best]
        local d = math.max(1, dist2D(np, sp))
        local lx, lz = B.landNear(np.x + (sp.x - np.x) / d * 700, np.z + (sp.z - np.z) / d * 700)
        local landing = { x = lx, z = lz }
        local gname = "DCC_AMPHIB_" .. pk.id
        local g = B.spawnFlight(side, "airmobile", gname, { x = sp.x + 300, z = sp.z + 300 }, 150, 60, {
          wp(sp.x + 300, sp.z + 300, 150, 60),
          wp(landing.x, landing.z, 0, 50, combo({ { id = "Land", params = { point = { x = landing.x, y = landing.z },
            durationFlag = true, duration = 600 } } })) }, { helicopter = true, task = "Transport" })
        if not g then war:packageDestroyed(pk.id); return nil end
        B.packages[pk.id] = { strike = gname, target = np, kind = "airmobile", landing = landing }
        say(side, string.format("marines lifting off %s for %s - escort them (Missions > AMPHIB).", ship.name,
          war:nodeName(best)), 20)
        B.refreshMenus()
        return pk
      end
    end
  end
end

-- ===========================================================================
-- 2. Shipping
-- ===========================================================================
function B.shipPos(s)
  local rec = B.x3.ships[s.id]
  local u = rec and unitsOf(rec.group)[1]
  if u then return u:getPoint() end
  local l = B.war:laneOf(s.port)
  if not l then return nil end
  local a, b = ll(l.start), ll(l.dock)
  return { x = a.x + (b.x - a.x) * s.progress, y = 0, z = a.z + (b.z - a.z) * s.progress }
end

function B.reconcileShipping()
  local war, cfg = B.war, XC().shipping
  for id, rec in pairs(B.x3.ships) do
    local s = war.state.shipping[id]
    if not s then
      destroyGroup(rec.group); B.x3.ships[id] = nil              -- docked (or the model lost it)
    elseif #unitsOf(rec.group) == 0 then
      B.x3.ships[id] = nil
      war:shippingSunk(id)
    end
  end
  if not online() then return end
  for _, id in ipairs(U.sortedKeys(war.state.shipping)) do
    local s = war.state.shipping[id]
    local l = war:laneOf(s.port)
    if l and not B.x3.ships[id] then
      local p, dock = B.shipPos(s), ll(l.dock)
      local t = cfg.ships[s.side] or "Dry-cargo ship-1"
      local gname = nextName("DCC_CARGOSHIP_" .. id .. "_")
      local speed = cfg.speedKmh / 3.6
      local hdg = math.atan2(dock.z - p.z, dock.x - p.x)
      if pcall(coalition.addGroup, B.countryId(s.side), Group.Category.SHIP, { name = gname,
          units = { { name = gname .. "_1", type = t, skill = "Average", x = p.x, y = p.z, heading = hdg } },
          route = { points = {
            { x = p.x, y = p.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
              ETA_locked = false, speed_locked = true },
            { x = dock.x, y = dock.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
              ETA_locked = false, speed_locked = true } } } }) then
        B.x3.ships[id] = { group = gname }
      end
    end
  end
end

function B.planShipStrikes()
  local war = B.war
  if not online() or not war:aiAttackAllowed() then return end
  for id, rec in pairs(B.x3.ships) do
    local s = war.state.shipping[id]
    local u = unitsOf(rec.group)[1]
    if s and u and war.rng:next() < XC().shipping.aiStrikeChance then
      local enemy = otherSide(s.side)
      local busy = false
      for _, so in pairs(B.sorties) do if so.side == enemy and so.kind == "ANTISHIP" then busy = true end end
      local g = ok(u.getGroup, u)
      if not busy and g then
        B.spawnSortie(enemy, "attack", "ANTISHIP", u:getPoint(), { groupId = g:getID(), template = "antiship" })
      end
    end
  end
end

-- ===========================================================================
-- 3. Carrier air wing: CAP and recovery tanker over each carrier
-- ===========================================================================
local function orbitTasks(kind, c, alt, speed)
  if kind == "tanker" then
    return combo({ { id = "Tanker", params = {} },
      { id = "Orbit", params = { pattern = "Race-Track", point = { x = c.x - 12000, y = c.z },
        point2 = { x = c.x + 12000, y = c.z }, altitude = alt, speed = speed } } })
  end
  return combo({ { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 60000 } },
    { id = "Orbit", params = { pattern = "Circle", point = { x = c.x, y = c.z }, altitude = alt, speed = speed } } })
end

function B.carrierWing()
  local war, cfg = B.war, XC().carrier
  local now = timer.getTime()
  for _, ship in ipairs(war.theater.naval or {}) do
    if ship.kind == "carrier" and ship.ship ~= "LHA_Tarawa" then
      for _, kind in ipairs({ "cap", "tanker" }) do
        local key = ship.id .. "|" .. kind
        local rec = B.x3.wing[key]
        local u = shipUnit(ship.id)
        local role = kind == "cap" and "carriercap" or "carriertanker"
        local alt = kind == "cap" and cfg.capAltM or cfg.tankerAltM
        local speed = kind == "cap" and 220 or 140
        if rec and rec.group and (not u or not online() or now - rec.born > cfg.lifeMin * 60) then
          destroyGroup(rec.group)                                  -- relieved (or nothing to guard)
          B.x3.wing[key] = { gone = now - cfg.respawnMin * 60 }
          rec = nil
        elseif rec and rec.group and #unitsOf(rec.group) == 0 then
          B.x3.wing[key] = { gone = now }                          -- shot down: a while until the next
          rec = nil
        end
        rec = B.x3.wing[key]
        if u and online() and (not rec or (not rec.group and now - (rec.gone or 0) >= cfg.respawnMin * 60))
           and B.findTemplate("DCC_TPL_" .. ship.side .. "_" .. role) then
          local c = u:getPoint()
          local gname = nextName("DCC_CVW_" .. ship.id .. "_" .. kind .. "_")
          local g = B.spawnFlight(ship.side, role, gname, { x = c.x - 3000, z = c.z - 3000 }, alt, speed,
            { wp(c.x, c.z, alt, speed, orbitTasks(kind, c, alt, speed)) },
            { task = kind == "cap" and "CAP" or "Refueling", size = kind == "tanker" and 1 or nil })
          if g then
            B.x3.wing[key] = { group = gname, born = now, center = { x = c.x, z = c.z } }
            if kind == "tanker" then
              local tu = unitsOf(gname)[1]
              local ctl = tu and ok(tu.getController, tu)
              if ctl then
                pcall(ctl.setCommand, ctl, { id = "ActivateBeacon", params = { type = 4, system = 4,
                  callsign = cfg.tankerCall, frequency = (1088 + cfg.tankerTacan - 1) * 1000000, AA = true,
                  channel = cfg.tankerTacan, modeChannel = "X", bearing = true, unitId = ok(tu.getID, tu) } })
              end
              say(ship.side, string.format("%s recovery tanker overhead, TACAN %dX.", ship.name, cfg.tankerTacan), 12)
            end
          end
        elseif rec and rec.group and u then
          local c = u:getPoint()
          if dist2D(c, rec.center) > cfg.retaskKm * 1000 then           -- the ship sailed on: follow it
            local g = ok(Group.getByName, rec.group)
            local ctl = g and ok(g.getController, g)
            if ctl then
              pcall(ctl.setTask, ctl, { id = "Mission", params = { route = { points = {
                wp(c.x, c.z, alt, speed, orbitTasks(kind, c, alt, speed)) } } } })
              rec.center = { x = c.x, z = c.z }
            end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 4. Scuds
-- ===========================================================================
function B.scudPos(b)
  local np = b.node and B.nodePos[b.node]
  if not np then return nil end
  local x, z = B.landNear(np.x + (b.off and b.off.dx or 0), np.z + (b.off and b.off.dz or 0))
  return { x = x, y = 0, z = z }
end

function B.reconcileScuds()
  local war = B.war
  for _, b in ipairs(war:scuds()) do
    local rec = B.x3.scuds[b.id]
    if rec and (b.status ~= "up" or rec.node ~= b.node) then
      destroyGroup(rec.group); B.x3.scuds[b.id] = nil; rec = nil   -- killed in the model, or it moved on
    elseif rec and #unitsOf(rec.group) == 0 then
      B.x3.scuds[b.id] = nil; rec = nil
      war:scudKilled(b.id)
    end
    if not rec and b.status == "up" and b.node then
      local p = B.scudPos(b)
      local units = {}
      for i, t in ipairs(cat().scud or { "Scud_B" }) do
        if B.validType(t) then
          units[#units + 1] = { name = "DCC_SCUD_" .. b.id .. "_" .. B.x3.n .. "_" .. i, type = t, skill = "Average",
                                x = p.x + i * 25, y = p.z + i * 10, heading = 0, playerCanDrive = false }
        end
      end
      local gname = nextName("DCC_SCUD_" .. b.id .. "_")
      if #units > 0 and pcall(coalition.addGroup, B.countryId(b.side), Group.Category.GROUND, { name = gname,
          task = "Ground Nothing", units = units, route = { points = { { x = p.x, y = p.z, type = "Turning Point",
          action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
        B.x3.scuds[b.id] = { group = gname, node = b.node }
      end
    end
  end
end

function B.scudImpact(node)
  local p = B.nodePos[node]
  if not p then return end
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, p) <= XC().scud.impactKm * 1000 then
      local a, r = math.random() * 2 * math.pi, math.random() * 1500
      local pt = { x = p.x + math.cos(a) * r, z = p.z + math.sin(a) * r }
      timer.scheduleFunction(function() ok(trigger.action.explosion, wpos(pt), 500) end, nil,
        timer.getTime() + 20 + math.random() * 40)
      return
    end
  end
end

-- ===========================================================================
-- 7. Pop-up threats
-- ===========================================================================
function B.popupPos(p)
  local a, b = B.nodePos[p.node], p.toward and B.nodePos[p.toward]
  if not a then return nil end
  local x, z = a.x, a.z
  if b then
    x, z = a.x + (b.x - a.x) * p.frac, a.z + (b.z - a.z) * p.frac
    local d = math.max(1, dist2D(a, b))
    x, z = x - (b.z - a.z) / d * p.jitter, z + (b.x - a.x) / d * p.jitter      -- off the straight line
  end
  x, z = B.landNear(x, z)
  return { x = x, y = 0, z = z }
end

function B.reconcilePopups()
  local war, cfg = B.war, XC().popup
  for id, rec in pairs(B.x3.pops) do
    local p = war.state.popups[id]
    if not p then
      destroyGroup(rec.group); B.x3.pops[id] = nil
    elseif #unitsOf(rec.group) == 0 then
      B.x3.pops[id] = nil
      war:popupKilled(id)
    elseif #enemyPlayersNear(p.side, rec.pos, cfg.despawnKm) == 0 then
      destroyGroup(rec.group); B.x3.pops[id] = nil                       -- nobody near: back to the model
    else
      for _, eu in ipairs(enemyPlayersNear(p.side, rec.pos, cfg.seeKm)) do
        local e, t = eu:getPoint(), unitsOf(rec.group)[1]
        local tp = t and t:getPoint()
        if tp and ok(land.isVisible, { x = e.x, y = e.y, z = e.z }, { x = tp.x, y = tp.y + 2, z = tp.z }) then
          war:popupSeen(id, otherSide(p.side), "visual")
          break
        end
      end
    end
  end
  for _, id in ipairs(U.sortedKeys(war.state.popups)) do
    local p = war.state.popups[id]
    if not B.x3.pops[id] then
      local pos = B.popupPos(p)
      if pos and #enemyPlayersNear(p.side, pos, cfg.spawnKm) > 0 then
        local types = ((cat().popups or {})[p.kind] or {})[p.side] or {}
        local gname = nextName("DCC_POP_" .. id .. "_")
        local units = {}
        for i, t in ipairs(types) do
          if B.validType(t) then
            units[#units + 1] = { name = gname .. "_" .. i, type = t, skill = "Good", x = pos.x + i * 12,
                                  y = pos.z + i * 6, heading = 0, playerCanDrive = false }
          end
        end
        if #units > 0 and pcall(coalition.addGroup, B.countryId(p.side), Group.Category.GROUND, { name = gname,
            task = "Ground Nothing", units = units, route = { points = { { x = pos.x, y = pos.z,
            type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false } } } }) then
          B.x3.pops[id] = { group = gname, pos = pos }
        end
      end
    end
  end
end

-- a pop-up that fires gives itself away
function B.x3OnEvent(e)
  if not e or e.id ~= world.event.S_EVENT_SHOT or not e.initiator then return end
  local g = ok(e.initiator.getGroup, e.initiator)
  local gname = g and ok(g.getName, g) or ""
  for id, rec in pairs(B.x3.pops) do
    if rec.group == gname then
      local p = B.war.state.popups[id]
      if p then B.war:popupSeen(id, otherSide(p.side), "visual") end
    end
  end
end
if world and world.addEventHandler and not B.x3Handler then
  B.x3Handler = { onEvent = function(_, e) pcall(B.x3OnEvent, e) end }
  world.addEventHandler(B.x3Handler)
end

-- ===========================================================================
-- Missions: positions, escort checks, effects
-- ===========================================================================
if B.missionPos then
  local baseMissionPos = B.missionPos
  function B.missionPos(m)
    local war = B.war
    if m.type == "SHIPSTRIKE" or m.type == "SHIPESCORT" then
      local s = war.state.shipping[m.target]
      return s and B.shipPos(s)
    elseif m.type == "AMPHIB" then
      local rec = B.packages and B.packages[m.target]
      local u = rec and unitsOf(rec.strike)[1]
      if u then return u:getPoint() end
      return rec and rec.landing
    elseif m.type == "SCUD" then
      for _, b in ipairs(war:scuds()) do if b.id == m.target then return B.scudPos(b) end end
    elseif m.type == "POPUP" then
      local p = war.state.popups[m.target]
      return p and B.popupPos(p)
    end
    return baseMissionPos(m)
  end
end

local baseDetect = B.detect
function B.detect()
  baseDetect()
  local war = B.war
  for uname, p in pairs(B.players) do
    local m = p.mission and war.state.missions[p.mission]
    local u = ok(Unit.getByName, uname)
    if m and m.status == "open" and alive(u) and not m.escortOk then
      local km = (m.type == "AMPHIB" and XC().amphib.escortKm) or (m.type == "SHIPESCORT" and XC().shipping.escortKm)
      local tp = km and B.missionPos(m)
      if tp and dist2D(u:getPoint(), tp) <= km * 1000 then
        m.escortOk = true
        trigger.action.outTextForGroup(p.gid, "On station - stay with them until they arrive.", 10)
      end
    end
  end
end

if B.EFFECT then
  B.EFFECT.AMPHIB = "Be within 20 km of the landing helicopters before they land. Then support the fight ashore (CAS)."
  B.EFFECT.SHIPSTRIKE = "Sink the supply ship before it docks - its whole cargo is lost."
  B.EFFECT.SHIPESCORT = "Be within 20 km of the supply ship; it counts when the ship docks."
  B.EFFECT.SCUD = "The launcher moves on about 15 min after firing - find it fast (a launcher and its truck)."
  B.EFFECT.POPUP = "Shoulder-launched or mobile SAM: it was seen here. Stay high or out of range until you have it."
end

-- ===========================================================================
-- Map: SCUD and pop-up contacts
-- ===========================================================================
local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs({ "blue", "red" }) do
    for key, c in pairs(war.state.contacts[side]) do
      local p
      if c.kind == "scud" then
        for _, b in ipairs(war:scuds()) do
          if "scud:" .. b.id == key then p = B.scudPos({ node = c.node, off = c.off }) end
        end
      elseif c.kind == "popup" then
        local pp = war.state.popups[c.popup]
        p = pp and B.popupPos(pp)
      end
      if p then
        local isFresh = war:isFresh(side, key)
        local ec = DCC.config.colours[otherSide(side)]
        local col = { ec[1], ec[2], ec[3], isFresh and 1 or 0.45 }
        B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.circleToAll(B.COAL[side], B.nextMark, { x = p.x, y = 0, z = p.z },
          c.kind == "scud" and 4000 or 5000, col, { ec[1], ec[2], ec[3], 0.12 }, 2, true, "")
        B.nextMark = B.nextMark + 1
        B.intelMarks[#B.intelMarks + 1] = B.nextMark
        trigger.action.textToAll(B.COAL[side], B.nextMark, { x = p.x + 5500, y = 0, z = p.z }, col,
          { 0, 0, 0, 0.35 }, 10, true, (c.label or c.kind) .. (isFresh and "" or " (last seen)"))
      end
    end
  end
end

-- ===========================================================================
-- Announcements
-- ===========================================================================
local OWN = { amphib_ashore = true, shipping_out = true, shipping_in = true, shipping_sunk = true,
              scud_destroyed = true, popup_killed = true }
local baseAnnounce = B.announce
function B.announce(events)
  baseAnnounce(events)
  for _, ev in ipairs(events) do
    if OWN[ev.kind] and ev.side then say(ev.side, ev.text, 12) end
    if ev.kind == "shipping_sunk" and ev.side then say(otherSide(ev.side), ev.text, 12) end
    if ev.kind == "scud" and ev.side then
      say(ev.side, ev.text, 20)
      if ev.node then B.scudImpact(ev.node) end
    end
  end
end

-- ===========================================================================
-- 10. Night illumination
-- ===========================================================================
-- One flare (DCS illumination bomb) above p.
function B.flare(p)
  local c = XC().illum
  local gx, gz = p.x + (math.random() - 0.5) * 800, p.z + (math.random() - 0.5) * 800
  local h = ok(land.getHeight, { x = gx, y = gz }) or 0
  return ok(trigger.action.illuminationBomb, { x = gx, y = h + c.heightM, z = gz }, c.power)
end

-- At night the troops fighting at a base light it up whenever players are near.
function B.autoIllumination()
  local war, c = B.war, XC().illum
  if not war:isNight() then return end
  B.x3.lit = B.x3.lit or {}
  local now, seen = timer.getTime(), {}
  for _, mv in pairs(war.state.moves) do
    local p = mv.status == "fighting" and B.nodePos[mv.to]
    if p and not seen[mv.to] then
      seen[mv.to] = true
      local near = false
      for _, pp in ipairs(B.playerPositions()) do if dist2D(pp, p) <= c.autoKm * 1000 then near = true end end
      if near and now - (B.x3.lit[mv.to] or -1e9) >= c.everySec then
        B.x3.lit[mv.to] = now
        B.flare(p)
      end
    end
  end
end

-- F10 > Support > Illumination on my map mark: mortars / artillery from an own
-- base within 30 km fire a string of flares over the mark.
function B.callIllumination(uname)
  local p = B.players[uname]
  if not p then return end
  local war, c = B.war, XC().illum
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  B.x3.illumAt = B.x3.illumAt or {}
  local left = c.callCooldownMin * 60 - (timer.getTime() - (B.x3.illumAt[p.side] or -1e9))
  if left > 0 then return tell(string.format("The mortars are reloading - %d min.", math.ceil(left / 60))) end
  local m = B.newestMark and B.newestMark(p.side, p)
  if not m then return tell("Put a mark on the F10 map first (your side, within 15 min).") end
  local node = B.nearestNodeOf(m.pos, p.side, c.callKm * 1000)
  if not node then return tell(string.format("No friendly base within %d km of the mark.", c.callKm)) end
  if war.paySupport and not war:paySupport(node, c.callSU) then
    return tell(war:nodeName(node) .. " has no supply to spare for flares.")
  end
  B.x3.illumAt[p.side] = timer.getTime()
  for i = 1, c.callFlares do
    timer.scheduleFunction(function() B.flare(m.pos) end, nil, timer.getTime() + 10 + (i - 1) * 60)
  end
  trigger.action.outTextForCoalition(B.COAL[p.side], string.format(
    "%s: illumination from %s - %d flares over the mark, one a minute.", p.name, war:nodeName(node), c.callFlares), 12)
end

if B.buildSupportMenu then
  local baseSupport = B.buildSupportMenu
  function B.buildSupportMenu(p)
    baseSupport(p)
    if p and p.gid and p.supportMenu then
      missionCommands.addCommandForGroup(p.gid, "Illumination on my map mark", p.supportMenu, B.callIllumination, p.unit)
    end
  end
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileShipping()
  B.reconcileScuds()
  B.reconcilePopups()
  B.autoIllumination()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  local war = B.war
  if online() then
    local per = DCC.config.tickSeconds / 60
    for _, side in ipairs({ "blue", "red" }) do
      if war.rng:next() < per / XC().amphib.minutes then B.launchAmphib(side) end
    end
  end
  B.planShipStrikes()
  B.carrierWing()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.x3 = fresh()
end

end

-- >>> src/dcc_dcs_ext4.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: Combined Arms, QRA, engineers and the
-- performance guard (v0.27). Load after dcc_dcs_ext3.lua.
-- ----------------------------------------------------------------------------
--   6. Combined Arms : campaign platoons, supply convoys, artillery and
--                      skirmish groups can be driven by CA commanders / JTACs
--                      (slots come from make_mission.py). A player in a ground
--                      vehicle is never slot-guarded and gets ground missions
--                      (ASSAULT, HOLD, GCONVOY, v0.28): credit for being there.
--   7. QRA           : a new INTERCEPT scrambles that side's grounded fighter
--                      pilots (heading and range to the threat). Airborne
--                      within 5 min = the mission is theirs, +10 QRA bonus
--                      when it is done.
--  15. Engineers     : CTLD > Engineering > Repair kit (any lift helicopter,
--                      20 SU) set down at an own base: one building, the SAM
--                      or the EWR is repaired at once.
--  16. Performance   : counts the ground units in DCS every minute; above 700
--                      / 1000 the live radius, live platoons, skirmishes and
--                      pop-ups shrink; back to normal when the load drops.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function XC() return DCC.config.ext4 end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true and (ok(u.getLife, u) or 0) >= 1 end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function sideOfCoal(c) return c == 2 and "blue" or (c == 1 and "red" or nil) end
local function isGroundUnit(u)
  local d = u and ok(u.getDesc, u)
  return d ~= nil and Unit and Unit.Category and d.category == Unit.Category.GROUND_UNIT
end

local function fresh() return { qraSeen = {}, qraCrew = {}, perfLevel = 0, perfBase = nil, perfNext = 0 } end
B.x4 = fresh()

-- ===========================================================================
-- 6. Combined Arms
-- ===========================================================================
function B.caDrivable(name)
  if type(name) ~= "string" then return false end
  for _, pat in ipairs(XC().ca.patterns or {}) do
    if name:find(pat) then return true end
  end
  return false
end

if coalition and coalition.addGroup and not coalition.dccCA then
  local rawAdd = coalition.addGroup
  coalition.addGroup = function(country, category, data)
    if XC().ca.playerCanDrive and Group and category == Group.Category.GROUND and type(data) == "table"
       and B.caDrivable(data.name) then
      for _, u in ipairs(data.units or {}) do u.playerCanDrive = true end
    end
    return rawAdd(country, category, data)
  end
  coalition.dccCA = true
end

-- A CA player taking over a vehicle is not slot-guarded (the tank may be
-- attacking an enemy base).
local baseOnBirth = B.onBirth
function B.onBirth(unit)
  if isGroundUnit(unit) then return end
  return baseOnBirth(unit)
end

-- ...and is a "ground player": the Missions menu shows only ground missions
-- (ASSAULT, HOLD, GCONVOY) within ext4.ground.rangeKm of the vehicle.
local baseRegister = B.registerPlayer
function B.registerPlayer(u)
  local p = baseRegister(u)
  if p and isGroundUnit(u) then
    p.ground, p.heli, p.slow = true, false, false
    B.buildMenu(p)
    if B.buildSupportMenu then B.buildSupportMenu(p) end
  end
  return p
end

local baseCaps = B.caps
function B.caps(p)
  if p and p.ground then return { GROUND = true } end
  return baseCaps(p)
end

local baseCanFly = B.canFly
function B.canFly(p, m)
  if p and p.ground then return m.needs == "GROUND" end
  return baseCanFly(p, m)
end

local baseMissionsFor = B.missionsFor
function B.missionsFor(p)
  if not (p and p.ground) then return baseMissionsFor(p) end
  local u = ok(Unit.getByName, p.unit)
  local here = alive(u) and u:getPoint() or p.spawn
  local range = XC().ground.rangeKm * 1000
  local list = {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if m.needs == "GROUND" then
      local pos = B.missionPos(m)
      local d = (pos and here) and dist2D(pos, here) or math.huge
      if d <= range then list[#list + 1] = { m = m, d = d } end
    end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local out = {}
  for _, e in ipairs(list) do
    out[#out + 1] = setmetatable({ _nm = math.floor(e.d / 1852 + 0.5) }, { __index = e.m })
  end
  return out
end

local baseMissionPos = B.missionPos
function B.missionPos(m)
  if m.type == "GCONVOY" then return baseMissionPos({ type = "CONVOY", target = m.target }) end
  return baseMissionPos(m)
end

if B.EFFECT then
  B.EFFECT.ASSAULT = "Drive with the attack and take the base. Be within 5 km of it for 5 min to get the credit."
  B.EFFECT.HOLD = "Hold the base until the attack breaks. Be within 5 km of it for 5 min to get the credit."
  B.EFFECT.GCONVOY = "Escort the supply convoy by road until it arrives. Stay within 5 km of it for 5 min for the credit."
end

-- Fire support for ground players (v0.29): the same artillery as the pilots'
-- Support menu (rank, 10 min cooldown per side, 10 SU from a battery within
-- 35 km), aimed without a map mark: the nearest enemy in sight, or the base of
-- the ground mission. Never within dangerCloseM of the caller.
local function enemyInSight(p, u)
  local here = u:getPoint()
  local eye = { x = here.x, y = here.y + 2.5, z = here.z }
  local enemyCoal = p.side == "blue" and 1 or 2
  local best, bestD
  for _, g in ipairs(ok(coalition.getGroups, enemyCoal, Group.Category.GROUND) or {}) do
    for _, e in ipairs(ok(g.getUnits, g) or {}) do
      if alive(e) then
        local ep = e:getPoint()
        local d = dist2D(here, ep)
        if d <= XC().ground.artyKm * 1000 and (not bestD or d < bestD) then
          local seen = ok(land.isVisible, eye, { x = ep.x, y = ep.y + 1.5, z = ep.z })
          if seen ~= false then best, bestD = ep, d end
        end
      end
    end
  end
  return best, bestD
end

function B.groundFire(uname, how)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  local pos, what
  if how == "enemy" then
    local d
    pos, d = enemyInSight(p, u)
    if not pos then return tell(string.format("No enemy in sight within %d km.", XC().ground.artyKm)) end
    what = string.format("nearest enemy, %d m", math.floor(d / 10 + 0.5) * 10)
  else
    local m = p.mission and B.war.state.missions[p.mission]
    if not (m and m.status == "open" and m.needs == "GROUND") then
      return tell("Take a ground mission first (F10 > Missions).")
    end
    pos = B.missionPos(m)
    if not pos then return tell("The objective cannot be located right now.") end
    what = m.type .. " " .. m.label
  end
  if dist2D(u:getPoint(), pos) < XC().ground.dangerCloseM then
    return tell("Danger close - the target is too near you. Pull back first.")
  end
  tell("Fire mission: " .. what .. ".")
  local realMark, ranks = B.newestMark, DCC.config.ext.ranks
  local realRank = ranks.arty
  B.newestMark = function() return { pos = { x = pos.x, y = 0, z = pos.z }, t = timer.getTime(), by = uname } end
  ranks.arty = XC().ground.artyRank           -- nil: tank crews need no rank for their own fire missions
  local s, err = pcall(B.callArtillery, uname)
  B.newestMark, ranks.arty = realMark, realRank
  if not s then U.log("ERROR ground fire mission: %s", tostring(err)) end
end

-- Smoke screen (v0.30): a battery within artyRangeKm fires smoke rounds that
-- build a curtain smokeAheadM in front of the vehicle, across its heading.
-- Cheap (smokeSU) and on its own cooldown per player, not the side's guns.
local function forwardOf(u, p)
  local pos = ok(u.getPosition, u)
  if pos and pos.x and (pos.x.x ~= 0 or pos.x.z ~= 0) then
    local l = math.sqrt(pos.x.x ^ 2 + pos.x.z ^ 2)
    return { x = pos.x.x / l, z = pos.x.z / l }
  end
  local here, tgt = u:getPoint(), enemyInSight(p, u)        -- no heading: toward the enemy, else north
  if tgt then
    local d = math.max(1, dist2D(here, tgt))
    return { x = (tgt.x - here.x) / d, z = (tgt.z - here.z) / d }
  end
  return { x = 1, z = 0 }
end

-- A curtain of smoke rounds centred on c, across direction f (unit vector).
function B.smokeCurtain(c, f)
  local gc, now = XC().ground, timer.getTime()
  B.x4.smokeN = (B.x4.smokeN or 0) + 1
  local n, w = gc.smokeRounds, gc.smokeWidthM
  local names = {}
  for i = 1, n do
    local off = (n == 1) and 0 or (-w / 2 + w * (i - 1) / (n - 1))
    local x, z = c.x - f.z * off, c.z + f.x * off                 -- across the heading
    local pt = { x = x, y = ok(land.getHeight, { x = x, y = z }) or 0, z = z }
    local name = string.format("DCC_SMOKE_%d_%d", B.x4.smokeN, i)
    names[#names + 1] = name
    timer.scheduleFunction(function()
      ok(trigger.action.explosion, pt, 2)                            -- the shell bursting
      ok(trigger.action.effectSmokeBig, pt, gc.smokePreset, 0.6, name)
    end, nil, now + 20 + i * 2)
  end
  timer.scheduleFunction(function()
    for _, name in ipairs(names) do ok(trigger.action.effectSmokeStop, name) end
  end, nil, now + 20 + gc.smokeMinutes * 60)
end

-- A battery of side within artillery range of c that can pay, or nil.
local function smokeBattery(side, c, su)
  local war, range = B.war, DCC.config.ext.support.artyRangeKm * 1000
  for _, b in ipairs(war:batteries(side) or {}) do
    if b.status == "up" and b.node and B.nodePos[b.node] and dist2D(B.nodePos[b.node], c) <= range
       and war:paySupport(b.node, su) then return b end
  end
end

-- AI smoke (v0.30): an attack in the live bubble lays a curtain between its lead
-- vehicles and the base once they are within withinKm, again every everyMin.
function B.aiSmokeTick()
  local cfg, gc, war = XC().aiSmoke, XC().ground, B.war
  if not (cfg and cfg.enabled and war) then return end
  local now = timer.getTime()
  B.x4.aiSmoke = B.x4.aiSmoke or {}
  for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
    local mv = war.state.moves[mid]
    local np = B.nodePos[mv.to]
    if mv.kind == "assault" and np and (B.liveNodes[mv.to] or B.liveNodes[mv.from])
       and now - (B.x4.aiSmoke[mid] or -math.huge) >= cfg.everyMin * 60 then
      local lead
      for _, pid in ipairs(mv.platoons or {}) do
        local rec = B.spawned[pid]
        local g = rec and ok(Group.getByName, rec.group)
        for _, u in ipairs(g and ok(g.getUnits, g) or {}) do
          if alive(u) then
            local d = dist2D(u:getPoint(), np)
            if d <= cfg.withinKm * 1000 and (not lead or d < lead.d) then lead = { p = u:getPoint(), d = d } end
          end
        end
      end
      if lead and lead.d > gc.dangerCloseM then
        local f = { x = (np.x - lead.p.x) / lead.d, z = (np.z - lead.p.z) / lead.d }
        local ahead = math.min(gc.smokeAheadM, lead.d / 2)
        local c = { x = lead.p.x + f.x * ahead, z = lead.p.z + f.z * ahead }
        if smokeBattery(mv.side, c, gc.smokeSU) then
          B.x4.aiSmoke[mid] = now
          B.smokeCurtain(c, f)
          U.log("AI smoke: %s attack on %s", mv.side, tostring(mv.to))
        end
      end
    end
  end
  for mid in pairs(B.x4.aiSmoke) do if not war.state.moves[mid] then B.x4.aiSmoke[mid] = nil end end
end

-- Defender smoke (v0.32): a live garrison screens itself with its own smoke
-- grenades (free, no battery) when an enemy attack's lead vehicles are within
-- defendKm, or an enemy aircraft is within airKm and below airMaxAltM. The
-- curtain goes defendOffsetM out from the base, toward the threat.
-- Only aircraft that attack set it off (v0.33): one that fired in the last
-- shotSec seconds, or one diving at the base (sinking faster than diveMps while
-- flying toward it).
function B.isAttacking(u, np, d)
  local cfg = XC().aiSmoke
  local name = ok(u.getName, u)
  local t = name and (B.x4.shots or {})[name]
  if t and timer.getTime() - t <= cfg.shotSec then return true end
  local v = ok(u.getVelocity, u)
  if not (v and v.y) then return false end
  local h = math.sqrt(v.x * v.x + v.z * v.z)
  if v.y > -cfg.diveMps or h < 1 then return false end
  local up = u:getPoint()
  local tx, tz = (np.x - up.x) / math.max(d, 1), (np.z - up.z) / math.max(d, 1)
  return (v.x * tx + v.z * tz) / h >= 0.7                  -- heading within ~45 deg of the base
end

local function enemyAircraftNear(side, np, cfg)
  local coal = side == "blue" and 1 or 2
  local best
  for _, cat in ipairs({ Group.Category.AIRPLANE, Group.Category.HELICOPTER }) do
    for _, g in ipairs(ok(coalition.getGroups, coal, cat) or {}) do
      for _, u in ipairs(ok(g.getUnits, g) or {}) do
        if alive(u) and ok(u.inAir, u) then
          local up = u:getPoint()
          local agl = up.y - (ok(land.getHeight, { x = up.x, y = up.z }) or 0)
          local d = dist2D(up, np)
          if d <= cfg.airKm * 1000 and agl <= cfg.airMaxAltM and (not best or d < best.d)
             and B.isAttacking(u, np, d) then
            best = { p = up, d = d }
          end
        end
      end
    end
  end
  return best
end

local function enemyLeadNear(side, id, np, km)
  local best
  for _, mv in pairs(B.war.state.moves) do
    if mv.kind == "assault" and mv.to == id and mv.side ~= side then
      for _, pid in ipairs(mv.platoons or {}) do
        local rec = B.spawned[pid]
        local g = rec and ok(Group.getByName, rec.group)
        for _, u in ipairs(g and ok(g.getUnits, g) or {}) do
          if alive(u) then
            local d = dist2D(u:getPoint(), np)
            if d <= km * 1000 and (not best or d < best.d) then best = { p = u:getPoint(), d = d } end
          end
        end
      end
    end
  end
  return best
end

function B.defenseSmokeTick()
  local cfg, war = XC().aiSmoke, B.war
  if not (cfg and cfg.enabled and cfg.defend and war) then return end
  local now = timer.getTime()
  B.x4.defSmoke = B.x4.defSmoke or {}
  for _, id in ipairs(war.T.order) do
    local ns, np = war.state.nodes[id], B.nodePos[id]
    if np and B.liveNodes[id] and #ns.platoons > 0
       and now - (B.x4.defSmoke[id] or -math.huge) >= cfg.defendEveryMin * 60 then
      local threat, why = enemyLeadNear(ns.side, id, np, cfg.defendKm), "attack"
      if not threat then threat, why = enemyAircraftNear(ns.side, np, cfg), "aircraft" end
      if threat and threat.d > 1 then
        local f = { x = (threat.p.x - np.x) / threat.d, z = (threat.p.z - np.z) / threat.d }
        local off = math.min(cfg.defendOffsetM, threat.d / 2)
        B.x4.defSmoke[id] = now
        B.smokeCurtain({ x = np.x + f.x * off, z = np.z + f.z * off }, f)
        U.log("defender smoke at %s (%s)", id, why)
      end
    end
  end
end

function B.groundSmoke(uname)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local function tell(t) trigger.action.outTextForGroup(p.gid, t, 12) end
  local gc, war = XC().ground, B.war
  local now = timer.getTime()
  B.x4.smokeAt = B.x4.smokeAt or {}
  local left = (B.x4.smokeAt[p.key] or -math.huge) + gc.smokeCooldownMin * 60 - now
  if left > 0 then return tell(string.format("Smoke rounds reloading - %d min.", math.ceil(left / 60))) end
  local here, f = u:getPoint(), forwardOf(u, p)
  local c = { x = here.x + f.x * gc.smokeAheadM, z = here.z + f.z * gc.smokeAheadM }
  local battery = smokeBattery(p.side, c, gc.smokeSU)
  if not battery then
    return tell(string.format("No battery with supply within %d km for smoke.", DCC.config.ext.support.artyRangeKm))
  end
  B.x4.smokeAt[p.key] = now
  B.smokeCurtain(c, f)
  tell(string.format("Smoke screen %d m ahead from %s - rounds on the way, curtain in 20 s for %d min.",
    gc.smokeAheadM, war:nodeName(battery.node), gc.smokeMinutes))
end

if B.buildSupportMenu then
  local baseSupportMenu = B.buildSupportMenu
  function B.buildSupportMenu(p)
    if not (p and p.ground) then return baseSupportMenu(p) end
    if not p.gid then return end
    if p.supportMenu then ok(missionCommands.removeItemForGroup, p.gid, p.supportMenu) end
    local root = missionCommands.addSubMenuForGroup(p.gid, "Support")
    p.supportMenu = root
    missionCommands.addCommandForGroup(p.gid, "Artillery on the nearest enemy in sight", root,
      function(uname) B.groundFire(uname, "enemy") end, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Artillery on my objective", root,
      function(uname) B.groundFire(uname, "objective") end, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Smoke screen ahead", root, B.groundSmoke, p.unit)
    if B.callArtillery then missionCommands.addCommandForGroup(p.gid, "Artillery on my map mark", root, B.callArtillery, p.unit) end
    if B.callCas then missionCommands.addCommandForGroup(p.gid, "CAS pair on my map mark", root, B.callCas, p.unit) end
    if B.callIllumination then
      missionCommands.addCommandForGroup(p.gid, "Illumination on my map mark", root, B.callIllumination, p.unit)
    end
  end
end

-- Who was there: one sample per poll for every ground player on a ground mission.
function B.groundPresenceTick()
  local now = timer.getTime()
  local dt = now - (B.x4.presenceAt or now)
  B.x4.presenceAt = now
  if dt <= 0 then return end
  local km = XC().ground.presenceKm * 1000
  for _, p in pairs(B.players or {}) do
    local m = p.ground and p.mission and B.war.state.missions[p.mission]
    local u = m and ok(Unit.getByName, p.unit)
    if m and m.status == "open" and alive(u) then
      local pos = B.missionPos(m)
      if pos and dist2D(u:getPoint(), pos) <= km then B.war:groundPresence(m.id, p.key, dt) end
    end
  end
end

-- A platoon a player is driving stays spawned, wherever he takes it.
local baseUpdateLive = B.updateLive
function B.updateLive()
  baseUpdateLive()
  local st = B.war.state
  for _, p in pairs(B.players or {}) do
    local u = p.ground and ok(Unit.getByName, p.unit)
    local g = u and ok(u.getGroup, u)
    local pid = g and (ok(g.getName, g) or ""):match("^DCC_(p%d+)$")
    if pid then
      for _, id in ipairs(B.war.T.order) do
        for _, x in ipairs(st.nodes[id].platoons) do if x == pid then B.liveNodes[id] = true end end
      end
      for _, mv in pairs(st.moves) do
        for _, x in ipairs(mv.platoons or {}) do
          if x == pid then B.liveNodes[mv.from], B.liveNodes[mv.to] = true, true end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7. Quick reaction alert
-- ===========================================================================
local function bearing(from, to)
  local deg = math.deg(math.atan2(to.z - from.z, to.x - from.x))   -- DCS: x north, z east
  return math.floor((deg % 360) + 0.5) % 360
end

function B.qraScan()
  local war, cfg = B.war, XC().qra
  if not (war and war.state.missions) then return end
  local now = timer.getTime()
  for _, mid in ipairs(U.sortedKeys(war.state.missions)) do
    local m = war.state.missions[mid]
    if m.type == "INTERCEPT" and m.status == "open" and not B.x4.qraSeen[mid] then
      B.x4.qraSeen[mid] = true
      local tp = B.missionPos(m)
      if tp then
        for _, p in pairs(B.players or {}) do
          local u = ok(Unit.getByName, p.unit)
          if p.side == m.side and not p.mission and not p.heli and alive(u) and not ok(u.inAir, u)
             and B.canFly(p, m) then
            local up = u:getPoint()
            local d = dist2D(up, tp)
            if d <= cfg.km * 1000 then
              p.qra = { mid = mid, t = now }
              trigger.action.outTextForGroup(p.gid, string.format(
                "QRA - SCRAMBLE! %s.\nIntercept heading %03d (true), %d nm.\nAirborne within %d min: the INTERCEPT is yours, +%d QRA bonus when it is done.",
                m.label, bearing(up, tp), math.floor(d / 1852 + 0.5), cfg.minutes, DCC.Pilots.POINTS.qra), 20)
            end
          end
        end
      end
    end
  end
  for mid in pairs(B.x4.qraSeen) do
    if not war.state.missions[mid] then B.x4.qraSeen[mid] = nil end
  end
end

function B.qraTakeoff(p)
  local q = p and p.qra
  if not q then return end
  p.qra = nil
  local m = B.war.state.missions[q.mid]
  if timer.getTime() - q.t > XC().qra.minutes * 60 or not m or m.status ~= "open" then return end
  if p.mission and p.mission ~= q.mid then return end
  if p.mission ~= q.mid then B.takeMission({ unit = p.unit, mid = q.mid }) end
  if p.mission == q.mid then
    B.x4.qraCrew[q.mid] = B.x4.qraCrew[q.mid] or {}
    B.x4.qraCrew[q.mid][p.key] = true
    trigger.action.outTextForGroup(p.gid, "QRA: airborne in time - the intercept is yours. Good hunting.", 12)
  end
end

local baseOpsEvent = B.onOpsEvent
function B.onOpsEvent(e)
  baseOpsEvent(e)
  if e.id == world.event.S_EVENT_SHOT and e.initiator then           -- who has fired (defender smoke)
    local d = ok(e.initiator.getDesc, e.initiator)
    if d and (d.category == Unit.Category.AIRPLANE or d.category == Unit.Category.HELICOPTER) then
      B.x4.shots = B.x4.shots or {}
      B.x4.shots[ok(e.initiator.getName, e.initiator) or "?"] = timer.getTime()
    end
  end
  -- a CA player taking over a vehicle that already exists (no birth event)
  if e.id == world.event.S_EVENT_PLAYER_ENTER_UNIT and e.initiator and isGroundUnit(e.initiator)
     and ok(e.initiator.getPlayerName, e.initiator) and not B.players[ok(e.initiator.getName, e.initiator) or ""] then
    B.registerPlayer(e.initiator)
  end
  if e.id == world.event.S_EVENT_TAKEOFF and e.initiator then
    local p = B.players[ok(e.initiator.getName, e.initiator) or ""]
    if p then B.qraTakeoff(p) end
  end
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  local crew = B.x4.qraCrew[m.id]
  B.x4.qraCrew[m.id] = nil
  if crew and outcome == "done" then
    for key in pairs(crew) do
      local name = m.taken and m.taken[key]
      if name then
        DCC.pilots:add(key, "qra", 1, name)
        for _, p in pairs(B.players) do
          if p.key == key then
            trigger.action.outTextForGroup(p.gid, string.format("QRA bonus: +%d.", DCC.Pilots.POINTS.qra), 12)
          end
        end
      end
    end
  end
  return baseDone(m, outcome)
end

-- ===========================================================================
-- 15. Engineer repair kit
-- ===========================================================================
function B.repairDown(crate, pos, loud)
  local war = B.war
  local side = sideOfCoal(crate.coalition)
  local function tell(text) if loud then trigger.action.outTextForCoalition(crate.coalition, text, 12) end end
  pos = pos or crate.position
  if not (war and side and pos) then return false end
  local km = XC().repair.km
  local best, bestD
  for _, id in ipairs(war.T.order) do
    local np = B.nodePos[id]
    if np and war.state.nodes[id].side == side then
      local d = dist2D(pos, np)
      if d <= km * 1000 and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  if not best then tell(string.format("A repair kit goes down within %d km of a friendly base.", km)); return false end
  if not war:repairNeed(best) then
    tell(string.format("Nothing to repair at %s - the kit stays on the ground for later.", war:nodeName(best)))
    return false
  end
  local text = war:engineerRepair(best, side)
  if not text then return false end
  tell(text .. ".")
  local cm = CTLDCrateManager and CTLDCrateManager.getInstance()
  if cm then ok(cm.destroyCrate, cm, crate.crateName) end
  if B.reconcileStatics then ok(B.reconcileStatics) end      -- the building / site is back at once
  if B.reconcileSams then ok(B.reconcileSams) end
  return true
end

if B.heavyDown then
  local baseHeavy = B.heavyDown
  function B.heavyDown(crate, pos, loud)
    if crate and crate.descriptor and crate.descriptor.dccHeavy == "repair" then
      return B.repairDown(crate, pos, loud)
    end
    return baseHeavy(crate, pos, loud)
  end
end

if B.ctldConfigure then
  local baseConfigure = B.ctldConfigure
  function B.ctldConfigure()
    baseConfigure()
    local crates = ctld.gs("spawnableCrates") or {}
    local list = crates["Engineering"] or {}
    local r = XC().repair
    list[#list + 1] = { unit = "DCC_REPAIRKIT", desc = "Repair kit (buildings, SAM, EWR)", weight = r.weight,
                        cratesRequired = 1, dccHeavy = "repair", dccCharge = r.charge }
    crates["Engineering"] = list
    CTLDConfig.get():setSetting("spawnableCrates", crates)
  end
end

-- ===========================================================================
-- 16. Performance guard
-- ===========================================================================
function B.groundUnitCount()
  if not (coalition and coalition.getGroups and Group) then return 0 end
  local n = 0
  for _, c in ipairs({ 1, 2 }) do
    for _, g in ipairs(ok(coalition.getGroups, c, Group.Category.GROUND) or {}) do
      for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then n = n + 1 end end
    end
  end
  return n
end

local function applyLevel(level)
  local cfg, pc = DCC.config, XC().perf
  local base = B.x4.perfBase
  if not base then
    base = { radius = cfg.liveRadiusKm, platoons = cfg.maxLivePlatoons, skirm = cfg.ground.skirmishMax,
             popups = cfg.ext3 and cfg.ext3.popup.max }
    B.x4.perfBase = base
  end
  local s = level > 0 and pc.levels[level].scale or 1
  cfg.liveRadiusKm = math.max(pc.minRadiusKm, math.floor(base.radius * (0.5 + 0.5 * s) + 0.5))
  cfg.maxLivePlatoons = math.max(10, math.floor(base.platoons * s))
  cfg.ground.skirmishMax = math.floor(base.skirm * s)
  if base.popups then cfg.ext3.popup.max = math.max(1, math.floor(base.popups * s)) end
  B.x4.perfLevel = level
end

function B.perfCheck(force)
  local pc = XC().perf
  local now = timer.getTime()
  if not force and now < B.x4.perfNext then return end
  B.x4.perfNext = now + pc.everySec
  local n = B.groundUnitCount()
  local cur, level = B.x4.perfLevel, 0
  for i, l in ipairs(pc.levels) do if n >= l.units then level = i end end
  -- step down only once clearly below the current level (no flicker)
  if level < cur and n >= pc.levels[cur].units * pc.restore then level = cur end
  if level == cur then return end
  applyLevel(level)
  local cfg = DCC.config
  if level > 0 then
    trigger.action.outText(string.format(
      "Server busy (%d ground units): fewer units in the field - live radius %d km, up to %d platoons, %d skirmishes.",
      n, cfg.liveRadiusKm, cfg.maxLivePlatoons, cfg.ground.skirmishMax), 15)
  else
    trigger.action.outText("Server load back to normal: full live radius and battles again.", 15)
  end
  U.log("performance guard: level %d (%d ground units)", level, n)
end

-- ===========================================================================
-- 1. Bogey dope (v0.34)
-- ===========================================================================
-- The nearest enemy aircraft your side has seen (radars, AWACS, eyes - the same
-- fog-of-war picture as the map) in the last staleSec: BRAA and aspect.
local function aspectOf(c, u, me)
  local v = u and ok(u.getVelocity, u)
  if not (v and v.x and (math.abs(v.x) + math.abs(v.z)) > 5) then return nil end
  local h = math.sqrt(v.x * v.x + v.z * v.z)
  local tx, tz = me.x - c.pos.x, me.z - c.pos.z
  local d = math.max(1, math.sqrt(tx * tx + tz * tz))
  local cosA = (v.x * tx + v.z * tz) / (h * d)                 -- 1 = flying straight at you
  if cosA >= 0.866 then return "HOT" elseif cosA >= 0.26 then return "FLANKING"
  elseif cosA >= -0.5 then return "BEAM" else return "DRAG" end
end

function B.bogeyDope(uname)
  local p = B.players[uname]
  local u = p and ok(Unit.getByName, uname)
  if not (p and alive(u)) then return end
  local me, cfg, now = u:getPoint(), XC().bogey, timer.getTime()
  local best
  for name, c in pairs(B.airContacts and B.airContacts[p.side] or {}) do
    if c.pos and now - (c.t or 0) <= cfg.staleSec then
      local d = dist2D(me, c.pos)
      if d <= cfg.maxNm * 1852 and (not best or d < best.d) then best = { name = name, c = c, d = d } end
    end
  end
  if not best then
    return trigger.action.outTextForGroup(p.gid, string.format("BOGEY DOPE: clean - no contacts within %d nm.", cfg.maxNm), 12)
  end
  local c = best.c
  local brg = (math.deg(math.atan2(c.pos.z - me.z, c.pos.x - me.x)) + 360) % 360
  local asp = aspectOf(c, ok(Unit.getByName, best.name), me)
  trigger.action.outTextForGroup(p.gid, string.format("BOGEY DOPE: BRAA %03d / %d nm / %d ft%s - %s (%d s old)",
    math.floor(brg + 0.5) % 360, math.floor(best.d / 1852 + 0.5), math.floor((c.alt or 0) * 3.28084 / 1000 + 0.5) * 1000,
    asp and (", " .. asp) or "", c.type or "aircraft", math.floor(now - (c.t or now))), 15)
end

if B.buildSupportMenu then
  local baseSupport4 = B.buildSupportMenu
  function B.buildSupportMenu(p)
    baseSupport4(p)
    if p and not p.ground and p.gid and p.supportMenu then
      missionCommands.addCommandForGroup(p.gid, "Bogey dope", p.supportMenu, B.bogeyDope, p.unit)
    end
  end
end

-- ===========================================================================
-- 2. Sortie debrief (v0.34)
-- ===========================================================================
-- From take-off to landing at a friendly base / FARP / own carrier: flight
-- time, kills, missions and what they did, points and rank.
local KILLS = { { "kills_air", "air" }, { "kills_ground", "ground" }, { "kills_convoy", "convoy" },
                { "kills_sam", "SAM" }, { "kills_structure", "buildings" } }
local EFFECT_DONE = {
  CAS = "the battle went our way", BAI = "the column will never arrive", STRIKE = "base output cut",
  SEAD = "air defence down", CAP = "1 h of air cover", ESCORT = "delivered", CONVOY = "delivered, no ambush",
  RECON = "intel on the map", CSAR = "pilot home, aircraft refunded", LOGISTICS = "supply delivered",
  INTERCEPT = "the attack never arrived", TANKER = "enemy tanker down", EWR = "radar off the air",
  ARTY = "battery silenced", FORT = "defences weakened", BRIDGE = "road cut", RUNWAY = "runway closed",
  FARP = "new FARP open", FARPSUP = "FARP stocked", MEDEVAC = "wounded home", POW = "prisoners home",
  SHIPSTRIKE = "cargo sunk", SHIPESCORT = "ship docked", SCUD = "launcher destroyed", POPUP = "threat cleared",
  ANTISHIP = "ship hit", HVAA = "enemy AWACS down", MINESWEEP = "harbour open again",
}

local function snapshot(p)
  local rec = DCC.pilots:get(p.key, p.name)
  local s = { t = timer.getTime(), score = DCC.pilots:score(p.key), rank = DCC.pilots:rank(p.key), kills = {}, missions = {} }
  for _, k in ipairs(KILLS) do s.kills[k[1]] = rec[k[1]] or 0 end
  return s
end

local function atHome(p, u)
  local pos = u:getPoint()
  if B.nearestNodeOf(pos, p.side, 5000) then return true end
  for _, rec in pairs(B.naval or {}) do
    local g = ok(Group.getByName, rec.group)
    local cv = g and ok(g.getUnit, g, 1)
    if rec.side == p.side and alive(cv) and dist2D(cv:getPoint(), pos) < 800 then return true end
  end
  return false
end

function B.debrief(p)
  local s = p.debrief
  if not s then return end
  p.debrief = nil
  local rec = DCC.pilots:get(p.key, p.name)
  local lines = { string.format("DEBRIEF - %d min", math.floor((timer.getTime() - s.t) / 60 + 0.5)) }
  local kills = {}
  for _, k in ipairs(KILLS) do
    local n = (rec[k[1]] or 0) - s.kills[k[1]]
    if n > 0 then kills[#kills + 1] = n .. " " .. k[2] end
  end
  lines[#lines + 1] = "Kills: " .. (#kills > 0 and table.concat(kills, ", ") or "none")
  if #s.missions == 0 then lines[#lines + 1] = "Missions: none finished" end
  for _, m in ipairs(s.missions) do
    lines[#lines + 1] = string.format("%s %s: %s%s", m.type, m.label, m.outcome == "done" and "COMPLETE" or m.outcome:upper(),
      (m.outcome == "done" and EFFECT_DONE[m.type]) and (" - " .. EFFECT_DONE[m.type]) or "")
  end
  local score, rank = DCC.pilots:score(p.key), DCC.pilots:rank(p.key)
  lines[#lines + 1] = string.format("Points: %+d (total %d)%s", score - s.score, score,
    rank ~= s.rank and string.format(" - PROMOTED: %s -> %s!", s.rank, rank) or "")
  trigger.action.outTextForGroup(p.gid, table.concat(lines, "\n"), 30)
end

local baseOps5 = B.onOpsEvent
function B.onOpsEvent(e)
  baseOps5(e)
  local u = e.initiator
  local p = u and B.players[ok(u.getName, u) or ""]
  if not p or p.ground then return end
  if e.id == world.event.S_EVENT_TAKEOFF then
    if not p.debrief then p.debrief = snapshot(p) end
  elseif e.id == world.event.S_EVENT_LAND and p.debrief and alive(u) and atHome(p, u) then
    B.debrief(p)
  end
end

local baseDone5 = B.onMissionDone
function B.onMissionDone(m, outcome)
  for key in pairs(m.taken or {}) do
    for _, p in pairs(B.players) do
      if p.key == key and p.debrief then
        table.insert(p.debrief.missions, { type = m.type, label = m.label, outcome = outcome })
      end
    end
  end
  return baseDone5(m, outcome)
end

-- ===========================================================================
-- 8. Harbour mines (v0.34)
-- ===========================================================================
local function llv(p) local v = coord.LLtoLO(p.lat, p.lon, 0); return { x = v.x, y = 0, z = v.z } end
function B.harbourPos(port)
  local l = B.war:laneOf(port)
  return l and llv(l.dock)
end

local baseCanFly5 = B.canFly
function B.canFly(p, m)
  if m and m.needs == "SWEEP" then return p and p.heli == true and not p.ground end
  return baseCanFly5(p, m)
end

local baseMissionPos5 = B.missionPos
function B.missionPos(m)
  if m.type == "MINESWEEP" then return B.harbourPos(m.target) or baseMissionPos5(m) end
  return baseMissionPos5(m)
end

if B.EFFECT then
  B.EFFECT.MINESWEEP = "Fly a helicopter below 150 m within 3 km of the harbour (the orange circle) for 5 min in total "
    .. "- several helicopters sweep faster. No supply ship sails for a mined port."
end

function B.sweepTick()
  local now = timer.getTime()
  local dt = now - (B.x4.sweepAt or now)
  B.x4.sweepAt = now
  if dt <= 0 then return end
  local cfg = XC().mines
  for _, p in pairs(B.players or {}) do
    local m = p.heli and p.mission and B.war.state.missions[p.mission]
    local u = m and m.type == "MINESWEEP" and ok(Unit.getByName, p.unit)
    if u and alive(u) and ok(u.inAir, u) then
      local up, hp = u:getPoint(), B.harbourPos(m.target)
      local agl = up.y - (ok(land.getHeight, { x = up.x, y = up.z }) or 0)
      if hp and agl <= cfg.sweepAglM and dist2D(up, hp) <= cfg.sweepKm * 1000 then B.war:sweepSample(m.id, dt) end
    end
  end
end

function B.drawMines()
  B.x4.mineMarks = B.x4.mineMarks or {}
  local mined = B.war:minedPorts()
  for port, ids in pairs(B.x4.mineMarks) do
    if not mined[port] then
      for _, id in ipairs(ids) do ok(trigger.action.removeMark, id) end
      B.x4.mineMarks[port] = nil
    end
  end
  for port in pairs(mined) do
    local hp = B.harbourPos(port)
    if hp and not B.x4.mineMarks[port] then
      B.x4.mineN = (B.x4.mineN or 0) + 1
      local id = DCC.config.markIdBase + 950000 + B.x4.mineN * 2
      ok(trigger.action.circleToAll, -1, id, hp, XC().mines.sweepKm * 1000, { 1, 0.55, 0, 1 }, { 1, 0.55, 0, 0.15 }, 2, true)
      ok(trigger.action.textToAll, -1, id + 1, hp, { 1, 0.55, 0, 1 }, { 0, 0, 0, 0 }, 14, true, "MINES")
      B.x4.mineMarks[port] = { id, id + 1 }
    end
  end
end

-- Minelayer ships (v0.35) ----------------------------------------------------
local function groupUnits(gname)
  local g = gname and ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(ok(g.getUnits, g) or {}) do if alive(u) then out[#out + 1] = u end end
  end
  return out
end

function B.minelayerPos(ml)
  local rec = (B.x4.layers or {})[ml.id]
  local u = rec and groupUnits(rec.group)[1]
  if u then return u:getPoint() end
  local l = B.war:laneOf(ml.port)
  if not l then return nil end
  local a, b = llv(l.start), llv(l.dock)
  return { x = a.x + (b.x - a.x) * ml.progress, y = 0, z = a.z + (b.z - a.z) * ml.progress }
end

-- Spawn with the first type this server has (the Bykov is a mod: falls back).
local function spawnLayer(ml, p, dock)
  local cfg = XC().mines
  local speed = cfg.layerSpeedKmh / 3.6
  local hdg = math.atan2(dock.z - p.z, dock.x - p.x)
  B.x4.layerN = (B.x4.layerN or 0) + 1
  for _, t in ipairs((cfg.layerShips or {})[ml.side] or {}) do
    local gname = string.format("DCC_MINELAYER_%s_%d", ml.id, B.x4.layerN)
    local okA = pcall(coalition.addGroup, B.countryId(ml.side), Group.Category.SHIP, { name = gname,
      units = { { name = gname .. "_1", type = t, skill = "Excellent", x = p.x, y = p.z, heading = hdg } },
      route = { points = {
        { x = p.x, y = p.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
          ETA_locked = false, speed_locked = true },
        { x = dock.x, y = dock.z, type = "Turning Point", action = "Turning Point", speed = speed, ETA = 0,
          ETA_locked = false, speed_locked = true } } } })
    if okA and #groupUnits(gname) > 0 then return gname, t end
    local g = ok(Group.getByName, gname)
    if g then ok(g.destroy, g) end
    U.log("minelayer type %s not available, trying the next", t)
  end
  return nil
end

function B.reconcileMinelayers()
  local war = B.war
  B.x4.layers = B.x4.layers or {}
  local mls = war:minelayers()
  for id, rec in pairs(B.x4.layers) do
    if not mls[id] then
      local g = ok(Group.getByName, rec.group)
      if g then ok(g.destroy, g) end                       -- mines laid (or called off): it heads home
      B.x4.layers[id] = nil
    elseif #groupUnits(rec.group) == 0 then
      B.x4.layers[id] = nil
      war:minelayerSunk(id)
    end
  end
  local cfg = XC().mines
  for _, id in ipairs(U.sortedKeys(war:minelayers())) do
    local ml = war:minelayers()[id]
    local pos = B.minelayerPos(ml)
    -- spotted by an enemy aircraft that comes close
    if pos and not ml.seen then
      for _, u in ipairs(coalition.getPlayers(B.COAL[ml.side == "blue" and "red" or "blue"]) or {}) do
        if alive(u) and dist2D(u:getPoint(), pos) <= cfg.spotKm * 1000 then war:spotMinelayer(id); break end
      end
    end
    local l = war:laneOf(ml.port)
    if l and pos and not B.x4.layers[id] and #B.playerPositions() > 0 then
      local gname, t = spawnLayer(ml, pos, llv(l.dock))
      if gname then B.x4.layers[id] = { group = gname, type = t } end
    end
  end
end

local baseMissionPos6 = B.missionPos
function B.missionPos(m)
  if m.type == "MINELAYER" then
    local ml = B.war:minelayers()[m.target]
    return ml and B.minelayerPos(ml)
  end
  return baseMissionPos6(m)
end

if B.EFFECT then
  B.EFFECT.MINELAYER = "Sink the minelayer before it reaches the harbour. Once it lays its mines, no supply ship "
    .. "can use the port until a helicopter sweeps it."
end

-- the hunted minelayer on the defender's map, redrawn every 5 min
function B.drawMinelayers()
  for _, id in ipairs(B.x4.layerMarks or {}) do ok(trigger.action.removeMark, id) end
  B.x4.layerMarks = {}
  for _, id in ipairs(U.sortedKeys(B.war:minelayers())) do
    local ml = B.war:minelayers()[id]
    local pos = ml.seen and B.minelayerPos(ml)
    if pos then
      B.x4.mineN = (B.x4.mineN or 0) + 1
      local mid = DCC.config.markIdBase + 950000 + B.x4.mineN * 2
      local coal = B.COAL[ml.side == "blue" and "red" or "blue"]
      ok(trigger.action.textToAll, coal, mid, pos, { 1, 0.55, 0, 1 }, { 0, 0, 0, 0.4 }, 13, true,
        "MINELAYER > " .. B.war:nodeName(ml.port))
      B.x4.layerMarks[#B.x4.layerMarks + 1] = mid
    end
  end
end

local baseAnnounce5 = B.announce
function B.announce(events)
  baseAnnounce5(events)
  for _, ev in ipairs(events) do
    if ev.kind == "minelayer_out" or ev.kind == "minelayer_seen" or ev.kind == "minelayer_sunk" then
      if B.COAL[ev.side] then trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 15) end
      if ev.kind == "minelayer_sunk" then
        local other = ev.side == "blue" and "red" or "blue"
        trigger.action.outTextForCoalition(B.COAL[other], "Command: our minelayer for " .. B.war:nodeName(ev.node)
          .. " has been sunk.", 15)
      end
    end
    if ev.kind == "mines_laid" or ev.kind == "mines_cleared" or ev.kind == "mine_strike" then
      if B.COAL[ev.side] then trigger.action.outTextForCoalition(B.COAL[ev.side], "Command: " .. ev.text, 15) end
      if ev.kind == "mines_laid" and ev.layer and B.COAL[ev.layer] then
        trigger.action.outTextForCoalition(B.COAL[ev.layer], string.format("Command: our minelayers have mined %s.",
          B.war:nodeName(ev.node)), 15)
      end
      if ev.kind == "mine_strike" then
        local hp = B.harbourPos(ev.node)
        if hp then ok(trigger.action.explosion, { x = hp.x, y = 0, z = hp.z }, 300) end
      end
    end
  end
end

local baseTick5 = B.opsTick
function B.opsTick()
  baseTick5()
  B.drawMines()
  B.drawMinelayers()
end

-- ===========================================================================
-- Main base / HQ on the map (v0.38)
-- ===========================================================================
-- A star and a double ring round each side's HQ, on everyone's map, redrawn
-- with the rest of the map (it moves if the HQ falls).
local baseDrawOps7 = B.drawOps
function B.drawOps(newMark, toVec3)
  baseDrawOps7(newMark, toVec3)
  local war, cfg = B.war, DCC.config
  for _, side in ipairs({ "blue", "red" }) do
    local id = war:mainBase(side)
    local pos = id and B.nodePos[id]
    if pos then
      local col = cfg.colours[side]
      ok(trigger.action.circleToAll, -1, newMark(), pos, 5200, col, { col[1], col[2], col[3], 0 }, 1, true)
      ok(trigger.action.circleToAll, -1, newMark(), pos, 5800, col, { col[1], col[2], col[3], 0 }, 1, true)
      ok(trigger.action.textToAll, -1, newMark(), { x = pos.x + 7000, y = pos.y, z = pos.z - 3000 }, col,
        { 0, 0, 0, 0.45 }, 22, true, string.format("\226\152\133 %s HQ - %s", side:upper(), war:nodeName(id)))
    end
  end
end

if B.opsStatusLines then
  local baseStatus7 = B.opsStatusLines
  function B.opsStatusLines(side)
    local lines = baseStatus7(side) or {}
    local own, enemy = B.war:mainBase(side), B.war:mainBase(side == "blue" and "red" or "blue")
    table.insert(lines, 1, string.format("HQ: %s (enemy HQ: %s) - the star on the map",
      own and B.war:nodeName(own) or "none", enemy and B.war:nodeName(enemy) or "none"))
    return lines
  end
end

-- ===========================================================================
-- Loops
-- ===========================================================================
local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.groundPresenceTick()
  B.sweepTick()
  B.reconcileMinelayers()
  B.aiSmokeTick()
  B.defenseSmokeTick()
  B.qraScan()
  B.perfCheck()
end

local baseInit = B.init
function B.init(war, theater, catalog)
  if B.x4.perfBase then applyLevel(0) end          -- a new war starts at the full settings
  baseInit(war, theater, catalog)
  B.x4 = fresh()
end

end

-- >>> src/dcc_dcs_armoury.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge: armoury by warehouse stock.
-- Load after dcc_dcs_ext_air.lua.
-- ----------------------------------------------------------------------------
-- ext.armoury.mode = "warehouse" (the mission must have limited munitions):
-- instead of recalling aircraft at take-off, every airbase's and FARP's
-- warehouse is stocked by the base's supply, so the re-arm menu itself only
-- offers what the base has.
--     basic    (bombs, rockets, tanks, pods)       always, free
--     guided   (IR missiles, laser / TV weapons)    from 30 % supply, 0.5 SU each
--     advanced (radar / anti-radiation / GPS ...)   from 60 % supply, 1 SU each
-- Shelves are topped up every 5 min. What pilots took since the last top-up
-- is paid from the base's supply; weapons above the base's tier come off the shelf.
--
-- Weapon names come from DCS itself (Warehouse.getResourceMap, or a
-- warehouse inventory), else from the catalogue's list. Each name is tested
-- once (setItem / getItemCount) and only names DCS accepts are used.
-- F10 > Armoury test shows what was found, so a server test can confirm it.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

local function AC() return DCC.config.ext.armoury end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

B.arm = { names = {}, tier = {}, source = "none", tested = 0, accepted = 0, rejected = {}, page = 1 }

-- if a mission sets DCC_ARMOURY_MODE before loading the engine, it wins
if DCC_ARMOURY_MODE then DCC.config.ext.armoury.mode = DCC_ARMOURY_MODE end
-- a test mission keeps its own saves and pilot records, and ignores the map rotation
if DCC_TEST_MISSION then
  DCC.config.saveFolder = "DCC_test"
  DCC.config.rotationEnforce = false
  DCC.config.ext.armoury.testMenu = true
end

function B.armWarehouseMode() return AC().mode == "warehouse" end

-- ===========================================================================
-- Tier of a weapon by its DCS resource name
-- ===========================================================================
-- Missiles: every missile is at least "guided"; these are "advanced"
-- (radar-guided air-to-air, anti-radiation, anti-ship, cruise, stand-off).
local ADV_MISSILE = { "aim_120", "aim120", "aim-120", "aim_7", "aim7", "aim-7", "aim_54", "aim54", "aim-54", "r_77", "r-77",
              "r_27", "r-27", "sd_10", "sd-10", "pl_12", "pl-12", "r_33", "r-33", "r_37", "r-37", "r_40", "r-40",
              "agm_88", "agm-88", "harm", "kh_58", "kh-58", "x_58", "kh_25mp", "kh-25mp", "x_25mp", "kh_31", "kh-31", "x_31",
              "agm_84", "agm-84", "harpoon", "slam", "kh_35", "kh-35", "x_35", "kh_59", "kh-59", "x_59", "agm_154", "agm-154",
              "c_802", "c-802", "yj_", "yj-", "agm_158", "storm_shadow", "scalp", "aim_260", "aim-260", "meteor", "derby",
              "mica_em", "super_530d", "super530d", "lj_7", "cm-400", "cm_400", "c_701ir" }
-- Bombs: unguided unless they match these; "advanced" first (GPS / glide), then "guided" (laser / TV).
local ADV_BOMB = { "gbu_31", "gbu-31", "gbu_32", "gbu-32", "gbu_38", "gbu-38", "gbu_39", "gbu-39", "gbu_54", "gbu-54",
                   "gbu_53", "jdam", "kab_500s", "kab-500s", "ls_6", "ls-6", "gb_6", "gb-6", "agm_154", "jsow", "lj_7" }
local GUIDED_BOMB = { "gbu_", "gbu-", "kab_", "kab-", "lgb", "paveway", "bgl", "agm_62", "walleye" }
-- Rockets: unguided unless laser-guided
local GUIDED_ROCKET = { "apkws", "agr_20", "agr-20" }

local function has(name, list)
  for _, p in ipairs(list) do if name:find(p, 1, true) then return true end end
  return false
end

-- By DCS's own category first (weapons.<category>.<name>), then by name.
-- Adapters, launchers, pods, tanks, guns and everything else are "basic":
-- always on the shelf, so a loadout never fails for want of a pylon.
function B.weaponTier(name)
  local n = string.lower(name)
  local cat = n:match("^weapons%.([^%.]+)%.") or ""
  if cat == "missiles" then
    return has(n, ADV_MISSILE) and "advanced" or "guided"
  elseif cat == "bombs" then
    if has(n, ADV_BOMB) then return "advanced" end
    if has(n, GUIDED_BOMB) then return "guided" end
    return "basic"
  elseif cat == "nurs" or cat == "rockets" then
    return has(n, GUIDED_ROCKET) and "guided" or "basic"
  end
  return "basic"
end

-- ===========================================================================
-- Finding the names DCS uses
-- ===========================================================================
local function addName(set, list, name)
  if type(name) == "string" and name:find("^weapons%.") and not set[name] then
    set[name] = true
    list[#list + 1] = name
  end
end

local function anyWarehouse()
  for id, name in pairs(B.airbases or {}) do
    local ab = ok(Airbase.getByName, name)
    local w = ab and ok(ab.getWarehouse, ab)
    if w then return w, id end
  end
end

function B.discoverWeapons()
  local set, list = {}, {}
  -- 1. the full resource list, when this DCS version has it
  if Warehouse and Warehouse.getResourceMap then
    local map = ok(Warehouse.getResourceMap)
    if type(map) == "table" then
      for k, v in pairs(map) do
        addName(set, list, k)
        if type(v) == "table" then addName(set, list, v.name or v.typeName) end
      end
      if #list > 0 then B.arm.source = "getResourceMap" end
    end
  end
  -- 2. what a warehouse holds right now
  if #list == 0 then
    local w = anyWarehouse()
    local inv = w and ok(w.getInventory, w)
    if type(inv) == "table" then
      for k in pairs(inv.weapon or inv.weapons or {}) do addName(set, list, k) end
      if #list > 0 then B.arm.source = "inventory" end
    end
  end
  -- 3. the catalogue's list (always added: covers what DCS did not report)
  local before = #list
  for _, n in ipairs((B.catalog.weapons or {}).names or {}) do addName(set, list, n) end
  if B.arm.source == "none" and #list > before then B.arm.source = "catalogue" end
  table.sort(list)
  return list
end

-- Keep only names DCS accepts: set 1, read it back, put it back.
function B.testWeaponNames(list)
  local w = anyWarehouse()
  local okNames, rejected = {}, {}
  if not w then return okNames, list end
  for _, name in ipairs(list) do
    local before = ok(w.getItemCount, w, name) or 0
    ok(w.setItem, w, name, before + 1)
    local after = ok(w.getItemCount, w, name)
    ok(w.setItem, w, name, before)
    if after == before + 1 then okNames[#okNames + 1] = name else rejected[#rejected + 1] = name end
  end
  return okNames, rejected
end

function B.armouryInit()
  local list = B.discoverWeapons()
  local names, rejected = B.testWeaponNames(list)
  B.arm.names, B.arm.rejected, B.arm.tested, B.arm.accepted = names, rejected, #list, #names
  B.arm.tier = {}
  for _, n in ipairs(names) do B.arm.tier[n] = B.weaponTier(n) end
  U.log("armoury: %d weapon names from %s, %d accepted by the warehouse", #list, B.arm.source, #names)
  if #names == 0 then
    U.log("ERROR armoury: no weapon names accepted - the re-arm menu would be empty")
    trigger.action.outText("ARMOURY: no weapon names found. Use the normal mission (unlimited munitions).", 60)
  end
end

-- ===========================================================================
-- Stocking
-- ===========================================================================
local ORDER = { basic = 1, guided = 2, advanced = 3 }

local function warehousesOf(id, side)
  local out = { farp = {} }
  local name = B.airbases and B.airbases[id]
  local ab = name and ok(Airbase.getByName, name)
  local w = ab and ok(ab.getWarehouse, ab)
  if w then out[#out + 1] = w end
  if B.war:canHaveFarp(id) and B.war:farpAt(id) then
    for _, pad in ipairs(B.farpPadNames and B.farpPadNames(id, side) or { "DCC_FARP_" .. id .. "_" .. side }) do
      local fab = ok(Airbase.getByName, pad)
      local fw = fab and ok(fab.getWarehouse, fab)
      if fw then out[#out + 1] = fw; out.farp[#out] = true end
    end
  end
  return out
end

function B.restockArmoury()
  if not B.armWarehouseMode() or #B.arm.names == 0 then return end
  local war, cfg = B.war, AC()
  B.arm.last = B.arm.last or {}
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local whs = (ns.side == "blue" or ns.side == "red") and warehousesOf(id, ns.side) or {}
    if #whs > 0 then
      local tier = war:armouryTier(id)
      local big = war.T.nodes[id].depot and (cfg.depotStock or 1) or 1
      for k, w in ipairs(whs) do
        for _, name in ipairs(B.arm.names) do
          local t = B.arm.tier[name]
          local key = id .. "|" .. k .. "|" .. name
          local cur = ok(w.getItemCount, w, name) or 0
          -- what pilots took since the last restock is paid for now
          local taken = math.max(0, (B.arm.last[key] or cur) - cur)
          local each = (t == "advanced" and cfg.advancedSU) or (t == "guided" and cfg.guidedSU) or 0
          if taken > 0 and each > 0 then ns.supply = math.max(0, (ns.supply or 0) - taken * each) end
          local target = (ORDER[t] <= ORDER[tier]) and (cfg.stock[t] or 0) * big or 0
          if whs.farp[k] and war:farpDry(id) then target = 0 end      -- a dry FARP: empty shelves
          if cur ~= target then ok(w.setItem, w, name, target) end   -- top up, or off the shelf
          B.arm.last[key] = target
        end
      end
    end
  end
end

-- the take-off recall is not needed: what is on the shelf is what you get
local baseTakeoff = B.armouryTakeoff
function B.armouryTakeoff(p, u)
  if B.armWarehouseMode() then return end
  return baseTakeoff(p, u)
end
local baseTaxi = B.armouryCheckTaxi
function B.armouryCheckTaxi(p, u)
  if B.armWarehouseMode() then return end
  return baseTaxi(p, u)
end

-- ===========================================================================
-- F10 > Armoury test (warehouse mode only)
-- ===========================================================================
local function tierCounts()
  local c = { basic = 0, guided = 0, advanced = 0 }
  for _, n in ipairs(B.arm.names) do c[B.arm.tier[n]] = c[B.arm.tier[n]] + 1 end
  return c
end

function B.armouryReport()
  local c = tierCounts()
  local lines = {
    "ARMOURY TEST",
    string.format("Warehouse.getResourceMap: %s", (Warehouse and Warehouse.getResourceMap) and "yes" or "no"),
    string.format("Names from: %s. Tested %d, accepted %d, rejected %d.", B.arm.source, B.arm.tested, B.arm.accepted,
      #B.arm.rejected),
    string.format("Tiers: basic %d, guided %d, advanced %d.", c.basic, c.guided, c.advanced),
  }
  for _, t in ipairs({ "guided", "advanced" }) do
    local s = {}
    for _, n in ipairs(B.arm.names) do
      if B.arm.tier[n] == t and #s < 12 then s[#s + 1] = n:gsub("^weapons%.", "") end
    end
    lines[#lines + 1] = t .. ": " .. table.concat(s, ", ")
  end
  if #B.arm.rejected > 0 then
    local s = {}
    for i = 1, math.min(8, #B.arm.rejected) do s[i] = B.arm.rejected[i]:gsub("^weapons%.", "") end
    lines[#lines + 1] = "rejected (sample): " .. table.concat(s, ", ")
  end
  trigger.action.outText(table.concat(lines, "\n"), 60)
end

function B.armouryListPage()
  local per, names = 40, B.arm.names
  local pages = math.max(1, math.ceil(#names / per))
  local pg = ((B.arm.page - 1) % pages) + 1
  local s = {}
  for i = (pg - 1) * per + 1, math.min(#names, pg * per) do
    s[#s + 1] = string.format("%s [%s]", names[i]:gsub("^weapons%.", ""), B.arm.tier[names[i]]:sub(1, 1))
  end
  trigger.action.outText(string.format("ARMOURY names page %d/%d (b/g/a = tier)\n%s", pg, pages, table.concat(s, "\n")), 60)
  B.arm.page = pg + 1
end

function B.armouryBaseReport(side)
  local war = B.war
  local lines = { "ARMOURY STOCK (" .. side:upper() .. " bases)" }
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == side and B.airbases and B.airbases[id] and #lines < 12 then
      local w = warehousesOf(id, side)[1]
      local c = { basic = 0, guided = 0, advanced = 0 }
      for _, n in ipairs(B.arm.names) do
        if (w and ok(w.getItemCount, w, n) or 0) > 0 then c[B.arm.tier[n]] = c[B.arm.tier[n]] + 1 end
      end
      lines[#lines + 1] = string.format("%s: tier %s, supply %d%% - types on the shelf: %d basic, %d guided, %d advanced",
        war:nodeName(id), war:armouryTier(id), math.floor(100 * (ns.supply or 0) / math.max(1, war:supplyCap(id))),
        c.basic, c.guided, c.advanced)
    end
  end
  trigger.action.outText(table.concat(lines, "\n"), 45)
end

function B.armourySetSupply(args)
  -- test helper: every base of a side to a supply share, restock now
  local war, n = B.war, 0
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.side == args.side then
      ns.supply = war:supplyCap(id) * args.share
      n = n + 1
    end
  end
  B.restockArmoury()
  trigger.action.outText(string.format("TEST: all %d %s bases at %d%% supply - tier %s. Re-open the re-arm menu.",
    n, args.side:upper(), math.floor(args.share * 100), args.tier), 20)
end

function B.addArmouryTestMenu()
  if not AC().testMenu then return end
  for side, c in pairs(B.COAL) do
    local root = missionCommands.addSubMenuForCoalition(c, "Armoury test")
    missionCommands.addCommandForCoalition(c, "Report: what DCS gave us", root, B.armouryReport)
    missionCommands.addCommandForCoalition(c, "List the names (next page)", root, B.armouryListPage)
    missionCommands.addCommandForCoalition(c, "Stock at my side's bases", root, B.armouryBaseReport, side)
    missionCommands.addCommandForCoalition(c, "All bases 10 % supply (basic)", root, B.armourySetSupply,
      { side = side, share = 0.1, tier = "basic" })
    missionCommands.addCommandForCoalition(c, "All bases 45 % supply (guided)", root, B.armourySetSupply,
      { side = side, share = 0.45, tier = "guided" })
    missionCommands.addCommandForCoalition(c, "All bases 90 % supply (advanced)", root, B.armourySetSupply,
      { side = side, share = 0.9, tier = "advanced" })
  end
end

-- ===========================================================================
-- Wiring
-- ===========================================================================
local baseInit = B.init
function B.init(war, theater, catalog)
  baseInit(war, theater, catalog)
  B.arm = { names = {}, tier = {}, source = "none", tested = 0, accepted = 0, rejected = {}, page = 1 }
  if B.armWarehouseMode() then
    B.armouryInit()
    B.restockArmoury()
  end
end

local baseAddMenus = B.addMenus
function B.addMenus()
  baseAddMenus()
  if B.armWarehouseMode() then B.addArmouryTestMenu() end
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  if B.armWarehouseMode() then ok(B.restockArmoury) end
end

local baseText = B.armouryText
function B.armouryText(id)
  local t = baseText(id)
  if B.armWarehouseMode() then
    t = t:gsub("Guided weapons cost", "The re-arm menu shows what is on the shelf. Guided weapons cost")
  end
  return t
end

end

-- >>> src/dcc_main.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - main: start-up and the two loops
-- ----------------------------------------------------------------------------
--   DCC.start()  is called once at mission start (by the loader or bundle).
--   Every liveCheckSeconds (30 s): poll spawned units, update the live bubble.
--   Every tickSeconds (5 min):     advance the war one step, redraw, save.
--
-- Both loops run through timer.scheduleFunction and are wrapped in pcall, so a
-- script error is logged to dcs.log instead of silently stopping the war.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util

local function safe(name, fn)
  return function(...)
    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end, debug.traceback)
    if not ok then U.log("ERROR in %s: %s", name, tostring(err)) end
  end
end

local function pickTheater()
  local name = DCC.config.theater
  if name == "auto" then name = env.mission and env.mission.theatre end
  local t = DCC_THEATERS and DCC_THEATERS[name]
  if not t then
    local msg = "DCC: no theater pack for map '" .. tostring(name) .. "'. Campaign not started."
    U.log(msg)
    trigger.action.outText(msg, 60)
  end
  return t, name
end

local function newSeed()
  -- os is sanitized in missions; mission clock + absolute time is unique enough
  return math.floor((timer.getAbsTime() * 1000 + timer.getTime() * 7919) % 2147483646) + 1
end

function DCC.save()
  if DCC.warObj then DCC.persist.save(DCC.theaterName, DCC.warObj:snapshot()) end
  if DCC.pilots and DCC.pilots.dirty then
    if DCC.persist.savePilots(DCC.pilots.data) then DCC.pilots.dirty = false end
  end
end

-- One war step.
function DCC.onTick()
  local war = DCC.warObj
  DCC.dcs.readWarehouses()          -- aircraft players took off with or landed
  local events = war:tick()
  DCC.dcs.announce(events)
  DCC.dcs.syncAirbases()
  DCC.dcs.writeWarehouses()         -- captures and restocks
  DCC.dcs.reconcile()
  DCC.dcs.reconcileCargo()
  DCC.dcs.opsTick()                 -- mission targets, AI air, menus
  DCC.dcs.draw()
  DCC.save()

  if war.state.winner and not DCC.ended then
    DCC.ended = true
    trigger.action.setUserFlag(DCC.config.campaignOverFlag, 1)
    local nextMap = DCC.nextMap(DCC.theaterName)
    -- the war report (scores before the bonus), then the victory bonus
    local report = DCC.warReport(war)
    local names, pts = DCC.pilots:warWon(war.state.roster, war.state.winner, war.state.winBy,
      DCC.config.victoryMinSorties)
    if #names > 0 then
      report = report .. string.format("\n\nVictory bonus (+%d points, %s) for %d %s pilots: %s", pts,
        war.state.winBy == "conquest" and "conquest" or "war clock", #names, war.state.winner:upper(),
        table.concat(names, ", "))
    end
    trigger.action.outText(report, 90)
    DCC.persist.writeReport(DCC.theaterName, war.state.tick, report)
    if DCC.dcs.publishFeed then DCC.dcs.publishFeed({ { kind = "report", text = report } }); DCC.dcs.writePublic() end
    DCC.save()
    -- the server hook sees this and loads the next map's mission
    DCC.persist.writeRotation({ current = nextMap, state = "ended", finished = DCC.theaterName,
                                winner = war.state.winner, next = nextMap, tick = war.state.tick })
    -- rotation without file access or hooks: end the mission after 2 minutes;
    -- the server then loads the next mission in its list
    timer.scheduleFunction(function()
      trigger.action.setUserFlag(DCC.config.endMissionFlag, 1)
    end, nil, timer.getTime() + 120)
    trigger.action.outText(string.format("The war on %s is over. %s wins.%s",
      DCC.theaterName, war.state.winner:upper(),
      nextMap and (" Next theater: " .. nextMap .. ".") or ""), 120)
    U.log("war over, winner %s, flag %d set", war.state.winner, DCC.config.campaignOverFlag)
  end
end

-- End-of-war report: how it ended, what it cost each side, the best pilots.
function DCC.warReport(war)
  local st, cfg = war.state, DCC.config
  local s, stats = war:summary(), st.stats
  local function two(t) t = t or {}; return string.format("BLUE %d / RED %d", math.floor((t.blue or 0) + 0.5),
    math.floor((t.red or 0) + 0.5)) end
  local days = (st.tick - (st.clockStart or 0)) * cfg.tickSeconds / 86400
  local lines = {
    string.format("=== WAR REPORT - %s ===", war.T.name),
    string.format("%s won %s after %.1f days.", st.winner:upper(),
      st.winBy == "conquest" and "by conquest" or "on the war clock", days),
    "Bases held at the end:   " .. two({ blue = s.blue.nodes, red = s.red.nodes }),
    "Bases captured:          " .. two(stats.captures),
    "Platoons lost:           " .. two(stats.lost),
    "Supply delivered (SU):   " .. two(stats.delivered),
    "Supply destroyed (SU):   " .. two(stats.cargoLost),
    "AI aircraft lost:        " .. two(stats.airLost),
  }
  -- best pilots of this war: points scored since their first sortie here
  local best = {}
  for key, r in pairs(st.roster or {}) do
    local gained = DCC.pilots:score(key) - (r.start or 0)
    local side = (r.blue or 0) >= (r.red or 0) and "BLUE" or "RED"
    best[#best + 1] = { key = key, name = r.name or key, pts = gained, side = side,
                        sorties = (r.blue or 0) + (r.red or 0),
                        missions = (r.blue_missions or 0) + (r.red_missions or 0) }
  end
  table.sort(best, function(a, b) if a.pts ~= b.pts then return a.pts > b.pts end return a.key < b.key end)
  if #best > 0 then
    lines[#lines + 1] = string.format("Top pilots (%d flew in this war):", #best)
    for i = 1, math.min(5, #best) do
      local b = best[i]
      lines[#lines + 1] = string.format("  %d. %s (%s) - %d points, %d sorties, %d missions",
        i, b.name, b.side, b.pts, b.sorties, b.missions)
    end
    local sq, sqList = {}, {}
    for _, b in ipairs(best) do
      local tag = DCC.Pilots.squadronOf(b.name)
      if tag then
        sq[tag] = sq[tag] or { tag = tag, pts = 0, n = 0 }
        sq[tag].pts, sq[tag].n = sq[tag].pts + b.pts, sq[tag].n + 1
      end
    end
    for _, s in pairs(sq) do sqList[#sqList + 1] = s end
    table.sort(sqList, function(a, b) if a.pts ~= b.pts then return a.pts > b.pts end return a.tag < b.tag end)
    if #sqList > 0 then
      lines[#lines + 1] = "Top squadrons:"
      for i = 1, math.min(3, #sqList) do
        lines[#lines + 1] = string.format("  %d. %s - %d points (%d pilots)", i, sqList[i].tag, sqList[i].pts, sqList[i].n)
      end
    end
  else
    lines[#lines + 1] = "No pilots flew in this war - the generals fought it alone."
  end
  return table.concat(lines, "\n")
end

-- The map after this one in the fixed rotation.
function DCC.nextMap(current)
  local rot = DCC.config.rotation
  for i, m in ipairs(rot) do if m == current then return rot[i % #rot + 1] end end
  return rot[1]
end

function DCC.start()
  if DCC.started then return end
  local theater, name = pickTheater()
  if not theater then return end

  -- Map rotation: if the server should be on another map (a restart loaded
  -- the wrong mission), do not touch this map's war - the hook switches over.
  local rot = DCC.persist.readRotation()
  if DCC.config.rotationEnforce and rot and rot.current and rot.current ~= (theater.name or name) then
    DCC.waitingForRotation = rot.current
    local msg = string.format("DCC: the campaign has moved on to %s. Loading it...", rot.current)
    U.log(msg)
    trigger.action.outText(msg, 120)
    return
  end
  DCC.persist.writeRotation({ current = theater.name or name, state = "running" })
  local catalog = DCC_CATALOGS and DCC_CATALOGS[DCC.config.era]
  if not catalog then U.log("no catalog for era %s", tostring(DCC.config.era)); return end
  DCC.theaterName = theater.name or name

  -- Restore the running war, or start a new one (also after a finished war).
  local state = DCC.persist.load(DCC.theaterName)
  -- Fresh-war switch (troubleshooting): a new token in config.freshWar throws the saved war away
  -- once (it is archived as a finished war); the new war carries the token, so later restarts
  -- continue it. freshWar = false switches this off.
  local fresh = DCC.config.freshWar
  local forced = false
  if fresh and state and state.freshWar ~= fresh then
    U.log("fresh-war switch %s: the saved war on %s (tick %d) is archived, a new war starts",
      tostring(fresh), DCC.theaterName, state.tick or 0)
    DCC.persist.archive(DCC.theaterName, state)
    state, forced = nil, true
  end
  local war
  if state and not state.winner then
    war = DCC.War.restore(theater, catalog, DCC.config, state)
    U.log("war restored on %s at tick %d", DCC.theaterName, state.tick or 0)
  else
    if state and state.winner then DCC.persist.archive(DCC.theaterName, state) end
    war = DCC.War.new(theater, catalog, DCC.config, newSeed())
    U.log("new war started on %s", DCC.theaterName)
  end
  if fresh then war.state.freshWar = fresh end
  if forced then
    trigger.action.outText("DCC: FRESH WAR - the saved war was archived and a new one has started (fresh-war switch "
      .. tostring(fresh) .. ").", 60)
  end
  DCC.warObj = war
  DCC.started = true
  war.noSave = not DCC.persist.available()
  DCC.pilots = DCC.Pilots.new(DCC.persist.loadPilots())   -- kept across wars and maps
  war.onMissionDone = function(m, outcome) DCC.dcs.onMissionDone(m, outcome) end

  DCC.dcs.init(war, theater, catalog)
  DCC.dcs.writeWarehouses()         -- enemy aircraft off every base before anyone slots
  DCC.dcs.addMenus()
  DCC.dcs.updateLive()
  DCC.dcs.reconcile()
  DCC.dcs.reconcileCargo()
  DCC.dcs.opsPoll()
  DCC.dcs.opsTick()
  DCC.dcs.draw()
  if DCC.dcs.writePublic then DCC.dcs.writePublic() end

  -- Save when the mission ends; guard player slots; pilot records and missions.
  world.addEventHandler({ onEvent = function(_, e)
    if e.id == world.event.S_EVENT_MISSION_END then safe("save", DCC.save)()
    else
      if e.id == world.event.S_EVENT_BIRTH and e.initiator then
        safe("slotGuard", DCC.dcs.onBirth)(e.initiator)
      end
      safe("opsEvent", DCC.dcs.onOpsEvent)(e)
    end
  end })

  local cfg = DCC.config
  timer.scheduleFunction(function(_, t)
    safe("liveCheck", DCC.dcs.liveCheck)()
    safe("opsPoll", DCC.dcs.opsPoll)()
    return t + cfg.liveCheckSeconds
  end, nil, timer.getTime() + cfg.liveCheckSeconds)

  timer.scheduleFunction(function(_, t)
    safe("detect", DCC.dcs.detect)()
    return t + 10
  end, nil, timer.getTime() + 10)

  if DCC.dcs.intelScan then
    timer.scheduleFunction(function(_, t)
      safe("intelScan", DCC.dcs.intelScan)()
      return t + cfg.intel.scanSeconds
    end, nil, timer.getTime() + 5)
    timer.scheduleFunction(function(_, t)
      safe("drawIntel", DCC.dcs.drawIntel)()
      return t + cfg.intel.drawEverySeconds
    end, nil, timer.getTime() + 6)
  end

  timer.scheduleFunction(function(_, t)
    safe("tick", DCC.onTick)()
    return t + cfg.tickSeconds
  end, nil, timer.getTime() + cfg.tickSeconds)

  local s = war:summary()
  trigger.action.outText(string.format("Danica Dynamic Campaign %s - %s, war day %.1f. BLUE %d nodes, RED %d nodes.",
    cfg.version, DCC.theaterName, war.state.tick * cfg.tickSeconds / 86400, s.blue.nodes, s.red.nodes), 20)
  if war.noSave then
    trigger.action.outText(string.format("This server cannot save the campaign: the war on %s runs for %d h " ..
      "(or until the server stops), then the next map loads.", DCC.theaterName, cfg.warClockDaysNoSave * 24), 30)
  end
end

end

-- >>> catalogs/modern.lua
do
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

end

-- >>> theaters/caucasus.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - theater pack: Caucasus
-- ----------------------------------------------------------------------------
-- A theater pack is pure data. The engine never names a place in code; every
-- map gets one of these files instead.
--
--   nodes  : places that can be owned (airbases, towns, depots)
--   edges  : road links between nodes (assaults and reinforcements move on them)
--
-- Positions are real-world latitude/longitude. In DCS the engine converts them
-- with coord.LLtoLO(), so the same file format works on every map.
-- If a node has `airbase`, the engine snaps it to that DCS airbase and keeps the
-- airbase coalition in sync with the node owner.
--
-- Scenario (Modern): BLUE holds Georgia, RED holds the north and Abkhazia /
-- South Ossetia. The opening front runs Zugdidi-Gali, Gori-Tskhinvali and
-- the Military Georgian Road.
-- BLUE's depots are Batumi and Kutaisi (with Tbilisi as a depot BLUE gained
-- ground in 11 of 12 empty-server test wars; with Kutaisi it is 5 of 12).
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.Caucasus = {
  name    = "Caucasus",
  era     = "modern",
  -- Country used for spawned units. CJTF countries accept any unit type.
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.0, red = 1.0 },
  main    = { blue = "kutaisi", red = "krasnodar_c" },   -- each side's HQ (a depot): the star on the map

  nodes = {
    -- ---------------- BLUE (Georgia) ----------------
    { id = "batumi",     name = "Batumi",          kind = "airbase", side = "blue", lat = 41.6103, lon = 41.5997, airbase = "Batumi", depot = true },
    { id = "kobuleti",   name = "Kobuleti",        kind = "airbase", side = "blue", lat = 41.9300, lon = 41.8639, airbase = "Kobuleti" },
    { id = "poti",       name = "Poti",            kind = "town",    side = "blue", lat = 42.1460, lon = 41.6720 },
    { id = "senaki",     name = "Senaki-Kolkhi",   kind = "airbase", side = "blue", lat = 42.2410, lon = 42.0480, airbase = "Senaki-Kolkhi" },
    { id = "zugdidi",    name = "Zugdidi",         kind = "town",    side = "blue", lat = 42.5088, lon = 41.8709 },
    { id = "kutaisi",    name = "Kutaisi",         kind = "airbase", side = "blue", lat = 42.1767, lon = 42.4826, airbase = "Kutaisi", depot = true },
    { id = "zestaponi",  name = "Zestaponi",       kind = "town",    side = "blue", lat = 42.1100, lon = 43.0520 },
    { id = "ambrolauri", name = "Ambrolauri",      kind = "town",    side = "blue", lat = 42.5210, lon = 43.1500 },
    { id = "khashuri",   name = "Khashuri",        kind = "town",    side = "blue", lat = 41.9930, lon = 43.6000 },
    { id = "gori",       name = "Gori",            kind = "town",    side = "blue", lat = 41.9840, lon = 44.1100 },
    { id = "pasanauri",  name = "Pasanauri",       kind = "town",    side = "blue", lat = 42.3500, lon = 44.6900 },
    { id = "tbilisi",    name = "Tbilisi-Lochini", kind = "airbase", side = "blue", lat = 41.6692, lon = 44.9547, airbase = "Tbilisi-Lochini" },
    { id = "soganlug",   name = "Soganlug",        kind = "airbase", side = "blue", lat = 41.6460, lon = 44.9370, airbase = "Soganlug" },
    { id = "vaziani",    name = "Vaziani",         kind = "airbase", side = "blue", lat = 41.6290, lon = 45.0270, airbase = "Vaziani" },

    -- ---------------- RED (north, Abkhazia, South Ossetia) ----------------
    { id = "gali",       name = "Gali",            kind = "town",    side = "red",  lat = 42.6260, lon = 41.7340 },
    { id = "ochamchire", name = "Ochamchire",      kind = "town",    side = "red",  lat = 42.7120, lon = 41.4680 },
    { id = "sukhumi",    name = "Sukhumi-Babushara", kind = "airbase", side = "red", lat = 42.8582, lon = 41.1281, airbase = "Sukhumi-Babushara" },
    { id = "gudauta",    name = "Gudauta",         kind = "airbase", side = "red",  lat = 43.1040, lon = 40.5790, airbase = "Gudauta" },
    { id = "sochi",      name = "Sochi-Adler",     kind = "airbase", side = "red",  lat = 43.4499, lon = 39.9566, airbase = "Sochi-Adler", depot = true },
    { id = "tuapse",     name = "Tuapse",          kind = "town",    side = "red",  lat = 44.0960, lon = 39.0740 },
    { id = "oni",        name = "Oni",             kind = "town",    side = "red",  lat = 42.5790, lon = 43.4420 },
    { id = "tskhinvali", name = "Tskhinvali",      kind = "town",    side = "red",  lat = 42.2270, lon = 43.9690 },
    { id = "kazbegi",    name = "Kazbegi",         kind = "town",    side = "red",  lat = 42.6570, lon = 44.6440 },
    { id = "alagir",     name = "Alagir",          kind = "town",    side = "red",  lat = 43.0410, lon = 44.2200 },
    { id = "vladikavkaz",name = "Vladikavkaz",     kind = "town",    side = "red",  lat = 43.0370, lon = 44.6680 },
    { id = "beslan",     name = "Beslan",          kind = "airbase", side = "red",  lat = 43.2051, lon = 44.6066, airbase = "Beslan", depot = true },
    { id = "mozdok",     name = "Mozdok",          kind = "airbase", side = "red",  lat = 43.7880, lon = 44.6190, airbase = "Mozdok" },
    { id = "nalchik",    name = "Nalchik",         kind = "airbase", side = "red",  lat = 43.5129, lon = 43.6366, airbase = "Nalchik" },
    { id = "pyatigorsk", name = "Pyatigorsk",      kind = "town",    side = "red",  lat = 44.0480, lon = 43.0590 },
    { id = "minvody",    name = "Mineralnye Vody", kind = "airbase", side = "red",  lat = 44.2251, lon = 43.0819, airbase = "Mineralnye Vody" },
    { id = "cherkessk",  name = "Cherkessk",       kind = "town",    side = "red",  lat = 44.2230, lon = 42.0580 },
    { id = "armavir",    name = "Armavir",         kind = "town",    side = "red",  lat = 44.9990, lon = 41.1290 },
    { id = "maykop",     name = "Maykop-Khanskaya",kind = "airbase", side = "red",  lat = 44.6710, lon = 40.0210, airbase = "Maykop-Khanskaya" },
    { id = "krasnodar_p",name = "Krasnodar-Pashkovsky", kind = "airbase", side = "red", lat = 45.0347, lon = 39.1705, airbase = "Krasnodar-Pashkovsky" },
    { id = "krasnodar_c",name = "Krasnodar-Center",kind = "airbase", side = "red",  lat = 45.0850, lon = 38.9250, airbase = "Krasnodar-Center", depot = true },
    { id = "krymsk",     name = "Krymsk",          kind = "airbase", side = "red",  lat = 44.9610, lon = 37.9850, airbase = "Krymsk" },
    { id = "anapa",      name = "Anapa-Vityazevo", kind = "airbase", side = "red",  lat = 45.0021, lon = 37.3473, airbase = "Anapa-Vityazevo" },
    { id = "novorossiysk",name = "Novorossiysk",   kind = "airbase", side = "red",  lat = 44.6660, lon = 37.7860, airbase = "Novorossiysk" },
    { id = "gelendzhik", name = "Gelendzhik",      kind = "airbase", side = "red",  lat = 44.5670, lon = 38.0040, airbase = "Gelendzhik" },
  },

  -- Road links (undirected). Keep them on real roads: DCS ground AI drives
  -- "On Road" between the two ends, so a link with no road gets units stuck.
  edges = {
    -- Georgian coast and west
    { "batumi", "kobuleti" }, { "kobuleti", "poti" }, { "poti", "senaki" },
    { "senaki", "zugdidi" }, { "senaki", "kutaisi" },
    -- Georgian interior
    { "kutaisi", "zestaponi" }, { "zestaponi", "khashuri" }, { "khashuri", "gori" },
    { "gori", "tbilisi" }, { "tbilisi", "soganlug" }, { "tbilisi", "vaziani" },
    { "kutaisi", "ambrolauri" }, { "tbilisi", "pasanauri" },
    -- Opening front lines
    { "zugdidi", "gali" }, { "ambrolauri", "oni" }, { "gori", "tskhinvali" },
    { "pasanauri", "kazbegi" },
    -- Abkhazia and Black Sea coast
    { "gali", "ochamchire" }, { "ochamchire", "sukhumi" }, { "sukhumi", "gudauta" },
    { "gudauta", "sochi" }, { "sochi", "tuapse" },
    { "tuapse", "maykop" }, { "tuapse", "gelendzhik" },
    -- Kuban
    { "gelendzhik", "novorossiysk" }, { "novorossiysk", "krymsk" }, { "novorossiysk", "anapa" },
    { "krymsk", "anapa" }, { "krymsk", "krasnodar_c" }, { "krasnodar_c", "krasnodar_p" },
    { "krasnodar_p", "maykop" }, { "krasnodar_p", "armavir" }, { "maykop", "armavir" },
    -- North Caucasus
    { "armavir", "cherkessk" }, { "cherkessk", "minvody" }, { "minvody", "pyatigorsk" },
    { "pyatigorsk", "nalchik" }, { "minvody", "mozdok" }, { "nalchik", "beslan" },
    { "beslan", "vladikavkaz" }, { "beslan", "mozdok" }, { "vladikavkaz", "alagir" },
    { "vladikavkaz", "kazbegi" }, { "alagir", "tskhinvali" }, { "oni", "alagir" },
  },

  -- Naval groups: placed by tools/make_mission.py (client slots on carriers). Each
  -- sails 80 km on its heading and turns around; sunk = its air wing is gone.
  --   tacan / icls: beacon channels (false = none). The tankers use 51X/52X.
  naval = {
    { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 42.0000, lon = 40.8500,
      heading = 300, ship = "Stennis", escorts = { "USS_Arleigh_Burke_IIa", "USS_Arleigh_Burke_IIa", "TICONDEROG" },
      tacan = 74, tacanCall = "STN", icls = 4,
      slots = { "FA-18C_hornet", "FA-18C_hornet", "F-14B", "F-14B", "F-14BU", "F-14A-135-GR" } },
    { id = "lha", side = "blue", name = "LHA-1 Tarawa", kind = "carrier", lat = 41.7500, lon = 41.2500,
      heading = 300, ship = "LHA_Tarawa", amphib = true, escorts = { "PERRY" },
      tacan = 75, tacanCall = "TAR", icls = 5,
      slots = { "AV8BNA", "AV8BNA", "UH-1H", "AH-64D_BLK_II", "SA342M" } },
    { id = "kuz", side = "red", name = "Admiral Kuznetsov", kind = "carrier", lat = 44.2000, lon = 37.6000,
      heading = 250, ship = "KUZNECOW", amphib = true, escorts = { "MOSCOW", "REZKY", "NEUSTRASH" },
      tacan = false, icls = false,
      slots = { "Su-33", "Su-33", "Su-33", "Su-33", "Ka-50_3" } },
  },

  -- Shipping lanes (dcc_ext3.lua): supply ships sail from start (open sea) to dock
  -- (just off the port) for whoever holds the port; the port is a node id.
  shipping = {
    { port = "batumi", start = { lat = 41.9000, lon = 40.9000 }, dock = { lat = 41.6700, lon = 41.5800 } },
    { port = "poti", start = { lat = 42.3000, lon = 40.9000 }, dock = { lat = 42.1600, lon = 41.6000 } },
    { port = "sukhumi", start = { lat = 42.7500, lon = 40.4000 }, dock = { lat = 42.9700, lon = 40.9500 } },
    { port = "gudauta", start = { lat = 42.8500, lon = 40.0000 }, dock = { lat = 43.0800, lon = 40.5500 } },
    { port = "sochi", start = { lat = 43.3500, lon = 39.2000 }, dock = { lat = 43.5600, lon = 39.6800 } },
    { port = "tuapse", start = { lat = 43.8500, lon = 38.6000 }, dock = { lat = 44.0800, lon = 39.0300 } },
    { port = "novorossiysk", start = { lat = 44.4000, lon = 37.5000 }, dock = { lat = 44.6400, lon = 37.8300 } },
    { port = "gelendzhik", start = { lat = 44.3000, lon = 37.7000 }, dock = { lat = 44.5400, lon = 38.0500 } },
  },
}

end

-- >>> theaters/germanycw.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - theater pack: GermanyCW
-- ----------------------------------------------------------------------------
-- GENERATED by tools/make_theater.py from tools/scenarios/germanycw.py.
-- Edit the scenario and regenerate rather than editing this file.
--
-- Scenario (Modern forces on the Cold War Germany map): BLUE holds the west,
-- RED the east, with the front on the old inner-German border from the Baltic
-- coast to the Fulda Gap. Berlin is not in play.
--
-- 55 nodes, 103 roads, 0 sea crossings, 15 front links.
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.GermanyCW = {
  name    = "GermanyCW",
  era     = "modern",
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.0, red = 1.10 },
  main    = { blue = "frankfurt", red = "schonefeld" },   -- each side's HQ (a depot): the star on the map

  nodes = {
    -- ---------------- BLUE ----------------
    { id = "kiel", name = "Kiel", kind = "airbase", side = "blue", lat = 54.3795, lon = 10.1447, airbase = "Kiel" },
    { id = "lubeck", name = "Lubeck", kind = "airbase", side = "blue", lat = 53.8049, lon = 10.7169, airbase = "Lubeck" },
    { id = "nordholz", name = "Nordholz", kind = "airbase", side = "blue", lat = 53.7676, lon = 8.6585, airbase = "Nordholz", ewr = true },
    { id = "hamburg", name = "Hamburg", kind = "airbase", side = "blue", lat = 53.6268, lon = 9.9813, airbase = "Hamburg" },
    { id = "luneburg", name = "Luneburg", kind = "airbase", side = "blue", lat = 53.2485, lon = 10.4595, airbase = "Luneburg" },
    { id = "bremen", name = "Bremen", kind = "airbase", side = "blue", lat = 53.0469, lon = 8.7883, airbase = "Bremen" },
    { id = "uelzen", name = "Uelzen", kind = "airbase", side = "blue", lat = 52.9836, lon = 10.4645, airbase = "Uelzen" },
    { id = "fassberg", name = "Fassberg", kind = "airbase", side = "blue", lat = 52.9194, lon = 10.1848, airbase = "Fassberg" },
    { id = "celle", name = "Celle", kind = "airbase", side = "blue", lat = 52.5914, lon = 10.0243, airbase = "Celle" },
    { id = "wunstorf", name = "Wunstorf", kind = "airbase", side = "blue", lat = 52.4573, lon = 9.4271, airbase = "Wunstorf" },
    { id = "hannover", name = "Hannover", kind = "airbase", side = "blue", lat = 52.4545, lon = 9.6938, airbase = "Hannover", depot = true },
    { id = "wolfsburg", name = "Wolfsburg", kind = "town", side = "blue", lat = 52.4230, lon = 10.7870 },
    { id = "braunschweig", name = "Braunschweig", kind = "airbase", side = "blue", lat = 52.3191, lon = 10.5539, airbase = "Braunschweig" },
    { id = "buckeburg", name = "Buckeburg", kind = "airbase", side = "blue", lat = 52.2786, lon = 9.0833, airbase = "Buckeburg" },
    { id = "helmstedt", name = "Helmstedt", kind = "town", side = "blue", lat = 52.2270, lon = 11.0100 },
    { id = "hildesheim", name = "Hildesheim", kind = "airbase", side = "blue", lat = 52.1798, lon = 9.9458, airbase = "Hildesheim" },
    { id = "gutersloh", name = "Gutersloh", kind = "airbase", side = "blue", lat = 51.9228, lon = 8.3041, airbase = "Gutersloh" },
    { id = "gottingen", name = "Gottingen", kind = "town", side = "blue", lat = 51.5410, lon = 9.9160 },
    { id = "kassel", name = "Kassel", kind = "town", side = "blue", lat = 51.3130, lon = 9.4790 },
    { id = "fritzlar", name = "Fritzlar", kind = "airbase", side = "blue", lat = 51.1146, lon = 9.2858, airbase = "Fritzlar" },
    { id = "fulda", name = "Fulda", kind = "airbase", side = "blue", lat = 50.5399, lon = 9.6430, airbase = "Fulda" },
    { id = "wiesbaden", name = "Wiesbaden", kind = "airbase", side = "blue", lat = 50.0498, lon = 8.3256, airbase = "Wiesbaden" },
    { id = "schweinfurt", name = "Schweinfurt", kind = "airbase", side = "blue", lat = 50.0489, lon = 10.1697, airbase = "Schweinfurt" },
    { id = "frankfurt", name = "Frankfurt", kind = "airbase", side = "blue", lat = 50.0404, lon = 8.5673, airbase = "Frankfurt", depot = true },
    { id = "hahn", name = "Hahn", kind = "airbase", side = "blue", lat = 49.9485, lon = 7.2639, airbase = "Hahn" },
    { id = "giebelstadt", name = "Giebelstadt", kind = "airbase", side = "blue", lat = 49.6479, lon = 9.9647, airbase = "Giebelstadt" },
    { id = "ramstein", name = "Ramstein", kind = "airbase", side = "blue", lat = 49.4369, lon = 7.6001, airbase = "Ramstein" },
    -- ---------------- RED ----------------
    { id = "laage", name = "Laage", kind = "airbase", side = "red", lat = 53.9181, lon = 12.2794, airbase = "Laage" },
    { id = "wismar", name = "Wismar", kind = "airbase", side = "red", lat = 53.9144, lon = 11.5024, airbase = "Wismar" },
    { id = "pinnow", name = "Schwerin-Pinnow", kind = "airbase", side = "red", lat = 53.6165, lon = 11.5631, airbase = "Pinnow" },
    { id = "parchim", name = "Parchim", kind = "airbase", side = "red", lat = 53.4279, lon = 11.7866, airbase = "Parchim" },
    { id = "wittstock", name = "Wittstock", kind = "airbase", side = "red", lat = 53.2024, lon = 12.5230, airbase = "Wittstock" },
    { id = "neuruppin", name = "Neuruppin", kind = "airbase", side = "red", lat = 52.9411, lon = 12.7869, airbase = "Neuruppin" },
    { id = "salzwedel", name = "Salzwedel", kind = "town", side = "red", lat = 52.8500, lon = 11.1500 },
    { id = "stendal", name = "Stendal", kind = "airbase", side = "red", lat = 52.6291, lon = 11.8199, airbase = "Stendal" },
    { id = "gardelegen", name = "Gardelegen", kind = "airbase", side = "red", lat = 52.5295, lon = 11.3501, airbase = "Gardelegen" },
    { id = "briest", name = "Briest", kind = "airbase", side = "red", lat = 52.4376, lon = 12.4539, airbase = "Briest" },
    { id = "mahlwinkel", name = "Mahlwinkel", kind = "airbase", side = "red", lat = 52.3883, lon = 11.8264, airbase = "Mahlwinkel" },
    { id = "schonefeld", name = "Berlin-Schonefeld", kind = "airbase", side = "red", lat = 52.3842, lon = 13.5344, airbase = "Schonefeld", depot = true },
    { id = "magdeburg", name = "Magdeburg", kind = "town", side = "red", lat = 52.1310, lon = 11.6400 },
    { id = "zerbst", name = "Zerbst", kind = "airbase", side = "red", lat = 51.9996, lon = 12.1443, airbase = "Zerbst" },
    { id = "altes_lager", name = "Altes Lager", kind = "airbase", side = "red", lat = 51.9955, lon = 12.9838, airbase = "Altes Lager" },
    { id = "cochstedt", name = "Cochstedt", kind = "airbase", side = "red", lat = 51.8559, lon = 11.4179, airbase = "Cochstedt" },
    { id = "dessau", name = "Dessau", kind = "airbase", side = "red", lat = 51.8317, lon = 12.1931, airbase = "Dessau" },
    { id = "holzdorf", name = "Holzdorf", kind = "airbase", side = "red", lat = 51.7678, lon = 13.1697, airbase = "Holzdorf" },
    { id = "kothen", name = "Kothen", kind = "airbase", side = "red", lat = 51.7214, lon = 11.9615, airbase = "Kothen" },
    { id = "nordhausen", name = "Nordhausen", kind = "town", side = "red", lat = 51.5050, lon = 10.7910 },
    { id = "schkeuditz", name = "Leipzig-Schkeuditz", kind = "airbase", side = "red", lat = 51.4150, lon = 12.2272, airbase = "Schkeuditz" },
    { id = "allstedt", name = "Allstedt", kind = "airbase", side = "red", lat = 51.3806, lon = 11.4465, airbase = "Allstedt" },
    { id = "merseburg", name = "Merseburg", kind = "airbase", side = "red", lat = 51.3640, lon = 11.9500, airbase = "Merseburg" },
    { id = "brandis", name = "Brandis", kind = "airbase", side = "red", lat = 51.3283, lon = 12.6564, airbase = "Brandis", depot = true },
    { id = "obermehler_schlotheim", name = "Obermehler Schlotheim", kind = "airbase", side = "red", lat = 51.2677, lon = 10.6348, airbase = "Obermehler Schlotheim" },
    { id = "haina", name = "Haina", kind = "airbase", side = "red", lat = 50.9917, lon = 10.4796, airbase = "Haina" },
    { id = "bindersleben", name = "Erfurt-Bindersleben", kind = "airbase", side = "red", lat = 50.9795, lon = 10.9623, airbase = "Bindersleben" },
    { id = "eisenach", name = "Eisenach", kind = "town", side = "red", lat = 50.9740, lon = 10.3200 },
  },

  edges = {
    { "allstedt", "bindersleben" },   -- 56 km
    { "allstedt", "cochstedt" },   -- 53 km
    { "allstedt", "kothen" },   -- 52 km
    { "allstedt", "merseburg" },   -- 35 km
    { "allstedt", "nordhausen" },   -- 48 km
    { "altes_lager", "briest" },   -- 61 km
    { "altes_lager", "dessau" },   -- 57 km
    { "altes_lager", "holzdorf" },   -- 28 km
    { "altes_lager", "schonefeld" },   -- 57 km
    { "altes_lager", "zerbst" },   -- 58 km
    { "bindersleben", "haina" },   -- 34 km
    { "bindersleben", "obermehler_schlotheim" },   -- 39 km
    { "brandis", "holzdorf" },   -- 60 km
    { "brandis", "schkeuditz" },   -- 31 km
    { "braunschweig", "celle" },   -- 47 km
    { "braunschweig", "helmstedt" },   -- 33 km
    { "braunschweig", "hildesheim" },   -- 44 km
    { "braunschweig", "wolfsburg" },   -- 20 km
    { "bremen", "fassberg" },   -- 95 km
    { "bremen", "hamburg" },   -- 102 km
    { "bremen", "nordholz" },   -- 80 km
    { "bremen", "wunstorf" },   -- 78 km
    { "briest", "mahlwinkel" },   -- 43 km
    { "briest", "neuruppin" },   -- 60 km
    { "briest", "schonefeld" },   -- 74 km
    { "briest", "stendal" },   -- 48 km
    { "briest", "zerbst" },   -- 53 km
    { "buckeburg", "gutersloh" },   -- 66 km
    { "buckeburg", "wunstorf" },   -- 31 km
    { "celle", "fassberg" },   -- 38 km
    { "celle", "hannover" },   -- 27 km
    { "cochstedt", "helmstedt" },   -- 50 km
    { "cochstedt", "kothen" },   -- 40 km
    { "cochstedt", "magdeburg" },   -- 34 km
    { "cochstedt", "nordhausen" },   -- 58 km
    { "dessau", "kothen" },   -- 20 km
    { "dessau", "zerbst" },   -- 19 km
    { "eisenach", "fritzlar" },   -- 74 km
    { "eisenach", "fulda" },   -- 68 km
    { "eisenach", "gottingen" },   -- 69 km
    { "eisenach", "haina" },   -- 11 km
    { "eisenach", "kassel" },   -- 70 km
    { "fassberg", "uelzen" },   -- 20 km
    { "frankfurt", "fulda" },   -- 94 km
    { "frankfurt", "giebelstadt" },   -- 109 km
    { "frankfurt", "schweinfurt" },   -- 115 km
    { "frankfurt", "wiesbaden" },   -- 17 km
    { "fritzlar", "fulda" },   -- 68 km
    { "fritzlar", "kassel" },   -- 26 km
    { "fulda", "schweinfurt" },   -- 66 km
    { "gardelegen", "helmstedt" },   -- 41 km
    { "gardelegen", "mahlwinkel" },   -- 36 km
    { "gardelegen", "salzwedel" },   -- 38 km
    { "gardelegen", "stendal" },   -- 34 km
    { "gardelegen", "wolfsburg" },   -- 40 km
    { "giebelstadt", "schweinfurt" },   -- 47 km
    { "gottingen", "hildesheim" },   -- 71 km
    { "gottingen", "kassel" },   -- 39 km
    { "gottingen", "nordhausen" },   -- 61 km
    { "gottingen", "obermehler_schlotheim" },   -- 58 km
    { "gutersloh", "kassel" },   -- 106 km
    { "hahn", "ramstein" },   -- 62 km
    { "hahn", "wiesbaden" },   -- 77 km
    { "haina", "obermehler_schlotheim" },   -- 32 km
    { "hamburg", "kiel" },   -- 84 km
    { "hamburg", "lubeck" },   -- 52 km
    { "hamburg", "luneburg" },   -- 52 km
    { "hamburg", "nordholz" },   -- 89 km
    { "hannover", "hildesheim" },   -- 35 km
    { "hannover", "wunstorf" },   -- 18 km
    { "helmstedt", "magdeburg" },   -- 44 km
    { "helmstedt", "wolfsburg" },   -- 26 km
    { "kiel", "lubeck" },   -- 74 km
    { "kiel", "nordholz" },   -- 118 km
    { "kothen", "merseburg" },   -- 40 km
    { "kothen", "schkeuditz" },   -- 39 km
    { "laage", "pinnow" },   -- 58 km
    { "laage", "wismar" },   -- 51 km
    { "laage", "wittstock" },   -- 81 km
    { "lubeck", "luneburg" },   -- 64 km
    { "lubeck", "pinnow" },   -- 60 km
    { "lubeck", "wismar" },   -- 53 km
    { "luneburg", "pinnow" },   -- 84 km
    { "luneburg", "uelzen" },   -- 29 km
    { "magdeburg", "mahlwinkel" },   -- 31 km
    { "magdeburg", "zerbst" },   -- 37 km
    { "mahlwinkel", "stendal" },   -- 27 km
    { "mahlwinkel", "zerbst" },   -- 48 km
    { "merseburg", "schkeuditz" },   -- 20 km
    { "neuruppin", "schonefeld" },   -- 80 km
    { "neuruppin", "stendal" },   -- 74 km
    { "neuruppin", "wittstock" },   -- 34 km
    { "nordhausen", "obermehler_schlotheim" },   -- 28 km
    { "parchim", "pinnow" },   -- 26 km
    { "parchim", "salzwedel" },   -- 77 km
    { "parchim", "stendal" },   -- 88 km
    { "parchim", "wittstock" },   -- 55 km
    { "pinnow", "wismar" },   -- 33 km
    { "ramstein", "wiesbaden" },   -- 86 km
    { "salzwedel", "uelzen" },   -- 48 km
    { "salzwedel", "wolfsburg" },   -- 53 km
    { "stendal", "wittstock" },   -- 79 km
    { "uelzen", "wolfsburg" },   -- 66 km
  },

  -- Naval groups: placed by tools/make_mission.py (client slots on carriers). Each
  -- sails legKm (default 80) on its heading and turns around; sunk = its air wing is gone.
  --   tacan / icls: beacon channels (false = none). The tankers use 51X/52X.
  -- Cold War: a NATO carrier in the German Bight, the Soviet carrier in the Baltic
  -- (Mecklenburg Bay). Both seas are narrow: short legs.
  naval = {
    { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 54.0000, lon = 7.9000,
      heading = 300, legKm = 40, ship = "Stennis", escorts = { "USS_Arleigh_Burke_IIa", "USS_Arleigh_Burke_IIa",
      "TICONDEROG" }, tacan = 74, tacanCall = "STN", icls = 4,
      slots = { "FA-18C_hornet", "FA-18C_hornet", "F-14B", "F-14B", "F-14BU", "F-14A-135-GR" } },
    { id = "kuz", side = "red", name = "Admiral Kuznetsov", kind = "carrier", lat = 54.2500, lon = 11.6000,
      heading = 80, legKm = 40, ship = "KUZNECOW", amphib = true, escorts = { "MOSCOW", "REZKY", "NEUSTRASH" },
      tacan = false, icls = false,
      slots = { "Su-33", "Su-33", "Su-33", "Su-33", "Ka-50_3" } },
  },

  -- Shipping lanes (dcc_ext3.lua): supply ships sail from start (open sea) to dock
  -- (just off the port) for whoever holds the port; the port is a node id.
  shipping = {
    { port = "kiel", start = { lat = 54.6200, lon = 10.4000 }, dock = { lat = 54.4000, lon = 10.2000 } },
    { port = "lubeck", start = { lat = 54.1500, lon = 11.1000 }, dock = { lat = 53.9800, lon = 10.9000 } },
    { port = "wismar", start = { lat = 54.2000, lon = 11.5000 }, dock = { lat = 54.0000, lon = 11.4200 } },
    { port = "laage", start = { lat = 54.4000, lon = 12.2000 }, dock = { lat = 54.2000, lon = 12.0800 } },
    { port = "nordholz", start = { lat = 54.0500, lon = 8.1000 }, dock = { lat = 53.9000, lon = 8.6500 } },
  },
}

end

-- >>> theaters/persiangulf.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - theater pack: PersianGulf
-- ----------------------------------------------------------------------------
-- GENERATED by tools/make_theater.py from tools/scenarios/persiangulf.py.
-- Edit the scenario and regenerate rather than editing this file.
--
-- Scenario (Modern): RED (Iran) has landed on the Musandam peninsula and the
-- northern Emirates and holds the Gulf islands. BLUE holds the rest of the UAE.
-- The ground fronts are Umm Al Quwain - Ras Al Khaimah and Al Dhaid / Hatta -
-- Masafi / Fujairah. Everything else is linked by sea crossings (ferries and
-- landing craft): those moves run on dice only - fight them at the ports and
-- islands, and in the air.
--
-- 32 nodes, 36 roads, 11 sea crossings, 6 front links.
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.PersianGulf = {
  name    = "PersianGulf",
  era     = "modern",
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.05, red = 1.0 },
  main    = { blue = "al_dhafra_afb", red = "bandar_abbas_intl" },   -- each side's HQ (a depot): the star on the map

  nodes = {
    -- ---------------- BLUE ----------------
    { id = "umm_al_quwain", name = "Umm Al Quwain", kind = "town", side = "blue", lat = 25.5650, lon = 55.5550 },
    { id = "sharjah_intl", name = "Sharjah Intl", kind = "airbase", side = "blue", lat = 25.3307, lon = 55.5183, airbase = "Sharjah Intl" },
    { id = "al_dhaid", name = "Al Dhaid", kind = "town", side = "blue", lat = 25.2880, lon = 55.8810 },
    { id = "dubai_intl", name = "Dubai Intl", kind = "airbase", side = "blue", lat = 25.2564, lon = 55.3653, airbase = "Dubai Intl" },
    { id = "sir_abu_nuayr", name = "Sir Abu Nuayr", kind = "airbase", side = "blue", lat = 25.2169, lon = 54.2336, airbase = "Sir Abu Nuayr" },
    { id = "al_minhad_afb", name = "Al Minhad AFB", kind = "airbase", side = "blue", lat = 25.0269, lon = 55.3658, airbase = "Al Minhad AFB", depot = true },
    { id = "al_maktoum_intl", name = "Al Maktoum Intl", kind = "airbase", side = "blue", lat = 24.8971, lon = 55.1602, airbase = "Al Maktoum Intl" },
    { id = "hatta", name = "Hatta", kind = "town", side = "blue", lat = 24.8000, lon = 56.1200 },
    { id = "abu_dhabi_intl", name = "Abu Dhabi Intl", kind = "airbase", side = "blue", lat = 24.4537, lon = 54.6543, airbase = "Abu Dhabi Intl" },
    { id = "sas_al_nakheel", name = "Sas Al Nakheel", kind = "airbase", side = "blue", lat = 24.4411, lon = 54.5170, airbase = "Sas Al Nakheel" },
    { id = "al_bateen", name = "Al-Bateen", kind = "airbase", side = "blue", lat = 24.4281, lon = 54.4586, airbase = "Al-Bateen" },
    { id = "al_ain_intl", name = "Al Ain Intl", kind = "airbase", side = "blue", lat = 24.2614, lon = 55.6092, airbase = "Al Ain Intl" },
    { id = "al_dhafra_afb", name = "Al Dhafra AFB", kind = "airbase", side = "blue", lat = 24.2483, lon = 54.5477, airbase = "Al Dhafra AFB", depot = true },
    { id = "liwa_afb", name = "Liwa AFB", kind = "airbase", side = "blue", lat = 23.6508, lon = 53.8244, airbase = "Liwa AFB" },
    -- ---------------- RED ----------------
    { id = "jiroft", name = "Jiroft", kind = "airbase", side = "red", lat = 28.7235, lon = 57.6751, airbase = "Jiroft" },
    { id = "lar", name = "Lar", kind = "airbase", side = "red", lat = 27.6747, lon = 54.3831, airbase = "Lar", depot = true },
    { id = "bandar_abbas_intl", name = "Bandar Abbas Intl", kind = "airbase", side = "red", lat = 27.2177, lon = 56.3790, airbase = "Bandar Abbas Intl", depot = true },
    { id = "havadarya", name = "Havadarya", kind = "airbase", side = "red", lat = 27.1582, lon = 56.1720, airbase = "Havadarya" },
    { id = "minab", name = "Minab", kind = "town", side = "red", lat = 27.1460, lon = 57.0800 },
    { id = "bandar_khamir", name = "Bandar Khamir", kind = "town", side = "red", lat = 26.9520, lon = 55.5850 },
    { id = "qeshm_island", name = "Qeshm Island", kind = "airbase", side = "red", lat = 26.7547, lon = 55.9024, airbase = "Qeshm Island" },
    { id = "bandar_lengeh", name = "Bandar Lengeh", kind = "airbase", side = "red", lat = 26.5323, lon = 54.8247, airbase = "Bandar Lengeh" },
    { id = "kish_intl", name = "Kish Intl", kind = "airbase", side = "red", lat = 26.5281, lon = 53.9810, airbase = "Kish Intl" },
    { id = "tunb_island_afb", name = "Greater Tunb", kind = "airbase", side = "red", lat = 26.2589, lon = 55.3158, airbase = "Tunb Island AFB" },
    { id = "khasab", name = "Khasab", kind = "airbase", side = "red", lat = 26.1698, lon = 56.2402, airbase = "Khasab", depot = true },
    { id = "sirri_island", name = "Sirri Island", kind = "airbase", side = "red", lat = 25.9096, lon = 54.5393, airbase = "Sirri Island" },
    { id = "abu_musa_island", name = "Abu Musa Island", kind = "airbase", side = "red", lat = 25.8760, lon = 55.0329, airbase = "Abu Musa Island" },
    { id = "bandar_e_jask", name = "Bandar-e-Jask", kind = "airbase", side = "red", lat = 25.6547, lon = 57.8014, airbase = "Bandar-e-Jask" },
    { id = "dibba", name = "Dibba", kind = "town", side = "red", lat = 25.6200, lon = 56.2700 },
    { id = "ras_al_khaimah_intl", name = "Ras Al Khaimah Intl", kind = "airbase", side = "red", lat = 25.6135, lon = 55.9388, airbase = "Ras Al Khaimah Intl" },
    { id = "masafi", name = "Masafi", kind = "town", side = "red", lat = 25.3160, lon = 56.1660 },
    { id = "fujairah_intl", name = "Fujairah Intl", kind = "airbase", side = "red", lat = 25.1109, lon = 56.3274, airbase = "Fujairah Intl" },
  },

  edges = {
    { "abu_dhabi_intl", "al_ain_intl" },   -- 99 km
    { "abu_dhabi_intl", "al_dhafra_afb" },   -- 25 km
    { "abu_dhabi_intl", "al_maktoum_intl" },   -- 71 km
    { "abu_dhabi_intl", "sas_al_nakheel" },   -- 14 km
    { "al_ain_intl", "al_maktoum_intl" },   -- 84 km
    { "al_ain_intl", "hatta" },   -- 79 km
    { "al_bateen", "al_dhafra_afb" },   -- 22 km
    { "al_bateen", "sas_al_nakheel" },   -- 6 km
    { "al_dhafra_afb", "liwa_afb" },   -- 99 km
    { "al_dhafra_afb", "sas_al_nakheel" },   -- 22 km
    { "al_dhaid", "hatta" },   -- 59 km
    { "al_dhaid", "masafi" },   -- 29 km
    { "al_dhaid", "ras_al_khaimah_intl" },   -- 36 km
    { "al_dhaid", "sharjah_intl" },   -- 37 km
    { "al_dhaid", "umm_al_quwain" },   -- 45 km
    { "al_maktoum_intl", "al_minhad_afb" },   -- 25 km
    { "al_minhad_afb", "dubai_intl" },   -- 25 km
    { "al_minhad_afb", "hatta" },   -- 80 km
    { "bandar_abbas_intl", "havadarya" },   -- 22 km
    { "bandar_abbas_intl", "minab" },   -- 70 km
    { "bandar_e_jask", "minab" },   -- 180 km
    { "bandar_khamir", "bandar_lengeh" },   -- 89 km
    { "bandar_khamir", "havadarya" },   -- 63 km
    { "bandar_khamir", "lar" },   -- 143 km
    { "bandar_lengeh", "lar" },   -- 134 km
    { "dibba", "khasab" },   -- 61 km
    { "dibba", "masafi" },   -- 35 km
    { "dibba", "ras_al_khaimah_intl" },   -- 33 km
    { "dubai_intl", "sharjah_intl" },   -- 17 km
    { "fujairah_intl", "hatta" },   -- 40 km
    { "fujairah_intl", "masafi" },   -- 28 km
    { "jiroft", "minab" },   -- 184 km
    { "khasab", "ras_al_khaimah_intl" },   -- 69 km
    { "masafi", "ras_al_khaimah_intl" },   -- 40 km
    { "ras_al_khaimah_intl", "umm_al_quwain" },   -- 39 km
    { "sharjah_intl", "umm_al_quwain" },   -- 26 km
    { "abu_musa_island", "sharjah_intl", sea = true },   -- sea crossing, 78 km
    { "abu_musa_island", "sirri_island", sea = true },   -- sea crossing, 50 km
    { "abu_musa_island", "tunb_island_afb", sea = true },   -- sea crossing, 51 km
    { "bandar_abbas_intl", "khasab", sea = true },   -- sea crossing, 117 km
    { "bandar_lengeh", "kish_intl", sea = true },   -- sea crossing, 84 km
    { "bandar_lengeh", "tunb_island_afb", sea = true },   -- sea crossing, 58 km
    { "havadarya", "qeshm_island", sea = true },   -- sea crossing, 52 km
    { "khasab", "qeshm_island", sea = true },   -- sea crossing, 73 km
    { "kish_intl", "sirri_island", sea = true },   -- sea crossing, 88 km
    { "sharjah_intl", "sir_abu_nuayr", sea = true },   -- sea crossing, 130 km
    { "sir_abu_nuayr", "sirri_island", sea = true },   -- sea crossing, 83 km
  },

  -- Naval groups: placed by tools/make_mission.py (with client slots on carriers);
  -- the engine tracks them and offers ANTISHIP missions against them.
  naval = {
    { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 24.9500, lon = 57.3500,
      heading = 330, ship = "Stennis", escorts = { "USS_Arleigh_Burke_IIa", "USS_Arleigh_Burke_IIa", "TICONDEROG" },
      tacan = 74, tacanCall = "STN", icls = 4,
      slots = { "FA-18C_hornet", "FA-18C_hornet", "F-14B", "F-14B", "F-14BU", "F-14A-135-GR" } },
    { id = "lha", side = "blue", name = "LHA-1 Tarawa", kind = "carrier", lat = 25.4000, lon = 56.6000,
      heading = 0, legKm = 40, ship = "LHA_Tarawa", amphib = true, escorts = { "PERRY" },
      tacan = 75, tacanCall = "TAR", icls = 5,
      slots = { "AV8BNA", "AV8BNA", "UH-1H", "AH-64D_BLK_II", "SA342M" } },
    { id = "kuz", side = "red", name = "Admiral Kuznetsov", kind = "carrier", lat = 26.2000, lon = 53.6000,
      heading = 270, legKm = 40, ship = "KUZNECOW", amphib = true, escorts = { "MOSCOW", "REZKY", "NEUSTRASH" },
      tacan = false, icls = false,
      slots = { "Su-33", "Su-33", "Su-33", "Su-33", "Ka-50_3" } },
  },

  -- Shipping lanes (dcc_ext3.lua): supply ships sail from start (open sea) to dock
  -- (just off the port) for whoever holds the port; the port is a node id.
  shipping = {
    { port = "dubai_intl", start = { lat = 25.7000, lon = 54.9000 }, dock = { lat = 25.3000, lon = 55.2500 } },
    { port = "sharjah_intl", start = { lat = 25.8000, lon = 55.0000 }, dock = { lat = 25.4000, lon = 55.3500 } },
    { port = "abu_dhabi_intl", start = { lat = 24.9500, lon = 54.1000 }, dock = { lat = 24.5600, lon = 54.3300 } },
    { port = "bandar_abbas_intl", start = { lat = 26.8000, lon = 56.6000 }, dock = { lat = 27.1200, lon = 56.2500 } },
    { port = "kish_intl", start = { lat = 26.2000, lon = 53.6000 }, dock = { lat = 26.5000, lon = 53.9300 } },
    { port = "bandar_lengeh", start = { lat = 26.2000, lon = 54.7000 }, dock = { lat = 26.5300, lon = 54.8800 } },
    { port = "fujairah_intl", start = { lat = 25.1000, lon = 57.0000 }, dock = { lat = 25.1500, lon = 56.3800 } },
    { port = "bandar_e_jask", start = { lat = 25.2000, lon = 57.9000 }, dock = { lat = 25.6200, lon = 57.7500 } },
  },
}

end

-- >>> theaters/syria.lua
do
-- ============================================================================
-- Danica Dynamic Campaign - theater pack: Syria
-- ----------------------------------------------------------------------------
-- GENERATED by tools/make_theater.py from tools/scenarios/syria.py.
-- Edit the scenario and regenerate rather than editing this file.
--
-- Scenario (Modern): a BLUE coalition holds Israel, Jordan and southern Lebanon;
-- RED holds Syria and the Bekaa / northern Lebanon. The opening fronts are the
-- Golan Heights, the Daraa - Irbid corridor and the Beirut - Bekaa road.
-- Turkey and Cyprus stay out of the war.
--
-- 45 nodes, 69 roads, 0 sea crossings, 8 front links.
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.Syria = {
  name    = "Syria",
  era     = "modern",
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.0, red = 1.10 },
  main    = { blue = "ramat_david", red = "damascus" },   -- each side's HQ (a depot): the star on the map

  nodes = {
    -- ---------------- BLUE ----------------
    { id = "beirut_rafic_hariri", name = "Beirut", kind = "airbase", side = "blue", lat = 33.8251, lon = 35.4830, airbase = "Beirut-Rafic Hariri" },
    { id = "sidon", name = "Sidon", kind = "town", side = "blue", lat = 33.5630, lon = 35.3690 },
    { id = "tyre", name = "Tyre", kind = "town", side = "blue", lat = 33.2700, lon = 35.2040 },
    { id = "kiryat_shmona", name = "Kiryat Shmona", kind = "airbase", side = "blue", lat = 33.2158, lon = 35.5958, airbase = "Kiryat Shmona" },
    { id = "rosh_pina", name = "Rosh Pina", kind = "airbase", side = "blue", lat = 32.9826, lon = 35.5707, airbase = "Rosh Pina" },
    { id = "haifa", name = "Haifa", kind = "airbase", side = "blue", lat = 32.8107, lon = 35.0435, airbase = "Haifa" },
    { id = "ramat_david", name = "Ramat David", kind = "airbase", side = "blue", lat = 32.6664, lon = 35.1842, airbase = "Ramat David", depot = true },
    { id = "megiddo", name = "Megiddo", kind = "airbase", side = "blue", lat = 32.5971, lon = 35.2301, airbase = "Megiddo" },
    { id = "irbid", name = "Irbid", kind = "town", side = "blue", lat = 32.5560, lon = 35.8500 },
    { id = "h4", name = "H4", kind = "airbase", side = "blue", lat = 32.5393, lon = 38.1951, airbase = "H4" },
    { id = "eyn_shemer", name = "Eyn Shemer", kind = "airbase", side = "blue", lat = 32.4409, lon = 35.0070, airbase = "Eyn Shemer" },
    { id = "king_hussein_air_college", name = "King Hussein Air College", kind = "airbase", side = "blue", lat = 32.3567, lon = 36.2599, airbase = "King Hussein Air College" },
    { id = "prince_hassan", name = "Prince Hassan", kind = "airbase", side = "blue", lat = 32.1607, lon = 37.1494, airbase = "Prince Hassan" },
    { id = "king_abdullah_ii", name = "King Abdullah II", kind = "airbase", side = "blue", lat = 32.0055, lon = 36.2237, airbase = "King Abdullah II" },
    { id = "marka", name = "Amman-Marka", kind = "airbase", side = "blue", lat = 31.9728, lon = 35.9917, airbase = "Marka", depot = true },
    { id = "muwaffaq_salti", name = "Muwaffaq Salti", kind = "airbase", side = "blue", lat = 31.8176, lon = 36.7787, airbase = "Muwaffaq Salti" },
    -- ---------------- RED ----------------
    { id = "kuweires", name = "Kuweires", kind = "airbase", side = "red", lat = 36.1875, lon = 37.5815, airbase = "Kuweires" },
    { id = "aleppo", name = "Aleppo", kind = "airbase", side = "red", lat = 36.1806, lon = 37.2244, airbase = "Aleppo", depot = true },
    { id = "jirah", name = "Jirah", kind = "airbase", side = "red", lat = 36.0969, lon = 37.9365, airbase = "Jirah" },
    { id = "taftanaz", name = "Taftanaz", kind = "airbase", side = "red", lat = 35.9741, lon = 36.7814, airbase = "Taftanaz" },
    { id = "tabqa", name = "Tabqa", kind = "airbase", side = "red", lat = 35.7547, lon = 38.5664, airbase = "Tabqa" },
    { id = "abu_al_duhur", name = "Abu al-Duhur", kind = "airbase", side = "red", lat = 35.7323, lon = 37.1041, airbase = "Abu al-Duhur" },
    { id = "bassel_al_assad", name = "Latakia (Bassel Al-Assad)", kind = "airbase", side = "red", lat = 35.4038, lon = 35.9502, airbase = "Bassel Al-Assad", depot = true },
    { id = "hama", name = "Hama", kind = "airbase", side = "red", lat = 35.1180, lon = 36.7124, airbase = "Hama" },
    { id = "tartus", name = "Tartus", kind = "town", side = "red", lat = 34.8890, lon = 35.8870 },
    { id = "homs", name = "Homs", kind = "town", side = "red", lat = 34.7300, lon = 36.7090 },
    { id = "rene_mouawad", name = "Qlayaat", kind = "airbase", side = "red", lat = 34.5893, lon = 36.0114, airbase = "Rene Mouawad" },
    { id = "al_qusayr", name = "Al Qusayr", kind = "airbase", side = "red", lat = 34.5693, lon = 36.5715, airbase = "Al Qusayr" },
    { id = "palmyra", name = "Palmyra", kind = "airbase", side = "red", lat = 34.5573, lon = 38.3168, airbase = "Palmyra" },
    { id = "tiyas", name = "Tiyas", kind = "airbase", side = "red", lat = 34.5226, lon = 37.6301, airbase = "Tiyas" },
    { id = "shayrat", name = "Shayrat", kind = "airbase", side = "red", lat = 34.4902, lon = 36.9076, airbase = "Shayrat", ewr = true },
    { id = "wujah_al_hajar", name = "Wujah Al Hajar", kind = "airbase", side = "red", lat = 34.2813, lon = 35.6801, airbase = "Wujah Al Hajar" },
    { id = "an_nasiriyah", name = "An Nasiriyah", kind = "airbase", side = "red", lat = 33.9186, lon = 36.8658, airbase = "An Nasiriyah" },
    { id = "rayak", name = "Rayak", kind = "airbase", side = "red", lat = 33.8511, lon = 35.9873, airbase = "Rayak" },
    { id = "zahle", name = "Zahle", kind = "town", side = "red", lat = 33.8460, lon = 35.9020 },
    { id = "sayqal", name = "Sayqal", kind = "airbase", side = "red", lat = 33.6798, lon = 37.2171, airbase = "Sayqal" },
    { id = "al_dumayr", name = "Al-Dumayr", kind = "airbase", side = "red", lat = 33.6097, lon = 36.7491, airbase = "Al-Dumayr" },
    { id = "mezzeh", name = "Mezzeh", kind = "airbase", side = "red", lat = 33.4778, lon = 36.2242, airbase = "Mezzeh" },
    { id = "qabr_as_sitt", name = "Qabr as Sitt", kind = "airbase", side = "red", lat = 33.4587, lon = 36.3577, airbase = "Qabr as Sitt" },
    { id = "damascus", name = "Damascus", kind = "airbase", side = "red", lat = 33.4255, lon = 36.5185, airbase = "Damascus", depot = true },
    { id = "marj_ruhayyil", name = "Marj Ruhayyil", kind = "airbase", side = "red", lat = 33.2888, lon = 36.4554, airbase = "Marj Ruhayyil" },
    { id = "quneitra", name = "Quneitra", kind = "town", side = "red", lat = 33.1260, lon = 35.8240 },
    { id = "khalkhalah", name = "Khalkhalah", kind = "airbase", side = "red", lat = 33.0784, lon = 36.5411, airbase = "Khalkhalah" },
    { id = "thalah", name = "Tha'lah", kind = "airbase", side = "red", lat = 32.7040, lon = 36.4138, airbase = "Tha'lah" },
    { id = "daraa", name = "Daraa", kind = "town", side = "red", lat = 32.6250, lon = 36.1060 },
  },

  edges = {
    { "abu_al_duhur", "aleppo" },   -- 51 km
    { "abu_al_duhur", "hama" },   -- 77 km
    { "abu_al_duhur", "taftanaz" },   -- 40 km
    { "al_dumayr", "an_nasiriyah" },   -- 36 km
    { "al_dumayr", "damascus" },   -- 30 km
    { "al_dumayr", "sayqal" },   -- 44 km
    { "al_qusayr", "homs" },   -- 22 km
    { "al_qusayr", "rayak" },   -- 96 km
    { "al_qusayr", "rene_mouawad" },   -- 51 km
    { "al_qusayr", "shayrat" },   -- 32 km
    { "aleppo", "kuweires" },   -- 32 km
    { "aleppo", "taftanaz" },   -- 46 km
    { "an_nasiriyah", "rayak" },   -- 82 km
    { "an_nasiriyah", "sayqal" },   -- 42 km
    { "an_nasiriyah", "shayrat" },   -- 63 km
    { "bassel_al_assad", "hama" },   -- 76 km
    { "bassel_al_assad", "taftanaz" },   -- 98 km
    { "bassel_al_assad", "tartus" },   -- 57 km
    { "beirut_rafic_hariri", "sidon" },   -- 31 km
    { "beirut_rafic_hariri", "wujah_al_hajar" },   -- 54 km
    { "beirut_rafic_hariri", "zahle" },   -- 39 km
    { "damascus", "marj_ruhayyil" },   -- 16 km
    { "damascus", "qabr_as_sitt" },   -- 15 km
    { "daraa", "irbid" },   -- 25 km
    { "daraa", "king_hussein_air_college" },   -- 33 km
    { "daraa", "quneitra" },   -- 61 km
    { "daraa", "thalah" },   -- 30 km
    { "eyn_shemer", "megiddo" },   -- 27 km
    { "h4", "prince_hassan" },   -- 107 km
    { "haifa", "ramat_david" },   -- 21 km
    { "haifa", "rosh_pina" },   -- 53 km
    { "haifa", "tyre" },   -- 53 km
    { "hama", "homs" },   -- 43 km
    { "hama", "tartus" },   -- 79 km
    { "homs", "shayrat" },   -- 32 km
    { "irbid", "marka" },   -- 66 km
    { "irbid", "megiddo" },   -- 58 km
    { "irbid", "rosh_pina" },   -- 54 km
    { "jirah", "kuweires" },   -- 33 km
    { "jirah", "tabqa" },   -- 68 km
    { "khalkhalah", "marj_ruhayyil" },   -- 25 km
    { "khalkhalah", "thalah" },   -- 43 km
    { "king_abdullah_ii", "king_hussein_air_college" },   -- 39 km
    { "king_abdullah_ii", "marka" },   -- 22 km
    { "king_abdullah_ii", "muwaffaq_salti" },   -- 56 km
    { "king_hussein_air_college", "prince_hassan" },   -- 86 km
    { "king_hussein_air_college", "thalah" },   -- 41 km
    { "kiryat_shmona", "quneitra" },   -- 23 km
    { "kiryat_shmona", "rosh_pina" },   -- 26 km
    { "kiryat_shmona", "sidon" },   -- 44 km
    { "kiryat_shmona", "tyre" },   -- 37 km
    { "marj_ruhayyil", "qabr_as_sitt" },   -- 21 km
    { "marj_ruhayyil", "quneitra" },   -- 62 km
    { "megiddo", "ramat_david" },   -- 9 km
    { "mezzeh", "qabr_as_sitt" },   -- 13 km
    { "mezzeh", "quneitra" },   -- 54 km
    { "mezzeh", "rayak" },   -- 47 km
    { "muwaffaq_salti", "prince_hassan" },   -- 52 km
    { "palmyra", "tiyas" },   -- 63 km
    { "prince_hassan", "thalah" },   -- 92 km
    { "quneitra", "rosh_pina" },   -- 28 km
    { "ramat_david", "rosh_pina" },   -- 50 km
    { "rayak", "zahle" },   -- 8 km
    { "rene_mouawad", "tartus" },   -- 35 km
    { "rene_mouawad", "wujah_al_hajar" },   -- 46 km
    { "sayqal", "tiyas" },   -- 101 km
    { "shayrat", "tiyas" },   -- 66 km
    { "sidon", "tyre" },   -- 36 km
    { "wujah_al_hajar", "zahle" },   -- 52 km
  },

  -- Naval groups: placed by tools/make_mission.py (client slots on carriers). Each
  -- sails legKm (default 80) on its heading and turns around; sunk = its air wing is gone.
  --   tacan / icls: beacon channels (false = none). The tankers use 51X/52X.
  naval = {
    { id = "cvn", side = "blue", name = "CVN-74 John C. Stennis", kind = "carrier", lat = 33.3000, lon = 34.4000,
      heading = 0, ship = "Stennis", escorts = { "USS_Arleigh_Burke_IIa", "USS_Arleigh_Burke_IIa", "TICONDEROG" },
      tacan = 74, tacanCall = "STN", icls = 4,
      slots = { "FA-18C_hornet", "FA-18C_hornet", "F-14B", "F-14B", "F-14BU", "F-14A-135-GR" } },
    { id = "lha", side = "blue", name = "LHA-1 Tarawa", kind = "carrier", lat = 32.9500, lon = 34.7500,
      heading = 0, legKm = 60, ship = "LHA_Tarawa", amphib = true, escorts = { "PERRY" },
      tacan = 75, tacanCall = "TAR", icls = 5,
      slots = { "AV8BNA", "AV8BNA", "UH-1H", "AH-64D_BLK_II", "SA342M" } },
    { id = "kuz", side = "red", name = "Admiral Kuznetsov", kind = "carrier", lat = 35.2000, lon = 35.3000,
      heading = 200, ship = "KUZNECOW", amphib = true, escorts = { "MOSCOW", "REZKY", "NEUSTRASH" },
      tacan = false, icls = false,
      slots = { "Su-33", "Su-33", "Su-33", "Su-33", "Ka-50_3" } },
  },

  -- Shipping lanes (dcc_ext3.lua): supply ships sail from start (open sea) to dock
  -- (just off the port) for whoever holds the port; the port is a node id.
  shipping = {
    { port = "beirut_rafic_hariri", start = { lat = 33.8500, lon = 34.8000 }, dock = { lat = 33.9100, lon = 35.4500 } },
    { port = "sidon", start = { lat = 33.5000, lon = 34.7500 }, dock = { lat = 33.5600, lon = 35.3300 } },
    { port = "tyre", start = { lat = 33.2000, lon = 34.6000 }, dock = { lat = 33.2700, lon = 35.1600 } },
    { port = "haifa", start = { lat = 32.9000, lon = 34.4000 }, dock = { lat = 32.8500, lon = 34.9600 } },
    { port = "bassel_al_assad", start = { lat = 35.4500, lon = 35.1000 }, dock = { lat = 35.5300, lon = 35.7300 } },
    { port = "tartus", start = { lat = 34.8500, lon = 35.2000 }, dock = { lat = 34.8900, lon = 35.8300 } },
  },
}

end

DCC.start()
