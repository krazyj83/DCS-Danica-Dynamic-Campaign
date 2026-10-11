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
