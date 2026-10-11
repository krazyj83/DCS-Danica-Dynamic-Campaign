-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, part 5: radar stations, AWACS and
-- recon photos. Load after dcc_dcs_intel.lua.
-- ----------------------------------------------------------------------------
--   EWR sites   - spawned as real radar units when a player is within
--                 ops.samLiveRadiusKm (kill it -> War:ewrHit). Whether spawned
--                 or not, every EWR that is up in the model gives its side an
--                 air picture: enemy aircraft within radar.ewrKm, above the
--                 radar horizon, with terrain not in the way.
--   AWACS       - one per side orbits radar.awacsStandoffKm behind its own
--                 front while anyone is online (drawn from the AWACS pool).
--                 It sees enemy aircraft out to radar.awacsKm. Shot down ->
--                 War:awacsLost (HVAA mission done). Relieved after 4 h.
--   ELINT       - EWRs always transmit: enemy aircraft above elintMinAglM
--                 within radar.ewrElintKm hear them (EWR strike missions).
--   Recon photo - a completed recon shows every photographed platoon with its
--                 vehicle types on the side's map, and the pilot gets the
--                 photo report as a message.
-- ============================================================================

DCC = DCC or {}
local B = DCC.dcs
local U = DCC.util

B.ewrs  = {}   -- node id -> { group, side }
B.awacs = {}   -- side -> { group, born }

local SIDES = { "blue", "red" }
local function RC() return DCC.config.radar end
local function IC() return DCC.config.intel end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end
local function ground(p) return ok(land.getHeight, { x = p.x, y = p.z }) or 0 end
local function otherSide(s) return s == "blue" and "red" or "blue" end

local function unitsOf(gname)
  local g = ok(Group.getByName, gname)
  local out = {}
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then out[#out + 1] = u end end
  end
  return out
end

local function playersNear(pos, km)
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, pos) <= km * 1000 then return true end
  end
  return false
end

