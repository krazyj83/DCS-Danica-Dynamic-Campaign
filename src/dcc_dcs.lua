-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge
-- ----------------------------------------------------------------------------
-- The war model (dcc_war.lua) is only numbers. This module is where those
-- numbers meet the DCS world:
--
--   * Live bubble  - nodes within liveRadiusKm of any player are "live".
--                    Their garrisons and the columns on roads touching them
--                    are spawned as real DCS ground groups.
--   * Read-back    - every liveCheckSeconds each spawned group is polled.
--                    Dead vehicles lower the platoon's health in the model,
--                    and a moving column's position becomes its progress.
--   * Despawn      - when players leave, groups are removed again, keeping
--                    their damage. Far from players the war runs on dice.
--   * Map          - front line, node circles and labels, own assault arrows
--                    are drawn on the F10 map.
--   * Airbases     - DCS auto-capture is switched off; airbase coalitions
--                    follow node ownership in the model.
--
-- Concept: the spawned units are a VIEW of the model, rebuilt from it at any
-- time. That is why a server restart only needs the save file - every unit
-- on the map can be recreated from the numbers.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = {
  war = nil, theater = nil, catalog = nil,
  nodePos = {},     -- node id -> vec3 (snapped to the airbase when there is one)
  airbases = {},    -- node id -> DCS airbase name
  liveNodes = {},   -- node id -> true
  spawned = {},     -- platoon id -> { group, size, base, key, kind, mid, failed }
  marks = {},       -- F10 mark ids drawn last time
  typeOk = {},      -- unit type -> bool (exists in this DCS install)
}
DCC.dcs = B

local COAL = { red = 1, blue = 2 }
B.COAL = COAL

-- ---------------------------------------------------------------------------
-- Geometry helpers (DCS: x = north, z = east, y = altitude)
-- ---------------------------------------------------------------------------
local function toVec3(ll)
  local v = coord.LLtoLO(ll.lat, ll.lon, 0)
  v.y = land.getHeight({ x = v.x, y = v.z })
  return v
end

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function isWater(x, z)
  local t = land.getSurfaceType({ x = x, y = z })
  return t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER
end

local function pidNumber(pid) return tonumber(tostring(pid):match("%d+")) or 1 end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------
local function resolveAirbase(tn, pos)
  local ab = tn.airbase and Airbase.getByName(tn.airbase)
  if ab then return ab end
  -- Names differ between DCS versions: fall back to the nearest airfield.
  local best, bestD
  for _, a in ipairs(world.getAirbases() or {}) do
    local desc = a:getDesc()
    if desc and desc.category == Airbase.Category.AIRDROME then
      local d = dist2D(a:getPoint(), pos)
      if d < 5000 and (not bestD or d < bestD) then best, bestD = a, d end
    end
  end
  return best
end

function B.init(war, theater, catalog)
  B.war, B.theater, B.catalog = war, theater, catalog
  B.nodePos, B.airbases, B.liveNodes, B.spawned = {}, {}, {}, {}   -- a clean view for this war
  for _, id in ipairs(war.T.order) do
    local tn = war.T.nodes[id]
    local pos = toVec3(tn)
    if tn.airbase then
      local ab = resolveAirbase(tn, pos)
      if ab then
        local p = ab:getPoint()
        pos = { x = p.x, y = p.y, z = p.z }
        B.airbases[id] = ab:getName()
        pcall(function() ab:autoCapture(false) end) -- the model decides who owns it
      else
        U.log("airbase '%s' for node %s not found - using its lat/lon", tn.airbase, id)
      end
    end
    B.nodePos[id] = pos
  end
  war.liveFn = function(id) return B.liveNodes[id] == true end
  war.airLive = true          -- airlifts are always real aircraft while DCS runs
  war.forcedMoveFn = function(mid) return B.forced ~= nil and B.forced[mid] == true end
  B.syncAirbases()
end

