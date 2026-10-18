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

function War:weatherKind() return self.state.weather and self.state.weather.kind or "clear" end
function War:isStorm() return self:weatherKind() == "storm" end
function War:isNight() return self.night == true end   -- set by the bridge, not saved

function War:weatherTick()
  local w, cfg = self.state.weather, W(self)
  if self.state.tick - w.since < cfg.weatherTicks then return end
  local roll, acc, nextKind = self.rng:next(), 0, w.kind
  for _, opt in ipairs(War.WEATHER_NEXT[w.kind]) do
    acc = acc + opt[2]
    if roll < acc then nextKind = opt[1]; break end
  end
  local changed = nextKind ~= w.kind
  self.state.weather = { kind = nextKind, since = self.state.tick }
  if changed then
    self:log("weather", nil, string.format("Weather on %s: %s.", self.T.name, War.WEATHER_TEXT[nextKind]))
  end
end

-- Ground column speed and dice battles in bad weather.
function War:moveSpeedFactor(mv)
  if mv.kind == "airlift" then return 1 end
  return W(self).speedFactor[self:weatherKind()] or 1
end

function War:battleFactor()
  return W(self).battleFactor[self:weatherKind()] or 1
end

-- Visual detection range multiplier (players' eyes).
function War:visualFactor(air)
  local f = W(self).visualFactor[self:weatherKind()] or 1
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
