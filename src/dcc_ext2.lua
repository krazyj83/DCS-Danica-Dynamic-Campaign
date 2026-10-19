-- ============================================================================
-- Danica Dynamic Campaign - more air and ground war (pure Lua 5.1, v0.18).
-- Load after dcc_ext.lua.
-- ----------------------------------------------------------------------------
--   2. HVA      : a lost tanker / AWACS is gone for 2 h. HVAESCORT missions
--                 (stay with your own tanker / AWACS); the bridge sends enemy
--                 fighters after them.
--   3. Packages : PKGESCORT missions ride with every STRIKE / INDUSTRY / EWR /
--                 RUNWAY mission. When the strike succeeds, everyone who flew
--                 SEAD or escort for it gets a package bonus.
--   5. Artillery: batteries not busy in a battle shell the nearest enemy base:
--                 it loses supply, and the flashes give the battery away (ARTY).
--   7 + 9. Pick-ups: prisoners after a surrender or capture (POW) and wounded
--                 after a battle (MEDEVAC), flown by helicopter to an airbase
--                 or depot. Prisoners talk (intel on nearby enemy bases);
--                 wounded come back (the garrison heals).
--   8. Heavy    : a generator raises a base's supply cap for 24 h; a runway
--                 repair kit reopens a cratered runway at once.
--   10. CSAR    : an enemy search party can capture a downed pilot.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

local function E(self) return self.cfg.ext2 end

local baseInitOps = War.initOps
function War:initOps()
  baseInitOps(self)
  local st = self.state
  st.hvaDown = st.hvaDown or { blue = {}, red = {} }
  st.pickups = st.pickups or {}
  st.hvaThreat = st.hvaThreat or {}
end

-- ===========================================================================
-- 2. High-value air assets
-- ===========================================================================
function War:hvaGrounded(side, kind)
  local t = self.state.hvaDown[side][kind]
  return t ~= nil and self.state.tick < t
end

local function grounded(self, side, kind)
  self.state.hvaDown[side][kind] = self.state.tick + E(self).hvaDownTicks
end

local baseAssetLost = War.assetLost
function War:assetLost(side, kind)
  baseAssetLost(self, side, kind)
  if kind == "tanker" then grounded(self, side, "tanker") end
end

local baseAwacsLost = War.awacsLost
function War:awacsLost(side)
  baseAwacsLost(self, side)
  grounded(self, side, "awacs")
end

function War:hvaUp(side, kind)
  if kind == "awacs" then return self:awacsUp(side) end
  return self:assetUp(side, kind)
end

-- The bridge sent enemy fighters after side's kind (or they went home).
function War:setHvaThreat(side, kind, on)
  self.state.hvaThreat[side .. "|" .. kind] = on and self.state.tick or nil
end

