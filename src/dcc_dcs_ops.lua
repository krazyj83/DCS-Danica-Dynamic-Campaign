-- ============================================================================
-- Danica Dynamic Campaign - DCS bridge, phase 3: missions and operations
-- ----------------------------------------------------------------------------
-- Load after dcc_dcs_supply.lua. Adds to DCC.dcs:
--
--   1. Players      - who is flying what, pilot records (sorties, kills,
--                     deaths, ejections), per-aircraft F10 menus.
--   2. Mission board- "Missions" menu per aircraft: take, brief, abandon.
--                     Briefing gives target, coordinates and an F10 mark.
--   3. Detection    - every 10 s: recon passes, CAP time on station, escort
--                     distance, CSAR pickups and drop-offs.
--   4. SAM sites    - spawned within 80 km of players; radar and launcher
--                     losses read back (SEAD/DEAD).
--   5. Structures   - fuel/ammo/warehouse statics at depots and airbases
--                     (STRIKE), read back when destroyed.
--   6. AI air       - CAP, CAS and airlift intercept sorties cloned from the
--                     mission's DCC_TPL_* template groups, paid from the
--                     side's air pool; losses read back.
--   7. CSAR         - ejected pilots wait on the ground; a transport
--                     helicopter lands next to them, then at a friendly base.
--   8. Logistics    - transport helicopters load supply crates and troops at
--                     friendly bases and unload them elsewhere (troops dropped
--                     at an enemy base attack it).
--   9. Convoy escort- taking the mission spawns an ambush on the convoy's road.
--  10. Map          - own SAM rings, recon intel, downed pilots.
-- ============================================================================

DCC = DCC or {}
local U = DCC.util
local B = DCC.dcs

B.players  = {}   -- unit name -> player record (see B.registerPlayer)
B.sams     = {}   -- node id -> { group, status }
B.statics  = {}   -- node id -> { side, names = { [k] = name } }
B.sorties  = {}   -- group name -> AI sortie
B.downedGroups = {} -- downed id -> group name
B.ambushes = {}   -- mission id -> group name
B.forced   = {}   -- move id -> true while a player mission targets it
B.sortieCount = 0

local function dist2D(a, b)
  local dx, dz = a.x - b.x, a.z - b.z
  return math.sqrt(dx * dx + dz * dz)
end

local function cat() return B.catalog end
local function wpos(p) return { x = p.x, y = land.getHeight({ x = p.x, y = p.z }), z = p.z } end
local function ok(fn, ...) local s, r = pcall(fn, ...); if s then return r end end

local function unitByName(n) return n and ok(Unit.getByName, n) end
local function alive(u) return u ~= nil and ok(u.isExist, u) == true end
local function landed(u) return alive(u) and ok(u.inAir, u) == false end

local function agl(u)
  local p = u:getPoint()
  return p.y - land.getHeight({ x = p.x, y = p.z })
end

local function sideOfUnit(u) return (u:getCoalition() == B.COAL.blue) and "blue" or "red" end

-- A spot near a node that is land and not runway, the same each time.
local function spotNear(id, k, radius)
  local c = B.nodePos[id]
  for i = 0, 11 do
    local ang = math.rad((k * 67 + i * 30) % 360)
    local x, z = c.x + radius * math.cos(ang), c.z + radius * math.sin(ang)
    local t = land.getSurfaceType({ x = x, y = z })
    if t ~= land.SurfaceType.WATER and t ~= land.SurfaceType.SHALLOW_WATER and t ~= land.SurfaceType.RUNWAY then
      return { x = x, z = z }
    end
  end
  return { x = c.x + radius, z = c.z }
end

local function nearestNodeOf(pos, side, maxM)
  return B.nearestNodeOf(pos, side, maxM)
end
function B.nearestNodeOf(pos, side, maxM)
  local best, bestD
  for id, p in pairs(B.nodePos) do
    if not side or B.war.state.nodes[id].side == side then
      local d = dist2D(pos, p)
      if (not maxM or d <= maxM) and (not bestD or d < bestD) then best, bestD = id, d end
    end
  end
  return best, bestD
end

-- ===========================================================================
-- 1. Players and pilot records
-- ===========================================================================
local function playerKey(name)
  if net and net.get_player_list then
    local list = ok(net.get_player_list) or {}
    for _, pid in ipairs(list) do
      local info = ok(net.get_player_info, pid)
      if info and info.name == name and info.ucid then return info.ucid end
    end
  end
  return name
end

function B.registerPlayer(u)
  local name = ok(u.getPlayerName, u)
  if not name then return nil end
  local uname = u:getName()
  local g = u:getGroup()
  local p = {
    unit = uname, name = name, key = playerKey(name), side = sideOfUnit(u),
    type = u:getTypeName(), gid = g and g:getID(), born = timer.getTime(),
    crates = 0, troops = {}, onboard = {}, capSeconds = 0, ticks = 0,
  }
  p.home = nearestNodeOf(u:getPoint(), nil, 6000)
  local d = ok(u.getDesc, u)
  p.heli = d and d.category == Unit.Category.HELICOPTER or false
  local sp = u:getPoint()
  p.spawn = { x = sp.x, y = 0, z = sp.z }     -- helicopters get missions near here
  p.slow = not p.heli and B.isSlowType(p.type)
  B.players[uname] = p
  B.updateHubs(true)
  DCC.pilots:get(p.key, name)
  B.buildMenu(p)
  return p
end

function B.caps(p)
  return (cat().capabilities or {})[p.type] or {}
end

function B.canFly(p, m)
  local c = B.caps(p)
  return m.needs == "ANY" or c[m.needs] == true
end

function B.clearPlayer(uname, how)
  local p = B.players[uname]
  if not p then return end
  if p.mission then B.war:leaveMission(p.mission, p.key) end
  if #p.troops > 0 then
    for _, pid in ipairs(p.troops) do
      if how == "lost" then B.war:loseCarried(pid) else B.war:returnCarried(pid) end
    end
  end
  if p.takeoff then
    DCC.pilots:add(p.key, "flightMinutes", (timer.getTime() - p.takeoff) / 60)
  end
  if p.menu then ok(missionCommands.removeItemForGroup, p.gid, p.menu) end
  B.players[uname] = nil
  B.updateHubs(true)                     -- its untaken local missions are withdrawn