-- ===========================================================================
-- 1. EWR sites
-- ===========================================================================
function B.spawnEwr(id)
  local ns = B.war.state.nodes[id]
  local list = B.catalog.ewr and B.catalog.ewr[ns.side] or {}
  local t
  for _, cand in ipairs(list) do if B.validType(cand) then t = cand; break end end
  if not t then return end
  local c = B.nodePos[id]
  -- a little away from the airfield, on the side away from the SAM site
  local x, z = c.x - 2200, c.z - 1600
  local gname = "DCC_EWR_" .. id
  local data = { name = gname, task = "Ground Nothing",
    units = { { name = gname .. "_1", type = t, skill = "High", x = x, y = z, heading = 0, playerCanDrive = false } },
    route = { points = { { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0,
                           ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(ns.side), Group.Category.GROUND, data) then
    B.ewrs[id] = { group = gname, side = ns.side }
  end
end

function B.despawnEwr(id)
  local rec = B.ewrs[id]
  if not rec then return end
  local g = ok(Group.getByName, rec.group)
  if g and ok(g.isExist, g) then g:destroy() end
  B.ewrs[id] = nil
end

function B.reconcileEwrs()
  local war, R = B.war, DCC.config.ops.samLiveRadiusKm
  for id, rec in pairs(B.ewrs) do
    if #unitsOf(rec.group) == 0 then war:ewrHit(id) end
    local ns = war.state.nodes[id]
    if not war:ewrUp(id) or ns.side ~= rec.side or not playersNear(B.nodePos[id], R + 10) then B.despawnEwr(id) end
  end
  for _, id in ipairs(war.T.order) do
    if not B.ewrs[id] and war:ewrUp(id) and playersNear(B.nodePos[id], R) then B.spawnEwr(id) end
  end
end

-- ===========================================================================
-- 2. AWACS
-- ===========================================================================
-- Orbit point: from the middle of the own front, back toward the own rear.
function B.awacsOrbit(side)
  local war = B.war
  local dist = war:frontDistance(side)
  local fx, fz, fn, rx, rz, rn = 0, 0, 0, 0, 0, 0
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side then
      local p = B.nodePos[id]
      rx, rz, rn = rx + p.x, rz + p.z, rn + 1
      if dist[id] == 1 then fx, fz, fn = fx + p.x, fz + p.z, fn + 1 end
    end
  end
  if rn == 0 then return nil end
  rx, rz = rx / rn, rz / rn
  if fn == 0 then return { x = rx, z = rz }, 0 end
  fx, fz = fx / fn, fz / fn
  local dx, dz = rx - fx, rz - fz
  local len = math.sqrt(dx * dx + dz * dz)
  if len < 1 then dx, dz, len = 1, 0, 1 end
  local s = RC().awacsStandoffKm * 1000
  local hdg = math.atan2(dz, dx)
  return { x = fx + dx / len * s, z = fz + dz / len * s }, hdg
end

function B.spawnAwacs(side)
  local war = B.war
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_awacs")
  if not tpl or (war.state.airPool[side].awacs or 0) < 1 then return nil end
  local p, hdg = B.awacsOrbit(side)
  if not p then return nil end
  local alt = RC().awacsAltM
  -- race-track at right angles to the front
  local ax, az = math.cos(hdg + math.pi / 2), math.sin(hdg + math.pi / 2)
  local p1 = { x = p.x - ax * 30000, z = p.z - az * 30000 }
  local p2 = { x = p.x + ax * 30000, z = p.z + az * 30000 }
  B.awacsCount = (B.awacsCount or 0) + 1
  local gname = string.format("DCC_AWACS_%s_%d", side, B.awacsCount)
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId, data.task = gname, nil, nil, "AWACS"
  data.units = { data.units[1] }
  local u = data.units[1]
  u.unitId, u.name = nil, gname .. "_1"
  u.x, u.y, u.alt, u.alt_type, u.speed, u.heading, u.skill = p1.x, p1.z, alt, "BARO", 200, hdg, "High"
  local tasks = { { id = "AWACS", params = {} },
                  { id = "Orbit", params = { pattern = "Race-Track", point = { x = p1.x, y = p1.z },
                    point2 = { x = p2.x, y = p2.z }, altitude = alt, speed = 200 } } }
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  data.route = { points = {
    { x = p1.x, y = p1.z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
      speed = 200, speed_locked = true, ETA = 0, ETA_locked = false,
      task = { id = "ComboTask", params = { tasks = tasks } } },
    { x = p2.x, y = p2.z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
      speed = 200, speed_locked = true, ETA = 0, ETA_locked = false,
      task = { id = "ComboTask", params = { tasks = {} } } } } }
  local s, err = pcall(coalition.addGroup, B.countryId(side), Group.Category.AIRPLANE, data)
  if not s then U.log("AWACS spawn failed: %s", tostring(err)); return nil end
  war:airTake(side, "awacs", 1)
  war:setAwacs(side, true)
  B.awacs[side] = { group = gname, born = timer.getTime() }
  trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s AWACS on station.", side:upper()), 10)
  return gname
end

local function returnAwacs(side)
  local p = B.war.state.airPool[side]
  p.awacs = math.min(RC().awacsPoolMax, (p.awacs or 0) + 1)
end

function B.pollAwacs()
  local war = B.war
  local online = #B.playerPositions() > 0
  for _, side in ipairs(SIDES) do
    local rec = B.awacs[side]
    if rec then
      local us = unitsOf(rec.group)
      if #us == 0 then
        war:awacsLost(side)
        B.awacs[side] = nil
      elseif not online or timer.getTime() - rec.born > RC().awacsLifeSeconds then
        local g = ok(Group.getByName, rec.group)
        if g then g:destroy() end
        returnAwacs(side)
        war:setAwacs(side, false)
        B.awacs[side] = nil
      end
    end
  end
end

function B.planAwacs()
  if #B.playerPositions() == 0 then return end
  for _, side in ipairs(SIDES) do
    if not B.awacs[side] then B.spawnAwacs(side) end
  end
end

-- ===========================================================================
-- 3. Air picture: EWRs and AWACS see enemy aircraft above the radar horizon
-- ===========================================================================
-- Every radar a side has right now: { pos (vec3 antenna), aglM, km }
function B.radarsOf(side)
  local war, out = B.war, {}
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side and war:ewrUp(id) then
      local p = B.nodePos[id]
      local h = RC().ewrAntennaM
      out[#out + 1] = { pos = { x = p.x, y = ground(p) + h, z = p.z }, agl = h, km = RC().ewrKm }
    end
  end
  local rec = B.awacs[side]
  local u = rec and unitsOf(rec.group)[1]
  if u then
    local p = u:getPoint()
    out[#out + 1] = { pos = p, agl = p.y - ground(p), km = RC().awacsKm, awacs = true }
  end
  return out
end

-- Can this radar see this unit?
function B.radarSees(r, u)
  local p = u:getPoint()
  local d = dist2D(r.pos, p)
  if d > r.km * 1000 then return false end
  local agl = p.y - ground(p)
  if agl < DCC.War.radarHorizonM(d / 1000, r.agl) then return false end
  return ok(land.isVisible, r.pos, p) == true
end

function B.scanRadars(idx)
  -- enemy aircraft per side: players in the air, AI sorties, AWACS, airlifts
  local airOf = { blue = {}, red = {} }
  for _, side in ipairs(SIDES) do
    for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
      if alive(u) and ok(u.inAir, u) then airOf[side][#airOf[side] + 1] = { u = u } end
    end
  end
  for _, e in pairs(idx) do
    if e.air then
      for _, u in ipairs(unitsOf(e.group)) do airOf[e.side][#airOf[e.side] + 1] = { u = u, e = e } end
    end
  end
  for _, side in ipairs(SIDES) do
    local radars = B.radarsOf(side)
    if #radars > 0 then
      for _, t in ipairs(airOf[otherSide(side)]) do
        for _, r in ipairs(radars) do
          if B.radarSees(r, t.u) then B.report(side, t.e, t.u, "radar"); break end
        end
      end
    end
  end
end

-- ELINT on early-warning radars (they always transmit).
function B.scanEwrElint()
  local war, cfg = B.war, IC()
  for _, side in ipairs(SIDES) do
    local ears = {}
    for _, u in ipairs(coalition.getPlayers(B.COAL[side]) or {}) do
      if alive(u) and ok(u.inAir, u) then ears[#ears + 1] = u end
    end
    for gname, s in pairs(B.sorties) do
      if s.side == side then for _, u in ipairs(unitsOf(gname)) do ears[#ears + 1] = u end end
    end
    for _, id in ipairs(war.T.order) do
      local ns = war.state.nodes[id]
      if ns.side ~= side and war:ewrUp(id) then
        local pos = B.nodePos[id]
        for _, u in ipairs(ears) do
          local p = u:getPoint()
          if dist2D(p, pos) <= RC().ewrElintKm * 1000 and p.y - ground(p) >= cfg.elintMinAglM then
            local key = "ewr:" .. id
            local c = war:contact(side, key)
            local err = cfg.elintBaseErrM
            if c and c.err and war:isFresh(side, key) then err = math.max(cfg.elintMinErrM, c.err * cfg.elintShrink) end
            local a, r = math.random() * 2 * math.pi, math.random() * err
            war:addContact(side, key, { kind = "ewr", node = id, source = "elint", err = err,
              pos = { x = pos.x + r * math.cos(a), z = pos.z + r * math.sin(a) }, label = "Early-warning radar" })
            break
          end
        end
      end
    end
  end
end

-- Index: AWACS aircraft are air contacts like sorties, and a sighting of one
-- also records the "awacs:<side>" contact the HVAA mission needs.
local baseIndex = B.intelIndex
function B.intelIndex()
  local idx = baseIndex()
  for side, rec in pairs(B.awacs) do
    idx[rec.group] = { side = side, kind = "air", air = true, group = rec.group, awacs = true }
  end
  for id, rec in pairs(B.ewrs) do
    idx[rec.group] = { side = rec.side, key = "ewr:" .. id, kind = "ewr", node = id, group = rec.group }
  end
  return idx
end

local baseReport = B.report
function B.report(side, e, u, source)
  if e and e.side == side then return end
  baseReport(side, e, u, source)
  if e and e.awacs then
    local p = u:getPoint()
    B.war:addContact(side, "awacs:" .. e.side, { kind = "awacs", source = source,
      pos = { x = p.x, z = p.z }, label = e.side:upper() .. " AWACS" })
  elseif e and e.kind == "ewr" then
    local p = u:getPoint()
    B.war:addContact(side, "ewr:" .. e.node, { kind = "ewr", node = e.node, source = source,
      pos = { x = p.x, z = p.z }, err = 200, label = "Early-warning radar" })
  end
end

local baseScan = B.intelScan
function B.intelScan()
  baseScan()
  if not B.war.fogOfWar then return end
  local idx = B.intelIndex()
  B.scanRadars(idx)
  B.scanEwrElint()
end

-- ===========================================================================
-- 4. Map: enemy radars, photos; own radar coverage
-- ===========================================================================
local function mark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.intelMarks[#B.intelMarks + 1] = B.nextMark
  return B.nextMark
end

local baseDrawIntel = B.drawIntel
function B.drawIntel()
  baseDrawIntel()
  local war = B.war
  if not war.fogOfWar then return end
  for _, side in ipairs(SIDES) do
    local coal, enemy = B.COAL[side], otherSide(side)
    local ec = DCC.config.colours[enemy]
    for _, key in ipairs(U.sortedKeys(war.state.contacts[side])) do
      local c = war.state.contacts[side][key]
      local fresh = war:isFresh(side, key)
      local col = { ec[1], ec[2], ec[3], fresh and 1 or 0.45 }
      if c.kind == "ewr" and war.state.nodes[c.node].side == enemy then
        local P = c.pos or B.nodePos[c.node]
        local v = { x = P.x, y = ground(P), z = P.z }
        if (c.err or 0) > 1000 then
          trigger.action.circleToAll(coal, mark(), v, c.err, col, { ec[1], ec[2], ec[3], 0.12 }, 3, true, "")
        end
        trigger.action.textToAll(coal, mark(), { x = v.x + 1500, y = v.y, z = v.z - 4000 }, col,
          { 0, 0, 0, 0.35 }, 10, true, string.format("EWR (%s%s)", c.source,
            (c.err or 0) > 1000 and string.format(" +/-%.1f km", c.err / 1000) or ""))
      elseif c.kind == "awacs" and fresh then
        local v = { x = c.pos.x, y = 0, z = c.pos.z }
        trigger.action.circleToAll(coal, mark(), v, 3000, col, { 0, 0, 0, 0 }, 1, true, "")
        trigger.action.textToAll(coal, mark(), { x = v.x + 3500, y = 0, z = v.z }, col, { 0, 0, 0, 0.35 }, 11, true,
          enemy:upper() .. " AWACS")
      elseif c.kind == "node" and c.photo and war.state.nodes[c.node].side == enemy then
        for _, ph in ipairs(c.photo) do
          local s = B.scatter(c.node, ph.pid)
          trigger.action.textToAll(coal, mark(), { x = s.x, y = ground(s), z = s.z }, col, { 0, 0, 0, 0.25 }, 9, true,
            "[photo] " .. ph.text)
        end
      end
    end
  end
end

local baseDrawOps = B.drawOps
function B.drawOps(newMark, toVec3)
  baseDrawOps(newMark, toVec3)
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if ns.ewr then
      local col, P = DCC.config.colours[ns.side], B.nodePos[id]
      if ns.ewr.status == "up" then
        trigger.action.circleToAll(B.COAL[ns.side], newMark(), P, RC().ewrKm * 1000,
          { col[1], col[2], col[3], 0.25 }, { 0, 0, 0, 0 }, 4, true, "")
      end
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = P.x + 1500, y = P.y, z = P.z - 4000 }, col,
        { 0, 0, 0, 0 }, 10, true, "EWR " .. ns.ewr.status)
    end
  end
end

-- ===========================================================================
-- 5. Recon photo report to the pilot
-- ===========================================================================
function B.photoReport(side, id)
  local war = B.war
  local c = war:contact(side, "n:" .. id)
  if not c then return nil end
  local lines = { "RECON PHOTOS - " .. war:nodeName(id) }
  local ns = war.state.nodes[id]
  for i, ph in ipairs(c.photo or {}) do lines[#lines + 1] = string.format("%d. %s (%s)", i, ph.text, ph.role) end
  if #(c.photo or {}) == 0 then lines[#lines + 1] = "No vehicles in the photos." end
  lines[#lines + 1] = "Air defence: " .. (ns.sam and ns.sam.status or "none") ..
                      ".  Early-warning radar: " .. (c.ewr or "none") .. "."
  lines[#lines + 1] = "Photos are on your F10 map ([photo] labels)."
  return table.concat(lines, "\n")
end

local baseDone = B.onMissionDone
function B.onMissionDone(m, outcome)
  if m.type == "RECON" and outcome == "done" then
    local text = B.photoReport(m.side, m.target)
    if text then
      for key in pairs(m.taken) do
        for _, p in pairs(B.players) do
          if p.key == key then trigger.action.outTextForGroup(p.gid, text, 45) end
        end
      end
    end
  end
  baseDone(m, outcome)
end

-- ===========================================================================
-- 6. Status and loop hooks
-- ===========================================================================
local baseStatus = B.opsStatusLines
function B.opsStatusLines(side)
  local lines = baseStatus(side)
  local war, up = B.war, 0
  for _, id in ipairs(war.T.order) do
    if war.state.nodes[id].side == side and war:ewrUp(id) then up = up + 1 end
  end
  lines[#lines + 1] = string.format("Radar: %d early-warning sites up. AWACS: %s, %d in reserve.", up,
    B.awacs[side] and "on station" or "none airborne", war.state.airPool[side].awacs or 0)
  return lines
end

local basePoll = B.opsPoll
function B.opsPoll()
  basePoll()
  B.reconcileEwrs()
  B.pollAwacs()
end

local baseTick = B.opsTick
function B.opsTick()
  baseTick()
  B.planAwacs()
end
