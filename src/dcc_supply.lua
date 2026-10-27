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