-- ===========================================================================
-- 5. Artillery duels: harassing fire when there is no battle to support
-- ===========================================================================
function War:artyHarassTick()
  local cfg = E(self)
  local fighting = {}
  for _, mv in pairs(self.state.moves) do if mv.status == "fighting" then fighting[mv.to] = true end end
  for _, side in ipairs(SIDES) do
    local enemy = U.otherSide(side)
    for _, b in ipairs(self:batteries(side)) do
      b.shelling = nil
      if b.status == "up" and b.node and self.state.nodes[b.node].side == side then
        local busy = fighting[b.node]
        for nb in pairs(self.T.nodes[b.node].nb) do if fighting[nb] then busy = true end end
        if not busy then
          local target
          for _, nb in ipairs(U.sortedKeys(self.T.nodes[b.node].nb)) do
            if self.state.nodes[nb].side == enemy and not target then target = nb end
          end
          if target then
            local ns = self.state.nodes[target]
            ns.supply = math.max(0, (ns.supply or 0) - cfg.harassSU)
            b.shelling = target
            self:addContact(enemy, "arty:" .. b.id, { kind = "arty", node = b.node, source = "sensor",
              label = "artillery battery" })
            if not b.lastLog or self.state.tick - b.lastLog >= cfg.harassLogTicks then
              b.lastLog = self.state.tick
              self:log("shelling", enemy, string.format("%s artillery at %s is shelling %s - supply is burning",
                side:upper(), self:nodeName(b.node), self:nodeName(target)), { node = target, from = b.node })
            end
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7 + 9. Prisoners and wounded: helicopter pick-ups
-- ===========================================================================
-- kind "pow": side holds n prisoners at node; "medevac": side has n wounded there.
function War:addPickup(kind, side, node, n)
  local open = 0
  for _, q in pairs(self.state.pickups) do if q.side == side then open = open + 1 end end
  if open >= E(self).maxPickups then return nil end
  for _, q in pairs(self.state.pickups) do
    if q.kind == kind and q.side == side and q.node == node and not q.onboard then
      q.n, q.tick = q.n + n, self.state.tick          -- one group per base
      return q
    end
  end
  local id = self:newId("q")
  local q = { id = id, kind = kind, side = side, node = node, n = n, tick = self.state.tick }
  self.state.pickups[id] = q
  if kind == "pow" then
    self:log("pows", side, string.format("%s holds %d prisoners at %s - fly them to the rear", side:upper(), n,
      self:nodeName(node)), { node = node })
  else
    self:log("casualties", side, string.format("%s has %d wounded at %s - MEDEVAC needed", side:upper(), n,
      self:nodeName(node)), { node = node })
  end
  return q
end

-- Where a pick-up may be delivered: an own airbase or depot, not where it came from.
function War:pickupDropOk(q, id)
  local tn, ns = self.T.nodes[id], self.state.nodes[id]
  return tn ~= nil and id ~= q.node and ns.side == q.side and (tn.kind == "airbase" or tn.depot == true)
end

function War:pickupLoaded(qid)
  local q = self.state.pickups[qid]
  if q and not q.onboard then q.onboard = true; return true end
  return false
end

