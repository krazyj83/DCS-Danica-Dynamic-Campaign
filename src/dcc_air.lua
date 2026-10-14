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

  local dst, dstKey
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    local busy = false
    for _, mv in pairs(self.state.moves) do if mv.helo and mv.to == id then busy = true end end
    if ns.side == side and tn.kind ~= "carrier" and not busy and (dist[id] == 1 or sdist[id] == 0) then
      local need = self:supplyKeep(id, dist, sdist) - ns.supply - self:incomingSupply(id, side)
      if need >= cap * 0.5 then
        local threat = 0
        if self.threatOn then
          for nb in pairs(tn.nb) do
            if self.state.nodes[nb].side == side then threat = math.max(threat, self:threatOn(side, nb, id)) end
          end
        end
        local key = (supplied[id] and 1 or 0) * 100000 - threat * 1000 - need
        if not dstKey or key < dstKey then dst, dstKey = id, key end
      end
    end
  end
  if not dst then return end

  local src, srcKm
  for _, id in ipairs(self.T.order) do
    local ns, tn = self.state.nodes[id], self.T.nodes[id]
    if id ~= dst and ns.side == side and tn.kind ~= "carrier" and dist[id] and dist[id] > 1 then
      local km = U.distKm(self.T.nodes[id], self.T.nodes[dst])
      local surplus = ns.supply - self:supplyKeep(id, dist, sdist)
      if km >= cfg.heliliftMinKm and km <= cfg.heliliftMaxKm and surplus >= cap and (not srcKm or km < srcKm) then
        src, srcKm = id, km
      end
    end
  end
  if not src then return end
  local mv = self:startCargo("airlift", side, src, dst, cap)
  if mv then
    mv.helo, mv.km = true, srcKm
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