end

-- Slow movers (A-10, Su-25, trainers) get a wider "local" range than helicopters.
function B.isSlowType(t)
  for _, s in ipairs(DCC.config.missions.slowTypes or {}) do if s == t then return true end end
  return false
end

-- The range a player's mission board is limited to, in km (nil = whole board).
function B.localRangeKm(p)
  local mc = DCC.config.missions
  if p.heli then return mc.heloRangeKm or 110 end
  if p.slow then return mc.slowRangeKm or 222 end
  return nil
end

-- Tell the war where helicopters and slow movers are, so it creates missions
-- near them (War:hubMissions). fill = update the local missions right away.
function B.updateHubs(fill)
  local hubs, seen = { blue = {}, red = {} }, {}
  for _, p in pairs(B.players) do
    local km = B.localRangeKm(p)
    if km and p.spawn and hubs[p.side] then
      local node = B.nearestNodeOf(p.spawn, p.side) or B.nearestNodeOf(p.spawn)
      local key = p.side .. "|" .. tostring(node) .. "|" .. p.type
      if node and not seen[key] then
        seen[key] = true
        table.insert(hubs[p.side], { node = node, km = km, caps = B.caps(p) })
      end
    end
  end
  for side, list in pairs(hubs) do B.war:setHubs(side, list) end
  if fill then ok(B.war.hubMissions, B.war) end
end

-- ===========================================================================
-- 2. Mission board menus
-- ===========================================================================
local function fmtLL(pos)
  local lat, lon = coord.LOtoLL(wpos(pos))
  local function dm(v, pos_, neg)
    local h = v >= 0 and pos_ or neg
    v = math.abs(v)
    local d = math.floor(v)
    return string.format("%s%02d°%06.3f'", h, d, (v - d) * 60)
  end
  local s = dm(lat, "N", "S") .. " " .. dm(lon, "E", "W")
  local m = ok(coord.LLtoMGRS, lat, lon)
  if m and m.UTMZone then
    s = s .. string.format("  MGRS %s %s %05d %05d", m.UTMZone, m.MGRSDigraph, math.floor(m.Easting), math.floor(m.Northing))
  end
  return s
end

-- Where a mission's target is right now (a map point), or nil.
function B.missionPos(m)
  local st = B.war.state
  if m.type == "BAI" or m.type == "ESCORT" or m.type == "CONVOY" then
    local rec = B.cargo[m.target]
    local g = rec and ok(Group.getByName, rec.group)
    if not g then
      local mv = st.moves[m.target]
      local first = mv and mv.platoons[1]
      local pr = first and B.spawned[first]
      g = pr and ok(Group.getByName, pr.group)
    end
    local u = g and ok(g.getUnit, g, 1)
    if alive(u) then return u:getPoint() end
    local mv = st.moves[m.target]
    if mv then
      local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
      return { x = a.x + (b.x - a.x) * mv.progress, y = 0, z = a.z + (b.z - a.z) * mv.progress }
    end
    return nil
  elseif m.type == "CSAR" then
    local d = st.downed[m.target]
    return d and { x = d.pos.x, y = 0, z = d.pos.z }
  end
  return m.node and B.nodePos[m.node]
end

local EFFECT = {
  CAS = "Kill enemy ground forces in the battle. The outcome decides who holds the base.",
  BAI = "Destroy the column on the road. Its cargo or platoons never arrive.",
  STRIKE = "Destroy fuel, ammo or warehouse buildings. Each one burns supply and cuts the base's output for hours.",
  SEAD = "Kill the radar to suppress the site for ~2 h, or radar and launchers to destroy it for ~6 h.",
  CAP = "Stay on station 20 min or shoot down an enemy aircraft. Gives 1 h of air superiority: enemy AI attack sorties stay away.",
  ESCORT = "Stay within 15 km of the transport until it lands. Enemy fighters may try to intercept it.",
  CONVOY = "Stay within 3 km of the convoy. An ambush waits ahead on the road. An escorted convoy is not ambushed.",
  RECON = "Overfly the base within 8 km below 4500 m. Your side gets its garrison and SAM status on the map.",
  CSAR = "Land within 150 m of the pilot (green smoke), then land at a friendly base. The aircraft is refunded.",
  LOGISTICS = "F10 > Missions > Cargo: load a supply crate at a friendly base and unload it at the target.",
}
B.EFFECT = EFFECT      -- other modules (CTLD) add or reword entries

