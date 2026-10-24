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
