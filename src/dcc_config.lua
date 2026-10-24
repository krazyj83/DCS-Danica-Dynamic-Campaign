-- ============================================================================
-- Danica Dynamic Campaign - configuration
-- ----------------------------------------------------------------------------
-- Every tunable number lives here. Values are starting points for phase 1
-- testing, not balanced results: tune them after watching a few nights of war.
-- ============================================================================

DCC = DCC or {}

DCC.config = {
  version         = "0.30.0",

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
                ASSAULT = 4, HOLD = 4, GCONVOY = 3 },   -- ground missions: Combined Arms players only
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
                stock = { basic = 500, guided = 60, advanced = 30 },   -- per weapon type per base (depots x2)
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
