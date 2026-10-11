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