function B.brief(p, m)
  local pos = B.missionPos(m)
  local u = unitByName(p.unit)
  local lines = { string.format("MISSION %s - %s", m.type, m.label) }
  if pos then
    lines[#lines + 1] = "Target: " .. fmtLL(pos)
    -- for typing into the jet or a DTC tool: seconds format and elevation
    local lat, lon = coord.LOtoLL(wpos(pos))
    local function dms(v, h1, h2)
      local h = v >= 0 and h1 or h2
      v = math.abs(v)
      local d = math.floor(v); local mf = (v - d) * 60; local m = math.floor(mf)
      return string.format("%s%02d°%02d'%04.1f\"", h, d, m, (mf - m) * 60)
    end
    local elev = ok(land.getHeight, { x = pos.x, y = pos.z }) or 0
    lines[#lines + 1] = string.format("DMS %s %s  Elev %d ft / %d m", dms(lat, "N", "S"), dms(lon, "E", "W"),
      math.floor(elev * 3.28084 + 0.5), math.floor(elev + 0.5))
    if alive(u) then
      local up = u:getPoint()
      local brg = (math.deg(math.atan2(pos.z - up.z, pos.x - up.x)) + 360) % 360
      lines[#lines + 1] = string.format("From you: %03d° / %d km", math.floor(brg + 0.5),
        math.floor(dist2D(up, pos) / 1000 + 0.5))
    end
    if p.gid then
      B.markId = (B.markId or (DCC.config.markIdBase + 500000)) + 1
      ok(trigger.action.markToGroup, B.markId, m.type .. ": " .. m.label, wpos(pos), p.gid, true)
      p.marks = p.marks or {}
      p.marks[#p.marks + 1] = B.markId
    end
  end
  lines[#lines + 1] = EFFECT[m.type] or ""
  trigger.action.outTextForGroup(p.gid, table.concat(lines, "\n"), 30)
end

function B.takeMission(args)
  local p = B.players[args.unit]
  if not p then return end
  local m = B.war:takeMission(args.mid, p.key, p.name)
  if not m then
    trigger.action.outTextForGroup(p.gid, "That mission is no longer open.", 10)
    return B.buildMenu(p)
  end
  if p.mission and p.mission ~= args.mid then B.war:leaveMission(p.mission, p.key) end
  p.mission, p.capSeconds = m.id, 0
  B.updateForced()                       -- the target spawns for real right away
  if m.type == "CONVOY" then B.spawnAmbush(m) end
  B.brief(p, m)
  B.buildMenu(p)
end

function B.myMission(uname)
  local p = B.players[uname]
  if not p then return end
  local m = p.mission and B.war.state.missions[p.mission]
  if not m then trigger.action.outTextForGroup(p.gid, "No mission. F10 > Missions to take one.", 10); return end
  if m.status ~= "open" then
    trigger.action.outTextForGroup(p.gid, "Your mission is " .. m.status .. ".", 10)
    return
  end
  B.brief(p, m)
end

function B.abandon(uname)
  local p = B.players[uname]
  if not p or not p.mission then return end
  B.war:leaveMission(p.mission, p.key)
  p.mission = nil
  trigger.action.outTextForGroup(p.gid, "Mission abandoned.", 10)
  B.buildMenu(p)
end

function B.showRecord(uname)
  local p = B.players[uname]
  if p then trigger.action.outTextForGroup(p.gid, DCC.pilots:summary(p.key), 30) end
end

function B.showLeaderboard(uname)
  local p = B.players[uname]
  if p then
    trigger.action.outTextForGroup(p.gid, "TOP PILOTS\n" .. table.concat(DCC.pilots:top(10), "\n"), 30)
  end
end

function B.showSquadrons(uname)
  local p = B.players[uname]
  if p then
    trigger.action.outTextForGroup(p.gid, "TOP SQUADRONS\n" .. table.concat(DCC.pilots:topSquadrons(10), "\n"), 30)
  end
end

-- The missions this aircraft is offered. Helicopters only see missions within
-- missions.heloRangeKm of where they spawned (slow movers: slowRangeKm), nearest
-- first (a 300 nm CSAR is no use to a Huey); if nothing is that close, the 3
-- nearest are offered instead.
function B.missionsFor(p)
  local out = {}
  for _, m in ipairs(B.war:openMissions(p.side)) do
    if B.canFly(p, m) then out[#out + 1] = m end
  end
  local rangeKm = B.localRangeKm(p)
  if not rangeKm or not p.spawn then return out end
  local range = rangeKm * 1000
  local list = {}
  for _, m in ipairs(out) do
    local pos = B.missionPos(m)
    local d = pos and math.sqrt((pos.x - p.spawn.x) ^ 2 + (pos.z - p.spawn.z) ^ 2) or math.huge
    list[#list + 1] = { m = m, d = d }
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  local near = {}
  for i, e in ipairs(list) do
    if e.d <= range or (i <= 3 and list[1].d > range and e.d < math.huge) then
      -- a shallow copy, so the distance label never leaks into the war state
      local c = setmetatable({ _nm = math.floor(e.d / 1852 + 0.5) }, { __index = e.m })
      near[#near + 1] = c
    end
  end
  return near
end

-- (Re)build one aircraft's "Missions" menu.
function B.buildMenu(p)
  if not p.gid then return end
  if p.menu then ok(missionCommands.removeItemForGroup, p.gid, p.menu) end
  local root = missionCommands.addSubMenuForGroup(p.gid, "Missions")
  p.menu = root
  -- One submenu per mission type this aircraft can fly ("SEAD (2)"), so the
  -- F10 page never overflows (DCS shows at most 10 items per page).
  local byType, order = {}, {}
  for _, m in ipairs(B.missionsFor(p)) do
    if not byType[m.type] then byType[m.type] = {}; order[#order + 1] = m.type end
    table.insert(byType[m.type], m)
  end
  for _, t in ipairs(order) do
    local sub = missionCommands.addSubMenuForGroup(p.gid, string.format("%s (%d)", t, #byType[t]), root)
    for i, m in ipairs(byType[t]) do
      if i <= 9 then
        local mark = (p.mission == m.id) and "> " or ""
        local far = m._nm and string.format(" (%d nm)", m._nm) or ""
        missionCommands.addCommandForGroup(p.gid, mark .. m.type .. ": " .. m.label .. far, sub, B.takeMission,
          { unit = p.unit, mid = m.id })
      end
    end
  end
  missionCommands.addCommandForGroup(p.gid, "My mission (brief again)", root, B.myMission, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Abandon mission", root, B.abandon, p.unit)
  missionCommands.addCommandForGroup(p.gid, "My pilot record", root, B.showRecord, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Leaderboard", root, B.showLeaderboard, p.unit)
  missionCommands.addCommandForGroup(p.gid, "Squadron leaderboard", root, B.showSquadrons, p.unit)
  local lift = (cat().lift or {})[p.type]
  if lift and not B.ctldActive then           -- with CTLD in the mission, CTLD's own menu does cargo
    local c = missionCommands.addSubMenuForGroup(p.gid, "Cargo", root)
    if lift.crates > 0 then missionCommands.addCommandForGroup(p.gid, "Load supply crate", c, B.loadCrate, p.unit) end
    if lift.troops > 0 then missionCommands.addCommandForGroup(p.gid, "Load troops", c, B.loadTroops, p.unit) end
    missionCommands.addCommandForGroup(p.gid, "Unload", c, B.unload, p.unit)
    missionCommands.addCommandForGroup(p.gid, "Cargo status", c, B.cargoStatus, p.unit)
  end
end

function B.refreshMenus()
  for _, p in pairs(B.players) do B.buildMenu(p) end
end

-- ===========================================================================
-- 3. Detection (every 10 s)
-- ===========================================================================
function B.detect()
  local war, mc = B.war, DCC.config.missions
  B.detectCount = (B.detectCount or 0) + 1
  for uname, p in pairs(B.players) do
    local u = unitByName(uname)
    if not alive(u) then
      -- unit gone without an event (slot change): tidy up
      if timer.getTime() - p.born > 30 then B.clearPlayer(uname, "left") end
    else
      local pos = u:getPoint()
      local m = p.mission and war.state.missions[p.mission]
      if m and m.status == "open" then
        local tpos = B.missionPos(m)
        if m.type == "RECON" and tpos and dist2D(pos, tpos) <= mc.reconRadiusKm * 1000 and agl(u) <= mc.reconMaxAglM then
          war:completeMission(m.id, true)
          trigger.action.outTextForGroup(p.gid, "Recon pass complete - " .. war:nodeName(m.target) .. " is on your map.", 15)
        elseif m.type == "CAP" and tpos and dist2D(pos, tpos) <= mc.capRadiusKm * 1000 then
          p.capSeconds = p.capSeconds + 10
          if p.capSeconds >= mc.capMinutes * 60 then
            war:completeMission(m.id, true)
            trigger.action.outTextForGroup(p.gid, "CAP complete - air superiority over " .. war:nodeName(m.target) .. " for 1 h.", 15)
          end
        elseif (m.type == "ESCORT" or m.type == "CONVOY") and B.detectCount % 3 == 0 then
          local limit = (m.type == "ESCORT") and mc.escortRadiusKm or mc.convoyEscortKm
          war:escortSample(m.id, tpos ~= nil and dist2D(pos, tpos) <= limit * 1000)
        end
      end
      B.csarCheck(p, u, pos)
    end
  end
end

-- ===========================================================================
-- 4. SAM sites
-- ===========================================================================
local function playerNear(pos, km)
  for _, pp in ipairs(B.playerPositions()) do
    if dist2D(pp, pos) <= km * 1000 then return true end
  end
  return false
end

function B.spawnSam(id)
  local ns = B.war.state.nodes[id]
  local spec = cat().sam and cat().sam[ns.side]
  if not spec then return end
  local units, k = {}, 0
  local function add(list, tag)
    for i, t in ipairs(list) do
      if B.validType(t) then
        k = k + 1
        local sp = spotNear(id, 40 + k, 1500 + (k % 3) * 120)
        local off = ns.sam.off                             -- the site moved (shoot and scoot)
        if off then sp = { x = sp.x + off.dx, z = sp.z + off.dz } end
        units[#units + 1] = { name = "DCC_SAM_" .. id .. "_" .. tag .. i, type = t, skill = "High",
                              x = sp.x, y = sp.z, heading = 0, playerCanDrive = false }
      end
    end
  end
  if ns.sam.status == "up" then add(spec.radars, "r") end
  add(spec.launchers, "l")
  add(spec.support, "s")
  if #units == 0 then return end
  local gname = "DCC_SAM_" .. id
  local data = { name = gname, task = "Ground Nothing", units = units,
                 route = { points = { { x = units[1].x, y = units[1].y, type = "Turning Point",
                   action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  local s = pcall(coalition.addGroup, B.countryId(ns.side), Group.Category.GROUND, data)
  if s then B.sams[id] = { group = gname, status = ns.sam.status, side = ns.side } end
end

function B.despawnSam(id)
  local rec = B.sams[id]
  if rec then
    local g = ok(Group.getByName, rec.group)
    if g and ok(g.isExist, g) then g:destroy() end
    B.sams[id] = nil
  end
end

function B.pollSam(id, rec)
  local g = ok(Group.getByName, rec.group)
  local radars, launchers = 0, 0
  if g and ok(g.isExist, g) then
    for _, u in ipairs(g:getUnits() or {}) do
      if alive(u) and u:getLife() >= 1 then
        local n = u:getName()
        if n:find("_r%d+$") then radars = radars + 1 elseif n:find("_l%d+$") then launchers = launchers + 1 end
      end
    end
  end
  if radars == 0 and launchers == 0 then B.war:samHit(id, "destroyed")
  elseif radars == 0 and rec.status == "up" then B.war:samHit(id, "radar") end
end

function B.reconcileSams()
  local war = B.war
  for id, rec in pairs(B.sams) do
    local ns = war.state.nodes[id]
    if ns.sam then B.pollSam(id, rec) end
    local want = ns.sam and ns.sam.status ~= "destroyed" and ns.side == rec.side
                 and playerNear(B.nodePos[id], DCC.config.ops.samLiveRadiusKm + 10)
    if not want or (ns.sam and ns.sam.status ~= rec.status) then B.despawnSam(id) end
  end
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    if not B.sams[id] and ns.sam and ns.sam.status ~= "destroyed"
       and playerNear(B.nodePos[id], DCC.config.ops.samLiveRadiusKm) then
      B.spawnSam(id)
    end
  end
end

-- ===========================================================================
-- 5. Structures (strike targets)
-- ===========================================================================
function B.reconcileStatics()
  local war = B.war
  for _, id in ipairs(war.T.order) do
    local ns = war.state.nodes[id]
    local inf = ns.infra
    local rec = B.statics[id]
    -- poll what exists
    if rec then
      for k, name in pairs(rec.names) do
        local o = ok(StaticObject.getByName, name)
        local dead = (not o) or (not ok(o.isExist, o)) or (ok(o.getLife, o) or 0) < 1
        if dead and rec.side == ns.side then war:infraHit(id, k) end
        if dead then rec.names[k] = nil end
      end
    end
    local want = inf and B.liveNodes[id]
    if rec and (not want or rec.side ~= ns.side) then
      for _, name in pairs(rec.names) do
        local o = ok(StaticObject.getByName, name)
        if o and ok(o.isExist, o) then o:destroy() end
      end
      B.statics[id], rec = nil, nil
    end
    if want then
      rec = rec or { side = ns.side, names = {} }
      B.statics[id] = rec
      for k = 1, inf.total do
        if not inf.lost[tostring(k)] and not rec.names[k] then
          local spec = (cat().infra or {})[k] or { type = "Warehouse", category = "Warehouses" }
          local sp = spotNear(id, k, 1900 + (k % 2) * 250)
          local name = string.format("DCC_INF_%s_%d_%d", id, k, B.war.state.tick)
          local s = pcall(coalition.addStaticObject, B.countryId(ns.side),
            { name = name, type = spec.type, category = spec.category, x = sp.x, y = sp.z, heading = 0, dead = false })
          if s then rec.names[k] = name end
        end
      end
    end
  end
end

-- ===========================================================================
-- 6. AI air sorties
-- ===========================================================================
function B.findTemplate(name)
  local mis = env.mission
  if not mis or not mis.coalition then return nil end
  for _, coal in pairs(mis.coalition) do
    for _, ctry in ipairs(coal.country or {}) do
      for _, catName in ipairs({ "plane", "helicopter" }) do
        local list = ctry[catName] and ctry[catName].group
        for _, g in ipairs(list or {}) do
          if g.name == name then return g end
        end
      end
    end
  end
end

local function waypoint(x, z, alt, speed, task)
  return { x = x, y = z, alt = alt, alt_type = "BARO", type = "Turning Point", action = "Turning Point",
           speed = speed, speed_locked = true, ETA = 0, ETA_locked = false, task = task }
end

local function combo(tasks)
  for i, t in ipairs(tasks) do t.number, t.auto, t.enabled = i, false, true end
  return { id = "ComboTask", params = { tasks = tasks } }
end

-- kind = "CAP" | "CAS" | "INTERCEPT"; target = map point; extra.groupId for intercepts
function B.spawnSortie(side, role, kind, target, extra)
  local tpl = B.findTemplate("DCC_TPL_" .. side .. "_" .. role)
  if not tpl then
    if not B.warnedTpl then U.log("AI air: template DCC_TPL_%s_%s not found - regenerate the mission", side, role) end
    B.warnedTpl = true
    return nil
  end
  if not B.war:airAvailable(side, role, #tpl.units) then return nil end
  local base = nearestNodeOf(target, side)
  local from = base and B.nodePos[base] or target
  local hdg = math.atan2(target.z - from.z, target.x - from.x)
  local sp = { x = from.x + math.cos(hdg) * 8000, z = from.z + math.sin(hdg) * 8000 }
  local alt = (kind == "CAS") and 3500 or 7000
  B.sortieCount = B.sortieCount + 1
  local gname = string.format("DCC_AIR_%s_%s_%d", side, kind, B.sortieCount)
  local data = U.copy(tpl)
  data.name, data.lateActivation, data.groupId = gname, nil, nil
  data.task = (kind == "CAS") and "CAS" or "CAP"
  for i, u in ipairs(data.units) do
    u.unitId = nil
    u.name = gname .. "_" .. i
    u.x, u.y, u.alt, u.alt_type = sp.x + (i - 1) * 200, sp.z + (i - 1) * 200, alt, "BARO"
    u.speed, u.heading, u.skill = 220, hdg, "High"
  end
  local task
  if extra and extra.task then
    task = combo(extra.task)
  elseif kind == "CAP" then
    task = combo({ { id = "EngageTargets", key = "CAP", params = { targetTypes = { "Air" }, priority = 0, maxDist = 70000 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 220 } } })
  elseif kind == "CAS" then
    task = combo({ { id = "EngageTargetsInZone", params = { point = { x = target.x, y = target.z }, zoneRadius = 5000,
                     targetTypes = { "Ground Units" }, priority = 0 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 180 } } })
  else
    task = combo({ { id = "AttackGroup", params = { groupId = extra.groupId } },
                   { id = "EngageTargets", params = { targetTypes = { "Air" }, priority = 0, maxDist = 60000 } },
                   { id = "Orbit", params = { pattern = "Circle", altitude = alt, speed = 220 } } })
  end
  data.route = { points = { waypoint(sp.x, sp.z, alt, 220, combo({})), waypoint(target.x, target.z, alt, 220, task) } }
  local s, err = pcall(coalition.addGroup, B.countryId(side), Group.Category.AIRPLANE, data)
  if not s then U.log("AI sortie spawn failed: %s", tostring(err)); return nil end
  B.war:airTake(side, role, #data.units)
  local life = (kind == "CAP") and 3600 or (kind == "CAS" and 2400 or 2700)
  if extra and extra.life then life = extra.life end
  B.sorties[gname] = { side = side, role = role, kind = kind, born = timer.getTime(), life = life,
                       size = #data.units, alive = #data.units, node = extra and extra.node }
  trigger.action.outTextForCoalition(B.COAL[side], string.format("Command: %s %s sortie airborne%s", side:upper(),
    kind, extra and extra.node and (" toward " .. B.war:nodeName(extra.node)) or ""), 10)
  return gname
end

function B.pollSorties()
  for gname, s in pairs(B.sorties) do
    local g = ok(Group.getByName, gname)
    local n = 0
    if g and ok(g.isExist, g) then
      for _, u in ipairs(g:getUnits() or {}) do if alive(u) and u:getLife() >= 1 then n = n + 1 end end
    end
    if n < s.alive then B.war:airLoss(s.side, s.role, s.alive - n); s.alive = n end
    if n == 0 or timer.getTime() - s.born > s.life then
      if n > 0 then B.war:airReturn(s.side, s.role, n) end
      if g and ok(g.isExist, g) then g:destroy() end
      B.sorties[gname] = nil
    end
  end
end

local function activeSorties(side, kind)
  local list = {}
  for gname, s in pairs(B.sorties) do if s.side == side and s.kind == kind then list[#list + 1] = s end end
  return list
end

-- Decide AI sorties once per tick (only while someone is flying).
function B.planAir()
  local war = B.war
  if #B.playerPositions() == 0 then return end
  for _, side in ipairs({ "blue", "red" }) do
    local enemy = U.otherSide(side)
    -- CAP over the main-effort staging area
    if #activeSorties(side, "CAP") == 0 then
      local f = war.state.focus and war.state.focus[side]
      if f then
        for _, nb in ipairs(U.sortedKeys(war.T.nodes[f.target].nb)) do
          if war.state.nodes[nb].side == side then
            B.spawnSortie(side, "fighter", "CAP", B.nodePos[nb], { node = nb })
            break
          end
        end
      end
    end
    -- CAS on live battles, unless the enemy holds the air or a SAM covers it
    local cas = #activeSorties(side, "CAS")
    for _, mid in ipairs(U.sortedKeys(war.state.moves)) do
      if cas >= 2 then break end
      local mv = war.state.moves[mid]
      if mv.status == "fighting" and B.liveNodes[mv.to] then
        local ns = war.state.nodes[mv.to]
        local involved = (mv.side == side) or (ns.side == side)
        local covered = war:hasAirCover(enemy, mv.to)
        local samUp = ns.side == enemy and ns.sam and ns.sam.status == "up"
        local already = false
        for _, s in pairs(B.sorties) do if s.side == side and s.kind == "CAS" and s.node == mv.to then already = true end end
        if involved and not covered and not samUp and not already then
          if B.spawnSortie(side, "attack", "CAS", B.nodePos[mv.to], { node = mv.to }) then cas = cas + 1 end
        end
      end
    end
    -- Intercept an enemy airlift now and then
    if #activeSorties(side, "INTERCEPT") == 0 and war.rng:next() < 0.25 then
      for mid, rec in pairs(B.cargo) do
        local mv = war.state.moves[mid]
        if rec.kind == "airlift" and mv and mv.side == enemy then
          local g = ok(Group.getByName, rec.group)
          local u = g and ok(g.getUnit, g, 1)
          if alive(u) then
            B.spawnSortie(side, "fighter", "INTERCEPT", u:getPoint(), { groupId = g:getID() })
            break
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- 7. CSAR
-- ===========================================================================
function B.spawnDowned(did)
  local d = B.war.state.downed[did]
  local t = (cat().downedPilot or {})[d.side] or "Soldier M4"
  local gname = "DCC_CSAR_" .. did
  local data = { name = gname, task = "Ground Nothing",
                 units = { { name = gname .. "_1", type = t, skill = "Average", x = d.pos.x, y = d.pos.z, heading = 0 } },
                 route = { points = { { x = d.pos.x, y = d.pos.z, type = "Turning Point", action = "Off Road",
                   speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(d.side), Group.Category.GROUND, data) then
    B.downedGroups[did] = gname
    local g = ok(Group.getByName, gname)
    local c = g and ok(g.getController, g)
    if c then ok(c.setOption, c, AI and AI.Option.Ground.id.ROE or 0, AI and AI.Option.Ground.val.ROE.WEAPON_HOLD or 4) end
  end
end

function B.reconcileDowned()
  for did, gname in pairs(B.downedGroups) do
    if not B.war.state.downed[did] then
      local g = ok(Group.getByName, gname)
      if g and ok(g.isExist, g) then g:destroy() end
      B.downedGroups[did] = nil
    end
  end
  for did in pairs(B.war.state.downed) do
    if not B.downedGroups[did] then B.spawnDowned(did) end
  end
end

function B.onEjection(u)
  local name = ok(u.getPlayerName, u)
  if not name then return end
  local p = B.players[u:getName()]
  local key = p and p.key or playerKey(name)
  DCC.pilots:add(key, "ejections", 1, name)
  local pos = u:getPoint()
  local t = land.getSurfaceType({ x = pos.x, y = pos.z })
  if t == land.SurfaceType.WATER or t == land.SurfaceType.SHALLOW_WATER then return end
  local did = B.war:addDowned(sideOfUnit(u), { x = pos.x + 150, z = pos.z + 150 }, name, u:getTypeName(),
    p and p.home, key)
  B.spawnDowned(did)
  trigger.action.outTextForCoalition(B.COAL[sideOfUnit(u)], string.format(
    "MAYDAY - %s is down. CSAR on the mission board. 2 hours before capture.", name), 20)
  B.refreshMenus()
end

function B.csarCheck(p, u, pos)
  local lift = (cat().lift or {})[p.type]
  if not lift then return end
  local war = B.war
  -- pickups
  for did, d in pairs(war.state.downed) do
    if d.side == p.side then
      local dd = dist2D(pos, { x = d.pos.x, z = d.pos.z })
      if dd < 2500 and not d.smoked then
        d.smoked = true
        ok(trigger.action.smoke, wpos({ x = d.pos.x, z = d.pos.z }), trigger.smokeColor and trigger.smokeColor.Green or 0)
      end
      if dd <= 150 and landed(u) and not p.onboard[did] then
        p.onboard[did] = true
        local gname = B.downedGroups[did]
        local g = gname and ok(Group.getByName, gname)
        if g and ok(g.isExist, g) then g:destroy() end
        B.downedGroups[did] = "onboard"
        trigger.action.outTextForGroup(p.gid, "Pilot " .. tostring(d.pilot) .. " on board. Land at a friendly base.", 15)
      end
    end
  end
  -- drop-offs at a friendly base
  if next(p.onboard) and landed(u) then
    local node = nearestNodeOf(pos, p.side, 3000)
    if node then
      for did in pairs(p.onboard) do
        local d = war.state.downed[did]
        if d and war:rescue(did, node) then
          DCC.pilots:add(p.key, "rescues", 1, p.name)
          if d.key then DCC.pilots:add(d.key, "saved", 1) end
          trigger.action.outTextForCoalition(B.COAL[p.side], string.format("%s rescued %s - aircraft returned to %s.",
            p.name, tostring(d.pilot), war:nodeName(node)), 15)
        end
        p.onboard[did] = nil
      end
    end
  end
end

-- ===========================================================================
-- 8. Logistics (helicopter cargo)
-- ===========================================================================
local function liftOf(p) return (cat().lift or {})[p.type] or { crates = 0, troops = 0 } end

local function landedAt(p, sideFilter)
  local u = unitByName(p.unit)
  if not landed(u) then
    trigger.action.outTextForGroup(p.gid, "Land first.", 8)
    return nil
  end
  local node = nearestNodeOf(u:getPoint(), sideFilter, 3000)
  if not node then trigger.action.outTextForGroup(p.gid, "No base within 3 km.", 8) end
  return node
end

local function setCargoMass(p)
  ok(trigger.action.setUnitInternalCargo, p.unit, p.crates * 1000 + #p.troops * 1200)
end

function B.loadCrate(uname)
  local p = B.players[uname]
  if not p then return end
  if p.crates >= liftOf(p).crates then
    return trigger.action.outTextForGroup(p.gid, "Cargo bay full.", 8)
  end
  local node = landedAt(p, p.side)
  if not node then return end
  local su = B.war:takeCrate(node, DCC.config.ops.crateSU)
  if su <= 0 then return trigger.action.outTextForGroup(p.gid, B.war:nodeName(node) .. " has no supply to spare.", 8) end
  p.crates = p.crates + 1
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, string.format("Supply crate loaded at %s (%d on board).", B.war:nodeName(node), p.crates), 10)
end

function B.loadTroops(uname)
  local p = B.players[uname]
  if not p then return end
  if #p.troops >= liftOf(p).troops then
    return trigger.action.outTextForGroup(p.gid, "No room for more troops.", 8)
  end
  local node = landedAt(p, p.side)
  if not node then return end
  local ns = B.war.state.nodes[node]
  if #ns.platoons <= 1 then return trigger.action.outTextForGroup(p.gid, "No troops to spare here.", 8) end
  local list = B.war:sortedGarrison(node, false)
  local pid = list[#list]
  for i = #list, 1, -1 do
    if B.war.state.platoons[list[i]].role == "MECH_PLT" then pid = list[i]; break end
  end
  local rec = B.spawned[pid]
  if rec then B.despawn(pid, rec) end
  B.war:carryPlatoon(pid, uname)
  p.troops[#p.troops + 1] = pid
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, "One platoon on board. Unload at a friendly base, or at an enemy base to attack it.", 12)
end

function B.unload(uname)
  local p = B.players[uname]
  if not p then return end
  local node = landedAt(p, nil)
  if not node then return end
  local war = B.war
  local friendly = war.state.nodes[node].side == p.side
  local msg = {}
  if p.crates > 0 then
    if friendly then
      war:deliverCrate(p.side, node, p.crates * DCC.config.ops.crateSU)
      msg[#msg + 1] = string.format("%d supply crate(s) delivered to %s.", p.crates, war:nodeName(node))
      p.crates = 0
    else
      msg[#msg + 1] = "Crates can only be unloaded at a friendly base."
    end
  end
  if #p.troops > 0 then
    local r = war:dropPlatoons(p.troops, node, p.side)
    msg[#msg + 1] = (r == "assault") and ("Troops are attacking " .. war:nodeName(node) .. "!")
                    or ("Troops landed at " .. war:nodeName(node) .. ".")
    p.troops = {}
  end
  setCargoMass(p)
  trigger.action.outTextForGroup(p.gid, #msg > 0 and table.concat(msg, "\n") or "Nothing on board.", 12)
end

function B.cargoStatus(uname)
  local p = B.players[uname]
  if not p then return end
  local l = liftOf(p)
  local pilots = 0
  for _ in pairs(p.onboard) do pilots = pilots + 1 end
  trigger.action.outTextForGroup(p.gid, string.format("Crates %d/%d, troops %d/%d, rescued pilots %d",
    p.crates, l.crates, #p.troops, l.troops, pilots), 10)
end

-- ===========================================================================
-- 9. Convoy escort ambush
-- ===========================================================================
function B.spawnAmbush(m)
  if B.ambushes[m.id] then return end
  local mv = B.war.state.moves[m.target]
  if not mv then return end
  local enemy = U.otherSide(m.side)
  local types = (cat().ambush or {})[enemy]
  if not types then return end
  local a, b = B.nodePos[mv.from], B.nodePos[mv.to]
  local t = math.max(mv.progress + 0.25, 0.6)
  local x, z = a.x + (b.x - a.x) * t + 250, a.z + (b.z - a.z) * t + 250
  local gname = "DCC_AMB_" .. m.id
  local units = {}
  for i, ty in ipairs(types) do
    if B.validType(ty) then
      units[#units + 1] = { name = gname .. "_" .. i, type = ty, skill = "Average", x = x + i * 15, y = z + i * 10, heading = 0 }
    end
  end
  if #units == 0 then return end
  local data = { name = gname, task = "Ground Nothing", units = units, route = { points = {
    { x = x, y = z, type = "Turning Point", action = "Off Road", speed = 0, ETA = 0, ETA_locked = false, speed_locked = true } } } }
  if pcall(coalition.addGroup, B.countryId(enemy), Group.Category.GROUND, data) then B.ambushes[m.id] = gname end
end

function B.cleanAmbushes()
  for mid, gname in pairs(B.ambushes) do
    local m = B.war.state.missions[mid]
    if not m or m.status ~= "open" then
      local g = ok(Group.getByName, gname)
      if g and ok(g.isExist, g) then g:destroy() end
      B.ambushes[mid] = nil
    end
  end
end

-- ===========================================================================
-- Kill credit and events
-- ===========================================================================
function B.onKill(e)
  local shooter = e.initiator
  local name = shooter and ok(shooter.getPlayerName, shooter)
  if not name then return end
  local p = B.players[shooter:getName()]
  local key = p and p.key or playerKey(name)
  local tgt = e.target
  if not tgt then return end
  local tname = ok(tgt.getName, tgt) or ""
  local field = "kills_ground"
  local category = ok(Object.getCategory, tgt)
  if category == Object.Category.STATIC then
    if not tname:find("^DCC_INF") and not tname:find("^DCC_FORT") and not tname:find("^DCC_IND") then return end
    field = "kills_structure"
  else
    local desc = ok(tgt.getDesc, tgt)
    if desc and (desc.category == Unit.Category.AIRPLANE or desc.category == Unit.Category.HELICOPTER) then
      field = "kills_air"
    elseif tname:find("^DCC_[ca]%d") then field = "kills_convoy"
    elseif tname:find("^DCC_SAM") or tname:find("^DCC_EWR") then field = "kills_sam" end
  end
  DCC.pilots:add(key, field, 1, name)
  -- an air kill completes a CAP on station
  if field == "kills_air" and p and p.mission then
    local m = B.war.state.missions[p.mission]
    if m and m.type == "CAP" and m.status == "open" then
      local tp = B.nodePos[m.target]
      if tp and dist2D(shooter:getPoint(), tp) <= DCC.config.missions.capRadiusKm * 1000 then
        B.war:completeMission(m.id, true)
      end
    end
  end
end

function B.onOpsEvent(e)
  local ev = world.event
  local u = e.initiator
  if e.id == ev.S_EVENT_BIRTH then
    if u and ok(u.getPlayerName, u) and Object.getCategory(u) == Object.Category.UNIT then
      if alive(u) then B.registerPlayer(u) end
    end
  elseif e.id == ev.S_EVENT_TAKEOFF then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p and not p.takeoff then
      p.takeoff = timer.getTime()
      DCC.pilots:sortie(p.key, p.side, B.war.T.name, p.name)
      B.war:recordSortie(p.key, p.side, p.name, DCC.pilots:score(p.key))   -- who flew for whom (victory bonus, report)
    end
  elseif e.id == ev.S_EVENT_LAND then
    local p = u and B.players[ok(u.getName, u) or ""]
    if p and p.takeoff then
      DCC.pilots:add(p.key, "flightMinutes", (timer.getTime() - p.takeoff) / 60)
      p.takeoff = nil
    end
  elseif e.id == ev.S_EVENT_KILL then
    B.onKill(e)
  elseif e.id == ev.S_EVENT_SHOT then
    if B.onShot then B.onShot(e) end
  elseif e.id == ev.S_EVENT_EJECTION then
    if u then B.onEjection(u) end
  elseif e.id == ev.S_EVENT_PILOT_DEAD then
    local name = u and ok(u.getPlayerName, u)
    if name then
      local p = B.players[u:getName()]
      DCC.pilots:add(p and p.key or playerKey(name), "deaths", 1, name)
    end
  elseif e.id == ev.S_EVENT_CRASH or e.id == ev.S_EVENT_DEAD then
    local un = u and ok(u.getName, u)
    if un and B.players[un] then B.clearPlayer(un, "lost") end
  elseif e.id == ev.S_EVENT_PLAYER_LEAVE_UNIT then
    local un = u and ok(u.getName, u)
    if un and B.players[un] then B.clearPlayer(un, "left") end
  end
end

-- Credits for missions finished in the model.
function B.onMissionDone(m, outcome)
  for key, name in pairs(m.taken) do
    if outcome == "done" then DCC.pilots:mission(key, m.type, name) end
    for _, p in pairs(B.players) do
      if p.key == key and p.mission == m.id then
        trigger.action.outTextForGroup(p.gid, string.format("Mission %s: %s %s.",
          outcome == "done" and "COMPLETE" or outcome:upper(), m.type, m.label), 15)
        p.mission = nil
      end
    end
  end
end

-- ===========================================================================
-- 10. Map extras
-- ===========================================================================
function B.drawOps(newMark, toVec3)
  local war, cfg = B.war, DCC.config
  for _, id in ipairs(war.T.order) do
    local ns, pos = war.state.nodes[id], B.nodePos[id]
    if ns.sam and ns.sam.status ~= "destroyed" then
      local col = cfg.colours[ns.side]
      trigger.action.circleToAll(B.COAL[ns.side], newMark(), pos, 25000, { col[1], col[2], col[3], 0.5 },
        { 0, 0, 0, 0 }, 2, true, "")
      trigger.action.textToAll(B.COAL[ns.side], newMark(), { x = pos.x - 26000, y = pos.y, z = pos.z }, col,
        { 0, 0, 0, 0 }, 10, true, "SAM " .. ns.sam.status)
    end
  end
  for _, side in ipairs(war.fogOfWar and {} or { "blue", "red" }) do   -- with fog: dcc_dcs_intel.lua
    for id, i in pairs(war.state.intel[side]) do
      local ns = war.state.nodes[id]
      if ns and ns.side ~= side then
        local age = (war.state.tick - i.tick) * cfg.tickSeconds / 3600
        local pos = B.nodePos[id]
        trigger.action.textToAll(B.COAL[side], newMark(), { x = pos.x + 4000, y = pos.y, z = pos.z + 3000 },
          { 1, 1, 1, 1 }, { 0, 0, 0, 0.5 }, 10, true,
          string.format("Recon %.0fh ago: %d plt, SAM %s", age, i.platoons, i.sam))
      end
    end
  end
  for _, d in pairs(war.state.downed) do
    trigger.action.textToAll(B.COAL[d.side], newMark(), wpos({ x = d.pos.x, z = d.pos.z }), { 0.2, 1, 0.2, 1 },
      { 0, 0, 0, 0.5 }, 11, true, "Downed: " .. tostring(d.pilot))
  end
end

function B.opsStatusLines(side)
  local war = B.war
  local pool = war.state.airPool[side]
  local open = #war:openMissions(side)
  return { string.format("Air force: %d fighters, %d attack aircraft. Open missions: %d", pool.fighter, pool.attack, open) }
end

-- ===========================================================================
-- Per-tick and per-poll entry points (called from dcc_main.lua)
-- ===========================================================================
function B.updateForced()
  B.forced = {}
  for _, m in pairs(B.war.state.missions or {}) do
    if m.status == "open" and next(m.taken) and B.war.state.moves[m.target] then B.forced[m.target] = true end
  end
end

function B.opsPoll()
  B.pollSorties()
  B.reconcileSams()
  B.reconcileStatics()
  B.reconcileDowned()
end

function B.opsTick()
  B.updateForced()
  B.cleanAmbushes()
  B.planAir()
  B.refreshMenus()
end
