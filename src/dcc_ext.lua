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
