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