function War:pickupDelivered(qid, atNode)
  local q = self.state.pickups[qid]
  if not q or not self:pickupDropOk(q, atNode) then return false end
  self.state.pickups[qid] = nil
  local enemy = U.otherSide(q.side)
  if q.kind == "pow" then
    -- interrogation: the two enemy bases nearest to where they were taken
    local list = {}
    for _, id in ipairs(self.T.order) do
      if self.state.nodes[id].side == enemy then
        list[#list + 1] = { id = id, km = U.distKm(self.T.nodes[id], self.T.nodes[q.node]) }
      end
    end
    table.sort(list, function(a, b) if a.km ~= b.km then return a.km < b.km end return a.id < b.id end)
    for i = 1, math.min(2, #list) do self:recordIntel(q.side, list[i].id) end
    self:log("pickup_done", q.side, string.format("%s prisoners from %s delivered to %s - interrogation reports "
      .. "on the nearest enemy bases", q.side:upper(), self:nodeName(q.node), self:nodeName(atNode)),
      { pickup = qid, node = q.node, pkind = "pow" })
  else
    local ns = self.state.nodes[q.node]
    if ns.side == q.side then
      for _, pid in ipairs(ns.platoons) do
        local pl = self.state.platoons[pid]
        if pl then pl.health = math.min(1, pl.health + E(self).medevacHeal) end
      end
    end
    self:log("pickup_done", q.side, string.format("%s wounded from %s flown to %s - the garrison there recovers",
      q.side:upper(), self:nodeName(q.node), self:nodeName(atNode)), { pickup = qid, node = q.node, pkind = "medevac" })
  end
  return true
end

-- The helicopter carrying them went down.
function War:pickupLost(qid)
  local q = self.state.pickups[qid]
  if not q then return end
  self.state.pickups[qid] = nil
  self:log("pickup_lost", q.side, string.format("The helicopter with the %s from %s was lost",
    q.kind == "pow" and "prisoners" or "wounded", self:nodeName(q.node)), { pickup = qid })
end

function War:pickupsTick()
  local cfg = E(self)
  -- new ones from this tick's battles
  local seen = {}
  for _, ev in ipairs(self.newEvents or {}) do
    if ev.kind == "surrender" and ev.node then
      self:addPickup("pow", ev.side, ev.node, cfg.powPerSurrender); seen[ev.node] = true
    end
  end
  for _, ev in ipairs(self.newEvents or {}) do
    if ev.kind == "capture" and ev.node and ev.from and not seen[ev.node] then
      self:addPickup("pow", ev.side, ev.node, cfg.powPerCapture)
      self:addPickup("medevac", ev.side, ev.node, cfg.medevacPerBattle)
    elseif ev.kind == "repulsed" and ev.node then
      self:addPickup("medevac", ev.side, ev.node, cfg.medevacPerBattle)
    end
  end
  -- old ones: walked out by road, or the base changed hands
  for _, qid in ipairs(U.sortedKeys(self.state.pickups)) do
    local q = self.state.pickups[qid]
    local life = q.kind == "pow" and cfg.powTicks or cfg.medevacTicks
    if not q.onboard and (self.state.nodes[q.node].side ~= q.side or self.state.tick - q.tick > life) then
      self.state.pickups[qid] = nil
    end
  end
end

-- ===========================================================================
-- 8. Heavy sling loads
-- ===========================================================================
local baseCap = War.supplyCap
function War:supplyCap(id)
  local cap = baseCap(self, id)
  local ns = self.state.nodes[id]
  if ns and ns.capBoostUntil and self.state.tick < ns.capBoostUntil then
    cap = cap * (1 + E(self).generatorBoost)
  end
  return cap
end

function War:installGenerator(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side then return false end
  ns.capBoostUntil = self.state.tick + E(self).generatorTicks
  self:log("generator", side, string.format("%s heavy lift: generators running at %s - it can store more supply for 24 h",
    side:upper(), self:nodeName(id)), { node = id })
  return true
end

function War:repairRunwayNow(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side or not self:runwayClosed(id) then return false end
  self.state.runways[id] = nil
  self:log("runway_open", side, string.format("%s heavy lift: engineers repaired the runway at %s", side:upper(),
    self:nodeName(id)), { node = id })
  return true
end

-- ===========================================================================
-- 10. A search party found the pilot
-- ===========================================================================
function War:downedCaptured(did, bySide)
  local d = self.state.downed[did]
  if not d or d.side == bySide then return false end
  self.state.downed[did] = nil
  self:log("captured", d.side, string.format("%s pilot %s was captured by a %s search party", d.side:upper(),
    tostring(d.pilot), bySide:upper()), { downed = did, pilot = d.pilot, pilotKey = d.key })
  return true
end

-- ===========================================================================
-- Missions: HVAESCORT, PKGESCORT, MEDEVAC, POW
-- ===========================================================================
War.MISSION_NEEDS.HVAESCORT = "A2A"
War.MISSION_NEEDS.PKGESCORT = "A2A"
War.MISSION_NEEDS.MEDEVAC = "LIFT"
War.MISSION_NEEDS.POW = "LIFT"
do
  local new = { HVAESCORT = true, PKGESCORT = true, MEDEVAC = true, POW = true }
  local order = {}
  for _, t in ipairs(War.MISSION_ORDER) do
    if not new[t] then order[#order + 1] = t end
    if t == "ESCORT" then order[#order + 1] = "PKGESCORT"; order[#order + 1] = "HVAESCORT" end
    if t == "CSAR" then order[#order + 1] = "MEDEVAC"; order[#order + 1] = "POW" end
  end
  War.MISSION_ORDER = order
end
if War.HUB_TYPES then War.HUB_TYPES.MEDEVAC, War.HUB_TYPES.POW = true, true end

local gen = War.missionGenerators
local HVA_NAME = { tanker = "tanker", awacs = "AWACS" }

gen.HVAESCORT = function(self, side)
  local out = {}
  for _, kind in ipairs({ "awacs", "tanker" }) do
    if self:hvaUp(side, kind) then
      local hot = self.state.hvaThreat[side .. "|" .. kind] ~= nil
      out[#out + 1] = { type = "HVAESCORT", target = side .. "|" .. kind, prio = hot and 0 or 5,
        label = string.format("our %s%s", HVA_NAME[kind], hot and " - enemy fighters inbound" or "") }
    end
  end
  return out
end

gen.PKGESCORT = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.missions or {})) do
    local m = self.state.missions[id]
    if m.side == side and m.status == "open" and E(self).pkgTypes[m.type] then
      out[#out + 1] = { type = "PKGESCORT", target = m.id, node = m.node, prio = next(m.taken) and 0 or 5,
        label = string.format("escort the %s on %s", m.type, m.label) }
    end
  end
  return out
end

local function genPickup(kind)
  return function(self, side)
    if self.isStorm and self:isStorm() then return {} end
    local out = {}
    for _, qid in ipairs(U.sortedKeys(self.state.pickups)) do
      local q = self.state.pickups[qid]
      if q.kind == kind and q.side == side and not q.onboard then
        out[#out + 1] = { type = kind == "pow" and "POW" or "MEDEVAC", target = qid, node = q.node, prio = q.tick,
          label = string.format(kind == "pow" and "%d prisoners at %s to the rear" or "%d wounded at %s", q.n,
            self:nodeName(q.node)) }
      end
    end
    return out
  end
end
gen.MEDEVAC = genPickup("medevac")
gen.POW = genPickup("pow")

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local st = self.state
  if m.type == "HVAESCORT" then
    local side, kind = m.target:match("^(.-)|(.+)$")
    for _, ev in ipairs(events) do
      if ev.kind == kind .. "_lost" and ev.side == side then return "failed" end
    end
    return self:hvaUp(side, kind) and "open" or "expired"
  elseif m.type == "PKGESCORT" then
    local s = st.missions[m.target]
    if not s or s.status == "failed" or s.status == "expired" then return "expired" end
    if s.status == "done" then return m.escortOk and "done" or "failed" end
    return "open"
  elseif m.type == "MEDEVAC" or m.type == "POW" then
    for _, ev in ipairs(events) do
      if ev.pickup == m.target then return ev.kind == "pickup_done" and "done" or "failed" end
    end
    return st.pickups[m.target] and "open" or "expired"
  end
  return baseOutcome(self, m, events)
end

-- Strike success: SEAD at the same target and the escorts share a package bonus.
local baseFinish = War.finishMission
function War:finishMission(m, outcome)
  baseFinish(self, m, outcome)
  if outcome ~= "done" or not E(self).pkgTypes[m.type] or not next(m.taken) then return end
  local crew, others = {}, 0
  for k, n in pairs(m.taken) do crew[k] = n end
  for _, o in pairs(self.state.missions) do
    local recent = o.status == "open" or (o.status == "done" and self.state.tick - (o.finished or 0) <= 2)
    if o ~= m and o.side == m.side and recent and next(o.taken)
       and ((o.type == "SEAD" and o.node == m.node) or (o.type == "PKGESCORT" and o.target == m.id)) then
      for k, n in pairs(o.taken) do if not crew[k] then others = others + 1 end; crew[k] = n end
    end
  end
  if others == 0 then return end
  local names = {}
  for _, n in pairs(crew) do names[#names + 1] = n end
  table.sort(names)
  self:log("package_done", m.side, string.format("%s strike package on %s: complete - %s", m.side:upper(), m.label,
    table.concat(names, ", ")), { crew = crew, node = m.node })
end

-- ===========================================================================
-- Tick
-- ===========================================================================
local baseOpsTick = War.opsTick
function War:opsTick()
  baseOpsTick(self)
  self:artyHarassTick()
  self:pickupsTick()
end
