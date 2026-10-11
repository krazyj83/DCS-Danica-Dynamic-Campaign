-- Danica Dynamic Campaign bundle 0.5.0-phase5 (generated - edit the sources, not this file)

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
  version         = "0.5.0-phase5",

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
    airPoolStart     = { fighter = 8,  attack = 8 },
    airPoolMax       = { fighter = 12, attack = 12 },
    airPoolRestockTicks = 24, airPoolRestockCost = 15, -- one AI aircraft bought every 2 h
    airCoverTicks    = 12,    -- CAP gives 1 h of air superiority over its area
    intelFreshTicks  = 72,    -- recon older than 6 h is stale
    convoyAmbushChance = 0.15, convoyAmbushLoss = 0.5, -- unescorted last leg to the front
    csarTimeoutTicks = 24,    -- a downed pilot is captured after 2 h
    crateSU          = 10,    -- supply in one helicopter crate
  },

  -- Mission board (phase 3)
  missions = {
    perType = { CAS = 2, BAI = 3, STRIKE = 2, SEAD = 2, CAP = 1, ESCORT = 2,
                CONVOY = 2, RECON = 2, CSAR = 4, LOGISTICS = 2, EWR = 1, HVAA = 1 },
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
  warClockDays     = 7,     -- a war ends after this many days of server time; most bases wins (0 = off)
  campaignOverFlag = 9900,  -- user flag set to 1 when a war ends (DCSServerBot watches it)
  rotation         = { "Caucasus", "Syria", "PersianGulf", "GermanyCW" }, -- fixed map order
  rotationEnforce  = true,  -- a mission for the wrong map waits for the hook instead of starting a war
                            -- (delete Saved Games\DCS\DCC\rotation.json to pick a map by hand)

  -- Drawing (F10 map) -----------------------------------------------------------
  markIdBase       = 7000000,  -- F10 mark ids used by the engine start here
  colours = {
    blue  = { 0.15, 0.45, 1.00, 1.0 },
    red   = { 1.00, 0.20, 0.15, 1.0 },
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
    T = indexTheater(theater), cat = catalog, cfg = cfg,
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
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv and mv.status == "moving" then
      if #mv.platoons == 0 and not mv.cargo then
        self:markKilled(mid)
        self.state.moves[mid] = nil
      else
        -- Live moves are advanced by the bridge from real unit positions.
        local step = (mv.kind == "airlift") and airKmPerTick or kmPerTick
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
  local rate = self.cfg.battleLossRate
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
function War:recordSortie(key, side, name)
  self.state.roster = self.state.roster or {}
  local r = self.state.roster[key] or { name = name, blue = 0, red = 0 }
  r[side] = (r[side] or 0) + 1
  r.name = name or r.name
  self.state.roster[key] = r
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
  self:log("victory", winner, string.format("%s wins the war on %s %s after %.1f days (BLUE %d bases, RED %d bases)",
    winner:upper(), self.T.name, how == "conquest" and "by conquest" or "on the war clock", days,
    s.blue.nodes, s.red.nodes))
end

-- War clock: the war ends after cfg.warClockDays. The side holding more bases
-- wins; a tie goes to the stronger army, then to the larger stock of supply.
function War:clockTicksLeft()
  local days = self.cfg.warClockDays
  if not days or days <= 0 then return nil end
  local limit = math.floor(days * 86400 / self.cfg.tickSeconds + 0.5)
  return limit - (self.state.tick - (self.state.clockStart or 0))
end

function War:clockLeader()
  local s, power, sup = self:summary(), { blue = 0, red = 0 }, self:supplySummary()
  for _, pl in pairs(self.state.platoons) do power[pl.side] = power[pl.side] + pl.health end
  if s.blue.nodes ~= s.red.nodes then return s.blue.nodes > s.red.nodes and "blue" or "red" end
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
      self:log("clock", nil, string.format("War clock: %s left on %s. %s holds the most bases and wins if it stays that way.",
        text, self.T.name, lead:upper()))
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
  if ns.supply == nil then ns.supply = self:supplyCap(id) * S(self).startFraction end
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
      self:log("airlift_in", mv.side, string.format("%s airlift landed at %s with %d supply",
        mv.side:upper(), self:nodeName(mv.to), math.floor(amount + 0.5)))
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
    string.format("%s %s from %s to %s destroyed%s", mv.side:upper(), mv.kind,
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
              local key = dist[nb] * 1000 - (keep - held)
              if not bestKey or key < bestKey then best, bestKey = { id = nb, room = keep - held }, key end
            end
            if not best and sd and sdist[nb] and sdist[nb] < sd then
              local room = keep + cfg.convoyCapacity * 2 - held
              if room > 0 then
                local key = 100000 + sdist[nb] * 1000 - room
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
  -- Air assault: a move that has already arrived and is fighting.
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
        label = string.format("airlift %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
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
        have[m.type] = (have[m.type] or 0) + 1
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
              needs = War.MISSION_NEEDS[t] }
            have[key] = true
            have[t] = (have[t] or 0) + 1
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
  missions = 20, rescues = 25, deaths = -10, captured = -5,
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
                 "wins_conquest", "wins_clock" }

function Pilots:get(key, name)
  local p = self.data.pilots[key]
  if not p then
    p = { name = name or key, sides = { blue = 0, red = 0 }, byType = {}, wars = {} }
    for _, f in ipairs(FIELDS) do p[f] = 0 end
    self.data.pilots[key] = p
    self.dirty = true
  end
  if name and p.name ~= name then p.name = name; self.dirty = true end
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

-- War won: every pilot who flew at least one sortie for the winner in this war.
-- roster = war.state.roster ({ [key] = { name, blue = sorties, red = sorties } }).
-- Returns the names that got the bonus.
function Pilots:warWon(roster, winner, how)
  local field = (how == "conquest") and "wins_conquest" or "wins_clock"
  local names = {}
  for _, key in ipairs(U.sortedKeys(roster or {})) do
    local r = roster[key]
    if (r[winner] or 0) >= 1 then
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

function Pilots:summary(key)
  local p = self.data.pilots[key]
  if not p then return "No record yet - fly a sortie." end
  local types = {}
  for _, t in ipairs(U.sortedKeys(p.byType)) do types[#types + 1] = t .. " " .. p.byType[t] end
  local wars = U.sortedKeys(p.wars)
  return table.concat({
    string.format("%s %s  -  %d points", self:rank(key), p.name, self:score(key)),
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
    if not isWater(x, z) then return { x = x, z = z } end
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
    units[i] = { name = gname .. "_" .. i, type = types[i], skill = "Average",
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

  -- Front line: visible to everyone.
  for _, seg in ipairs(DCC.front.segments(war)) do
    trigger.action.lineToAll(-1, newMark(), toVec3(seg.a), toVec3(seg.b), cfg.colours.front, 1, true)
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
           or ev.kind == "ewr_destroyed" or ev.kind == "awacs_lost"
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
    lines[#lines + 1] = string.format("War clock: %dd %02dh left - %s holds the most bases", math.floor(h / 24),
      math.floor(h % 24), war:clockLeader():upper())
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
    local expect = total / (DCC.config.supply.airliftSpeedKmh / 3.6)
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
  B.players[uname] = p
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
  if p.mission then B.war:leaveMission(p.mission, p.key) end
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

function B.brief(p, m)
  local pos = B.missionPos(m)
  local u = unitByName(p.unit)
  local lines = { string.format("MISSION %s - %s", m.type, m.label) }
  if pos then
    lines[#lines + 1] = "Target: " .. fmtLL(pos)
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
  if p.mission and p.mission ~= args.mid then B.war:leaveMission(p.mission, p.key) end
  p.mission, p.capSeconds = m.id, 0
  B.updateForced()                       -- the target spawns for real right away
  if m.type == "CONVOY" then B.spawnAmbush(m) end
  B.brief(p, m)
  B.buildMenu(p)
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
  B.war:leaveMission(p.mission, p.key)
  p.mission = nil
  trigger.action.outTextForGroup(p.gid, "Mission abandoned.", 10)
  B.buildMenu(p)
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

-- (Re)build one aircraft's "Missions" menu.
function B.buildMenu(p)
  if not p.gid then return end
  if p.menu then ok(missionCommands.removeItemForGroup, p.gid, p.menu) end
  local root = missionCommands.addSubMenuForGroup(p.gid, "Missions")
  p.menu = root
  -- One submenu per mission type this aircraft can fly ("SEAD (2)"), so the
  -- F10 page never overflows (DCS shows at most 10 items per page).
  local byType, order = {}, {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if B.canFly(p, m) then
      if not byType[m.type] then byType[m.type] = {}; order[#order + 1] = m.type end
      table.insert(byType[m.type], m)
    end
  end
  for _, t in ipairs(order) do
    local sub = missionCommands.addSubMenuForGroup(p.gid, string.format("%s (%d)", t, #byType[t]), root)
    for i, m in ipairs(byType[t]) do
      if i <= 9 then
        local mark = (p.mission == m.id) and "> " or ""
        missionCommands.addCommandForGroup(p.gid, mark .. m.type .. ": " .. m.label, sub, B.takeMission,
          { unit = p.unit, mid = m.id })
      end
    end
  end
  missionCommands.addCommandForGroup(p.gid, "My mission (brief again)", root, B.myMission, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Abandon mission", root, B.abandon, p.unit)
  missionCommands.addCommandForGroup(p.gid, "My pilot record", root, B.showRecord, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Leaderboard", root, B.showLeaderboard, p.unit)
  local lift = (cat().lift or {})[p.type]
  if lift then
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
  if kind == "CAP" then
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
    if not tname:find("^DCC_INF") then return end
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
      B.war:recordSortie(p.key, p.side, p.name)   -- who flew for whom in this war (victory bonus)
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
  for key, name in pairs(m.taken) do
    if outcome == "done" then DCC.pilots:mission(key, m.type, name) end
    for _, p in pairs(B.players) do
      if p.key == key and p.mission == m.id then
        trigger.action.outTextForGroup(p.gid, string.format("Mission %s: %s %s.",
          outcome == "done" and "COMPLETE" or outcome:upper(), m.type, m.label), 15)
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
            local range = ((not t.e) or t.e.air) and cfg.visualKmAir or cfg.visualKmGround
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
      for _, u in ipairs(air[enemy]) do
        if dist2D(u:getPoint(), pos) <= cfg.samWakeKm * 1000 then awake = true; break end
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
    -- victory bonus for everyone who flew for the winner in this war
    local names, pts = DCC.pilots:warWon(war.state.roster, war.state.winner, war.state.winBy)
    if #names > 0 then
      trigger.action.outText(string.format("Victory bonus (+%d points, %s) for %d %s pilots: %s", pts,
        war.state.winBy == "conquest" and "conquest" or "war clock", #names, war.state.winner:upper(),
        table.concat(names, ", ")), 60)
    end
    DCC.save()
    -- the server hook sees this and loads the next map's mission
    DCC.persist.writeRotation({ current = nextMap, state = "ended", finished = DCC.theaterName,
                                winner = war.state.winner, next = nextMap, tick = war.state.tick })
    trigger.action.outText(string.format("The war on %s is over. %s wins.%s",
      DCC.theaterName, war.state.winner:upper(),
      nextMap and (" Next theater: " .. nextMap .. ".") or ""), 120)
    U.log("war over, winner %s, flag %d set", war.state.winner, DCC.config.campaignOverFlag)
  end
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
  local war
  if state and not state.winner then
    war = DCC.War.restore(theater, catalog, DCC.config, state)
    U.log("war restored on %s at tick %d", DCC.theaterName, state.tick or 0)
  else
    if state and state.winner then DCC.persist.archive(DCC.theaterName, state) end
    war = DCC.War.new(theater, catalog, DCC.config, newSeed())
    U.log("new war started on %s", DCC.theaterName)
  end
  DCC.warObj = war
  DCC.started = true
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
      awacs   = { type = "E-3A",     loadout = {}, size = 1 },
    },
    red = {
      fighter = { type = "MiG-29S",  loadout = { { "R-77", 4 }, { "R-73", 2 } } },
      attack  = { type = "Su-25",    loadout = { { "S-8KOM", 4 }, { "OFAB-250", 4 }, { "R-60M", 2 } } },
      awacs   = { type = "A-50",     loadout = {}, size = 1 },
    },
  },

  -- Early-warning radar sites (phase 5). The first type that exists in this DCS install is used.
  ewr = {
    blue = { "FPS-117", "55G6 EWR" },
    red  = { "1L13 EWR", "55G6 EWR" },
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
-- ============================================================================

DCC_THEATERS = DCC_THEATERS or {}

DCC_THEATERS.Caucasus = {
  name    = "Caucasus",
  era     = "modern",
  -- Country used for spawned units. CJTF countries accept any unit type.
  country = { blue = "CJTF_BLUE", red = "CJTF_RED" },
  balance = { blue = 1.0, red = 1.0 },

  nodes = {
    -- ---------------- BLUE (Georgia) ----------------
    { id = "batumi",     name = "Batumi",          kind = "airbase", side = "blue", lat = 41.6103, lon = 41.5997, airbase = "Batumi", depot = true },
    { id = "kobuleti",   name = "Kobuleti",        kind = "airbase", side = "blue", lat = 41.9300, lon = 41.8639, airbase = "Kobuleti" },
    { id = "poti",       name = "Poti",            kind = "town",    side = "blue", lat = 42.1460, lon = 41.6720 },
    { id = "senaki",     name = "Senaki-Kolkhi",   kind = "airbase", side = "blue", lat = 42.2410, lon = 42.0480, airbase = "Senaki-Kolkhi" },
    { id = "zugdidi",    name = "Zugdidi",         kind = "town",    side = "blue", lat = 42.5088, lon = 41.8709 },
    { id = "kutaisi",    name = "Kutaisi",         kind = "airbase", side = "blue", lat = 42.1767, lon = 42.4826, airbase = "Kutaisi" },
    { id = "zestaponi",  name = "Zestaponi",       kind = "town",    side = "blue", lat = 42.1100, lon = 43.0520 },
    { id = "ambrolauri", name = "Ambrolauri",      kind = "town",    side = "blue", lat = 42.5210, lon = 43.1500 },
    { id = "khashuri",   name = "Khashuri",        kind = "town",    side = "blue", lat = 41.9930, lon = 43.6000 },
    { id = "gori",       name = "Gori",            kind = "town",    side = "blue", lat = 41.9840, lon = 44.1100 },
    { id = "pasanauri",  name = "Pasanauri",       kind = "town",    side = "blue", lat = 42.3500, lon = 44.6900 },
    { id = "tbilisi",    name = "Tbilisi-Lochini", kind = "airbase", side = "blue", lat = 41.6692, lon = 44.9547, airbase = "Tbilisi-Lochini", depot = true },
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
  balance = { blue = 1.0, red = 1.15 },

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
  balance = { blue = 1.0, red = 1.0 },

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
  balance = { blue = 1.0, red = 1.0 },

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
}

end

DCC.start()
