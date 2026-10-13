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