function B.syncAirbases()
  for id, name in pairs(B.airbases) do
    local ab = Airbase.getByName(name)
    local want = COAL[B.war.state.nodes[id].side]
    if ab then
      pcall(function()
        if ab:getCoalition() ~= want then ab:setCoalition(want) end
      end)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Live bubble
-- ---------------------------------------------------------------------------
function B.playerPositions()
  local pts = {}
  for _, c in ipairs({ coalition.side.RED, coalition.side.BLUE }) do
    for _, u in ipairs(coalition.getPlayers(c) or {}) do
      if u and u:isExist() then pts[#pts + 1] = u:getPoint() end
    end
  end
  return pts
end

-- Nodes near players become live, nearest first, until the spawn budget is used.
function B.updateLive()
  local cfg, war = DCC.config, B.war
  local players = B.playerPositions()
  local R = cfg.liveRadiusKm * 1000
  local H = (cfg.liveRadiusKm + cfg.liveHysteresisKm) * 1000
  local cand = {}
  for id, pos in pairs(B.nodePos) do
    local nearest
    for _, p in ipairs(players) do
      local d = dist2D(p, pos)
      if not nearest or d < nearest then nearest = d end
    end
    local limit = B.liveNodes[id] and H or R   -- hysteresis: no flicker at the edge
    if nearest and nearest <= limit then cand[#cand + 1] = { id = id, d = nearest } end
  end
  table.sort(cand, function(a, b) return a.d < b.d end)

  local budget, live = cfg.maxLivePlatoons, {}
  for _, c in ipairs(cand) do
    local cost = #war.state.nodes[c.id].platoons
    for _, mv in pairs(war.state.moves) do
      if mv.from == c.id or mv.to == c.id then cost = cost + #mv.platoons end
    end
    if cost <= budget then live[c.id] = true; budget = budget - cost end
  end
  B.liveNodes = live
end

-- What should exist in DCS right now, by platoon id.
function B.desired()
  local war, want = B.war, {}
  for id in pairs(B.liveNodes) do
    for _, pid in ipairs(war.state.nodes[id].platoons) do
      want[pid] = { key = "g:" .. id, kind = "garrison", node = id }
    end
  end
  for mid, mv in pairs(war.state.moves) do
    if (B.liveNodes[mv.from] or B.liveNodes[mv.to] or (B.forced and B.forced[mid])) and not war:onSea(mv) then
      for _, pid in ipairs(mv.platoons) do
        want[pid] = { key = "m:" .. mid, kind = "move", mv = mv }
      end
    end
  end
  return want
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
function B.validType(t)
  if B.typeOk[t] == nil then
    local ok, desc = pcall(Unit.getDescByName, t)
    B.typeOk[t] = ok and type(desc) == "table"
    if not B.typeOk[t] then U.log("unit type '%s' not found - using fallback", t) end
  end
  return B.typeOk[t]
end

function B.unitTypes(role, side)
  local entry = B.catalog.roles[role][side]
  for _, t in ipairs(entry.units) do
    if not B.validType(t) then return entry.fallback end
  end
  return entry.units
end

function B.countryId(side)
  local name = B.theater.country and B.theater.country[side]
  return (name and country.id[name]) or (side == "blue" and country.id.CJTF_BLUE or country.id.CJTF_RED)
end

-- A spot inside the node for a garrison platoon, the same every time for the
-- same platoon, and never in the sea.
function B.scatter(nodeId, pid)
  local c, n = B.nodePos[nodeId], pidNumber(pid)
  local spread = DCC.config.spawnSpreadM
  for i = 0, 7 do
    local ang = math.rad((n * 137.5 + i * 45) % 360)
    local r = spread * (0.3 + 0.7 * ((n * 0.618) % 1))
    local x, z = c.x + r * math.cos(ang), c.z + r * math.sin(ang)
    if not isWater(x, z) then return { x = x, z = z } end
  end
  return { x = c.x, z = c.z }
end

local function roadPoint(x, z)
  local ok, rx, rz = pcall(land.getClosestPointOnRoads, "roads", x, z)
  if ok and rx and rz then return rx, rz end
  return x, z
end

local function wp(x, z, action, speed)
  return { x = x, y = z, type = "Turning Point", action = action, speed = speed,
           speed_locked = true, ETA = 0, ETA_locked = false, formation_template = "" }
end

function B.spawn(pid, w)
  local war = B.war
  local pl = war.state.platoons[pid]
  local types = B.unitTypes(pl.role, pl.side)
  local n = math.max(1, math.ceil(#types * pl.health - 1e-6))
  local cfg = DCC.config
  local start, points

  if w.kind == "garrison" then
    start = B.scatter(w.node, pid)
    points = { wp(start.x, start.z, "Off Road", 0) }
  else
    local mv = w.mv
    local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
    local total = math.max(dist2D(a, b), 1)
    local t = mv.status == "fighting" and math.max(0, 1 - 2500 / total) or mv.progress
    start = { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t }
    local s = cfg.liveSpeedMps
    local r1x, r1z = roadPoint(start.x, start.z)
    local r2x, r2z = roadPoint(b.x, b.z)
    -- Off-road to the nearest road, on roads to the target, off-road into it.
    points = { wp(start.x, start.z, "Off Road", s), wp(r1x, r1z, "On Road", s),
               wp(r2x, r2z, "On Road", s), wp(b.x, b.z, "Off Road", s) }
  end

  local gname = "DCC_" .. pid
  local units = {}
  for i = 1, n do
    units[i] = { name = gname .. "_" .. i, type = types[i], skill = "Average",
                 x = start.x + (i - 1) * 18, y = start.z + (i % 2) * 12,
                 heading = 0, playerCanDrive = false }
  end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = points } }

  local ok, err = pcall(coalition.addGroup, B.countryId(pl.side), Group.Category.GROUND, data)
  B.spawned[pid] = { group = gname, size = n, base = pl.health, key = w.key, kind = w.kind,
                     mid = w.mv and w.mv.id, failed = not ok }
  if not ok then U.log("spawn of %s failed: %s", pid, tostring(err)) end
end

function B.despawn(pid, rec)
  local g = Group.getByName(rec.group)
  if g and g:isExist() then g:destroy() end
  B.spawned[pid] = nil
end

-- Read one spawned group back into the model: health, and progress if moving.
function B.pollOne(pid, rec)
  if rec.failed then return end
  local war, cfg = B.war, DCC.config
  local g = Group.getByName(rec.group)
  local alive, lead = 0, nil
  if g and g:isExist() then
    for _, u in ipairs(g:getUnits() or {}) do
      if u:isExist() and u:getLife() >= 1 then
        alive = alive + 1
        lead = lead or u
      end
    end
  end
  war:setHealth(pid, rec.base * alive / rec.size)

  local mv = rec.mid and war.state.moves[rec.mid]
  if lead and mv and mv.status == "moving" then
    local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
    local d = dist2D(lead:getPoint(), b)
    local p = 1 - d / math.max(dist2D(a, b), 1)
    if d <= cfg.captureRadiusKm * 1000 then p = 1 end
    war:setProgress(mv.id, p)
  end
end

-- Make the DCS world match the model.
function B.reconcile()
  local war = B.war
  local want = B.desired()
  for pid, rec in pairs(B.spawned) do
    local w = want[pid]
    if not war.state.platoons[pid] or not w or w.key ~= rec.key then
      if war.state.platoons[pid] then B.pollOne(pid, rec) end -- keep its damage
      B.despawn(pid, rec)
    end
  end
  for pid, w in pairs(want) do
    if not B.spawned[pid] and war.state.platoons[pid] then B.spawn(pid, w) end
  end
end

-- The 30-second loop: poll, recompute the bubble, then reconcile.
function B.liveCheck()
  for pid, rec in pairs(B.spawned) do
    if B.war.state.platoons[pid] then B.pollOne(pid, rec) end
  end
  if B.pollAllCargo then B.pollAllCargo() end
  B.updateLive()
  B.reconcile()
  if B.reconcileCargo then B.reconcileCargo() end
end

-- Remove every spawned group (used when a war ends).
function B.despawnAll()
  for pid, rec in pairs(B.spawned) do B.despawn(pid, rec) end
  for mid, rec in pairs(B.cargo or {}) do B.despawnCargo(mid, rec) end
end

-- ---------------------------------------------------------------------------
-- F10 map
-- ---------------------------------------------------------------------------
local function newMark()
  B.nextMark = (B.nextMark or DCC.config.markIdBase) + 1
  B.marks[#B.marks + 1] = B.nextMark
  return B.nextMark
end

local function alpha(c, a) return { c[1], c[2], c[3], a } end

function B.draw()
  local war, cfg = B.war, DCC.config
  for _, id in ipairs(B.marks) do trigger.action.removeMark(id) end
  B.marks = {}

  -- Territory and front line (Voronoi cells, dcc_territory.lua): visible to everyone.
  local terr = DCC.territory.compute(war)
  local fillA = cfg.territory.fillAlpha
  for _, cell in ipairs(terr.territory) do
    local col = cfg.colours[cell.side]
    local args = { 7, -1, newMark() }
    for _, p in ipairs(cell.poly) do args[#args + 1] = toVec3(p) end
    args[#args + 1] = { col[1], col[2], col[3], 0 }          -- no outline: cells of one side merge
    args[#args + 1] = { col[1], col[2], col[3], fillA }
    args[#args + 1] = 0
    args[#args + 1] = true
    pcall(trigger.action.markupToAll, unpack(args))
  end
  for _, line in ipairs(terr.front) do
    for i = 2, #line do
      trigger.action.lineToAll(-1, newMark(), toVec3(line[i - 1]), toVec3(line[i]), cfg.colours.front, 1, true)
    end
  end

  -- Nodes: everyone sees who owns what; only the owner sees the strength.
  for _, id in ipairs(war.T.order) do
    local ns, tn, pos = war.state.nodes[id], war.T.nodes[id], B.nodePos[id]
    local col = cfg.colours[ns.side]
    local radius = tn.depot and 3500 or 2500
    trigger.action.circleToAll(-1, newMark(), pos, radius, col, alpha(col, 0.15), tn.depot and 2 or 1, true)
    trigger.action.textToAll(-1, newMark(), { x = pos.x + radius + 600, y = pos.y, z = pos.z - 2000 },
      col, { 0, 0, 0, 0 }, 12, true, tn.name .. (tn.depot and " (depot)" or ""))
    local label = string.format("%d plt | %d SU", #ns.platoons, math.floor((ns.supply or 0) + 0.5))
    if ns.outOfSupply then label = label .. " | NO SUPPLY" end
    trigger.action.textToAll(COAL[ns.side], newMark(), { x = pos.x - radius - 600, y = pos.y, z = pos.z - 2000 },
      col, { 0, 0, 0, 0.35 }, 11, true, label)
  end

  if B.drawOps then B.drawOps(newMark, toVec3) end

  -- Own assaults in progress: arrows only the attacking side sees.
  for _, mv in pairs(war.state.moves) do
    if mv.kind == "assault" then
      local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
      local s = { x = a.x + (b.x - a.x) * 0.2, y = a.y, z = a.z + (b.z - a.z) * 0.2 }
      local e = { x = a.x + (b.x - a.x) * 0.8, y = b.y, z = a.z + (b.z - a.z) * 0.8 }
      local col = cfg.colours[mv.side]
      trigger.action.arrowToAll(COAL[mv.side], newMark(), s, e, col, alpha(col, 0.35), 1, true)
    elseif mv.kind == "airlift" then
      -- Own airlifts: a dashed line origin -> destination, own side only.
      trigger.action.lineToAll(COAL[mv.side], newMark(), B.nodePos[mv.from], B.nodePos[mv.to],
        alpha(cfg.colours[mv.side], 0.6), 2, true)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Messages and the F10 radio menu
-- ---------------------------------------------------------------------------
function B.announce(events)
  for _, ev in ipairs(events) do
    if ev.kind == "capture" or ev.kind == "victory" or ev.kind == "clock" then
      trigger.action.outText(ev.text, ev.kind == "victory" and 60 or 20)
    elseif ev.kind == "repulsed" then
      trigger.action.outText(ev.text, 15)
    elseif ev.kind == "convoy_lost" or ev.kind == "airlift_lost" then
      trigger.action.outText(ev.text, 15)            -- both sides: the kill mattered
    elseif ev.kind == "sam_destroyed" or ev.kind == "sam_suppressed" or ev.kind == "infra_hit"
           or ev.kind == "ewr_destroyed" or ev.kind == "awacs_lost" or ev.kind == "tanker_lost"
           or ev.kind == "drone_lost" or ev.kind == "strike_hit" or ev.kind == "package_down"
           or ev.kind == "arty_destroyed" or ev.kind == "fort_hit" or ev.kind == "bridge_down"
           or ev.kind == "bridge_up" or ev.kind == "surrender" or ev.kind == "farp_lost"
           or ev.kind == "rescued" or ev.kind == "captured" or ev.kind == "airassault" then
      trigger.action.outText(ev.text, 15)
    elseif (ev.kind == "focus" or ev.kind == "assault" or ev.kind == "airlift" or ev.kind == "airlift_in"
            or ev.kind == "nosupply" or ev.kind == "cargo_lost" or ev.kind == "mission_done"
            or ev.kind == "mission_failed" or ev.kind == "sam_up" or ev.kind == "ewr_up" or ev.kind == "airdrop"
            or ev.kind == "airmobile" or ev.kind == "ambush" or ev.kind == "downed") and ev.side then
      trigger.action.outTextForCoalition(COAL[ev.side], "Command: " .. ev.text, 12)
    end
  end
end

function B.showStatus(side)
  local war = B.war
  local s = war:summary()
  local lines = {
    string.format("DANICA DYNAMIC CAMPAIGN - %s  (war day %.1f)", war.T.name, war.state.tick * DCC.config.tickSeconds / 86400),
    string.format("BLUE: %d nodes   RED: %d nodes", s.blue.nodes, s.red.nodes),
    string.format("Your forces: %d platoons", s[side].platoons),
  }
  local f = war.state.focus and war.state.focus[side]
  if f then lines[#lines + 1] = "Main effort: " .. war:nodeName(f.target) end
  if B.supplyLines then for _, l in ipairs(B.supplyLines(side)) do lines[#lines + 1] = l end end
  local left = war:clockTicksLeft()
  if left then
    local h = math.max(0, left) * DCC.config.tickSeconds / 3600
    local gb = war:groundGained("blue")
    lines[#lines + 1] = string.format("War clock%s: %dd %02dh left - %s", war.noSave and " (no saving on this server)" or "",
      math.floor(h / 24), math.floor(h % 24),
      gb == 0 and "even: no ground gained yet" or string.format("%s is ahead (%+d bases since the start)",
        gb > 0 and "BLUE" or "RED", math.abs(gb)))
  end
  if B.opsStatusLines then for _, l in ipairs(B.opsStatusLines(side)) do lines[#lines + 1] = l end end
  if B.intelStatusLines then for _, l in ipairs(B.intelStatusLines(side)) do lines[#lines + 1] = l end end
  lines[#lines + 1] = "Recent:"
  local evs = war.state.events
  local shown = 0
  for i = #evs, 1, -1 do
    local ev = evs[i]
    if ev.kind == "capture" or ev.kind == "repulsed" or ev.kind == "victory"
       or ev.kind == "convoy_lost" or ev.kind == "airlift_lost" then
      lines[#lines + 1] = "  " .. ev.text
      shown = shown + 1
      if shown >= 5 then break end
    end
  end
  trigger.action.outTextForCoalition(COAL[side], table.concat(lines, "\n"), 25)
end

function B.addMenus()
  for side, c in pairs(COAL) do
    local root = missionCommands.addSubMenuForCoalition(c, "Campaign")
    missionCommands.addCommandForCoalition(c, "Campaign status", root, B.showStatus, side)
  end
end
