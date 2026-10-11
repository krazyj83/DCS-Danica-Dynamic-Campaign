-- Danica Dynamic Campaign bundle 0.2.0-phase2 (generated - edit the sources, not this file)

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
  local T = { name = theater.name, nodes = {}, order = {}, edges = {} }
  for _, n in ipairs(theater.nodes) do
    assert(n.id and n.lat and n.lon and n.side, "theater node needs id, lat, lon, side")
    T.nodes[n.id] = {
      id = n.id, name = n.name or n.id, kind = n.kind or "town",
      depot = n.depot and true or false,
      lat = n.lat, lon = n.lon, airbase = n.airbase,
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
      T.edges[#T.edges + 1] = { a = a.id, b = b.id, km = km }
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
function War:log(kind, side, text)
  local ev = { tick = self.state.tick, kind = kind, side = side, text = text }
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
function War:isMoveLive(mv)
  if mv.kind == "airlift" then return self.airLive == true end
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

function War:produce()
  self.state.prodPoints = self.state.prodPoints or {}
  for _, id in ipairs(self.T.order) do
    local tn, ns = self.T.nodes[id], self.state.nodes[id]
    if tn.depot then
      local factor = self:productionFactor(ns.side)
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
    self:log("battle", mv.side, string.format("%s forces attack %s", mv.side:upper(), self:nodeName(mv.to)))
  end
end

function War:advanceMoves()
  local kmPerTick = self.cfg.groundSpeedKmh * self.cfg.tickSeconds / 3600
  local airKmPerTick = self.cfg.supply.airliftSpeedKmh * self.cfg.tickSeconds / 3600
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv and mv.status == "moving" then
      if #mv.platoons == 0 and not mv.cargo then
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
    mv.side:upper(), self:nodeName(mv.to), old:upper()))
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
          ns.side:upper(), self:nodeName(target), attackers[1].side:upper()))
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

function War:checkVictory()
  if self.state.winner then return end
  for _, side in ipairs(SIDES) do
    if self:countNodes(side) == 0 then
      local winner = U.otherSide(side)
      self.state.winner = winner
      -- Stray units of the loser are removed so one lost truck cannot stall the end.
      for pid, pl in pairs(self.state.platoons) do
        if pl.side == side then self:destroyPlatoon(pid) end
      end
      for mid, mv in pairs(self.state.moves) do
        if mv.side == side then self.state.moves[mid] = nil end
      end
      self:log("victory", winner, string.format("%s wins the war on %s after %d ticks",
        winner:upper(), self.T.name, self.state.tick))
    end
  end
end

-- One war step. Returns the events that happened in it.
function War:tick()
  self.newEvents = {}
  if self.state.winner then return self.newEvents end
  self.state.tick = self.state.tick + 1
  self:produce()
  self:produceSupply()
  self:advanceMoves()
  self:resolveBattles()
  self:upkeep()
  self:restockAircraft()
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
  return self.newEvents
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
  return n
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
      ns.supply = math.min(self:supplyCap(id), ns.supply + cfg.depotPerTick * self:productionFactor(ns.side))
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
    if ns.air and ns.supply >= cfg.airRestockCost then
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
  local amount = mv.cargo * (mv.health or 1)
  if ns.side == mv.side then
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
          self:startCargo("convoy", side, id, best.id, math.min(surplus, best.room, cfg.convoyCapacity))
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
    if B.liveNodes[mv.from] or B.liveNodes[mv.to] then
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
    if ev.kind == "capture" or ev.kind == "victory" then
      trigger.action.outText(ev.text, ev.kind == "victory" and 60 or 20)
    elseif ev.kind == "repulsed" then
      trigger.action.outText(ev.text, 15)
    elseif ev.kind == "convoy_lost" or ev.kind == "airlift_lost" then
      trigger.action.outText(ev.text, 15)            -- both sides: the kill mattered
    elseif (ev.kind == "focus" or ev.kind == "assault" or ev.kind == "airlift" or ev.kind == "airlift_in"
            or ev.kind == "nosupply" or ev.kind == "cargo_lost") and ev.side then
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
      elseif B.liveNodes[mv.from] or B.liveNodes[mv.to] then want[mid] = mv end
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
    local ok, err = pcall(fn, ...)
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
  DCC.dcs.draw()
  DCC.save()

  if war.state.winner and not DCC.ended then
    DCC.ended = true
    trigger.action.setUserFlag(DCC.config.campaignOverFlag, 1)
    local rot, nextMap = DCC.config.rotation, nil
    for i, m in ipairs(rot) do if m == DCC.theaterName then nextMap = rot[i % #rot + 1] end end
    trigger.action.outText(string.format("The war on %s is over. %s wins.%s",
      DCC.theaterName, war.state.winner:upper(),
      nextMap and (" Next theater: " .. nextMap .. ".") or ""), 120)
    U.log("war over, winner %s, flag %d set", war.state.winner, DCC.config.campaignOverFlag)
  end
end

function DCC.start()
  if DCC.started then return end
  local theater, name = pickTheater()
  if not theater then return end
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

  DCC.dcs.init(war, theater, catalog)
  DCC.dcs.writeWarehouses()         -- enemy aircraft off every base before anyone slots
  DCC.dcs.addMenus()
  DCC.dcs.updateLive()
  DCC.dcs.reconcile()
  DCC.dcs.reconcileCargo()
  DCC.dcs.draw()

  -- Save when the mission ends; guard player slots at enemy-held bases.
  world.addEventHandler({ onEvent = function(_, e)
    if e.id == world.event.S_EVENT_MISSION_END then safe("save", DCC.save)()
    elseif e.id == world.event.S_EVENT_BIRTH and e.initiator then
      safe("slotGuard", DCC.dcs.onBirth)(e.initiator)
    end
  end })

  local cfg = DCC.config
  timer.scheduleFunction(function(_, t)
    safe("liveCheck", DCC.dcs.liveCheck)()
    return t + cfg.liveCheckSeconds
  end, nil, timer.getTime() + cfg.liveCheckSeconds)

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

DCC.start()
