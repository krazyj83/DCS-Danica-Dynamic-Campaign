-- ============================================================================
-- Danica Dynamic Campaign - mission board (phase 3, pure Lua 5.1)
-- ----------------------------------------------------------------------------
-- Each side gets a board of player missions generated from the live war. A
-- mission is an OFFER pointed at something real in the model; its effect
-- happens through the model itself (a destroyed convoy really loses its cargo,
-- a SAM really goes down). The board only decides whether the players who
-- took it succeeded, and credits them.
--
--   type       target            success when                       needs
--   CAS        node in battle    the battle goes our way            A2G
--   BAI        enemy move        that column/convoy is destroyed    A2G
--   STRIKE     enemy node        one of its buildings destroyed     A2G
--   SEAD       enemy node        its SAM is suppressed or destroyed SEAD
--   CAP        own node          20 min on station or an air kill   A2A   -> air cover 1 h
--   ESCORT     own airlift       delivered, escort stayed close     A2A
--   CONVOY     own convoy        delivered, escort stayed close     HELO  -> no ambush
--   RECON      enemy node        overflown low (intel recorded)     ANY
--   CSAR       downed pilot      pilot brought back                 LIFT
--   LOGISTICS  own node          crate unloaded there               LIFT
--
-- Detection that needs DCS (on station, overflight, escort distance, pickup)
-- lives in the bridge, which calls completeMission / recordIntel / rescue.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local War = DCC.War
local SIDES = { "blue", "red" }

War.MISSION_NEEDS = {
  CAS = "A2G", BAI = "A2G", STRIKE = "A2G", SEAD = "SEAD", CAP = "A2A",
  ESCORT = "A2A", CONVOY = "HELO", RECON = "ANY", CSAR = "LIFT", LOGISTICS = "LIFT",
}
War.MISSION_ORDER = { "CAS", "BAI", "SEAD", "STRIKE", "CAP", "ESCORT", "CONVOY", "RECON", "CSAR", "LOGISTICS" }

local function M(self) return self.cfg.missions end

-- ---------------------------------------------------------------------------
-- Candidates per type: { key, type, target, node, label, prio, base }
-- ---------------------------------------------------------------------------
local gen = {}
War.missionGenerators = gen   -- later modules add mission types here

