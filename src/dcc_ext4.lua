-- ============================================================================
-- Danica Dynamic Campaign - engineers (pure Lua 5.1, v0.27).
-- Load after dcc_ext3.lua.
-- ----------------------------------------------------------------------------
--  15. Engineer repair: a CTLD repair kit set down at an own base fixes one
--      thing at once instead of waiting hours for the base to do it:
--        1. a destroyed strike building (fuel, ammo, warehouse ...), else
--        2. the air defence (suppressed or destroyed SAM), else
--        3. a destroyed early-warning radar.
--      The kit is paid for when it is requested (CTLD), so no supply here.
--  (6 Combined Arms, 7 QRA and 16 performance guard are bridge-only:
--   dcc_dcs_ext4.lua)
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War

-- What a repair kit would fix at base id, or nil: "infra", "sam" or "ewr".
function War:repairNeed(id)
  local ns = self.state.nodes[id]
  if not ns then return nil end
  if ns.infra and next(ns.infra.lost or {}) then return "infra" end
  if ns.sam and ns.sam.status ~= "up" then return "sam" end
  if ns.ewr and ns.ewr.status == "destroyed" then return "ewr" end
  return nil
end

-- Engineers repair one thing at base id (held by side). Returns a text or nil.
function War:engineerRepair(id, side)
  local ns = self.state.nodes[id]
  if not ns or ns.side ~= side then return nil end
  local need = self:repairNeed(id)
  local name = self:nodeName(id)
  local text
  if need == "infra" then
    local k = U.sortedKeys(ns.infra.lost)[1]
    ns.infra.lost[k] = nil
    ns.infra.repairAt = next(ns.infra.lost) and ns.infra.repairAt or nil
    text = string.format("Engineers rebuilt the %s at %s", k == "1" and "fuel store" or "supply building", name)
  elseif need == "sam" then
    ns.sam = { status = "up" }
    text = string.format("Engineers put the air defence at %s back up", name)
  elseif need == "ewr" then
    ns.ewr = { status = "up" }
    text = string.format("Engineers put the early-warning radar at %s back on the air", name)
  else
    return nil
  end
  self:log("engineer_repair", side, side:upper() .. ": " .. text, { node = id, what = need })
  return text
end

-- ============================================================================
-- 6b. Ground missions for Combined Arms players (v0.28)
-- ----------------------------------------------------------------------------
--   ASSAULT  own attack on an enemy base   the base is captured        GROUND
--   HOLD     own base under attack         the attack is repulsed      GROUND
--   GCONVOY  own supply convoy by road     it arrives                  GROUND
-- Only players in ground vehicles see them. Credit goes to those who were
-- there: the bridge samples who is within presenceKm (War:groundPresence) and
-- players with less than presenceMin minutes are dropped before the credit.
-- ============================================================================
local gen = War.missionGenerators
local function G(self) return self.cfg.ext4.ground end