function gen.CAS(self, side)
  local out, seen = {}, {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.status == "fighting" and not seen[mv.to] then
      local ns = self.state.nodes[mv.to]
      if mv.side == side or ns.side == side then
        seen[mv.to] = true
        local attack = (mv.side == side)
        out[#out + 1] = { type = "CAS", target = mv.to, node = mv.to, prio = 0,
          label = (attack and "support attack on " or "defend ") .. self:nodeName(mv.to),
          base = { attack = attack } }
      end
    end
  end
  return out
end

function gen.BAI(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)       -- enemy nodes near OUR territory have small values
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    local seen = (not self.fogOfWar) or self:isFresh(side, "m:" .. mid)    -- phase 4: only what we saw
    if seen and mv.side == enemy and mv.status == "moving" and mv.kind ~= "airlift" and not self:onSea(mv)
       and math.min(dist[mv.to] or 99, dist[mv.from] or 99) <= 2 then
      local what = mv.cargo and "convoy" or (mv.kind == "assault" and "assault column" or "reinforcements")
      out[#out + 1] = { type = "BAI", target = mid, node = mv.to,
        prio = (mv.cargo and 0 or 1) * 10 + (dist[mv.to] or 9),
        label = string.format("%s %s %s > %s", enemy:upper(), what, self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.STRIKE(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and ns.infra and self:infraLost(id) < ns.infra.total then
      out[#out + 1] = { type = "STRIKE", target = id, node = id,
        prio = (self.T.nodes[id].depot and 0 or 5) + (dist[id] or 9),
        label = self:nodeName(id) .. (self.T.nodes[id].depot and " depot" or " airbase stores"),
        base = { lost = self:infraLost(id) } }
    end
  end
  return out
end

function gen.SEAD(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    local known = (not self.fogOfWar) or self:samKnown(side, id) == "known"  -- phase 4
    if known and ns.side == enemy and ns.sam and ns.sam.status == "up" then
      local c = self.fogOfWar and self:contact(side, "sam:" .. id)
      local how = (c and c.source == "elint") and string.format(" (ELINT +/-%.1f km)", (c.err or 0) / 1000) or ""
      out[#out + 1] = { type = "SEAD", target = id, node = id, prio = dist[id] or 9,
        label = "air defence at " .. self:nodeName(id) .. how }
    end
  end
  return out
end

function gen.CAP(self, side)
  local f = self.state.focus and self.state.focus[side]
  local out = {}
  if f then
    for _, nb in ipairs(U.sortedKeys(self.T.nodes[f.target].nb)) do
      if self.state.nodes[nb].side == side then
        out[#out + 1] = { type = "CAP", target = nb, node = nb, prio = 0,
          label = "over " .. self:nodeName(nb) .. " (main effort)" }
        break
      end
    end
  end
  return out
end

function gen.ESCORT(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "airlift" and mv.status == "moving" then
      out[#out + 1] = { type = "ESCORT", target = mid, node = mv.to, prio = 0,
        needs = mv.helo and "ANY" or nil,        -- helicopters escort helicopters too
        label = string.format("%s %s > %s", mv.helo and "supply helicopter" or "airlift",
          self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.CONVOY(self, side)
  local out = {}
  for _, mid in ipairs(U.sortedKeys(self.state.moves)) do
    local mv = self.state.moves[mid]
    if mv.side == side and mv.kind == "convoy" and mv.front and mv.status == "moving" and mv.progress < 0.6
       and not self:onSea(mv) then
      out[#out + 1] = { type = "CONVOY", target = mid, node = mv.to, prio = 0,
        label = string.format("convoy %s > %s", self:nodeName(mv.from), self:nodeName(mv.to)) }
    end
  end
  return out
end

function gen.RECON(self, side)
  local enemy = U.otherSide(side)
  local dist = self:frontDistance(enemy)
  local f = self.state.focus and self.state.focus[side]
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == enemy and (dist[id] or 9) <= 2 and self:intelAge(side, id) > self.cfg.ops.intelFreshTicks then
      out[#out + 1] = { type = "RECON", target = id, node = id,
        prio = ((f and f.target == id) and 0 or 5) + (dist[id] or 9), label = self:nodeName(id) }
    end
  end
  return out
end

function gen.CSAR(self, side)
  local out = {}
  for _, did in ipairs(U.sortedKeys(self.state.downed)) do
    local d = self.state.downed[did]
    if d.side == side then
      out[#out + 1] = { type = "CSAR", target = did, prio = d.tick, label = "pilot " .. tostring(d.pilot) }
    end
  end
  return out
end

function gen.LOGISTICS(self, side)
  local dist = self:frontDistance(side)
  local out = {}
  for _, id in ipairs(self.T.order) do
    local ns = self.state.nodes[id]
    if ns.side == side and not self.T.nodes[id].depot then
      local low = ns.outOfSupply or (dist[id] == 1 and ns.supply < self:supplyCap(id) * 0.3)
      if low then
        out[#out + 1] = { type = "LOGISTICS", target = id, node = id,
          prio = (ns.outOfSupply and 0 or 5) + (dist[id] or 9), label = "supply to " .. self:nodeName(id) }
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Validity and completion of open missions
-- ---------------------------------------------------------------------------
-- Returns "open", "done", "failed" or "expired".
function War:missionOutcome(m, events)
  local st = self.state
  local t = m.type
  if t == "CAS" then
    for _, ev in ipairs(events) do
      if ev.node == m.target and (ev.kind == "capture" or ev.kind == "repulsed") then
        local ours = (ev.side == m.side)
        return ours and "done" or "failed"
      end
    end
    for _, mv in pairs(st.moves) do if mv.status == "fighting" and mv.to == m.target then return "open" end end
    return "expired"
  elseif t == "BAI" then
    if st.moves[m.target] then return "open" end
    return st.killedMoves[m.target] and "done" or "expired"
  elseif t == "STRIKE" then
    if st.nodes[m.target].side == m.side then return "expired" end
    return (self:infraLost(m.target) > (m.base.lost or 0)) and "done" or "open"
  elseif t == "SEAD" then
    local ns = st.nodes[m.target]
    if ns.side == m.side then return "expired" end
    return (ns.sam and ns.sam.status ~= "up") and "done" or "open"
  elseif t == "CAP" then
    return (st.nodes[m.target].side == m.side) and "open" or "expired"
  elseif t == "ESCORT" or t == "CONVOY" then
    if st.moves[m.target] then return "open" end
    if st.killedMoves[m.target] then return "failed" end
    local d = st.deliveredMoves and st.deliveredMoves[m.target]
    if d and m.escortOk and (t == "ESCORT" or d.health >= 0.5) then return "done" end
    return "expired"
  elseif t == "RECON" then
    if st.nodes[m.target].side == m.side then return "expired" end
    local i = st.intel[m.side][m.target]
    return (i and i.tick >= m.created and next(m.taken)) and "done" or "open"
  elseif t == "CSAR" then
    if st.downed[m.target] then return "open" end
    for _, ev in ipairs(events) do
      if ev.downed == m.target then return ev.kind == "rescued" and "done" or "failed" end
    end
    return "expired"
  elseif t == "LOGISTICS" then
    if st.nodes[m.target].side ~= m.side then return "expired" end
    for _, ev in ipairs(events) do
      if ev.kind == "airdrop" and ev.node == m.target and ev.side == m.side then return "done" end
    end
    return "open"
  end
  return "expired"
end

-- Finish a mission and credit whoever took it.
function War:finishMission(m, outcome)
  m.status, m.finished = outcome, self.state.tick
  if outcome == "done" and m.type == "CAP" then self:setAirCover(m.side, m.target) end
  if outcome == "done" then
    for key, name in pairs(m.taken) do self:recordMissionDone(key, m.side, name) end
  end
  if next(m.taken) and (outcome == "done" or outcome == "failed") then
    local names = {}
    for _, n in pairs(m.taken) do names[#names + 1] = n end
    table.sort(names)
    self:log("mission_" .. outcome, m.side, string.format("%s mission %s: %s %s - %s",
      m.side:upper(), outcome == "done" and "complete" or "failed", m.type, m.label,
      table.concat(names, ", ")), { mission = m.id })
  end
  if self.onMissionDone then self.onMissionDone(m, outcome) end
end

-- Called by the bridge when it detects success (CAP on station, recon pass...).
function War:completeMission(mid, ok)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return end
  if m.type == "RECON" and ok then self:recordIntel(m.side, m.target) end
  self:finishMission(m, ok and "done" or "failed")
end

-- ---------------------------------------------------------------------------
-- Taking and leaving missions
-- ---------------------------------------------------------------------------
function War:takeMission(mid, key, name)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return nil end
  m.taken[key] = name or key
  if m.type == "CONVOY" and self.state.moves[m.target] then self.state.moves[m.target].escorted = true end
  return m
end

function War:leaveMission(mid, key)
  local m = self.state.missions[mid]
  if m then m.taken[key] = nil end
end

-- Escort bookkeeping from the bridge: one sample per poll.
function War:escortSample(mid, close)
  local m = self.state.missions[mid]
  if not m or m.status ~= "open" then return end
  m.escort = m.escort or { inside = 0, total = 0 }
  m.escort.total = m.escort.total + 1
  if close then m.escort.inside = m.escort.inside + 1 end
  m.escortOk = m.escort.total >= 3 and (m.escort.inside / m.escort.total) >= M(self).escortShare
end

function War:openMissions(side)
  local list = {}
  self.state.missions = self.state.missions or {}   -- a player may slot in before the first tick
  for _, id in ipairs(U.sortedKeys(self.state.missions)) do
    local m = self.state.missions[id]
    if m.side == side and m.status == "open" then list[#list + 1] = m end
  end
  local order = {}
  for i, t in ipairs(War.MISSION_ORDER) do order[t] = i end
  table.sort(list, function(a, b)
    if a.type ~= b.type then return order[a.type] < order[b.type] end
    return a.id < b.id
  end)
  return list
end

-- ---------------------------------------------------------------------------
-- The per-tick board update
-- ---------------------------------------------------------------------------
function War:missionsTick()
  local st = self.state
  st.missions = st.missions or {}
  st.deliveredMoves = st.deliveredMoves or {}

  -- 1. Resolve open missions against what happened this tick.
  for _, id in ipairs(U.sortedKeys(st.missions)) do
    local m = st.missions[id]
    if m.status == "open" then
      local outcome = self:missionOutcome(m, self.newEvents)
      if outcome ~= "open" then self:finishMission(m, outcome) end
    elseif st.tick - (m.finished or st.tick) > 12 then
      st.missions[id] = nil               -- finished missions linger 1 h for messages
    end
  end
  for mid, d in pairs(st.deliveredMoves) do
    if st.tick - d.tick > 12 then st.deliveredMoves[mid] = nil end
  end

  -- 2. Fill each side's board up to the per-type limits.
  for _, side in ipairs(SIDES) do
    local have = {}
    for _, m in pairs(st.missions) do
      if m.side == side and m.status == "open" then
        have[m.type .. ":" .. tostring(m.target)] = true
        have[m.type] = (have[m.type] or 0) + 1
      end
    end
    for _, t in ipairs(War.MISSION_ORDER) do
      local limit = M(self).perType[t] or 0
      if (have[t] or 0) < limit then
        local cands = gen[t](self, side)
        table.sort(cands, function(a, b)
          if a.prio ~= b.prio then return a.prio < b.prio end
          return tostring(a.target) < tostring(b.target)
        end)
        for _, c in ipairs(cands) do
          if (have[t] or 0) >= limit then break end
          local key = t .. ":" .. tostring(c.target)
          if not have[key] then
            local mid = self:newId("x")
            st.missions[mid] = { id = mid, side = side, type = t, target = c.target, node = c.node,
              label = c.label, base = c.base or {}, created = st.tick, taken = {}, status = "open",
              needs = c.needs or War.MISSION_NEEDS[t] }
            have[key] = true
            have[t] = (have[t] or 0) + 1
          end
        end
      end
    end
  end
end