War.MISSION_NEEDS.ASSAULT, War.MISSION_NEEDS.HOLD, War.MISSION_NEEDS.GCONVOY = "GROUND", "GROUND", "GROUND"
for _, t in ipairs({ "ASSAULT", "HOLD", "GCONVOY" }) do War.MISSION_ORDER[#War.MISSION_ORDER + 1] = t end

gen.ASSAULT = function(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "assault" and not seen[mv.to]
       and (mv.status == "fighting" or mv.status == "moving") and self.state.nodes[mv.to].side ~= side then
      seen[mv.to] = true
      out[#out + 1] = { type = "ASSAULT", target = mv.to, node = mv.to, prio = mv.status == "fighting" and 0 or 1,
        label = "take " .. self:nodeName(mv.to) }
    end
  end
  return out
end

gen.HOLD = function(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side ~= side and mv.kind == "assault" and not seen[mv.to] and self.state.nodes[mv.to].side == side
       and (mv.status == "fighting" or mv.status == "moving") then
      seen[mv.to] = true
      out[#out + 1] = { type = "HOLD", target = mv.to, node = mv.to, prio = mv.status == "fighting" and 0 or 1,
        label = "hold " .. self:nodeName(mv.to) }
    end
  end
  return out
end

gen.GCONVOY = function(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "convoy" and mv.status == "moving" and (mv.progress or 0) < 0.8
       and not (self.onSea and self:onSea(mv)) then
      out[#out + 1] = { type = "GCONVOY", target = mid, node = mv.to, prio = mv.front and 0 or 1,
        label = string.format("convoy %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

-- The bridge: player key was near the mission for `seconds`.
function War:groundPresence(mid, key, seconds)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" or not m.taken[key] then return end
  m.presence = m.presence or {}
  m.presence[key] = (m.presence[key] or 0) + seconds
end

-- Only players who were there are credited.
local function onlyPresent(self, m)
  local need = G(self).presenceMin * 60
  for key in pairs(m.taken) do
    if ((m.presence or {})[key] or 0) < need then m.taken[key] = nil end
  end
end

local baseOutcome = War.missionOutcome
function War:missionOutcome(m, events)
  local t, st = m.type, self.state
  local r
  if t == "ASSAULT" or t == "HOLD" then
    for _, ev in ipairs(events) do
      if ev.node == m.target and (ev.kind == "capture" or ev.kind == "repulsed") then
        r = (ev.side == m.side) and "done" or "failed"
      end
    end
    if not r then
      local attacker = (t == "ASSAULT") and m.side or U.otherSide(m.side)
      local holder = st.nodes[m.target].side
      if (t == "ASSAULT" and holder == m.side) or (t == "HOLD" and holder ~= m.side) then return "expired" end
      for _, mv in pairs(st.moves) do
        if mv.to == m.target and mv.side == attacker and mv.kind == "assault" then return "open" end
      end
      return "expired"
    end
  elseif t == "GCONVOY" then
    if st.moves[m.target] then return "open" end
    if st.killedMoves[m.target] then return "failed" end
    r = (st.deliveredMoves and st.deliveredMoves[m.target]) and "done" or "expired"
  else
    return baseOutcome(self, m, events)
  end
  if r == "done" then onlyPresent(self, m) end
  return r
end

-- ============================================================================
-- 8. Harbour mines (v0.34)
-- ----------------------------------------------------------------------------
-- Now and then each side's minelayers (submarines, aircraft - abstract) mine an
-- enemy port on a shipping lane. While mined: no supply ship sails for that
-- port, and a ship already on its way strikes a mine on the approach (sunk,
-- cargo lost). The port's side gets a MINESWEEP mission (helicopters: fly low
-- over the harbour). Mines also clear by themselves after lifeTicks.
-- ============================================================================
local function MC(self) return self.cfg.ext4.mines end

War.MISSION_NEEDS.MINESWEEP = "SWEEP"                -- the bridge: any helicopter
War.MISSION_ORDER[#War.MISSION_ORDER + 1] = "MINESWEEP"

function War:minedPorts() return self.state.seaMines or {} end
function War:isMined(port) return (self.state.seaMines or {})[port] ~= nil end

-- side lays mines off port (an enemy port on a lane). Returns true if laid.
function War:layMines(side, port)
  local ns = self.state.nodes[port]
  self.state.seaMines = self.state.seaMines or {}
  if not ns or ns.side == side or self.state.seaMines[port] or not self:laneOf(port) then return false end
  self.state.seaMines[port] = { side = side, tick = self.state.tick, till = self.state.tick + MC(self).lifeTicks }
  self:log("mines_laid", ns.side, string.format("Mines reported off %s - %s supply ships hold until it is swept",
    self:nodeName(port), ns.side:upper()), { node = port, layer = side })
  return true
end

function War:clearMines(port, how)
  local m = (self.state.seaMines or {})[port]
  if not m then return false end
  self.state.seaMines[port] = nil
  local ns = self.state.nodes[port]
  self:log("mines_cleared", ns.side, string.format("%s harbour %s - shipping resumes", self:nodeName(port),
    how == "swept" and "swept clear of mines" or "clear, the mines have drifted or sunk"), { node = port })
  return true
end

function War:harbourMinesTick()
  local cfg = MC(self)
  self.state.seaMines = self.state.seaMines or {}
  for port, m in pairs(self.state.seaMines) do
    if self.state.tick >= m.till or self.state.nodes[port].side == m.side then self:clearMines(port, "time") end
  end
  if self.state.tick % cfg.everyTicks ~= 0 or self.state.tick == 0 then return end
  for _, side in ipairs({ "blue", "red" }) do
    -- own pseudo-random draw: does not shift the war's dice for everything else
    local roll = ((self.state.tick * 7919 + (side == "blue" and 13 or 61)) % 997) / 997
    if roll < cfg.chance then
      -- the enemy port that hurts most: a ship on its way, else the lowest supply
      local best, bestScore
      for _, l in ipairs(self:lanes()) do
        local ns = self.state.nodes[l.port]
        local busy = false
        for _, ml in pairs(self.state.minelayers or {}) do if ml.port == l.port then busy = true end end
        if ns and ns.side ~= side and not self.state.seaMines[l.port] and not busy then
          local score = (ns.supply or 0) / math.max(1, self:supplyCap(l.port))
          for _, s in pairs(self.state.shipping) do if s.port == l.port then score = score - 10 end end
          if not bestScore or score < bestScore then best, bestScore = l.port, score end
        end
      end
      if best then self:sendMinelayer(side, best) end
    end
  end
  self:minelayerTick()
end

-- ----------------------------------------------------------------------------
-- 8b. Minelayer ships (v0.35): mines are laid by a real patrol ship (BLUE Castle
-- class, RED Vasily Bykov) that sails the lane into the enemy harbour and lays
-- them at strikeAt. It is spotted by coastal radar at detectAt (or by anyone
-- who sees it) and the port's side gets a MINELAYER mission: sink it first.
-- ----------------------------------------------------------------------------
War.MISSION_NEEDS.MINELAYER = "A2G"
War.MISSION_ORDER[#War.MISSION_ORDER + 1] = "MINELAYER"

function War:minelayers() return self.state.minelayers or {} end

function War:sendMinelayer(side, port)
  local l = self:laneOf(port)
  if not l then return nil end
  self.state.minelayers = self.state.minelayers or {}
  local id = self:newId("ml")
  self.state.minelayers[id] = { id = id, side = side, port = port, progress = 0, km = U.distKm(l.start, l.dock),
                                started = self.state.tick }
  self:log("minelayer_out", side, string.format("%s minelayer sails for %s", side:upper(), self:nodeName(port)),
    { node = port, minelayer = id })
  return id
end

-- The port's side sees it (coastal radar, or a pilot): the hunt is on.
function War:spotMinelayer(id)
  local ml = (self.state.minelayers or {})[id]
  if not ml or ml.seen then return false end
  ml.seen = true
  local enemy = U.otherSide(ml.side)
  self:log("minelayer_seen", enemy, string.format("%s minelayer heading for %s - sink it before it lays mines",
    ml.side:upper(), self:nodeName(ml.port)), { node = ml.port, minelayer = id })
  return true
end

function War:minelayerSunk(id)
  local ml = (self.state.minelayers or {})[id]
  if not ml then return false end
  self.state.minelayers[id] = nil
  self.state.sunkMinelayers = self.state.sunkMinelayers or {}
  self.state.sunkMinelayers[id] = self.state.tick
  self:log("minelayer_sunk", U.otherSide(ml.side), string.format("%s minelayer bound for %s sunk - no mines",
    ml.side:upper(), self:nodeName(ml.port)), { node = ml.port, minelayer = id })
  return true
end

function War:minelayerTick()
  local cfg = MC(self)
  local step = cfg.layerSpeedKmh * self.cfg.tickSeconds / 3600
  for _, id in ipairs(U.sortedKeys(self.state.minelayers or {})) do
    local ml = self.state.minelayers[id]
    ml.progress = math.min(1, ml.progress + step / math.max(ml.km, 0.1))
    if ml.progress >= cfg.detectAt then self:spotMinelayer(id) end
    if self.state.nodes[ml.port].side == ml.side then
      self.state.minelayers[id] = nil                              -- the port changed hands: called off
    elseif ml.progress >= cfg.strikeAt then
      self.state.minelayers[id] = nil                              -- mines down, the ship heads home
      self.state.laidBy = self.state.laidBy or {}
      self.state.laidBy[id] = self.state.tick
      self:layMines(ml.side, ml.port)
    end
  end
  for id, t in pairs(self.state.sunkMinelayers or {}) do
    if self.state.tick - t > 12 then self.state.sunkMinelayers[id] = nil end
  end
  for id, t in pairs(self.state.laidBy or {}) do
    if self.state.tick - t > 12 then self.state.laidBy[id] = nil end
  end
end

gen.MINELAYER = function(self, side)
  local out = {}
  for _, id in ipairs(U.sortedKeys(self.state.minelayers or {})) do
    local ml = self.state.minelayers[id]
    if ml.side ~= side and ml.seen then
      out[#out + 1] = { type = "MINELAYER", target = id, node = ml.port, prio = 0,
        label = string.format("%s minelayer bound for %s", ml.side:upper(), self:nodeName(ml.port)) }
    end
  end
  return out
end

-- No ship sails for a mined port: they look "busy" to the planner.
local basePlan = War.planShipping
function War:planShipping()
  local dummies = {}
  for port in pairs(self.state.seaMines or {}) do
    local id = "_mined_" .. port
    self.state.shipping[id] = { id = id, side = "none", port = port, su = 0, km = 1, progress = 0 }
    dummies[#dummies + 1] = id
  end
  local s, err = pcall(basePlan, self)
  for _, id in ipairs(dummies) do self.state.shipping[id] = nil end
  if not s then error(err) end
end

-- A ship on the last stretch into a mined port strikes a mine.
local baseShipTick = War.shippingTick
function War:shippingTick()
  for _, id in ipairs(U.sortedKeys(self.state.shipping)) do
    local s = self.state.shipping[id]
    local m = (self.state.seaMines or {})[s.port]
    if m and m.side ~= s.side and (s.progress or 0) >= MC(self).strikeAt then
      self:log("mine_strike", s.side, string.format("%s supply ship struck a mine off %s", s.side:upper(),
        self:nodeName(s.port)), { node = s.port, ship = id })
      self:shippingSunk(id)
    end
  end
  return baseShipTick(self)
end

local baseOps4 = War.opsTick
function War:opsTick()
  baseOps4(self)
  self:harbourMinesTick()
end

gen.MINESWEEP = function(self, side)
  local out = {}
  for _, port in ipairs(U.sortedKeys(self.state.seaMines or {})) do
    if self.state.nodes[port].side == side then
      out[#out + 1] = { type = "MINESWEEP", target = port, node = port, prio = 0,
        label = "sweep the harbour at " .. self:nodeName(port) }
    end
  end
  return out
end

-- The bridge: a helicopter on the mission was low over the harbour for `seconds`.
function War:sweepSample(mid, seconds)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" or m.type ~= "MINESWEEP" then return end
  m.swept = (m.swept or 0) + seconds
  if m.swept >= MC(self).sweepMin * 60 and self:clearMines(m.target, "swept") then m.sweepDone = true end
end

local baseOutcome2 = War.missionOutcome
function War:missionOutcome(m, events)
  if m.type == "MINELAYER" then
    if (self.state.minelayers or {})[m.target] then return "open" end
    if (self.state.sunkMinelayers or {})[m.target] then return "done" end
    if (self.state.laidBy or {})[m.target] then return "failed" end
    return "expired"
  end
  if m.type ~= "MINESWEEP" then return baseOutcome2(self, m, events) end
  if m.sweepDone then return "done" end
  if self.state.nodes[m.target].side ~= m.side or not self:isMined(m.target) then return "expired" end
  return "open"
end

-- ============================================================================
-- Main base / HQ (v0.38)
-- ----------------------------------------------------------------------------
-- Each side's HQ is `main` in the theater pack (a depot). Lost, the side's
-- next depot (theater order) takes over, else its first airbase. The bridge
-- draws it as a star on everyone's map; Campaign status names it.
-- ============================================================================
function War:mainBase(side)
  local want = self.theater.main and self.theater.main[side]
  if want and self.state.nodes[want] and self.state.nodes[want].side == side then return want end
  local airbase
  for _, id in ipairs(self.T.order) do
    if self.state.nodes[id].side == side then
      if self.T.nodes[id].depot then return id end
      if not airbase and self.T.nodes[id].kind == "airbase" then airbase = id end
    end
  end
  return airbase
end
